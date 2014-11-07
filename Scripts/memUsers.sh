#!/bin/bash

/bin/ps ax -eo user,stat | awk '{arr[$1]++} END{for(i in arr) {print arr[i],i}}' | sort -nr | tr "\n" ","
