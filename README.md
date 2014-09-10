# Kubernetes on CoreOS

This is a fork of [CoreOS Vagrant](https://github.com/coreos/coreos-vagrant) with [rudder](https://github.com/coreos/rudder) and Kelsey Hightower's [kubernetes-coreos](https://github.com/kelseyhightower/kubernetes-coreos)

Technically, rudder isn't neccessary to get coreos working with kubernetes and vagrant. The point of this project is to gain some experience with rudder and kubernetes for eventual deployment in the cloud.

You may want to read Kelsey Hightower's [Running Kubernetes Example on CoreOS, Part 1](https://coreos.com/blog/running-kubernetes-example-on-CoreOS-part-1/) and [Running Kubernetes Example on CoreOS, Part 2](https://coreos.com/blog/running-kubernetes-example-on-CoreOS-part-2/) before continuing.

Kelsey assumes VMWare Fusion above. As the [CoreOS Vagrant](https://github.com/coreos/coreos-vagrant) works with VirtualBox or VMWare Fusion.

The start.sh script included runs through the steps in an automated fashion.

# Usage:

Run `./start.sh`

Note: This bootstraps through pulling down a golang docker container and compiling rudder, so it takes a bit to get going. Give it some time. Be patient. :)

# Preparation:

You will also want to install the `kubecfg` command.

    ./install_kubecfg_client.sh

As this is a binary, this is NOT being run automatically as part of the start.sh.
While this is an official google kubernetes binary via an HTTPS wget, there is no signature verification.
This works both with OS/X Darwin and with Linux.

The default kubeletes apiserver host is "localhost" and the default port is "8080". 
You may need to port-forward 8080 to use kubecfg locally if not run on the master.
To port forward using vagrant ssh, do this:

    vagrant ssh core-01 -- -L 8080:localhost:8080

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

Alternatively, you can follow the Shared Folder Setup below to share this project folder to your coreos nodes.
By commenting out the shared folder line in the Vagrantfile, you will be prompted for your password when you `vagrant up` as it attempts to configure your system to share the project folder using NFS.
This is defaulted as off to avoid as much required privilege as possible.

If you have any further questions, join us on IRC via [freenode](https://freenode.net/) in either [#coreos](http://webchat.freenode.net/?channels=coreos) or [#google-containers](http://webchat.freenode.net/?channels=google-containers)

# Implementation Details:

This script will generate a user-data script that is the concatenation of the user-data.sample and minion.yml files.
The `vagrant up` will bootstrap the coreos nodes with rudder, and docker will be restarted to use it.

The config.rb referenced by the Vagrantfile will populate the `ETCD_DISCOVERY_URL` in the user-data file.
All nodes will start with the generated user-data file.

Finally, the master node is provisioned to start the apiserver and controller-manager.

The only services not automatically installed by a `vagrant up` are the master's apiserver, and controller-manager services.

The `start.sh` script is really little more than a wrapper for preparing the master separately than the other minions.

The only hard-coded IP is the rudder subnet, as embedded in minion.yml, which is set to 172.30.0.0/16 at the moment so as not to collide with any other RFC1918 address spaces that are common.
All other IP information is discovered via vagrant ssh into the coreos nodes.

# Cloud deployment

As this is all standard vagrant faire, it should be possible to use [mitchellh/vagrant-aws](https://github.com/mitchellh/vagrant-aws) or other vagrant cloud plugins to deploy this to the cloud instead of locally for testing. If you manage to get any of these working, a pull request is most welcomed!

You may also be interested in [bketelsen/coreos-kubernetes-digitalocean](https://github.com/bketelsen/coreos-kubernetes-digitalocean), which was helpful in generating this project.

Also, [metral/corekube](https://github.com/metral/corekube) is another recent effort by @mikemetral for OpenStack/Rackspace Heat template deployment of CoreOS/Kubernetes. See Mike's (blog post)[http://bit.ly/Zh4C93] for more information.

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
