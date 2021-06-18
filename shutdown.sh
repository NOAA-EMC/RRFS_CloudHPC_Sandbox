#!/bin/bash


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
		echo "All $count forecasts complete"
		echo "All $count clusters are being shutdown"
		fcst_complete_stat=Yes
	else
		sleep 15
	fi
done


exit 0
