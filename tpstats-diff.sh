#!/bin/bash

function print_usage
{
cat << EOF
Usage: $(basename $0) statname

Grep through all *.tpstats files and calculate the change for any one
statistic, being one of:
  RANGE_SLICE
  READ_REPAIR
  BINARY
  READ
  MUTATION
  REQUEST_RESPONSE
EOF
}

stat=$1

if [ $# -lt 1 ]; then
	print_usage
	exit 1
fi

grep $stat tpstats.out | sort -u -k2,2 -k4,4n | awk -v stat="$stat" '{if ($5>"")next; if ($3 != stat)next; if (min[$2]==""){min[$2]=max[$2]=$4}if (last[$2]==""){last[$2]=$1}if ($4<min[$2]){min[$2]=$4};if ($4 > max[$2]){max[$2]=$4;last[$2]=$1}}END{for(i in min){total+=(max[i]-min[i]);print last[i],i,max[i]-min[i]}print "total " total}' 


