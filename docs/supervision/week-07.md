# What have been done during the last week (7)?

@arnenator has looked into how Liburing works in order to get a better understanding of how io_uring works. Furthermore, he has spent some time looking into some C++ code and cmake files in duckdb to become better at these two technologies.
___

## Questions?
___

1. It seems that the NVMe device (FDP), we have gained access to supports up to 16 namespaces, and the FDP configuration supports up to 2 namespaces. We have crated a single name space with half of the total capacity (we want to name spaces with equal capacity and access to 4 reclaim unit handlers) and attached it to the device. However, when trying to create another namespace with the same configuration (different placement handler ids), we recieve an error code `NVMe status: unrecognized(0x2A)`. Do you have any idea why?

Reproduction of error:
```
## Delete existing namespaces and enable FDP (Can only be when no namespaces exist)
...

## Find size and capacity:
nvme id-ctrl /dev/nvme0 | grep nvmcap | sed “s/,//g” | awk ‘{print $3/4096}’
> 918.149.526
> 918.149.526

## Create namespace with half the size and first 4 RUH
nvme create-ns /dev/nvme1 -b 4096 --nsze=459074763 --ncap=459074763 -p 0,1,2,3 -n 4

## Attach namespace
nvme attach-ns /dev/nvme1 --namespace-id=1 --controllers=0x7

## Create second namespace
nvme create-ns /dev/nvme1 -b 4096 --nsze=459074763 --ncap=459074763 -p 0,1,2,3 -n 4
> NVMe status: unrecognized(0x2a)
```
