#!/bin/bash
cd /var/lib/deis/store/cloud-init
sudo coreos-cloudinit --from-file=ec2.cloud-init
sudo coreos-cloudinit --from-file=ntp.cloud-init
sudo coreos-cloudinit --from-file=blackhole.cloud-init
sudo coreos-cloudinit --from-file=newrelic.cloud-init
sudo coreos-cloudinit --from-file=elasticsearch.cloud-init
sudo coreos-cloudinit --from-file=fluentd.cloud-init
sudo coreos-cloudinit --from-file=packetbeat.cloud-init
sudo coreos-cloudinit --from-file=statsd-librato.cloud-init
sudo coreos-cloudinit --from-file=users.cloud-init
