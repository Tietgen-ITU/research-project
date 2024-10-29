#!/bin/bash

DEVICE="/dev/nvme1"
DEVICE_NS=""
NVME_CMD="nvme"
NAMESPACE="1"
CONTROLLER="0x7"
FDP="0x1D"

BLOCK_SIZE=4096

# Return the total number of blocks on the device
blocks_on_device(){
    local var CMD="$NVME_CMD id-ctrl $DEVICE | grep -i tnvmcap | sed 's/,//g' | awk {print $3/$BLOCK_SIZE}"
    echo $(CMD)
}

# Return the total capacity on the device
capacity_on_device(){
    local var CMD="$NVME_CMD id-ctrl $DEVICE | grep -i tnvmcap | sed 's/,//g' | awk {print $3}"
    echo $(CMD)
}

# Return the capacity of the device with x% utilization  
utilized_capacity() {
    local var UTIL={$1-100}
    local var DEVICE_CAP=$(capacity_on_device)
    echo $(DEVICE * (UTIL / 100))
}

# Remove the namespace on the device (can maybe extend to multiple)
remove_namespace (){
    local var CMD="$NVME_CMD delete-ns $DEVICE -n $NAMESPACE"
    $CMD
}

# Erase all blocks on the device
deallocate_device(){
    local var num_blocks=$(blocks_on_device)
    local var CMD="$NVME_CMD dsm $DEVICE --ad -s 0 -b $num_blocks"
    $CMD
}

disable_fdp(){
    local var CMD="$NVME_CMD set-feature $DEVICE -f $FDP -c 0 -s"
    $CMD
}

enable_fdp(){
    local var CMD="$NVME_CMD set-feature $DEVICE -f $FDP -c 1 -s"
    $CMD
}

reset_device() {
    remove_namespace
    deallocate_device
}

fill_device() {
    local var UTIL=$1
    # TODO : fill device with random garbage using fio

}

setup_device_fpd_disabled() {
    $(reset_device)
    $(disable_fdp)
    
    local var PRECON_UTIL={$1-0}
    local var DEVICE_CAP= $(capacity_on_device)
    local var CREATE_NS="$NVME_CMD create-ns $DEVICE -b $BLOCK_SIZE --nsze=$DEVICE_CAP --ncap=$DEVICE_CAP"
    local var ATTACH_NS="$NVME_CMD attach-ns $DEVICE --namespace-id=$NAMESPACE --controllers=$CONTROLLER"

    $CREATE_NS
    $ATTACH_NS

    DEVICE_NS="${DEVICE}n${NAMESPACE}"

    if [PRECON_UTIL > 0]; then
        $(fill_device $PRECON_UTIL)
    fi
}

setup_device_fpd_enabled() {
    $(reset_device)
    $(enable_fdp)

    local var PRECON_UTIL={$1-0}
    local var DEVICE_CAP= $(capacity_on_device)
    local var CREATE_NS="$NVME_CMD create-ns $DEVICE -b $BLOCK_SIZE --nsze=$DEVICE_CAP --ncap=$DEVICE_CAP --nphndls=8 --phndls=0,1,2,3,4,5,6,7"
    local var ATTACH_NS="$NVME_CMD attach-ns $DEVICE --namespace-id=$NAMESPACE --controllers=$CONTROLLER"

    $CREATE_NS
    $ATTACH_NS

    DEVICE_NS="${DEVICE}n${NAMESPACE}"

    if [PRECON_UTIL > 0]; then
        $(fill_device $PRECON_UTIL)
    fi
}


#############################################################################
#
# Benchmarks
#
#############################################################################

benchmark(){
    BENCH_BLOCK_SIZES=(512, 4096)
    BENCH_THREADS=(1, 2, 4, 8, 16, 32)
    BENCH_IODEPTH=(1, 2, 4, 8, 16, 32, 64, 128)
    BENCH_WORKLOAD_SIZE=(50,100)
    BENCH_PRECONDITION_UTILIZATION=(20, 50, 70, 100)
    BENCH_RUNS=3
    
    $(setup_device_fpd_disabled)
    fio --name="test_non_fdp" --filename=$DEVICE_NS --rw="randwrite" --size="20" --direct="1" --ioengine="io_uring_cmd" --bs="4k" --iodepth="1" --numjobs="4" --loops=$BENCH_RUNS --allow_create_file="false" --output-format="json" --output="test_non_fdp.txt" --group_reporting

    $(setup_device_fpd_enabled)
    fio --name="test_fdp" --filename=$DEVICE_NS --rw="randwrite" --size="20" --direct="1" --ioengine="io_uring_cmd" --bs="4k" --iodepth="1" --numjobs="4" --loops=$BENCH_RUNS --allow_create_file="false" --output-format="json" --output="test_fdp.txt" --group_reporting

}

$(benchmark)

#SIZE='1G'

#for ((job=1; job <= 16; job*=2))
#do
#    fio --name=test_${job} --rw=randwrite --ioengine=posixaio --direct=1 --group_reporting --loops=3 --bs=4k --iodepth=1 --output=test_${job} --output-format=json --size=${SIZE} --numjobs=${job}
#done
