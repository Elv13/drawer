#!/bin/bash

#Set localization for bc localizaton
LC_NUMERIC="en_US.UTF-8"

CPU_INFO=`cat /proc/cpuinfo`
SENSOR=`sensors`
CORE_NB=`echo -e "$CPU_INFO" | grep processor | tail -n 1 | awk '{print $3}'`



#COUNTER=0
#CPU_STATE=`mpstat -P ALL 1 1 | head -n 8 | tail -n 4`
IFS_BACK=$IFS
IFS=`echo -en "\n\b"`
CORE_INFO=0
#for CORE in `seq 0 $CORE_NB`; do
#echo "Core: $CORE"
	#Add usr, nice and sys
	#USAGE=`echo $CORE | awk ' {print $3 "+" $4 }' | bc`
    #echo "line $CORE: $CPU_INFO | grep 'cpu MHz' | cut -d':' -f 2 | sed -n $COREp"
    #USAGE=$(echo -e "$CPU_INFO" | grep "cpu MHz" | cut -d":" -f 2 | sed -n $(printf "%sp" $(($CORE+1))))
    #echo "Usage: $USAGE"
    #USAGE=`printf "%.0f" $USAGE`
    #IOWAIT=`echo $CORE | awk ' {print $6}'`
	#IOWAIT=`printf "%.0f" $IOWAIT`
	#IDLE=`echo $CORE | awk ' {print $11}'`
	#IDLE=`printf "%.0f" $IDLE`
	#echo "  <b>use=</b><i>$USAGE%</i>, <b>I/O=</b><i>$IOWAIT%</i>, <b>idle=</b><i>$IDLE%</i>" > /tmp/cpuStat.${COUNTER}
	#CORE_INFO[$CORE]=""
    
	#let COUNTER=$COUNTER+1
#done
IOWAIT=0
IDLE=0
USAGE=0
IFS=$IFS_BACK
echo "cpuInfo = {"
#echo "   core = $CORE_NB"
echo "   overallLoad = `top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | bc`,"
for CURRENT_CORE in `seq 0 $CORE_NB`;do
    CPU_CORE=`echo -e "$CPU_INFO" | grep -e "processor[	]*: $CURRENT_CORE" --context +6 | grep "cpu MHz"`
    SPEED=$( echo -e "$CPU_INFO" | grep "cpu MHz" | cut -d":" -f 2 | sed -n $( printf "%sp" $(($CORE+1)) ) ) 
    SPEED=$( echo "scale=2; $SPEED / 1024" | bc )
    CORE_ONE=`echo -e "$CPU_CORE" | head -n 1 | grep -e "[0-9.]*" -o`
    CORE_ONE=`printf "%.0f" $CORE_ONE`
    TEMP_ONE=`echo -e "$SENSOR" | grep "Core $CURRENT_CORE" | grep -e "   +[0-9]*" -o`
    echo "   core${CURRENT_CORE} = { speed= \"$SPEED\", temp= \"${TEMP_ONE:4}\", usage =\"$USAGE\", iowait = \"$IOWAIT\", idle = \"$IDLE\", },"
done
echo "}"
