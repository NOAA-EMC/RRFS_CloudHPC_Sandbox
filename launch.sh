#!/bin/bash                                                                                                  

declare -A clust_ip_addr

date_cur=20210602
res=3445 #or 3445
nclusts=9

cmd=${1}

hosts_file=${HOME}/.hosts
base_dir=/lustre/ensemble/UFS_UTILS/driver_scripts
status_dir=/lustre/ensemble/${date_cur}/status

if [ -f $hosts_file  ]; then
	rm -rf $hosts_file
fi

export HOSTALIASES=${hosts_file}

#create the cluster string for starting them

if [ "$res"  == "3357" ]; then
	clust_str=pclust_m1
	for i in $(seq 2 $nclusts)
	do
		clust_str=${clust_str},pclust_m${i}
	done
	echo "Cluster start string is $clust_str"
fi
if [ "$res"  == "3445" ]; then
	clust_str=pcna_m1
	for i in $(seq 2 $nclusts)
	do
		clust_str=${clust_str},pcna_m${i}
	done
	echo "Cluster start string is $clust_str"
fi


#start clusters and wait till they are ready

dirpath=${base_dir}/pw_api_python

cd $dirpath
if [ "$cmd" == "start" ];then
	python3 startClusters.py "${clust_str}"
elif [ "$cmd" == "stop" ];then
	python3 stopClusters.py "${clust_str}"
	exit 0
fi
cd ../

status=No
while (test "$status" != "Yes" )
do
	if [ -f $hosts_file ]; then
		cat $HOME/.hosts
		status=Yes
	fi
	sleep 60
 
done	

while read -r line
do
        str_array=($line)
        key=${str_array[0]}
        val=${str_array[1]}
        clust_ip_addr[$key]=$val
        #echo "IP address is $key $val  ${clust_ip_addr[$key]}"
done < "$hosts_file"

sleep 120

for i in $(seq 1 "$nclusts")
do
	if [ $res == "3357" ];then
        	key=pclust_m${i}
	elif [ $res == "3445" ];then
        	key=pcna_m${i}
	fi
	ip_addr=${clust_ip_addr[$key]}
        echo "IP address of cluster $i is $ip_addr"
	scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  ensemble.yml ${ip_addr}:${base_dir}
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  ${ip_addr}  ${base_dir}/run.sh $i
done

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
                                                                                                             
                                                                                                             
