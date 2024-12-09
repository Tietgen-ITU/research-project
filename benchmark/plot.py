import json
import sys
from typing import DefaultDict, TypeAlias
from pathlib import Path
from collections import defaultdict
import numpy as np
import matplotlib.pyplot as plt

Results: TypeAlias = DefaultDict[str, DefaultDict[str, DefaultDict[str, DefaultDict[str, DefaultDict[str, DefaultDict[str, DefaultDict[str,float]]]]]]]

def parse_result(folder: Path) -> Results:
    # name -> bs -> precon_util -> io_depth -> threads
    results = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(float)))))))
    for path in folder.rglob("*.txt"):
        with open(path, "r") as f:
            run = json.load(f)
            print(path.stem)
            test, name, bs, precon_util, iodepth, threads  = (path.stem).split("_")
            read_job = run["jobs"][0]["read"]
            write_job = run["jobs"][0]["write"]
            
            # Read clat 99th percentile
            results[name]["read"][bs][precon_util][iodepth][threads]["clat"] = read_job["clat_ns"]["percentile"]["99.000000"]
            results[name]["write"][bs][precon_util][iodepth][threads]["clat"] = write_job["clat_ns"]["percentile"]["99.000000"]

            # Read iops for Writes
            results[name]["write"][bs][precon_util][iodepth][threads]["iops"] = write_job["iops_mean"]
            results[name]["write"][precon_util][iodepth][threads]["iops_stddev"] = write_job["iops_stddev"]
    return results
            

def plot_iops_iodepth_threads(results: Results, bs: str, precon: str) -> None:
    # The gorupings on the x axis
    x_ticks = [1, 2, 4, 8, 16, 32, 64, 128]
    
    # Define how many ticks there are
    x = np.arange(len(x_ticks))

    # Witdth of the bars within a bar group (x tick)
    bar_width = 0.20
    
    # Group specifier
    multiplier = 0

    fig, ax = plt.subplots()

    # Hatches
    colors = ["blue", "darkgreen", "red", "violet"]
    hathces = ["//", "--", "xx", "++"]
    
    # Gather lists from results
    nonfdp_iodepth = [results["nonfdp"]["write"][bs][precon][str(tio)]["1"]["iops"] for tio in x_ticks]    
    fdp_iodepth = [results["fdp"]["write"][bs][precon][str(tio)]["1"]["iops"] for tio in x_ticks]
    nonfdp_threads = [results["nonfdp"]["write"][bs][precon]["1"][str(tio)]["iops"] for tio in x_ticks]
    fdp_threads = [results["fdp"]["write"][bs][precon]["1"][str(tio)]["iops"] for tio in x_ticks]
    l = [("Non-FDP (iodepth)", nonfdp_iodepth), ("FDP (iodepth)", fdp_iodepth)]#, ("Non-FDP (threads)", nonfdp_threads), ("FDP (threads)", fdp_threads)]
    for i, (case, measurements) in enumerate(l):
        offset = bar_width * multiplier
        rects = ax.bar(x + offset, measurements, bar_width, label=case)
        #ax.bar_label(rects, padding=1)
        multiplier += 1
    
    ax.set_ylabel('IOPS')
    ax.set_title('Performance with increasing iodepth/threads for non-fdp/fdp')
    ax.set_xticks(x + (1.5 * bar_width), x_ticks)
    ax.legend(loc='upper left', ncols=4)
    ax.set_ylim(0, 1500000)

    plt.savefig("iops_iodepth_threads.pdf", format="pdf", bbox_inches="tight")


def plot_clat(results, bs, precon):
    threads = ["1", "2", "4", "8", "16"]
    io_depth = ["1", "2", "4"]

    colors = ["blue", "green", "violet", "orange"]
    markers = [".", "x", "s", "v"]
    linestyles = ["solid", "dotted", "solid", "dotted"]

    for thread in threads:
        
        fig, ax = plt.subplots()
        
        write_nonfdp = [results["nonfdp"]["write"][bs][precon][iodep][thread]["clat"] / 1000 for iodep in io_depth]
        write_fdp = [results["fdp"]["write"][bs][precon][iodep][thread]["clat"] / 1000 for iodep in io_depth]
        read_nonfdp = [results["nonfdp"]["read"][bs][precon][iodep][thread]["clat"] / 1000 for iodep in io_depth]
        read_fdp = [results["nonfdp"]["read"][bs][precon][iodep][thread]["clat"] / 1000 for iodep in io_depth]
        
        l = [("Write", write_nonfdp), ("Write - FDP", write_fdp), ("Read", read_nonfdp), ("Read - FDP", read_fdp)] 
        
        for i, (lbl, res) in enumerate(l): 
            plt.plot(io_depth, res, color=colors[i], marker=markers[i], linestyle=linestyles[i], label=lbl)
        
        plt.ylabel("Completion latency (microseconds)")
        plt.xlabel("IO depth")
        plt.legend(loc="upper right", ncols=1)

        plt.savefig(f"clat_threads{thread}.pdf", format="pdf", bbox_inches="tight")





    


def main(folder: Path) -> None:
    results = parse_result(folder)
    #plot_iops_iodepth_threads(results, "4096", "0")
    plot_clat(results, "4096", "0")
    
if __name__ == "__main__":
    folder = Path(sys.argv[1])

    main(folder)
