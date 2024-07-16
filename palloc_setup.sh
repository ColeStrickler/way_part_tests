#!/bin/bash

# palloc mask for pi5 cache partitioning
# L2 Cache: 512KB, 8way, 64byte cache lines (https://developer.arm.com/documentation/100798/0401/L2-memory-system/About-the-L2-memory-system)
# L3 cache: 2MB, 16way, 64byte
# L2 Set bits --> (2^19)/((2^3)(2^6)) = 10 bits
# L3 Set bits --> (2^21)/((2^4)(2^6)) = 11 bits 
# 1 bit can be used to partition L3 --> Bit16



echo 0x10000 > /sys/kernel/debug/palloc/palloc_mask


#Create partitions
cgcreate -g palloc:part1
cgcreate -g palloc:part2
cgcreate -g palloc:part3
cgcreate -g palloc:part4
cgcreate -g palloc:part5
cgcreate -g palloc:part6
cgcreate -g palloc:part7
cgcreate -g palloc:part8

#Assign bins to partitions
echo 0 > /sys/fs/cgroup/palloc/part1/palloc.bins 
echo 1 > /sys/fs/cgroup/palloc/part2/palloc.bins
echo 0-1 > /sys/fs/cgroup/palloc/part3/palloc.bins

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 2 > /sys/kernel/debug/palloc/alloc_balance
echo 1 > /sys/kernel/debug/palloc/use_palloc



