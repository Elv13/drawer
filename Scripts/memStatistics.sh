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



A=`ps ax -eo user,stat | awk '{print $2 }'|cut -c1| awk '{arr[$1]++ } END{for(i in arr) {print arr[i],i,","}}'`
echo $A