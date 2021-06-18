#!/bin/bash
source /etc/profile
cd /lustre/ensemble/UFS_UTILS/driver_scripts
./member_rerun_chgres.sh ensemble.yml ${1}  >& member_rerun_chgres.out &

