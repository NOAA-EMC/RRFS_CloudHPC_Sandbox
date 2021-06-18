#!/usr/bin/env bash

module use /contrib/apps/modules
module load hpc-stack/1.1.0
module load intel/19.0.5.281
module load intelmpi

export gridspecs="lambert:262.5:38.5:38.5 237.280:1799:3000 21.138:1059:3000"

	mem_num=3
	res=3445
	date_cur=20210504
	hour=00
	bucket_bdp=noaa-rrfs-pds
	bucket=noaa-ncepdev-ncep-cam
	RUNDIR=/lustre/ensemble/${date_cur}
	nhours_fcst=60
	num_posts_beg=50
	num_posts_end=50
	hr_post_skip=1


	fcst_memdir=${RUNDIR}/forecast/${mem_num}
	fcst_rundir=${RUNDIR}/forecast/${mem_num}/work.c${res}
	if [ $res == "3357" ]; then
		s3_post_grib_pfx="s3://${bucket_bdp}/rrfs.${date_cur}/${hour}/mem0${mem_num}"
		s3_post_text_pfx="s3://${bucket}/HWT/CONUS/${date_cur}/forecast/text/${mem_num}"
	elif [ $res == "3445" ]; then
		s3_post_grib_pfx="s3://${bucket_bdp}/rrfs.${date_cur}/${hour}/mem0${mem_num}"
		s3_post_text_pfx="s3://${bucket}/HWT/NA/${date_cur}/forecast/text/${mem_num}"
	fi

#Store post-processed file in AWS S3 bucket
	source /contrib/.aws/bdp.key
	cd ${fcst_rundir}
	#num_posts=`expr $num_posts - 1`
        #for chour in $(seq "num_posts_beg" "$hr_post_skip" "$num_posts_end")
	for ((chour=$num_posts_beg; chour<=$num_posts_end; chour++))
        do
		status=No
		while (test "$status" != "Yes" )
		do
                        if [ $chour -lt 10 ]; then
                                hour_name='0'$chour
                                new_hour_name='00'$chour
                        else
                                hour_name=''$chour
                                new_hour_name='0'$chour
                        fi
                        post_file=PRSLEV.GrbF${hour_name}
                        post_conv_file=PRSLEV.GrbF${hour_name}.converted
                        post_small_file=PRSLEV_small1
                        path_file=${fcst_rundir}/PRSLEV.GrbF${hour_name}
                        path_small_file=${fcst_rundir}/PRSLEV_small1
			echo "$post_file is about to be uploaded to S3"

                        if [ -f "$path_file" ]; then
                                #check if chgres processed file size changes in 1 second
                                file_size=$(stat --printf=%s $path_file)
                                sleep 1
                                file_size1=$(stat --printf=%s $path_file)
                                #if file size hasn't changed, count the file; increment the counter, etc.
                                if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
					if [ $res == "3357" ]; then
                        			s3_file=rrfs.t00z.mem0${mem_num}.conusf${new_hour_name}.grib2
                        			s3_reduc_file=rrfs.t00z.mem0${mem_num}.testbed.conusf${new_hour_name}.grib2
						post_stat=$(aws s3 cp ${post_file} ${s3_post_grib_pfx}/${s3_file})
						wgrib2 $post_file | grep -F -f /contrib/rpanda/parm/testbed.txt  | wgrib2 -i -grib PRSLEV_small1 $post_file 
						post_reduc_stat=$(aws s3 cp ${post_small_file} ${s3_post_grib_pfx}/${s3_reduc_file})
						wait
                                        	echo "$post_file is uploaded and has a size of $file_size bytes"
                                        	echo "$post_stat"
						status=Yes
					elif [ $res == "3445" ]; then
                        			s3_file=rrfs.t00z.mem0${mem_num}.naf${new_hour_name}.grib2
                        			s3_reduc_file=rrfs.t00z.mem0${mem_num}.testbed.conusf${new_hour_name}.grib2
						post_stat=$(aws s3 cp ${post_file} ${s3_post_grib_pfx}/${s3_file})
						wait
						date_str=$(date)
						wgrib2 -v $post_file  > tmp.txt
						if [ "$?" -eq 0 ]; then
							wgrib2 $post_file -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid -new_grid $gridspecs $post_conv_file > /dev/null
							wgrib2 $post_conv_file | grep -F -f /contrib/rpanda/parm/testbed.txt  | wgrib2 -i -grib PRSLEV_small1 $post_conv_file 
							post_reduc_stat=$(aws s3 cp ${post_small_file} ${s3_post_grib_pfx}/${s3_reduc_file})
							wait
                                        		echo "$post_file is uploaded and has a size of $file_size bytes"
                                        		echo "$post_stat"
					 	else
							echo "$post_file did not validate; skipping upload to S3"
						fi
						date_str=$(date)
						status=Yes
					fi 
				else
					sleep 5
                                fi
			else
				sleep 30
                        fi
        	done
        done
	source /contrib/.aws/proj.key
	post_stat=$(aws s3 cp ${fcst_out_file} ${s3_post_text_pfx}/${fcst_out_file})
	wait
        echo "$post_stat"
	post_stat=$(aws s3 cp ${fcst_err_file} ${s3_post_text_pfx}/${fcst_err_file})
	wait
        echo "$post_stat"

exit 0

# Functions
