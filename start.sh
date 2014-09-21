#!/bin/bash

COREOS_MEMORY=${COREOS_MEMORY:-1024}
COREOS_CPUS=${COREOS_CPUS:-1}
COREOS_CHANNEL=${COREOS_CHANNEL:-alpha}
NUM_INSTANCES=${NUM_INSTANCES:-3}

ENABLE_KUBERNETES=${ENABLE_KUBERNETS:-true}
ENABLE_LIBSWARM=${ENABLE_LIBSWARM:-false}
ENABLE_PANAMAX=${ENABLE_PANAMAX:-false}

export COREOS_MEMORY COREOS_CPUS COREOS_CHANNEL NUM_INSTANCES

set -e

which vagrant || (
  echo "Vagrant is required for this project"
  false
)

cat user-data.sample flannel.yml > user-data

[ "$ENABLE_KUBERNETES" = "true" ] && cat kubernetes-minion.yml >> user-data
[ "$ENABLE_LIBSWARM" = "true" ] && cat libswarm.yml >> user-data

vagrant up

NODES=( $(vagrant status | grep running | awk '{print $1}') )
MASTER=${NODES[0]}

[ "$ENABLE_KUBERNETES" = "true" ] && (
  cat kubernetes-master.yml | vagrant ssh $MASTER -c "cat - > kubernetes-master.yml ; sudo /usr/bin/coreos-cloudinit --from-file=/home/core/kubernetes-master.yml"
)

[ "$ENABLE_PANAMAX" = "true" ] && (
  cat panamax-master.yml | vagrant ssh $MASTER -c "cat - > panamax-master.yml ; sudo /usr/bin/coreos-cloudinit --from-file=/home/core/panamax-master.yml"
)

echo "Master: $MASTER"
