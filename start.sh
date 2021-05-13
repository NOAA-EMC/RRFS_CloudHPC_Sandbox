#!/bin/bash

#cd $HOME/.ssh
#cp /contrib/rpanda/parm/pw_api.key .

pip3 install --user requests

export HOSTALIASES=$HOME/.hosts

cd /lustre/ensemble/UFS_UTILS/driver_scripts

date_prv=$(date --date="yesterday" +"%Y%m%d")
date_cur=$(date --date="today" +"%Y%m%d")

cp ensemble.yml.tmpl ensemble.yml
sed -i "s@__DATE_CUR__@${date_cur}@g" ensemble.yml
sed -i "s@__DATE_PRV__@${date_prv}@g" ensemble.yml
cp launch.sh.tmpl launch.sh
sed -i "s@__DATE_CUR__@${date_cur}@g" launch.sh
cp monitor.sh.tmpl monitor.sh
sed -i "s@__DATE_CUR__@${date_cur}@g" monitor.sh


kill -9 $(pidof launch.sh)
kill -9 $(pidof sleep)
kill -9 $(pidof ssh)
kill -9 $(pidof scp)
kill -9 $(pidof python3)

cp -pr monitor monitor.${date_prv}
rm -rf monitor/*
./launch.sh start >& launch.out &

exit
