#!/bin/bash
vagrant destroy -f
[ -f user-data ] && rm -f user-data
