#!/bin/bash
tmpfile=/tmp/fleet-list-machines.out.$$
deis_registry=$(fleetctl list-units | grep registry | cut -d/ -f2| awk '{print $1}')
deis_router_image=$(etcdctl get /deis/router/image | cut -d: -f2-)
echo "${deis_registry}:${deis_router_image}" | etcdctl set /deis/router/image
echo "set /deis/router/image = $(etcdctl get /deis/router/image)"
fleetctl list-machines --fields=ip -no-legend | sort -n > $tmpfile
echo "Run these commands yourself when you feel so inclined:"
for ip in $(docker exec -ti deis-store-monitor ceph mon dump | grep internal | cut -d: -f2); do
  if ! grep $ip $tmpfile > /dev/null; then
    echo etcdctl rm /deis/store/hosts/${ip}
    echo etcdctl rm /deis/store/osds/${ip}
  fi
done
