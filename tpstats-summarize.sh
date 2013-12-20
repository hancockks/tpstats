#!/bin/bash

function print_usage
{
cat << EOF
Usage: $(basename $0) pool-name stage
Usage: $(basename $0) statistic

Arguments
	pool-name	Which pool to summarize changes over
	stage		Which stage/status to summarize
	statistic	Which statistic to summarize changes over

Process the tpstats.out file and summarize changes for any one
pool name and stage or one statistic over time.

Pools as of DSE 3.1:
	ReadStage
	RequestResponseStage
	MutationStage
	ReadRepairStage
	ReplicateOnWriteStage
	GossipStage
	AntiEntropyStage
	MigrationStage
	MemtablePostFlusher
	FlushWriter
	MiscStage
	commitlog_archiver
	InternalResponseStage
	HintedHandoff
	
Stages:
	active
	pending
	completed
	blocked
	total-blocked

Statistics:
	RANGE_SLICE
	READ_REPAIR
	BINARY
	READ
	MUTATION
	REQUEST_RESPONSE
EOF
}

if [ $# -lt 1 ]; then
	print_usage
	exit 1
fi

if [ $# -eq 1 ]; then

	stat=$1
	column=4

read -d '' script << "EOF"
	BEGIN{
		OFS="\\t"; 
		printf("%-20s    %-15s    %-16s    %9s    %9s\\n", "Date","Host","Statistic","Count","Delta")
	}
	{
		if (last[$2]=="") {
			last[$2]=$col
		}
		if (last[$2]!=$col) {
			printf("%-20s    %-15s    %-16s    %9d    %9d\\n", $1,$2,$3,$col,$col-last[$2]);
			last[$2]=$col
		}
	}
EOF

echo $script

	grep $stat tpstats.out | sort -u -k2,2 -k1,1 | awk -v stat="$stat" -v col=$column '
	BEGIN{
		OFS="\t"; 
		printf("%-20s    %-15s    %-16s    %9s    %9s\n", "Date","Host","Statistic","Count","Delta")
	}
	{
		if (last[$2]=="") {
			last[$2]=$col
		}
		if (last[$2]!=$col) {
			printf("%-20s    %-15s    %-16s    %9d    %9d\n", $1,$2,$3,$col,$col-last[$2]);
			last[$2]=$col
		}
	}'

else

	stat=$1
	stage=$2

	if [ "$stage" == "active" ]; then
		column=4
	elif [ "$stage" == "pending" ]; then
		column=5
	elif [ "$stage" == "completed" ]; then
		column=6
	elif [ "$stage" == "blocked" ]; then
		column=7
	elif [ "$stage" == "total-blocked" ]; then
		column=8
	fi

	grep $stat tpstats.out | sort -u -k2,2 -k1,1 | awk -v stat="$stat" -v col=$column -v stage="$stage" '
	BEGIN{
		OFS="\t";
		printf("%-20s  %-15s  %-16s    %9s        %6s %7s %9s %7s %16s\n","Date","Host","Pool",stage,"Active","Pending","Compld","Blocked","All Time Blocked");
		ttotal=0;
		tsamples=0;
		tmax=0;
	}
	{
		if(last[$2]==""){
			last[$2]=$col
		}; 
		if (samples[$2]==""){
			samples[$2]=0;
			total[$2]=0;
			max[$2]=0;
		}
		if ($col > max[$2]){
			max[$2]=$col;
		}
		samples[$2]+=1;
		total[$2]+=$col
		if ($col > tmax){
			tmax=$col
		}

		if(last[$2]!=$col){
			last[$2]=$col;
			printf("%-20s  %-15s  %-16s    %9s        %6s %7s %9s %7s %16s\n",$1,$2,$3,$col,$4,$5,$6,$7,$8);
		};
	}
	END{
		printf("\nNode summary statistics for %s %s\n",stage,stat); 
		printf("%-20s  %16s    %8s    %8s\n", "Host", "Average", "Maximum","Samples");
		for(i in samples){
			printf("%-20s  %16f    %8d    %8d\n", i, total[i]/samples[i], max[i], samples[i]);
			ttotal+=total[i];
			tsamples+=samples[i]
		}; 
		printf("Cluster-wide statistics for %s %s: Average: %f, Max: %d, Samples: %d \n",stage, stat, ttotal/tsamples, tmax, tsamples);
	}
	'
fi
