#!/bin/bash

module use /contrib/apps/miniconda3/modulefiles/
module load miniconda3
module use /contrib/apps/modules
module load hpc-stack/1.1.0
module load intel/19.0.5.281

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

source /contrib/.aws/bdp.key
conda activate pygraf

declare -a SUBDOMAIN=([0]=conus [1]=BN [2]=CE [3]=CO [4]=LA [5]=MA [6]=NC [7]=NE [8]=NW [9]=OV [10]=SC [11]=SE [12]=SF [13]=SP [14]=SW [15]=UM )
declare -a DOM_STAT=([0]=No [1]=No [2]=No [3]=No [4]=No [5]=No [6]=No [7]=No [8]=No [9]=No [10]=No [11]=No [12]=No [13]=No [14]=No [15]=No )

cd $pngs_dir

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

	mt_pfx=2mt_members_
	mdew_pfx=2mdew_members_
	refc_pfx=refc_members_
	uh25_pfx=uh25_members_
	mucape_pfx=mucape_members_
	maxuvv_pfx=maxuvv_members_
	qpf_pfx=qpf_members_



	for indx in {0..7}
	do
		DOM_STAT[$indx]=No
		while (test ${DOM_STAT[$indx]} != "Yes")
		do
			sub_d=${SUBDOMAIN[$indx]}
			echo "$indx $sub_d"
			if [ ${DOM_STAT[$indx]} != "Yes" ]; then

        			p1=${pngs_dir}/${mt_pfx}${sub_d}_f${phour}.png
        			p2=${pngs_dir}/${mdew_pfx}${sub_d}_f${phour}.png
        			p3=${pngs_dir}/${refc_pfx}${sub_d}_f${phour}.png
        			p4=${pngs_dir}/${uh25_pfx}${sub_d}_f${phour}.png
        			p5=${pngs_dir}/${mucape_pfx}${sub_d}_f${phour}.png
        			p6=${pngs_dir}/${maxuvv_pfx}${sub_d}_f${phour}.png
        			p7=${pngs_dir}/${qpf_pfx}${sub_d}_f${phour}.png

				if [[ -f "$p1" && -f "$p2" && -f "$p3" && -f "$p4" && -f "$p5" && -f "$p6" && -f "$p7" ]]; then


					aws s3 cp ${p1} ${s3_pfx}/plots/
					aws s3 cp ${p2} ${s3_pfx}/plots/
					aws s3 cp ${p3} ${s3_pfx}/plots/
					aws s3 cp ${p4} ${s3_pfx}/plots/
					aws s3 cp ${p5} ${s3_pfx}/plots/
					aws s3 cp ${p6} ${s3_pfx}/plots/
					aws s3 cp ${p7} ${s3_pfx}/plots/
					DOM_STAT[$indx]=Yes
				fi
			else
				sleep 15
			fi
		done
	done
	for indx in {8..15}
	do
		DOM_STAT[$indx]=No
		while (test ${DOM_STAT[$indx]} != "Yes")
		do
			sub_d=${SUBDOMAIN[$indx]}
			echo "$indx $sub_d"
			if [ ${DOM_STAT[$indx]} != "Yes" ]; then

        			p1=${pngs_dir}/${mt_pfx}${sub_d}_f${phour}.png
        			p2=${pngs_dir}/${mdew_pfx}${sub_d}_f${phour}.png
        			p3=${pngs_dir}/${refc_pfx}${sub_d}_f${phour}.png
        			p4=${pngs_dir}/${uh25_pfx}${sub_d}_f${phour}.png
        			p5=${pngs_dir}/${mucape_pfx}${sub_d}_f${phour}.png
        			p6=${pngs_dir}/${maxuvv_pfx}${sub_d}_f${phour}.png
        			p7=${pngs_dir}/${qpf_pfx}${sub_d}_f${phour}.png

				if [[ -f "$p1" && -f "$p2" && -f "$p3" && -f "$p4" && -f "$p5" && -f "$p6" && -f "$p7" ]]; then


					aws s3 cp ${p1} ${s3_pfx}/plots/
					aws s3 cp ${p2} ${s3_pfx}/plots/
					aws s3 cp ${p3} ${s3_pfx}/plots/
					aws s3 cp ${p4} ${s3_pfx}/plots/
					aws s3 cp ${p5} ${s3_pfx}/plots/
					aws s3 cp ${p6} ${s3_pfx}/plots/
					aws s3 cp ${p7} ${s3_pfx}/plots/
					DOM_STAT[$indx]=Yes
				fi
			else
				sleep 15
			fi
		done
	done

        sleep 60
       	chour=`expr $chour + 1`
done


exit 0



