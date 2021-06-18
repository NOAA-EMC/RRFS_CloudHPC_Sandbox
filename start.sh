#!/bin/bash -l

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
cp gen_plots.sh.tmpl gen_plots.sh
sed -i "s@__DATE_CUR__@${date_cur}@g" gen_plots.sh
cp upload_plots.sh.tmpl upload_plots.sh
sed -i "s@__DATE_CUR__@${date_cur}@g" upload_plots.sh


kill -9 $(pidof launch.sh)
kill -9 $(pidof sleep)
kill -9 $(pidof ssh)
kill -9 $(pidof scp)
kill -9 $(pidof python3)

cp -pr monitor monitor.${date_prv}
rm -rf monitor/*
./launch.sh start >& launch.out &
#sleep 6600
#./gen_plots.sh >& gen_plots.out &
#./upload_plots.sh >& upload_plots.out &

fcst_complete_stat=No

while (test "$fcst_complete_stat" != "Yes")
do
        count=0

        for mem in {1..9}
        do
                if [ -f "monitor/${mem}_FORECAST_COMPLETED" ];then
                        count=`expr $count + 1`
                fi
        done

        if [[ "$count" -eq "9" ]];then
                echo "All $count forecasts complete" >> launch.out
                echo "All $count clusters are being shutdown" >> launch.out
		./launch.sh stop >> launch.out 
		cd /lustre/rpanda/plots
		./runall.sh >& runall.out &
                fcst_complete_stat=Yes
        else
                sleep 300
        fi
done

exit
