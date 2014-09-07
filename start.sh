#!/bin/bash

COREOS_MEMORY=${COREOS_MEMORY:-1024}
COREOS_CPUS=${COREOS_CPUS:-1}
COREOS_CHANNEL=${COREOS_CHANNEL:-alpha}
NUM_INSTANCES=${NUM_INSTANCES:-3}
DOCKER_HOST=${DOCKER_HOST:-tcp://127.0.0.1:2375}

export COREOS_MEMORY COREOS_CPUS COREOS_CHANNEL NUM_INSTANCES DOCKER_HOST

set -e

which vagrant || (
  echo "Vagrant is required for this project"
  false
)

cat user-data.sample minion.yml > user-data

vagrant up

NODES=( $(vagrant status | grep running | awk '{print $1}') )
MASTER=${NODES[0]}
MINIONS=("${NODES[@]:1}")

IPS=()

for NODE in ${NODES[@]} ; do

  IP=$(vagrant ssh ${NODE} -c 'ID=$(curl -sL http://127.0.0.1:4001/v2/stats/self | sed -e s/^.*\"name\":\"// -e s/\".*$// -e s/\r//g); fleetctl list-machines -fields=machine,ip -full -no-legend | grep $ID | awk "{print \$2}"' | tr -d '\r')
  IPS+=( $IP )

  cat <<KUBLETE | vagrant ssh $MASTER -c "cat - > kubelet.yml; sudo /usr/bin/coreos-cloudinit --from-file=/home/core/kubelet.yml"
#cloud-config

coreos:
  units:
    - name: kubelet.service
      command: start
      enable: true
      content: |
        [Unit]
        After=etcd.service
        After=download-kubernetes.service
        ConditionFileIsExecutable=/opt/bin/kubelet
        Description=Kubernetes Kubelet
        Documentation=https://github.com/GoogleCloudPlatform/kubernetes
        Wants=etcd.service
        Wants=download-kubernetes.service

        [Service]
        ExecStart=/opt/bin/kubelet \\
        --address=0.0.0.0 \\
        --port=10250 \\
        --hostname_override=$IP \\
        --etcd_servers=http://127.0.0.1:4001 \\
        --logtostderr=true
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
KUBLETE
done

MACHINES=$(echo ${IPS[@]} | sed -e 's/ /,/g')

cat <<MASTER | vagrant ssh $MASTER -c "cat - > master.yml ; sudo /usr/bin/coreos-cloudinit --from-file=/home/core/master.yml"
#cloud-config

coreos:
  units:
    - name: download-kubernetes-master.service
      command: start
      content: |
        [Unit]
        After=network-online.target
        Before=apiserver.service
        Before=controller-manager.service
        Description=Download Kubernetes Binaries for Master
        Documentation=https://github.com/GoogleCloudPlatform/kubernetes
        Requires=network-online.target

        [Service]
        ExecStart=/usr/bin/wget -N -P /opt/bin http://storage.googleapis.com/kubernetes/apiserver
        ExecStart=/usr/bin/wget -N -P /opt/bin http://storage.googleapis.com/kubernetes/controller-manager
        ExecStart=/usr/bin/chmod +x /opt/bin/apiserver
        ExecStart=/usr/bin/chmod +x /opt/bin/controller-manager
        RemainAfterExit=yes
        Type=oneshot
    - name: apiserver.service
      command: start
      content: |
        [Unit]
        After=etcd.service
        After=download-kubernetes-master.service
        ConditionFileIsExecutable=/opt/bin/apiserver
        Description=Kubernetes API Server
        Documentation=https://github.com/GoogleCloudPlatform/kubernetes
        Wants=etcd.service
        Wants=download-kubernetes-master.service

        [Service]
        ExecStart=/opt/bin/apiserver \\
        --address=0.0.0.0 \\
        --port=8080 \\
        --etcd_servers=http://127.0.0.1:4001 \\
        --machines=${MACHINES} \\
        --logtostderr=true
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
    - name: controller-manager.service
      command: start
      content: |
        [Unit]
        After=etcd.service
        After=download-kubernetes-master.service
        ConditionFileIsExecutable=/opt/bin/controller-manager
        Description=Kubernetes Controller Manager
        Documentation=https://github.com/GoogleCloudPlatform/kubernetes
        Wants=etcd.service
        Wants=download-kubernetes-master.service

        [Service]
        ExecStart=/opt/bin/controller-manager \\
        --master=127.0.0.1:8080 \\
        --logtostderr=true
        Restart=on-failure
        RestartSec=1

        [Install]
        WantedBy=multi-user.target
MASTER

