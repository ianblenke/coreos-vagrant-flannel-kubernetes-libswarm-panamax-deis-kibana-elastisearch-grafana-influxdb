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

cat master.yml | vagrant ssh $MASTER -c "cat - > master.yml ; sudo /usr/bin/coreos-cloudinit --from-file=/home/core/master.yml"

echo "Master: $MASTER"
