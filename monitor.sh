#!/bin/bash                                                                                                  

declare -A clust_ip_addr

date_cur=20210602
res=3445 #or 3445
nclusts=9

hosts_file=${HOME}/.hosts
base_dir=/lustre/ensemble/UFS_UTILS/driver_scripts
status_dir=/lustre/ensemble/${date_cur}/status


export HOSTALIASES=${hosts_file}


while read -r line
do
        str_array=($line)
        key=${str_array[0]}
        val=${str_array[1]}
        clust_ip_addr[$key]=$val
        #echo "IP address is $key $val  ${clust_ip_addr[$key]}"
done < "$hosts_file"


cd $base_dir
if [ ! -d "monitor" ]; then
	mkdir -p monitor
fi

cd monitor


stat_mon=No
while (test "$stat_mon" != "Yes")
do
	count=0
	for i in $(seq 1 "$nclusts")
	do
        	if [ $res == "3357" ];then
                	key=pclust_m${i}
        	elif [ $res == "3445" ];then
                	key=pcna_m${i}
        	fi
		ip_addr=${clust_ip_addr[$key]}
		scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${ip_addr}:${status_dir}/* .
		ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  ${ip_addr}  "test -e ${status_dir}/${i}_FORECAST_COMPLETED"
		if [ $? -eq 0 ]; then
			count=`expr $count + 1`
		fi
	done
	if [ "$count" == "$nclusts" ]; then
		echo "All forecasts have been done"
		stat_mon=Yes
	else
		sleep 60
	fi
done
exit 0
                                                                                                             
                                                                                                             
