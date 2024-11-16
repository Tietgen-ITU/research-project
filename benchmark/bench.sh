#!/bin/bash

DEVICE=/dev/nvme1
DEVICE_NS=
DEVICE_NG=/dev/ng1n1
NVME_CMD=/home/pinar/.local/nvme-cli/.build/nvme
FIO_CMD=/home/pinar/.local/fio/fio
NAMESPACE=1
CONTROLLER=0x7
FDP=0x1D

BLOCK_SIZE=4096

# Return the total number of blocks on the device
blocks_on_device(){
    $NVME_CMD id-ctrl $DEVICE | grep 'tnvmcap' | sed 's/,//g' | awk -v BS=$BLOCK_SIZE '{print $3/BS}'
}

# Return the total capacity on the device
capacity_on_device(){
    $NVME_CMD id-ctrl $DEVICE | grep 'tnvmcap' | sed 's/,//g' | awk '{print $3}'
}

# Return the capacity of the device with x% utilization  
utilized_capacity() {
    local var UTIL={$1-100}
    local var DEVICE_CAP=$(capacity_on_device)
    echo $(DEVICE * (UTIL / 100))
}

# Remove the namespace on the device (can maybe extend to multiple)
remove_namespace (){
    $NVME_CMD delete-ns $DEVICE -n $NAMESPACE
}

# Return information about WAF
waf_info (){
	$NVME_CMD fdp stats $DEVICE -e 1 | awk '/(HBMW)/ {lHBMW=$7} /(MBMW)/ {lMBMW = $7} END {print "WAF = " lMBMW/lHBMW}'
}

# Erase all blocks on the device
deallocate_device(){
    local var NUM_BLOCKS=$(blocks_on_device)
    $NVME_CMD dsm $DEVICE --namespace-id=$NAMESPACE --ad -s 0 -b $NUM_BLOCKS
}

disable_fdp(){
    $NVME_CMD set-feature $DEVICE -f $FDP -c 0 -s
    $NVME_CMD get-feature $DEVICE -f $FDP -H
}

enable_fdp(){
    $NVME_CMD set-feature $DEVICE -f $FDP -c 1 -s
    $NVME_CMD get-feature $DEVICE -f $FDP -H
}

reset_device() {
    #remove_namespace
    echo "Deallocating all blocks..."
    deallocate_device
    echo "Removing previous namespace"
    remove_namespace
}

fill_device() {
    local var UTIL=$1
    # TODO : fill device with random garbage using fio

}

setup_device_fdp_disabled() {
    echo "______ SETUP NON-FDP ______"
    echo "Resetting the device: $DEVICE"
    reset_device
    echo "Disabling fdp on the device"
    disable_fdp
    
    local var PRECON_UTIL="${1-0}"
    local var DEVICE_CAP=$(blocks_on_device)
    
    echo "Creating namepace with size: $DEVICE_CAP, and block size: $BLOCK_SIZE"
    $NVME_CMD create-ns $DEVICE -b $BLOCK_SIZE --nsze=$DEVICE_CAP --ncap=$DEVICE_CAP
    
    echo "Attaching the namespace to the device: $DEVICE"
    $NVME_CMD attach-ns $DEVICE --namespace-id=$NAMESPACE --controllers=$CONTROLLER


    DEVICE_NS=${DEVICE}n${NAMESPACE}

    if [ $PRECON_UTIL -gt 0 ]; then
        $(fill_device $PRECON_UTIL)
    fi
    echo "___________________________"
}

setup_device_fdp_enabled() {
    echo "________ SETUP FDP ________"
    echo "Resetting the device: $DEVICE"
    reset_device
    echo "enabling fdp on the device"
    enable_fdp

    local var PRECON_UTIL="${1-0}"
    local var DEVICE_CAP=$(blocks_on_device)
   
    # For some reason it is not possible to allocate all 8 reclaim unit handles. The error code can be found in the base specification by searching "2Ah"
    echo "Creating namepace with size: $DEVICE_CAP, and block size: $BLOCK_SIZE. Using placement handlers: 0,1,2,3,4,5,6,7" 
    $NVME_CMD create-ns $DEVICE -b $BLOCK_SIZE --nsze=$DEVICE_CAP --ncap=$DEVICE_CAP --nphndls=7 --phndls=0,1,2,3,4,5,6
    
    echo "Attaching the namespace to the device: $DEVICE."
    $NVME_CMD attach-ns $DEVICE --namespace-id=$NAMESPACE --controllers=$CONTROLLER

    DEVICE_NS=${DEVICE}n${NAMESPACE} 
  
    if [ $PRECON_UTIL -gt 0 ]; then
        $(fill_device $PRECON_UTIL)
    fi
    echo "___________________________"
}


#############################################################################
#
# Benchmarks
#
#############################################################################
export LD_LIBRARY_PATH=/usr/local/lib64
benchmark(){
    BENCH_BLOCK_SIZES=(4096)
    BENCH_THREADS=(1 2 4 8 16)
    BENCH_IODEPTH=(1 2 4 8 16 32)
    BENCH_WORKLOAD_SIZE=(50 100)
    BENCH_PRECONDITION_UTILIZATION=(20 50 70 100)
    BENCH_RUNS=5
    PATH_TO_OUT_BENCH=/home/pinar/research-project/benchmark
    for bs in "${BENCH_BLOCK_SIZES[@]}" ; do
	    for threads in "${BENCH_THREADS[@]}" ; do
		    for iodepth in "${BENCH_IODEPTH[@]}" ; do
    			setup_device_fdp_disabled
   			$FIO_CMD --name="nonfdp" --filename=$DEVICE_NG --rw="randwrite" --size="5GB" --direct="0" --ioengine="io_uring_cmd" --bs=$bs --iodepth=$iodepth --numjobs=$threads --loops=$BENCH_RUNS --allow_file_create="1" --output-format="json" --output="$PATH_TO_OUT_BENCH/nonfdp_${bs}_0_${iodepth}_${threads}.txt" --group_reporting

    			setup_device_fdp_enabled
    			$FIO_CMD --name="fdp" --filename=$DEVICE_NG --rw="randwrite" --size="30GB" --direct="0" --ioengine="io_uring_cmd" --bs=$bs --iodepth=$iodepth --numjobs=$threads --loops=$BENCH_RUNS --allow_file_create="1" --output-format="json" --output="$PATH_TO_OUT_BENCH/fdp_${bs}_0_${iodepth}_${threads}.txt" --group_reporting --fdp=1 --fdp_pli=0,1,2,3,4,5,6 
			waf_info
    	   	    done 
	   done 
    done
}

benchmark
