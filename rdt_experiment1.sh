#!/bin/bash
export PATH=$PATH:../bench
# This experiment tests 3 co-runners and 1 victim each allocated half the way partitions of the LLC
#
# I conducted this experiment by modifying the number of co-runners and by editing the variable
# LLC_BOMB_SIZE to the appropriate WSS for the victim
#
killall bandwidth

DRAM_BOMB_SIZE=6144
LLC_BOMB_SIZE=1024 # needs to be > L2_SIZE and < Partition size
ATTACKER_SCHEMEID=0x1
VICTIM_SCHEMEID=0x0
WAY_ALLOC=0xffffffc3

# Set up way partitioning
# Set CLUSTERPARTCR to allocate way groups to schemeIDs
wpuser-control 1 $WAY_ALLOC 0 # --> this allocates way group 2,3 to schemeID 1 and way groups 0,1 to schemeID 0

# tell victim core to use schemeID 0
wpuser-control 5 $VICTIM_SCHEMEID 0
# tell attacker cores to use schemeID 1
for core in 1 2 3; do
	wpuser-control 1 $WAY_ALLOC $core
	wpuser-control 5 $ATTACKER_SCHEMEID $core
done;


#start co-runners
for core in 1 2 3; do
	bandwidth -a write -c $core -m $DRAM_BOMB_SIZE -t 0 2>/dev/null &
done

perf stat -e instructions,LLC-load-misses,LLC-loads  ../bench/bandwidth -a read -c 0  -t 10 -m $LLC_BOMB_SIZE
