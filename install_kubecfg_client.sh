#!/bin/bash
set -e

SYSTEM=`uname -s`

if [ -n "$1" ] ; then
  for NODE in $@; do
    cat install_kubecfg_client.sh | vagrant ssh $NODE -c 'cat - > install_kubecfg_client.sh; chmod +x install_kubecfg_client.sh; ./install_kubecfg_client.sh'
    echo "Installed kubecfg on $NODE"
  done
  exit 0
fi

case "$SYSTEM" in
  Darwin)
                  echo "Installing Darwin version of kubecfg in /usr/local/bin"
                  [ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin
                  [ -f /usr/local/bin/kubecfg ] || sudo wget https://storage.googleapis.com/kubernetes/darwin/kubecfg -O /usr/local/bin/kubecfg
                  [ -x /usr/local/bin/kubecfg ] || sudo chmod +x /usr/local/bin/kubecfg
  ;;
  Linux)
                  echo "Installing Linux version of kubecfg in /opt/bin"
                  [ -d /opt/bin ] || sudo mkdir -p /opt/bin
                  [ -f /opt/bin/kubecfg ] || sudo wget https://storage.googleapis.com/kubernetes/kubecfg -O /opt/bin/kubecfg
                  [ -x /opt/bin/kubecfg ] || sudo chmod +x /opt/bin/kubecfg
  ;;
  *)
                  echo "Unknown system: $SYSTEM"
                  exit 1
  ;;
esac
