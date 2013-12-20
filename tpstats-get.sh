
function print_usage
{
cat << EOF
Usage: $(basename $0) [ip_address1 ipaddress2 ipaddress3 ...]

This tool will loop through all the Cassandra nodes specified on
the command line and call nodetool tpstats, one server per 5 seconds.
Output will be appended to a file called tpstats.out

If no addresses are specified, /etc/dse/cassandra/cassandra.yaml is
parsed to return the seed list.

After completion, run tpstats-diff.sh to summarize the delta for
any one metric across each of the stat files or use tpstat-summarize.sh
to detect changes between statatistics.
EOF
}


file="/etc/dse/cassandra/cassandra.yaml"

outfile=tpstats.out

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] ; then
	print_usage
	exit 1
fi

if [ $# -lt 1 ]; then
	echo "Using seed list from $file"
	seeds=`sed -n "s/ - {*seeds:.\(.*\)/\1/p" $file | tr ",\'\"{}" " "`
else
	seeds="$@"
fi

if [ -e tpstats.out ]; then
	echo "ERROR: $outfile exists!"
	echo "If you are starting a new test, stop $0 and then archive/delete $outfile"
	echo "Exiting."
	exit 1
fi

while [ 1 ]
do
	for host in $seeds
	do
		date=`date +"%Y-%m-%dT%H:%M:%S"`
		nodetool -h $host tpstats 2>/dev/null | awk -v d="$date" -v h="$host" '{for(i=1;i<=NF;++i)$i=(i==1)?d " " h " " $i:$i;print}' >> $outfile
	done
	sleep 5
done



