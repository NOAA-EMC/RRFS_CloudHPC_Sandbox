#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091

# Configure
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./bash-yaml/script/yaml.sh

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
		rm -rf $MEMBER_TMPDIR
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
	rm -rf $STATUS_DIR
        echo "Creating status directory"
        mkdir -p $STATUS_DIR

	rm -rf $MEMBER_SCRIPTS
        echo " member scripts directory for runs is being created"
        mkdir -p $MEMBER_SCRIPTS

	rm -rf download
	mkdir -p download


member=${2}
echo "My member number is $member"
	create_scripts $member &
	run_scripts $member &

exit 0

# Functions
