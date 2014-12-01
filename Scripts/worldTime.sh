#!/bin/bash

for var in "$@"
do
echo "$var"
done
#UTC
date -u                       +"<b>UTC:        </b><i> %T</i>"
#Places
TZ='America/Toronto' date     +"<b>Toronto:  </b><i> %T</i>"
TZ='Europe/Rome' date         +"<b>Rome:      </b><i> %T</i>"
TZ='Asia/Shanghai' date       +"<b>Shanghai:</b><i> %T</i>"