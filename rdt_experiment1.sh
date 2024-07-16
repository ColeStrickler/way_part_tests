#!/bin/bash
export PATH=$PATH:../IsolBench/bench
# This experiment tests 3 co-runners and 1 victim each allocated half the way partitions of the LLC
#
#
killall bandwidth

DRAM_BOMB_SIZE=6144
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
	 bandwidth -a write -c $core -m $DRAM_BOMB_SIZE -t 0 & 2>/dev/null
done

taskset -c 0 perf stat -e instructions,LLC-load-misses,LLC-loads,r00A3,r00A2,r00A1,r00A0,r0029,r002A,r002B,r002C,r36,r37 bandwidth -a read -c 0 -t 10 -m $LLC_BOMB_SIZE > out.txt 2>&1
#taskset -c 0 perf stat -e instructions,LLC-load-misses,LLC-loads,r36,r37 bandwidth -a read -c 0 -t 10 -m $LLC_BOMB_SIZE > out.txt 2>&1

killall bandwidth


sed -i 's/old-text/new-text/g' ./out.txt
sed -i 's/r0029/L3D_CACHE_ALLOCATE/g' ./out.txt
sed -i 's/r002A/L3D_CACHE_REFILL/g' ./out.txt
sed -i 's/r002B/L3D_CACHE/g' ./out.txt
sed -i 's/r002C/L3D_CACHE_WB/g' ./out.txt
sed -i 's/r00A0/L3D_CACHE_RD/g' ./out.txt
sed -i 's/r00A1/L3D_CACHE_WR/g' ./out.txt
sed -i 's/r00A2/L3D_CACHE_REFILL_RD/g' ./out.txt
sed -i 's/r00A3/L3D_CACHE_REFILL_WR/g' ./out.txt
sed -i 's/r36/LL_CACHE_RD/g' ./out.txt
sed -i 's/r37/LL_CACHE_MISS_RD/g' ./out.txt

cat out.txt
