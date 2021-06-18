#!/bin/bash

module use /contrib/apps/miniconda3/modulefiles/
module load miniconda3
module use /contrib/apps/modules
module load hpc-stack/1.1.0
module load intel/19.0.5.281

conda activate pygraf

#date_cur=$(date --date="today" +"%Y%m%d")
date_cur=20210602
num_posts=61
hr_post_skip=1
hour=00
cyc_str=${date_cur}${hour}
date_cur_dir=rrfs.${date_cur}
s3_pfx=s3://noaa-rrfs-pds/${date_cur_dir}/00
base_dir=/lustre/rpanda/plots
data_dir=${base_dir}/data
pngs_dir=${base_dir}/pngs
#num_data_dir_files=550


if [ ! -d "$data_dir" ]; then
        mkdir -p $data_dir
else
        cd $data_dir
        rm -rf *
fi

if [ ! -d "$pngs_dir" ]; then
        mkdir -p $pngs_dir
else
        cd $pngs_dir
        rm -rf *
fi
cd $base_dir


source /contrib/.aws/bdp.key

chour=0

while [[ "$chour" -lt "$num_posts" ]]
do

        if [ $chour -lt 10 ]; then
                phour='0'$chour
                fhour='00'$chour
        else
                phour=$chour
                fhour='0'$chour
        fi

        fl1=${data_dir}/rrfs.t00z.mem01.testbed.conusf${fhour}.grib2
        fl2=${data_dir}/rrfs.t00z.mem02.testbed.conusf${fhour}.grib2
        fl3=${data_dir}/rrfs.t00z.mem03.testbed.conusf${fhour}.grib2
        fl4=${data_dir}/rrfs.t00z.mem04.testbed.conusf${fhour}.grib2
        fl5=${data_dir}/rrfs.t00z.mem05.testbed.conusf${fhour}.grib2
        fl6=${data_dir}/rrfs.t00z.mem06.testbed.conusf${fhour}.grib2
        fl7=${data_dir}/rrfs.t00z.mem07.testbed.conusf${fhour}.grib2
        fl8=${data_dir}/rrfs.t00z.mem08.testbed.conusf${fhour}.grib2
        fl9=${data_dir}/rrfs.t00z.mem09.testbed.conusf${fhour}.grib2

        mt_pfx=2mt_members_
        mdew_pfx=2mdew_members_
        refc_pfx=refc_members_
        uh25_pfx=uh25_members_
        mucape_pfx=mucape_members_
        maxuvv_pfx=maxuvv_members_
        qpf_pfx=qpf_members_

#Check if testbed files have been created for all 9 members
	while [[ "$n_avail" -lt 9 ]]
	do
		n_avail=0

		for mem_num in 01 02 03 04 05 06 07 08 09
		do
			f_stat=$(aws s3 ls ${s3_pfx}/mem${mem_num}/rrfs.t00z.mem${mem_num}.testbed.conusf${fhour}.grib2 | cut -c 32-) 
			if [ ! -z "$f_stat" ]; then 
				#echo "$f_stat exists" 
				n_avail=`expr $n_avail + 1`
			else
			       sleep 15	
			fi
		done
	done
#Get data for the forecast hour for which all 9 member testbed files are available
	cd $data_dir
	for mem_num in 01 02 03 04 05 06 07 08 09
	do
		f_stat=$(aws s3 cp ${s3_pfx}/mem${mem_num}/rrfs.t00z.mem${mem_num}.testbed.conusf${fhour}.grib2 .) 
	done

#Submit slurm jobs for plot generation
        cd $pngs_dir

	submit_stat=No
	while (test $submit_stat != "Yes")
	do
        	if [[ -f "$fl1"  &&  -f "$fl2"  &&  -f "$fl3"  &&  -f "$fl4"  &&  -f "$fl5"  &&  -f "$fl6"  &&  -f "$fl7"  &&  -f "$fl8"  &&  -f "$fl9" ]];then
                	echo "all testbed files are there for $fhour to be plotted"
                	sbatch /lustre/rpanda/plots/plots.a.sh ${cyc_str} ${phour} ${data_dir}
                	sbatch /lustre/rpanda/plots/plots.b.sh ${cyc_str} ${phour} ${data_dir}
			submit_stat=Yes
		else
			sleep 15
		fi
	done

	chour=`expr $chour + 1`
done
exit 0



