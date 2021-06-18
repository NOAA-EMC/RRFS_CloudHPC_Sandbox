#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091

# Configure
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./bash-yaml/script/yaml.sh

module use /contrib/apps/modules
module load hpc-stack/1.1.0
module load intel/19.0.5.281
module load intelmpi

#export gridspecs="lambert:262.5:38.5:38.5 237.826355:1746:3000 21.885885:1014:3000"
export gridspecs="lambert:262.5:38.5:38.5 237.280:1799:3000 21.138:1059:3000"

create_scripts () {
        local mem_num=${1}
	local idx
	local cp_from
	local gep_num
	local beg_hour
	local end_hour
	local tstamps=${STATUS_DIR}/${mem_num}_tstamps
	MEMBER_SCRIPTS=${RUNDIR}/scripts/${mem_num}
	if [ ! -d "$MEMBER_SCRIPTS" ]; then
		mkdir -p $MEMBER_SCRIPTS
	fi
	MEMBER_DOWNLOAD=${RUNDIR}/download/${mem_num}
	if [ ! -d "$MEMBER_DOWNLOAD" ]; then
		mkdir -p $MEMBER_DOWNLOAD
	fi
	MEMBER_DOWNLOAD_COMBINE=${MEMBER_DOWNLOAD}/combine/
	MEMBER_TMPDIR=${RUNDIR}/stmp1/${mem_num}
	if [ ! -d "$MEMBER_TMPDIR" ]; then
		mkdir -p $MEMBER_TMPDIR
		cd $MEMBER_TMPDIR
		cp -pr ${PFXDIR}/data/C${res} .
	fi
#	Initialize an array for suffix numbers
	for i in $(seq 0 "99")
	do
        	if [ "$i" -lt "10" ]; then
                	add0[$i]="0"${i}
        	else
                	add0[$i]="$i"
        	fi
	done

	idx=$(($mem_num-1))
echo "Member = $mem_num"
echo "date_cur = $date_cur"
echo "date_prv = $date_prv"
echo "hour_from = $hour_from"
echo "res = $res"
Type=${members__Type[$idx]}
echo "Type = $Type"
cd $MEMBER_SCRIPTS
	if [ $Type == '"GFS"' ]; then
		local status_file_beg=${STATUS_DIR}/${mem_num}_SCRIPTS_STARTED
		local status_file_end=${STATUS_DIR}/${mem_num}_SCRIPTS_COMPLETED

		echo "CREATE GFS SCRIPTS STARTED" > ${status_file_beg}
		date_str=$(date)
		echo "$date_str member:$mem_num CREATE SCRIPTS STARTED" >> ${tstamps}

        	cp ${SCRIPTS_DIR}/run_download.tmpl run_download.sh
		cp_from=`eval echo "${members__cp_from[$idx]}"`
		gep_num=`eval echo "${members__gep_num[$idx]}"`
		beg_hour=`eval echo "${members__beg_hour[$idx]}"`
		end_hour=`eval echo "${members__end_hour[$idx]}"`
        	sed -i "s@__TYPE__@$Type@g" run_download.sh 
        	sed -i "s@__MEM_NUM__@${mem_num}@g" run_download.sh 
        	sed -i "s@__GEP_NUM__@${gep_num}@g" run_download.sh 
        	sed -i "s@__CP_FROM__@${cp_from}@g" run_download.sh 
        	sed -i "s@__DATE_CUR__@${date_cur}@g" run_download.sh 
        	sed -i "s@__DATE_PRV__@${date_prv}@g" run_download.sh 
        	sed -i "s@__HOUR_FROM__@${hour_from}@g" run_download.sh 
        	sed -i "s@__BEG_HOUR__@${beg_hour}@g" run_download.sh 
        	sed -i "s@__END_HOUR__@${end_hour}@g" run_download.sh 
        	sed -i "s@__HR_INTERVAL__@${hr_interval}@g" run_download.sh 
        	sed -i "s@__GFS_PFIX__@${gfs_pfix}@g" run_download.sh 
        	sed -i "s@__GFS_FILE_ATM__@${gfs_file_atm}@g" run_download.sh 
        	sed -i "s@__GFS_FILE_SFC__@${gfs_file_sfc}@g" run_download.sh 
        	sed -i "s@__GFS_STUB_B2__@${gfs_stub_b2}@g" run_download.sh 
        	sed -i "s@__GFS_STUB_B2B__@${gfs_stub_b2b}@g" run_download.sh 
        	sed -i "s@__RUNDIR__@${RUNDIR}@g" run_download.sh 
#Create the python file from its template to combine download data
		cp ${SCRIPTS_DIR}/grib2_combine.tmpl grib2_combine.py
		cp ${SCRIPTS_DIR}/grib2_unique.pl . 
		cycle=${date_prv}${hour_from}
        	sed -i "s@__GRIB2_DIR__@${MEMBER_DOWNLOAD}/@g" grib2_combine.py
        	sed -i "s@__GRIB2_COMBINE_DIR__@${MEMBER_DOWNLOAD_COMBINE}@g" grib2_combine.py
        	sed -i "s@__UNIQUE_DIR__@${MEMBER_SCRIPTS}/@g" grib2_combine.py
        	sed -i "s@__END_HOUR__@${end_hour}@g" grib2_combine.py
        	sed -i "s@__HR_INTERVAL__@${hr_interval}@g" grib2_combine.py
        	sed -i "s@__CYCLE__@${cycle}@g" grib2_combine.py
#Create the chgres scripts
        	cp ${SCRIPTS_DIR}/run_chgres.GFS.IC.tmpl run_chgres.IC.sh
		workdir_ic=${MEMBER_TMPDIR}/chgres_fv3
        	sed -i "s@__RES__@$res@g" run_chgres.IC.sh 
        	sed -i "s@__DATE__@${date_prv}${hour_from}@g" run_chgres.IC.sh 
        	sed -i "s@__DATE_PRV__@${date_prv}@g" run_chgres.IC.sh 
        	sed -i "s@__BASEDIR__@${PFXDIR}/UFS_UTILS@g" run_chgres.IC.sh 
        	sed -i "s@__FIXDIR__@${MEMBER_TMPDIR}@g" run_chgres.IC.sh 
        	sed -i "s@__MEMBER_DOWNLOAD__@${MEMBER_DOWNLOAD}@g" run_chgres.IC.sh 
        	sed -i "s@__WORKDIR_IC__@${workdir_ic}@g" run_chgres.IC.sh 
        	cp ${SCRIPTS_DIR}/run_chgres.GFS.LBC.tmpl run_chgres.LBC.sh
		workdir_lbc=${MEMBER_TMPDIR}/chgres_fv3.LBC.grib2.c${res}
        	sed -i "s@__RES__@$res@g" run_chgres.LBC.sh 
        	sed -i "s@__DATE__@${date_prv}${hour_from}@g" run_chgres.LBC.sh 
        	sed -i "s@__DATE_PRV__@${date_prv}@g"  run_chgres.LBC.sh
        	sed -i "s@__BASEDIR__@${PFXDIR}/UFS_UTILS@g"  run_chgres.LBC.sh
        	sed -i "s@__FIXDIR__@${MEMBER_TMPDIR}@g"  run_chgres.LBC.sh
        	sed -i "s@__MEMBER_DOWNLOAD_COMBINE__@${MEMBER_DOWNLOAD_COMBINE}@g"  run_chgres.LBC.sh
        	sed -i "s@__WORKDIR_LBC__@${workdir_lbc}@g"  run_chgres.LBC.sh
        	sed -i "s@__HOUR_FROM__@${hour_from}@g" run_chgres.LBC.sh
        	sed -i "s@__BEG_HOUR__@${beg_hour}@g" run_chgres.LBC.sh
        	sed -i "s@__END_HOUR__@${end_hour}@g" run_chgres.LBC.sh
        	sed -i "s@__HR_INTERVAL__@${hr_interval}@g"  run_chgres.LBC.sh

		echo "CREATE GFS SCRIPTS COMPLETED" > ${status_file_end}
		date_str=$(date)
		echo "$date_str member:$mem_num CREATE SCRIPTS COMPLETED" >> ${tstamps}


	elif [ $Type == '"GEFS"' ]; then
		local status_file_beg=${STATUS_DIR}/${mem_num}_SCRIPTS_STARTED
		local status_file_end=${STATUS_DIR}/${mem_num}_SCRIPTS_COMPLETED
		echo "CREATE GEFS SCRIPTS STARTED" > ${status_file_beg}
		date_str=$(date)
		echo "$date_str member:$mem_num CREATE SCRIPTS STARTED" >> ${tstamps}

        	cp ${SCRIPTS_DIR}/run_download.tmpl run_download.sh
		cp_from=`eval echo "${members__cp_from[$idx]}"`
		gep_num=`eval echo "${members__gep_num[$idx]}"`
		beg_hour=`eval echo "${members__beg_hour[$idx]}"`
		end_hour=`eval echo "${members__end_hour[$idx]}"`
echo "Member No =  = $mem_num"
        	sed -i "s@__TYPE__@$Type@g" run_download.sh 
        	sed -i "s@__MEM_NUM__@${mem_num}@g" run_download.sh 
        	sed -i "s@__GEP_NUM__@${gep_num}@g" run_download.sh 
        	sed -i "s@__CP_FROM__@${cp_from}@g" run_download.sh 
        	sed -i "s@__DATE_CUR__@${date_cur}@g" run_download.sh 
        	sed -i "s@__DATE_PRV__@${date_prv}@g" run_download.sh 
        	sed -i "s@__HOUR_FROM__@${hour_from}@g" run_download.sh 
        	sed -i "s@__BEG_HOUR__@${beg_hour}@g" run_download.sh 
        	sed -i "s@__END_HOUR__@${end_hour}@g" run_download.sh 
        	sed -i "s@__HR_INTERVAL__@${hr_interval}@g" run_download.sh 
        	sed -i "s@__GEFS_PFIX_A__@${gefs_pfix_a}@g" run_download.sh 
        	sed -i "s@__GEFS_PFIX_B__@${gefs_pfix_b}@g" run_download.sh 
        	sed -i "s@__GEFS_STUB__@${gefs_stub}@g" run_download.sh 
        	sed -i "s@__GEFS_STUB_A__@${gefs_stub_a}@g" run_download.sh 
        	sed -i "s@__GEFS_STUB_B__@${gefs_stub_b}@g" run_download.sh 
        	sed -i "s@__RUNDIR__@${RUNDIR}@g" run_download.sh 

#Create the chgres scripts
                cp ${SCRIPTS_DIR}/run_chgres.GEFS.IC.tmpl run_chgres.IC.sh
                workdir_ic=${MEMBER_TMPDIR}/chgres_fv3
                sed -i "s@__RES__@$res@g" run_chgres.IC.sh
                sed -i "s@__DATE__@${date_prv}${hour_from}@g" run_chgres.IC.sh
                sed -i "s@__DATE_PRV__@${date_prv}@g" run_chgres.IC.sh
                sed -i "s@__BASEDIR__@${PFXDIR}/UFS_UTILS@g" run_chgres.IC.sh
        	sed -i "s@__GEP_NUM__@${gep_num}@g" run_chgres.IC.sh
                sed -i "s@__FIXDIR__@${MEMBER_TMPDIR}@g" run_chgres.IC.sh
                sed -i "s@__MEMBER_DOWNLOAD__@${MEMBER_DOWNLOAD}@g" run_chgres.IC.sh
                sed -i "s@__WORKDIR_IC__@${workdir_ic}@g" run_chgres.IC.sh
        	cp ${SCRIPTS_DIR}/run_chgres.GEFS.LBC.tmpl run_chgres.LBC.sh
		workdir_lbc=${MEMBER_TMPDIR}/chgres_fv3.LBC.grib2.c${res}
        	sed -i "s@__RES__@$res@g" run_chgres.LBC.sh 
        	sed -i "s@__DATE__@${date_prv}${hour_from}@g" run_chgres.LBC.sh 
        	sed -i "s@__DATE_PRV__@${date_prv}@g"  run_chgres.LBC.sh
        	sed -i "s@__BASEDIR__@${PFXDIR}/UFS_UTILS@g"  run_chgres.LBC.sh
        	sed -i "s@__FIXDIR__@${MEMBER_TMPDIR}@g"  run_chgres.LBC.sh
        	sed -i "s@__MEMBER_DOWNLOAD__@${MEMBER_DOWNLOAD}@g"  run_chgres.LBC.sh
        	sed -i "s@__WORKDIR_LBC__@${workdir_lbc}@g"  run_chgres.LBC.sh
        	sed -i "s@__BEG_HOUR__@${beg_hour}@g" run_chgres.LBC.sh
        	sed -i "s@__END_HOUR__@${end_hour}@g" run_chgres.LBC.sh
        	sed -i "s@__HOUR_FROM__@${hour_from}@g" run_chgres.LBC.sh
        	sed -i "s@__HR_INTERVAL__@${hr_interval}@g"  run_chgres.LBC.sh
        	sed -i "s@__GEP_NUM__@${add0[$gep_num]}@g"  run_chgres.LBC.sh

		echo "CREATE GEFS SCRIPTS COMPLETED" > ${status_file_end}
		date_str=$(date)
		echo "$date_str member:$mem_num CREATE SCRIPTS COMPLETED" >> ${tstamps}
	fi
}
run_scripts () {
	local mem_num=${1}
	local Type
	local dirpath
	local idx
	local status
	local fixdir=${RUNDIR}/stmp1/${mem_num}/C${res}
	local tstamps=${STATUS_DIR}/${mem_num}_tstamps
	if [ $res == "3357" ]; then
		local s3_download_pfx="s3://${bucket}/HWT/CONUS/${date_cur}/download"
		local s3_scripts_pfx="s3://${bucket}/HWT/CONUS/${date_cur}/scripts"
	elif [ $res == "3445" ]; then
		local s3_download_pfx="s3://${bucket}/HWT/NA/${date_cur}/download"
		local s3_scripts_pfx="s3://${bucket}/HWT/NA/${date_cur}/scripts"
	fi
	declare -a local FILES_DONE
        local file_done_count=0
	local total_bc_files=21
        local increment=1
	local nhours_fcst=60

	dirpath=${RUNDIR}/scripts/${mem_num}
	idx=$(($mem_num-1))
	Type=${members__Type[$idx]}
	echo "Member = $mem_num"
	echo "fixdir = $fixdir"
	echo "Type = $Type"
	echo "s3_download_pfx $s3_download_pfx"
	echo "s3_scripts_pfx $s3_scripts_pfx"

                for chour in $(seq 0 "$hr_interval"  "$nhours_fcst")
        do
                if [ $chour -lt 10 ]; then
                        hour='0'$chour
                        JOBS[chour]=No
                        FILES_DONE[chour]=No
                else
                        hour=$chour
                        JOBS[chour]=No
                        FILES_DONE[chour]=No
                fi

        done
	if [ $Type == '"GFS"' ]; then
		local status_file_script=${STATUS_DIR}/${mem_num}_SCRIPTS_COMPLETED
		local status_file_download_beg=${STATUS_DIR}/${mem_num}_DOWNLOAD_STARTED
		local status_file_download_end=${STATUS_DIR}/${mem_num}_DOWNLOAD_COMPLETED
		local status_file_chgres_beg=${STATUS_DIR}/${mem_num}_CHGRES_STARTED
		local status_file_chgres_end=${STATUS_DIR}/${mem_num}_CHGRES_COMPLETED
		if [ -f "$status_file_script" ]; then
			rm -rf $status_file_script
		fi
		if [ -f "$status_file_download_beg" ]; then
			rm -rf $status_file_download_beg
		fi
		if [ -f "$status_file_download_end" ]; then
			rm -rf $status_file_download_end
		fi
		if [ -f "$status_file_chgres_beg" ]; then
			rm -rf $status_file_chgres_beg
		fi
		if [ -f "$status_file_chgres_end" ]; then
			rm -rf $status_file_chgres_end
		fi

		##cd ${RUNDIR}/scripts
		##post_stat=$(aws s3 cp ${mem_num} ${s3_scripts_pfx}/${mem_num}/ --recursive)
		##wait 
		##echo "$post_stat"

		cd ${dirpath}
		status=No
		while (test "$status" != "Yes" )
		do
			if [ -f "$status_file_script" ]; then
				echo "GFS DATA DOWNLOAD STARTED" > ${status_file_download_beg}
				date_str=$(date)
				echo "$date_str member:$mem_num DATA DOWNLOAD STARTED" >> ${tstamps}
				bash ${dirpath}/run_download.sh >& download.out 
				wait
				status=Yes
				echo "GFS DATA DOWNLOAD COMPLETED" > ${status_file_download_end}
				date_str=$(date)
				echo "$date_str member:$mem_num DATA DOWNLOAD COMPLETED" >> ${tstamps}
			else
				sleep 5
			fi
		done
		if [ $mem_num == "1" ]; then
			        cd ${RUNDIR}/download
				post_stat=$(aws s3 cp ${mem_num} ${s3_download_pfx}/${mem_num}/ --recursive)
		fi

				echo "GFS CHGRES STARTED" > ${status_file_chgres_beg}
				date_str=$(date)
				echo "$date_str member:$mem_num CHGRES STARTED" >> ${tstamps}

				sbatch ${dirpath}/run_chgres.IC.sh
				sbatch ${dirpath}/run_chgres.LBC.sh

		#       Now check to see all IC files are ready before the forecast step
		file_stat=No
		ic_filename=${fixdir}/gfs_data.tile7.nc
		echo "GFS IC file is $ic_filename"
		while (test "$file_stat" != "Yes")
		do

                        if [ -f "$ic_filename" ]; then
                        	#check if chgres processed file size changes in 1 second
                        	file_size=$(stat --printf=%s $ic_filename)
                        	sleep 1
                        	file_size1=$(stat --printf=%s $ic_filename)
                        	#if file size hasn't changed, count the file; increment the counter, etc.
                        	if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                	echo "$ic_filename is complete and has a size of $file_size bytes"
					date_str=$(date)
					echo "$date_str member:$mem_num CHGRES - $ic_filename is complete and its size is $file_size bytes" >> ${tstamps}
				file_stat=Yes
				else
					sleep 1
                		fi
                	fi
                done
		file_stat=No
		ic_filename=${fixdir}/sfc_data.tile7.nc
		echo "GFS IC file is $ic_filename"
		while (test "$file_stat" != "Yes")
		do

                        if [ -f "$ic_filename" ]; then
                        	#check if chgres processed file size changes in 1 second
                        	file_size=$(stat --printf=%s $ic_filename)
                        	sleep 1
                        	file_size1=$(stat --printf=%s $ic_filename)
                        	#if file size hasn't changed, count the file; increment the counter, etc.
                        	if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                	echo "$ic_filename is complete and has a size of $file_size bytes"
					date_str=$(date)
					echo "$date_str member:$mem_num CHGRES - $ic_filename is complete and its size is $file_size bytes" >> ${tstamps}
				file_stat=Yes
				else
					sleep 1
                		fi
                	fi
                done

		file_stat=No
		ic_filename=${fixdir}/gfs_ctrl.nc
		echo "GFS IC file is $ic_filename"
		while (test "$file_stat" != "Yes")
		do

                        if [ -f "$ic_filename" ]; then
                        	#check if chgres processed file size changes in 1 second
                        	file_size=$(stat --printf=%s $ic_filename)
                        	sleep 1
                        	file_size1=$(stat --printf=%s $ic_filename)
                        	#if file size hasn't changed, count the file; increment the counter, etc.
                        	if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                	echo "$ic_filename is complete and has a size of $file_size bytes"
					date_str=$(date)
					echo "$date_str member:$mem_num CHGRES - $ic_filename is complete and its size is $file_size bytes" >> ${tstamps}
				file_stat=Yes
				else
					sleep 1
                		fi
                	fi
                done
		#       Now check to see all LBC files are ready before the forecast step
        	while (test "$file_done_count" -lt "$total_bc_files")
                do
                        for chour in $(seq 0 "$hr_interval" "$nhours_fcst")
                        do
                                if [ ${FILES_DONE[$chour]} != "Yes" ]; then
                                        if [ $chour -lt 10 ]; then
                                                hour_name='00'$chour
                                                FILES_DONE[chour]=No
                                        else
                                                hour_name='0'$chour
                                                FILES_DONE[chour]=No
                                        fi
                                        done_filename=${fixdir}/gfs_bndy.tile7.${hour_name}.nc

                                        if [ -f "$done_filename" ]; then
                                                #check if chgres processed file size changes in 1 second
                                                file_size=$(stat --printf=%s $done_filename)
                                                sleep 1
                                                file_size1=$(stat --printf=%s $done_filename)
                                                #if file size hasn't changed, count the file; increment the counter, etc.
                                                if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                                        FILES_DONE[$chour]=Yes
                                                        file_done_count=`expr $file_done_count + $increment`
                                                        echo "$done_filename is complete and has a size of $file_size bytes"
							date_str=$(date)
							echo "$date_str member:$mem_num CHGRES - $done_filename is complete and its size is $file_size bytes" >> ${tstamps}
                                                fi
                                        fi
                                fi
                        done
                done
		echo "GFS CHGRES COMPLETED" > ${status_file_chgres_end}
		date_str=$(date)
		echo "$date_str member:$mem_num CHGRES COMPLETED" >> ${tstamps}
	elif [ $Type == '"GEFS"' ]; then
		local status_file_script=${STATUS_DIR}/${mem_num}_SCRIPTS_COMPLETED
		local status_file_download_beg=${STATUS_DIR}/${mem_num}_DOWNLOAD_STARTED
		local status_file_download_end=${STATUS_DIR}/${mem_num}_DOWNLOAD_COMPLETED
		local status_file_chgres_beg=${STATUS_DIR}/${mem_num}_CHGRES_STARTED
		local status_file_chgres_end=${STATUS_DIR}/${mem_num}_CHGRES_COMPLETED
		if [ -f "$status_file_script" ]; then
			rm -rf $status_file_script
		fi
		if [ -f "$status_file_download_beg" ]; then
			rm -rf $status_file_download_beg
		fi
		if [ -f "$status_file_download_end" ]; then
			rm -rf $status_file_download_end
		fi
		if [ -f "$status_file_chgres_beg" ]; then
			rm -rf $status_file_chgres_beg
		fi
		if [ -f "$status_file_chgres_end" ]; then
			rm -rf $status_file_chgres_end
		fi

		##cd ${RUNDIR}/scripts
		##post_stat=$(aws s3 cp ${mem_num} ${s3_scripts_pfx}/${mem_num}/ --recursive)
		##wait 
		##echo "$post_stat"

		cd ${dirpath}
		status=No
		while (test "$status" != "Yes" )
		do
			if [ -f "$status_file_script" ]; then
				echo "GEFS DATA DOWNLOAD STARTED" > ${status_file_download_beg}
				date_str=$(date)
				echo "$date_str member:$mem_num DATA DOWNLOAD STARTED" >> ${tstamps}
				bash ${dirpath}/run_download.sh >& download.out 
				wait
				status=Yes
				echo "GEFS DATA DOWNLOAD COMPLETED" > ${status_file_download_end}
				date_str=$(date)
				echo "$date_str member:$mem_num DATA DOWNLOAD COMPLETED" >> ${tstamps}
			else
				sleep 5
			fi
		done
		if [[ $mem_num == "2" || $mem_num == "3" ]]; then
			        cd ${RUNDIR}/download
				post_stat=$(aws s3 cp ${mem_num} ${s3_download_pfx}/${mem_num}/ --recursive)
		fi
		echo "GEFS CHGRES STARTED" > ${status_file_chgres_beg}
		date_str=$(date)
		echo "$date_str member:$mem_num CHGRES STARTED" >> ${tstamps}
			sbatch ${dirpath}/run_chgres.IC.sh
			sbatch ${dirpath}/run_chgres.LBC.sh

		#       Now check to see all IC files are ready before the forecast step

		file_stat=No
		ic_filename=${fixdir}/gfs_data.tile7.nc
		echo "GEFS IC file is $ic_filename"
		while (test "$file_stat" != "Yes")
		do

                        if [ -f "$ic_filename" ]; then
                        	#check if chgres processed file size changes in 1 second
                        	file_size=$(stat --printf=%s $ic_filename)
                        	sleep 1
                        	file_size1=$(stat --printf=%s $ic_filename)
                        	#if file size hasn't changed, count the file; increment the counter, etc.
                        	if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                	echo "$ic_filename is complete and has a size of $file_size bytes"
					date_str=$(date)
					echo "$date_str member:$mem_num CHGRES - $ic_filename is complete and its size is $file_size bytes" >> ${tstamps}
				file_stat=Yes
				else
					sleep 1
                		fi
                	fi
                done
		file_stat=No
		ic_filename=${fixdir}/sfc_data.tile7.nc
		echo "GEFS IC file is $ic_filename"
		while (test "$file_stat" != "Yes")
		do

                        if [ -f "$ic_filename" ]; then
                        	#check if chgres processed file size changes in 1 second
                        	file_size=$(stat --printf=%s $ic_filename)
                        	sleep 1
                        	file_size1=$(stat --printf=%s $ic_filename)
                        	#if file size hasn't changed, count the file; increment the counter, etc.
                        	if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                	echo "$ic_filename is complete and has a size of $file_size bytes"
					date_str=$(date)
					echo "$date_str member:$mem_num CHGRES - $ic_filename is complete and its size is $file_size bytes" >> ${tstamps}
				file_stat=Yes
				else
					sleep 1
                		fi
                	fi
                done

		file_stat=No
		ic_filename=${fixdir}/gfs_ctrl.nc
		echo "GEFS IC file is $ic_filename"
		while (test "$file_stat" != "Yes")
		do

                        if [ -f "$ic_filename" ]; then
                        	#check if chgres processed file size changes in 1 second
                        	file_size=$(stat --printf=%s $ic_filename)
                        	sleep 1
                        	file_size1=$(stat --printf=%s $ic_filename)
                        	#if file size hasn't changed, count the file; increment the counter, etc.
                        	if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                	echo "$ic_filename is complete and has a size of $file_size bytes"
					date_str=$(date)
					echo "$date_str member:$mem_num CHGRES - $ic_filename is complete and its size is $file_size bytes" >> ${tstamps}
				file_stat=Yes
				else
					sleep 1
                		fi
                	fi
                done
		#       Now check to see all LBC files are ready before the forecast step

        	while (test "$file_done_count" -lt "$total_bc_files")
                do
                        for chour in $(seq 0 "$hr_interval" "$nhours_fcst")
                        do
                                if [ ${FILES_DONE[$chour]} != "Yes" ]; then
                                        if [ $chour -lt 10 ]; then
                                                hour_name='00'$chour
                                                FILES_DONE[chour]=No
                                        else
                                                hour_name='0'$chour
                                                FILES_DONE[chour]=No
                                        fi
                                        done_filename=${fixdir}/gfs_bndy.tile7.${hour_name}.nc

                                        if [ -f "$done_filename" ]; then
                                                #check if chgres processed file size changes in 1 second
                                                file_size=$(stat --printf=%s $done_filename)
                                                sleep 1
                                                file_size1=$(stat --printf=%s $done_filename)
                                                #if file size hasn't changed, count the file; increment the counter, etc.
                                                if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
                                                        FILES_DONE[$chour]=Yes
                                                        file_done_count=`expr $file_done_count + $increment`
                                                        echo "$done_filename is complete and has a size of $file_size bytes"
							date_str=$(date)
							echo "$date_str member:$mem_num CHGRES - $done_filename is complete and its size is $file_size bytes" >> ${tstamps}
                                                fi
                                        fi
                                fi
                        done
                done
		echo "GEFS CHGRES COMPLETED" > ${status_file_chgres_end}
		date_str=$(date)
		echo "$date_str member:$mem_num CHGRES COMPLETED" >> ${tstamps}
	fi

}
run_forecast () {
	local mem_num=${1}
	local Type
	local dirpath
	local idx
	local status
	local year
	local month
	local day
	local hour=00

	idx=$(($mem_num-1))
	Type=${members__Type[$idx]}
	cp_from=${members__cp_from[$idx]}

	local tstamps=${STATUS_DIR}/${mem_num}_tstamps
	local fixdir=${RUNDIR}/stmp1/${cp_from}/C${res}
	local fcst_memdir=${RUNDIR}/forecast/${mem_num}
	local fcst_rundir=${RUNDIR}/forecast/${mem_num}/work.c${res}
	if [ $res == "3357" ]; then
		local s3_post_grib_pfx="s3://${bucket_bdp}/rrfs.${date_cur}/${hour}/mem0${mem_num}"
	#	local s3_post_grib_pfx="s3://${bucket}/HWT/CONUS/${date_cur}/forecast/grib/${mem_num}"
		local s3_post_text_pfx="s3://${bucket}/HWT/CONUS/${date_cur}/forecast/text/${mem_num}"
	elif [ $res == "3445" ]; then
		local s3_post_grib_pfx="s3://${bucket_bdp}/rrfs.${date_cur}/${hour}/mem0${mem_num}"
	#	local s3_post_grib_pfx="s3://${bucket}/HWT/NA/${date_cur}/forecast/grib/${mem_num}"
		local s3_post_text_pfx="s3://${bucket}/HWT/NA/${date_cur}/forecast/text/${mem_num}"
	fi

	echo "Member = $mem_num"
	echo "fixdir = $fixdir"
	echo "fcst_memdir = $fcst_memdir"
	echo "fcst_rundir = $fcst_rundir"

        year=`echo $date_cur | cut -c1-4`
        month=`echo $date_cur | cut -c5-6`
        day=`echo $date_cur | cut -c7-8`
	cyc=${date_cur}${hour}

        start_year="start_year:              $year"
        start_month="start_month:             $month"
        start_day="start_day:               $day"
        start_hour="start_hour:              $hour"
        nhours_fcst_str="nhours_fcst:             $nhours_fcst"
        diag_line1=${year}${month}${day}.${hour}Z.C${res}.32bit.non-hydro
        diag_line2="$year $month $day $hour 0 0"

        echo "$start_year"
        echo "$start_month"
        echo "$start_day"
        echo "$start_hour"
        echo "$nhours_fcst_str"

	if [ ! -d "$fcst_memdir" ]; then
		cd ${RUNDIR}/forecast
		mkdir -p ${mem_num}
	fi

	if [ ! -d "$fcst_rundir" ]; then
		cd $fcst_memdir
		cp -pr ${PFXDIR}/data/work.c${res} .
	else
		rm -rf $fcst_mem_dir
		cp -pr ${PFXDIR}/data/work.c${res} .
	fi

        cd $fcst_rundir
        cp ${PFXDIR}/data/config_files/${res}/model_configure.tmpl model_configure
        sed -i "s@__YEAR__@$start_year@g" model_configure
        sed -i "s@__MONTH__@$start_month@g" model_configure
        sed -i "s@__DAY__@$start_day@g" model_configure
        sed -i "s@__HOUR__@$start_hour@g" model_configure
        sed -i "s@__NHOURS_FCST__@$nhours_fcst_str@g" model_configure

        cp ${PFXDIR}/data/config_files/${res}/diag_table.member${mem_num}.tmpl diag_table
        sed -i "s@__DIAG_LINE_1__@$diag_line1@g" diag_table
        sed -i "s@__DIAG_LINE_2__@$diag_line2@g" diag_table

	cp ${PFXDIR}/data/config_files/${res}/field_table.member${mem_num} field_table
	#Generate seeds for stochastic physics [as suggested by Jeff Beck]
	if [[ $mem_num == "2" || $mem_num == "3" || $mem_num == "5" || $mem_num == "6" || $mem_num == "8" || $mem_num == "9" ]]; then
		iseed_shum=$(( cyc*1000 + mem_num*10 + 2 ))
		iseed_skeb=$(( cyc*1000 + mem_num*10 + 3 ))
		iseed_sppt=$(( cyc*1000 + mem_num*10 + 1 ))
		#iseed_shum=$(( 2 ))
		#iseed_skeb=$(( 3 ))
		#iseed_sppt=$(( 1 ))
		cp ${PFXDIR}/data/config_files/${res}/input.nml.member${mem_num}.tmpl input.nml
        	sed -i "s@__ISEED_SHUM__@$iseed_shum@g" input.nml
        	sed -i "s@__ISEED_SKEB__@$iseed_skeb@g" input.nml
        	sed -i "s@__ISEED_SPPT__@$iseed_sppt@g" input.nml
	else
		cp ${PFXDIR}/data/config_files/${res}/input.nml.member${mem_num} input.nml
	fi

        cp run_forecast.tmpl run_forecast.sh
        chmod +x run_forecast.sh
        sed -i "s@__FCST_MEMDIR__@$fcst_memdir@g" run_forecast.sh
        sed -i "s@__FCST_OUT_FILE__@$fcst_out_file@g" run_forecast.sh
        sed -i "s@__FCST_ERR_FILE__@$fcst_err_file@g" run_forecast.sh

	if [[ $mem_num == "7" || $mem_num == "8" || $mem_num == "9" ]]; then
		cp fv3_gfs.x.upp1006 fv3_gfs.x
		chmod +x fv3_gfs.x
	else
		chmod +x fv3_gfs.x
	fi

        if [ ! -d "RESTART" ]; then
                mkdir -p RESTART
        fi

	#Upload all simulation input and script files to S3
	post_stat=$(aws s3 cp input.nml ${s3_post_text_pfx}/input.nml)
	wait
        echo "$post_stat"
	post_stat=$(aws s3 cp model_configure ${s3_post_text_pfx}/model_configure)
	wait
        echo "$post_stat"
	post_stat=$(aws s3 cp diag_table ${s3_post_text_pfx}/diag_table)
	wait
        echo "$post_stat"
	post_stat=$(aws s3 cp field_table ${s3_post_text_pfx}/field_table)
	wait
        echo "$post_stat"
	post_stat=$(aws s3 cp run_forecast.sh ${s3_post_text_pfx}/run_forecast.sh)
	wait
        echo "$post_stat"


	if [ $Type == '"GFS"' ]; then
		local status_file_chgres_end=${STATUS_DIR}/${cp_from}_CHGRES_COMPLETED
		local status_file_forecast_beg=${STATUS_DIR}/${mem_num}_FORECAST_STARTED
		local status_file_forecast_end=${STATUS_DIR}/${mem_num}_FORECAST_COMPLETED
		#if [ -f "$status_file_chgres_end" ]; then
		#	rm -rf $status_file_chgres_end
		#fi
		if [ -f "$status_file_forecast_beg" ]; then
			rm -rf $status_file_forecast_beg
		fi
		if [ -f "$status_file_forecast_end" ]; then
			rm -rf $status_file_forecast_end
		fi

		status=No
		while (test "$status" != "Yes" )
		do
			if [ -f "$status_file_chgres_end" ]; then
				echo "RRFS FORECAST STARTED" > ${status_file_forecast_beg}
				date_str=$(date)
				echo "$date_str member:$mem_num FORECAST STARTED" >> ${tstamps}

				cd $fcst_rundir
				cd INPUT

				cp -p $fixdir/gfs_data.tile7.nc .
				cp -p $fixdir/sfc_data.tile7.nc .
				cp -p $fixdir/gfs_ctrl.nc .
				cp -pr $fixdir/gfs_bndy.tile7.*.nc .


				ln -s gfs_data.tile7.nc gfs_data.nc
        			ln -s sfc_data.tile7.nc sfc_data.nc
        			ln -s oro_data.tile7.nc oro_data.nc
				ln -s C${res}_grid.tile7.halo4.nc grid.tile7.halo4.nc
				cd ../

				sbatch run_forecast.sh
				echo "Started the forecast job for Member: $mem_num"
				status=Yes
			else
				sleep 5
			fi
		done
	elif [ $Type == '"GEFS"' ]; then
		local status_file_chgres_end=${STATUS_DIR}/${cp_from}_CHGRES_COMPLETED
		local status_file_forecast_beg=${STATUS_DIR}/${mem_num}_FORECAST_STARTED
		local status_file_forecast_end=${STATUS_DIR}/${mem_num}_FORECAST_COMPLETED
		#if [ -f "$status_file_chgres_end" ]; then
		#	rm -rf $status_file_chgres_end
		#fi
		if [ -f "$status_file_forecast_beg" ]; then
			rm -rf $status_file_forecast_beg
		fi
		if [ -f "$status_file_forecast_end" ]; then
			rm -rf $status_file_forecast_end
		fi

		status=No
		while (test "$status" != "Yes" )
		do
			if [ -f "$status_file_chgres_end" ]; then
				echo "RRFS FORECAST STARTED" > ${status_file_forecast_beg}
				date_str=$(date)
				echo "$date_str member:$mem_num FORECAST STARTED" >> ${tstamps}

				cd $fcst_rundir
				cd INPUT
				cp -p $fixdir/gfs_data.tile7.nc .
				cp -p $fixdir/sfc_data.tile7.nc .
				cp -p $fixdir/gfs_ctrl.nc .
				cp -pr $fixdir/gfs_bndy.tile7.*.nc .


				ln -s gfs_data.tile7.nc gfs_data.nc
        			ln -s sfc_data.tile7.nc sfc_data.nc
        			ln -s oro_data.tile7.nc oro_data.nc
				ln -s C${res}_grid.tile7.halo4.nc grid.tile7.halo4.nc
				cd ../

				sbatch run_forecast.sh
				echo "Started the forecast job for Member: $mem_num"
				status=Yes
			else
				sleep 5
			fi
		done

	fi
#Store post-processed file in AWS S3 bucket
	source /contrib/.aws/bdp.key
#unset e to continue processing with wgrib2 errors
unset e
	cd ${fcst_rundir}
	num_posts=`expr $num_posts - 1`
        for chour in $(seq 0 "$hr_post_skip" "$num_posts")
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
						wait
                                                echo "$post_file is uploaded and has a size of $file_size bytes"
						date_str=$(date)
						echo "$date_str member:$mem_num $s3_file uploaded to BDP bucket" >> ${tstamps}
						#########################
                                                wgrib2 -v $post_file  > tmp.txt
                                                if [ "$?" -eq 0 ]; then
							wgrib2 $post_file | grep -F -f /contrib/rpanda/parm/testbed.txt  | wgrib2 -i -grib PRSLEV_small1 $post_file 
                                                        post_reduc_stat=$(aws s3 cp ${post_small_file} ${s3_post_grib_pfx}/${s3_reduc_file})
                                                        wait
                                                	date_str=$(date)						
							echo "$date_str member:$mem_num $s3_reduc_file uploaded to BDP bucket" >> ${tstamps}
                                                else
                                                        echo "$post_file did not validate; skipping upload to S3"
                                                	date_str=$(date)						
							echo "$date_str member:$mem_num $post_file did not validate; skipping upload of $s3_reduc_file to BDP bucket" >> ${tstamps}
                                                fi
						status=Yes
					elif [ $res == "3445" ]; then
                        			s3_file=rrfs.t00z.mem0${mem_num}.naf${new_hour_name}.grib2
                        			s3_reduc_file=rrfs.t00z.mem0${mem_num}.testbed.conusf${new_hour_name}.grib2
						post_stat=$(aws s3 cp ${post_file} ${s3_post_grib_pfx}/${s3_file})
						wait
                                                echo "$post_file is uploaded and has a size of $file_size bytes"
						date_str=$(date)
						echo "$date_str member:$mem_num $s3_file uploaded to BDP bucket" >> ${tstamps}
						#########################
                                                wgrib2 -v $post_file  > tmp.txt
                                                if [ "$?" -eq 0 ]; then
                                                        wgrib2 $post_file -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid -new_grid $gridspecs $post_conv_file > /dev/null
                                                        wgrib2 $post_conv_file | grep -F -f /contrib/rpanda/parm/testbed.txt  | wgrib2 -i -grib PRSLEV_small1 $post_conv_file
                                                        post_reduc_stat=$(aws s3 cp ${post_small_file} ${s3_post_grib_pfx}/${s3_reduc_file})
                                                        wait
                                                	date_str=$(date)						
							echo "$date_str member:$mem_num $s3_reduc_file uploaded to BDP bucket" >> ${tstamps}
                                                else
                                                        echo "$post_file did not validate; skipping upload to S3"
                                                	date_str=$(date)						
							echo "$date_str member:$mem_num $post_file did not validate; skipping upload of $s3_reduc_file to BDP bucket" >> ${tstamps}
                                                fi
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
set -e
	source /contrib/.aws/proj.key
	post_stat=$(aws s3 cp ${fcst_out_file} ${s3_post_text_pfx}/${fcst_out_file})
	wait
        echo "$post_stat"
	post_stat=$(aws s3 cp ${fcst_err_file} ${s3_post_text_pfx}/${fcst_err_file})
	wait
        echo "$post_stat"

	if [ $Type == '"GFS"' ]; then
		local status_file_forecast_end=${STATUS_DIR}/${mem_num}_FORECAST_COMPLETED
		echo "RRFS FORECAST COMPLETED" > ${status_file_forecast_end}
		date_str=$(date)
		echo "$date_str member:$mem_num FORECAST COMPLETED" >> ${tstamps}
	elif [ $Type == '"GEFS"' ]; then
		local status_file_forecast_end=${STATUS_DIR}/${mem_num}_FORECAST_COMPLETED
		echo "RRFS FORECAST COMPLETED" > ${status_file_forecast_end}
		date_str=$(date)
		echo "$date_str member:$mem_num FORECAST COMPLETED" >> ${tstamps}
	fi

}
# Execute
echo "${BASH_SOURCE[0]}"
create_variables ensemble.yml
date_cur=`eval echo "${date_cur}"`
date_prv=`eval echo "${date_prv}"`
hour_from=`eval echo "${hour_from}"`
hr_interval=`eval echo "${hr_interval}"`
nhours_fcst=`eval echo "${nhours_fcst}"`
num_posts=`eval echo "${num_posts}"`
hr_post_skip=`eval echo "${hr_post_skip}"`
res=`eval echo "${res}"`
tot_mem=`eval echo "${tot_mem}"`
fcst_out_file=`eval echo "${fcst_out_file}"`
fcst_err_file=`eval echo "${fcst_err_file}"`
PFXDIR=`eval eval echo "${pfx_dir}"`
gfs_pfix=`eval eval echo "${gfs_pfix}"`
gfs_file_atm=`eval eval echo "${gfs_file_atm}"`
gfs_file_sfc=`eval eval echo "${gfs_file_sfc}"`
gfs_stub_b2=`eval eval echo "${gfs_stub_b2}"`
gfs_stub_b2b=`eval eval echo "${gfs_stub_b2b}"`
gefs_pfix_a=`eval eval echo "${gefs_pfix_a}"`
gefs_pfix_b=`eval eval echo "${gefs_pfix_b}"`
gefs_stub=`eval eval echo "${gefs_stub}"`
gefs_stub_a=`eval eval echo "${gefs_stub_a}"`
gefs_stub_b=`eval eval echo "${gefs_stub_b}"`
bucket=`eval eval echo "${bucket}"`
bucket_bdp=`eval eval echo "${bucket_bdp}"`
echo "gfs_pfix= $gfs_pfix"
echo "gfs_file_atm= $gfs_file_atm"
echo "gfs_file_sfc= $gfs_file_sfc"
echo "gfs_stub_b2= $gfs_stub_b2"
echo "gfs_stub_b2b= $gfs_stub_b2b"
echo "gefs_pfix_a= $gefs_pfix_a"
echo "gefs_pfix_b= $gefs_pfix_b"
echo "gefs_stub= $gefs_stub"
echo "gefs_stub_a= $gefs_stub_a"
echo "gefs_stub_b= $gefs_stub_b"
echo "$PFXDIR"
echo "$CLUSTERNAME"

#Set directory paths
RUNDIR=${PFXDIR}/${date_cur}
STATUS_DIR=${RUNDIR}/status
SCRIPTS_DIR=${PFXDIR}/UFS_UTILS/driver_scripts
MEMBER_SCRIPTS=${RUNDIR}/scripts
FCST_DIR=${RUNDIR}/forecast

#Create high level directories
cd $PFXDIR
if [ ! -d "$RUNDIR" ]; then
        echo "Run directory for the chosen date string $date_str is being created"
        mkdir -p $RUNDIR
else
        echo "Run directory for $date_str is not created; it exists"
fi
cd ${RUNDIR}
if [ ! -d "$STATUS_DIR" ]; then
        echo "Creating status directory"
        mkdir -p $STATUS_DIR
else
        echo "status directory exists"
fi
if [ ! -d "$FCST_DIR" ]; then
        echo "Creating forecast directory"
        mkdir -p $FCST_DIR
else
        echo "forecast directory exists"
fi

if [ ! -d "$MEMBER_SCRIPTS" ]; then
        echo " member scripts directory for runs is being created"
        mkdir -p $MEMBER_SCRIPTS
else
        echo "driver_scripts directory for sequential runs already exists"
fi


member=${2}
echo "My member number is $member"
	create_scripts $member &
	run_scripts $member &
	run_forecast $member &

exit 0

# Functions
