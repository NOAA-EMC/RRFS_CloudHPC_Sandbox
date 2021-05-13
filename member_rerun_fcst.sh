#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091

# Configure
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./bash-yaml/script/yaml.sh

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

	chmod +x fv3_gfs.x

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
				echo "GFS FORECAST STARTED" > ${status_file_forecast_beg}
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
				echo "GEFS FORECAST STARTED" > ${status_file_forecast_beg}
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
                        post_filename=PRSLEV.GrbF${hour_name}
                        path_filename=${fcst_rundir}/PRSLEV.GrbF${hour_name}
			echo "$post_filename is about to be uploaded to S3"

                        if [ -f "$path_filename" ]; then
                                #check if chgres processed file size changes in 1 second
                                file_size=$(stat --printf=%s $path_filename)
                                sleep 1
                                file_size1=$(stat --printf=%s $path_filename)
                                #if file size hasn't changed, count the file; increment the counter, etc.
                                if [ $file_size == $file_size1 ] && [ $file_size -gt 0 ]; then
					if [ $res == "3357" ]; then
                        			s3_filename=rrfs.t00z.mem0${mem_num}.conusf${new_hour_name}.grib2
						post_stat=$(aws s3 cp ${post_filename} ${s3_post_grib_pfx}/${s3_filename})
						#post_stat=$(aws s3 cp ${post_filename} ${s3_post_grib_pfx}/${post_filename})
						wait
                                        	echo "$post_filename is uploaded and has a size of $file_size bytes"
                                        	echo "$post_stat"
						status=Yes
					elif [ $res == "3445" ]; then
                        			s3_filename=rrfs.t00z.mem0${mem_num}.naf${new_hour_name}.grib2
						post_stat=$(aws s3 cp ${post_filename} ${s3_post_grib_pfx}/${s3_filename})
						#post_stat=$(aws s3 cp ${post_filename} ${s3_post_grib_pfx}/${post_filename})
						wait
                                        	echo "$post_filename is uploaded and has a size of $file_size bytes"
                                        	echo "$post_stat"
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

	if [ $Type == '"GFS"' ]; then
		local status_file_forecast_end=${STATUS_DIR}/${mem_num}_FORECAST_COMPLETED
		echo "GFS FORECAST COMPLETED" > ${status_file_forecast_end}
		date_str=$(date)
		echo "$date_str member:$mem_num FORECAST COMPLETED" >> ${tstamps}
	elif [ $Type == '"GEFS"' ]; then
		local status_file_forecast_end=${STATUS_DIR}/${mem_num}_FORECAST_COMPLETED
		echo "GEFS FORECAST COMPLETED" > ${status_file_forecast_end}
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
echo "Creating forecast directory"
rm -rf $FCST_DIR
mkdir -p $FCST_DIR

if [ ! -d "$MEMBER_SCRIPTS" ]; then
        echo " member scripts directory for runs is being created"
        mkdir -p $MEMBER_SCRIPTS
else
        echo "driver_scripts directory for sequential runs already exists"
fi


member=${2}
echo "My member number is $member"
	run_forecast $member &

exit 0

# Functions
