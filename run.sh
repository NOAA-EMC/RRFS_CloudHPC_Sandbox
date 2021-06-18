#!/bin/bash
source /etc/profile
cd /lustre/ensemble/UFS_UTILS/driver_scripts
./member_run.sh ensemble.yml ${1}  >& member_run.out &

