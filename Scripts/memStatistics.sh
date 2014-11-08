#!/bin/bash

function replace_acronym() {
   if   [ $1 == "S" ]; then
      echo "Sleeping"
   elif [ $1 == "D" ]; then
      echo "IO Wait"
   elif [ $1 == "R" ]; then
      echo "Running"
   elif [ $1 == "T" ]; then
      echo "Stopped"
   elif [ $1 == "Z" ]; then
      echo "Zombie"
   elif [ $1 == "X" ]; then
      echo "Dead"
   fi
}

#Statistic
A=`awk '$1~/Mem[(Total)(Free)]/{print $2/1024 ","} $1~/Swap[(Total)(Free)]/{print $2/1024 ","}' /proc/meminfo`
echo 's;'$A
#Users
echo "u;`ps ax -eo user,stat | awk '{arr[$1]++} END{for(i in arr) {print arr[i],i}}' | sort -nr | tr "\n" ","`"
#pie
A=`ps ax -eo user,stat | awk '{print $2 }'|cut -c1| awk '{arr[$1]++ } END{for(i in arr) {print arr[i],i,","}}'`
echo 'p;'$A
#top
/bin/ps -e -o pid,pmem,args --sort -rss | awk '$2>0.5 {print "t;" $1 ","$2","$3}'
echo 't;'


