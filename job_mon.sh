#!/bin/bash

num_posts=61
hr_post_skip=1
job_init_time=480
file_gap_limit=720
#monitor the forecast job and resubmit on failure

beg_file=logf000
run_done=No
while (test "$run_done" != "Yes")
do
	#wait for job to start running
	job_stat=P
	while (test "$job_stat" != "R" )
	do
		qstat=`echo $(squeue -h)`

		job_id=`echo $qstat|awk -F" " '{ print $1 }'`
	 	partition=`echo $qstat|awk -F" " '{ print $2 }'`
		job_stat=`echo $qstat|awk -F" " '{ print $5 }'`

		#echo "$qstat"
		#echo "$job_id"
		#echo "$partition"
		#echo "$job_stat"
		sleep 60
	done

	sleep job_init_time

#wait for the first log file (logf000) to be written

	if [ -f "$beg_file" ]; then
		file_beg_time=$(date +%s)
	else
		sleep 30
	fi

	num_posts=`expr $num_posts - 1`
	for chour in $(seq 1 "$hr_post_skip" "$num_posts")
	do
        	if [ $chour -lt 10 ]; then
                	phour='0'$chour
                	fhour='00'$chour
        	else
                	phour=$chour
                	fhour='0'$chour
        	fi
		nex_file=logf${fhour}
		echo "$nex_file"
		file_gap_time=0
		file_gap_stat=No
		while (test "$file_gap_stat" != "Yes" )
		do
			if [ -f "$nex_file" ];then
				beg_file=${nex_file}
				file_beg_time=$(date +%s)
				file_gap_stat=Yes
			else
				sleep 30
				file_gap_time=`expr $file_gap_time + 30`
				if [ "$file_gap_time" -gt "$file_gap_limit" ]; then
#cancel current slurm job & resubmit
					scancel $job_id
					sleep 60
					sbatch run_forecast.sh
					run_done=Yes
				fi
			fi
		done
	done
done

exit 0
