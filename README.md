# CoreOS Vagrant Kitchen Sink

This is a fork of [CoreOS Vagrant](https://github.com/coreos/coreos-vagrant) with [flannel](https://github.com/coreos/flannel), Kelsey Hightower's [kubernetes-coreos](https://github.com/kelseyhightower/kubernetes-coreos), and a growing number of other useful fleet units.

Technically, flannel isn't neccessary to get coreos working with kubernetes and vagrant. The point of this project is to gain some experience with flannel and kubernetes for eventual deployment in the cloud.

You may want to read Kelsey Hightower's [Running Kubernetes Example on CoreOS, Part 1](https://coreos.com/blog/running-kubernetes-example-on-CoreOS-part-1/) and [Running Kubernetes Example on CoreOS, Part 2](https://coreos.com/blog/running-kubernetes-example-on-CoreOS-part-2/) before continuing.

Kelsey assumes VMWare Fusion above. As the [CoreOS Vagrant](https://github.com/coreos/coreos-vagrant) works with VirtualBox or VMWare Fusion.

The start.sh script included runs through the steps in an automated fashion.

# Usage:

Run `./start.sh`

By default, this will deploy a fleet based kubernetes across 3 vagrant virtual machines.

# Preparation:

You will also want to install the `kubecfg` command.

    ./install_kubecfg_client.sh

As this is a binary, this is NOT being run automatically as part of the start.sh.
While this is an official google kubernetes binary via an HTTPS wget, there is no signature verification.
This works both with OS/X Darwin and with Linux.

The default kubeletes apiserver host is "localhost" and the default port is "8080". 
You may need to port-forward 8080 to use kubecfg locally if not run on the master.

To list which node the master/controller landed on, run this:

    vagrant ssh core-01 -- fleetctl list-units

Ideally, they landed on the first/default core node: core-01.

To port forward using vagrant ssh, do this:

    vagrant ssh core-01 -- fleetctl ssh -L 8080:localhost:8080

This will let you run the kubecfg command locally without having to specify the `-h http://hostname:port` parameter.

You can also run this `install_kubecfg_client.sh` script on a coreos host:

    ./install_kubecfg_client.sh core-01

NOTE: You would have to do this everytime you do a "vagrant destroy" followed by a "vagrant up" as the coreos nodes will be completely new.


Using kubecfg:

To list the current pods:

    kubecfg list /pods

To run a pod:

    kubecfg -c pods/redis.json create /pods

There are other pods in the pods/ folder of this project. At the moment, it is only redis.json, but rest assured there will be others soon.

Should you find yourself on the master wishing you had the pods/ folder from this project, you can run this locally to copy the folder over to that coreos node:

    tar cf - pods/ | vagrant ssh core-01 -c 'tar xf -'

Alternatively, you can enable sharing of the project via NFS from your host over to /home/core/share in the guest by setting:

    export USE_SHARED_FOLDER=1

As this requires sudo access and asks you to enter your password to enable, this is defaulted as off to avoid as much required privilege as possible.

If you have any further questions, join us on IRC via [freenode](https://freenode.net/) in either [#coreos](http://webchat.freenode.net/?channels=coreos) or [#google-containers](http://webchat.freenode.net/?channels=google-containers)

# Implementation Details:

This project has been entirely refactored to rely on a cloud-init bootstrap using a generated user-data config.

All of the units and write_file segments concatenated by the start.sh script are in the cloud-init/ folder in this project.

The sole purpose of the start.sh script is to generates a "user-data" config in this project's main directory and run vagrant up.

While not strictly necessary for anything but kubernetes and libswarm/panamax at the moment, flannel (previously known as rudder) is included by default.

The config.rb referenced by the Vagrantfile will populate the `ETCD_DISCOVERY_URL` in the user-data file.

All nodes will start with the generated user-data file.

In earlier version of this project, start.sh would vagrant ssh in and install the master/controller systemd units for kubernetes. 
To keep things clean, the "master" node for kubernetes is now chosen by fleet when the unit is scheduled. 

The only hard-coded IP is the flannel subnet, as embedded in minion.yml, which is set to 172.30.0.0/16 at the moment so as not to collide with any other RFC1918 address spaces that are common.
All other IP information is discovered via vagrant ssh into the coreos nodes.

# Cloud deployment

As this is all standard vagrant faire, it should be possible to use [mitchellh/vagrant-aws](https://github.com/mitchellh/vagrant-aws) or other vagrant cloud plugins to deploy this to the cloud instead of locally for testing. If you manage to get any of these working, a pull request is most welcomed!

You may also be interested in [bketelsen/coreos-kubernetes-digitalocean](https://github.com/bketelsen/coreos-kubernetes-digitalocean), which was helpful in generating this project.

Also, [metral/corekube](https://github.com/metral/corekube) is another recent effort by @mikemetral for OpenStack/Rackspace Heat template deployment of CoreOS/Kubernetes. See Mike's (blog post)[http://bit.ly/Zh4C93] for more information.

# Panamax and libswarm

This also supports spinning up a panamax cluster on top of libswarm. To enable this, export the following variables before running the `start.sh` script:

    export ENABLE_LIBSWARM=true
    export ENABLE_PANAMAX=true

You can also disable Kubernetes entirely, if you would like:

    export ENABLE_KUBERNETES=false

Note: libswarm is currently under active development, so you may run into issues. Using Panamax this way is also entirely unanticipated.

If you wish to access the panamax UI, forward port 3000 using vagrant ssh:

    vagrant ssh core-01 -- -L 3000:localhost:3000

Or by changing your vagrant VM settings as in the Panamax [How-To: Port Forwarding on Virtualbox](https://github.com/CenturyLinkLabs/panamax-ui/wiki/How-To%3A-Port-Forwarding-on-VirtualBox).

Then open your web browser to http://localhost:3000

# Elasticsearch, Logstash, Kibana

If you wish to check out a self-clustering Kibana deployment on CoreOS, try out:

    COREOS_MEMORY=2048 ENABLE_KUBERNETES=false ENABLE_ELASTICSEARCH=true ENABLE_KIBANA=true ENABLE_LOGSTASH=true ./start.sh

After this downloads and installs the fleet units, you should be able to ssh in with a port forward and check out the kibana webpage on any vagrant node:

    vagrant ssh core-01 -- -L 8090:localhost:8090 -L 9200:localhost:9200

Open your browser to:

    http://localhost:8090

The logstash is setup to forward ElasticSearch all nodes json systemd journalctl output as well as logspout output from the docker container logs.

Now you have distributed searchable logging.

# Deis

This deploys a deis cluster automagically using current deisctl 0.13-beta+ best practices.

    COREOS_MEMORY=2048 ENABLE_KUBERNETES=false DEIS=true ./start.sh

Now you have the beginnings of a PaaS. Next step, visit [deis.io](http://deis.io)

Thanks to deis 0.13 and later, deis-store also presents a deis-database postgres unit that now wal-e archives to a deis-store s3 backend based on ceph + radosgw.
This effectively provides an HA Postgres DBaaS layer.

# Heapster / Grafana / cadvisor / influxdb

This deploys a kubernetes aware cadvisor, thanks to [heapster](https://github.com/GoogleCloudPlatform/heapster), integrated with grafana and a clustered tutum influxdb backend with 3 data replicas.

    COREOS_MEMORY=2048 ENABLE_HEAPSTER=true ./start.sh

Now you have distributed searchable system metrics.

This also installs elasticsearch, as that is a dependency for grafana.

# Galera (MySQL cluster)

This deploys a Galera MySQL cluster:

    ENABLE_GALERA=true ./start.sh

Now you have the beginnings of a MySQL DBaaS layer.

Presently, a galera-data container is created for the persistent volume rather than simply a referenced coreos host shared volume.
This may change.
The decision whether to globally adopt coreos host shared volume model or docker data containers for persistence volumes hasn't been made yet.

# Zookeeper

This deploys a fleet of zookeeper containers that are configured to bootstrap their initial discovery from etcd fleet membership:

    ENABLE_KUBERNETS=false ENABLE_ZOOKEEPER=true ./start.sh

Nothing else needs this. Yet.

# Future...

I'm actively trying to get a couchbase fleet going now, with cbfs after that. Having an HA memcache layer is at the top of my short list.

Getting deis-store going with ceph osd and radosgw is a close second. Eventually, that will be rolled into deis 0.13, it's just a waiting game at this point.
With deis-store for wal-e backending deis-database, clustered postgres is a reality.

HA redis is another personal goal. Sharding redis with twemproxy is nice as well. Having redis handle SLAVEOF automagically to the etcd leader on the loss of a master node would be even better.

After the persistence is sorted out (if it is even wise to attempt that yet on immutable infrastructure), influxdb and cadvisor for performance monitoring will happen as well.

# Now back to your regularly scheduled program

Everything below this point in the README is from the original CoreOS Vagrant project upon which this fork is based.


# CoreOS Vagrant

This repo provides a template Vagrantfile to create a CoreOS virtual machine using the VirtualBox software hypervisor.
After setup is complete you will have a single CoreOS virtual machine running on your local machine.

## Streamlined setup

1) Install dependencies

* [VirtualBox][virtualbox] 4.3.10 or greater.
* [Vagrant][vagrant] 1.6 or greater.

2) Clone this project and get it running!

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant
```

3) Startup and SSH

There are two "providers" for Vagrant with slightly different instructions.
Follow one of the following two options:

**VirtualBox Provider**

The VirtualBox provider is the default Vagrant provider. Use this if you are unsure.

```
vagrant up
vagrant ssh
```

**VMware Provider**

The VMware provider is a commercial addon from Hashicorp that offers better stability and speed.
If you use this provider follow these instructions.

```
vagrant up --provider vmware_fusion
vagrant ssh
```

``vagrant up`` triggers vagrant to download the CoreOS image (if necessary) and (re)launch the instance

``vagrant ssh`` connects you to the virtual machine.
Configuration is stored in the directory so you can always return to this machine by executing vagrant ssh from the directory where the Vagrantfile was located.

3) Get started [using CoreOS][using-coreos]

[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/downloads.html
[using-coreos]: http://coreos.com/docs/using-coreos/

#### Shared Folder Setup

There is optional shared folder setup.
You can try it out by adding a section to your Vagrantfile like this.

```
config.vm.network "private_network", ip: "172.17.8.150"
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

#### Provisioning with user-data

The Vagrantfile will provision your CoreOS VM(s) with [coreos-cloudinit][coreos-cloudinit] if a `user-data` file is found in the project directory.
coreos-cloudinit simplifies the provisioning process through the use of a script or cloud-config document.

To get started, copy `user-data.sample` to `user-data` and make any necessary modifications.
Check out the [coreos-cloudinit documentation][coreos-cloudinit] to learn about the available features.

[coreos-cloudinit]: https://github.com/coreos/coreos-cloudinit

#### Configuration

The Vagrantfile will parse a `config.rb` file containing a set of options used to configure your CoreOS cluster.
See `config.rb.sample` for more information.

## Cluster Setup

Launching a CoreOS cluster on Vagrant is as simple as configuring `$num_instances` in a `config.rb` file to 3 (or more!) and running `vagrant up`.
Make sure you provide a fresh discovery URL in your `user-data` if you wish to bootstrap etcd in your cluster.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS.
Simply remove the old box file and vagrant will download the latest one the next time you `vagrant up`.

```
vagrant box remove coreos --provider vmware_fusion
vagrant box remove coreos --provider virtualbox
```

## Docker Forwarding

By setting the `$expose_docker_tcp` configuration value you can forward a local TCP port to docker on
each CoreOS machine that you launch. The first machine will be available on the port that you specify
and each additional machine will increment the port by 1.

Follow the [Enable Remote API instructions][coreos-enabling-port-forwarding] to get the CoreOS VM setup to work with port forwarding.

[coreos-enabling-port-forwarding]: https://coreos.com/docs/launching-containers/building/customizing-docker/#enable-the-remote-api-on-a-new-socket

Then you can then use the `docker` command from your local shell by setting `DOCKER_HOST`:

    export DOCKER_HOST=tcp://localhost:2375
