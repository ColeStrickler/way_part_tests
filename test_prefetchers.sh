#!/bin/bash
export PATH=$PATH:./
# This experiment tests 3 co-runners and 1 victim each allocated half the way partitions of the LLC
#
#
killall bandwidth

# disable dynamic frequency scaling
echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 

DRAM_BOMB_SIZE=2144
LLC_BOMB_SIZE=600 # needs to be > L2_SIZE and < Partition size
ATTACKER_SCHEMEID=0x1
VICTIM_SCHEMEID=0x0
WAY_ALLOC=0xccccccc3 # schemeID 0 gets way groups 0,1 and schemeID 1 gets way groups 2,3

# Set up way partitioning
# Set flags in CLUSTERPARTCR to allocate way groups to schemeIDs
wpuser-control 1 $WAY_ALLOC 0 
wpuser-control 5 $VICTIM_SCHEMEID 0 # tell victim core0 to use $VICTIM_SCHEMEID

# tell attacker cores to use $ATTACKER_SCHEMEID
for core in 1 2 3; do
	wpuser-control 1 $WAY_ALLOC $core
	wpuser-control 5 $ATTACKER_SCHEMEID $core
done;


#start co-runners
for core in 1 2 3; do
	 bandwidth -a read -c $core -m $DRAM_BOMB_SIZE -t 0 & 2>/dev/null
done

taskset -c 0 perf stat -e r0500,r0501,r0502,r0503,r0504 bandwidth -a write -c 0 -t 10 -m $LLC_BOMB_SIZE > out.txt 2>&1
#taskset -c 0 perf stat -e instructions,LLC-load-misses,LLC-loads,r36,r37 bandwidth -a read -c 0 -t 10 -m $LLC_BOMB_SIZE > out.txt 2>&1

killall bandwidth


# sed -i 's/old-text/new-text/g' ./out.txt
sed -i 's/r0500/SCU_PFTCH_CPU_ACCESS/g' ./out.txt
sed -i 's/r0501/SCU_PFTCH_CPU_MISS/g' ./out.txt
sed -i 's/r0502/SCU_PFTCH_CPU_HIT/g' ./out.txt
sed -i 's/r0503/SCU_PFTCH_CPU_MATCH/g' ./out.txt
sed -i 's/r0504/SCU_PFTCH_CPU_KILL/g' ./out.txt
cat out.txt
