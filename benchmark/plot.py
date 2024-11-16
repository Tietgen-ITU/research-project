import json
import sys
from typing import DefaultDict, TypeAlias
from pathlib import Path
from collections import defaultdict
import numpy as np
import matplotlib.pyplot as plt

Results: TypeAlias = DefaultDict[str, DefaultDict[str, DefaultDict[str, DefaultDict[str, DefaultDict[str, DefaultDict[str,float]]]]]]

def parse_result(folder: Path) -> Results:
    # name -> bs -> precon_util -> io_depth -> threads
    results = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(float)))))) 
    for path in folder.rglob("*.txt"):
        with open(path, "r") as f:
            run = json.load(f)
            name, bs, precon_util, iodepth, threads  = (path.stem).split("_")
            jobs = run["jobs"][0]
            iops = float(jobs["write"]["iops_mean"])
            iopss_stdv = float(jobs["write"]["iops_stddev"])
            results[name][bs][precon_util][iodepth][threads]["iops"] = iops
            results[name][bs][precon_util][iodepth][threads]["iops_stddev"] = iopss_stdv
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
    nonfdp_iodepth = [results["nonfdp"][bs][precon][str(tio)]["1"]["iops"] for tio in x_ticks]    
    fdp_iodepth = [results["fdp"][bs][precon][str(tio)]["1"]["iops"] for tio in x_ticks]
    nonfdp_threads = [results["nonfdp"][bs][precon]["1"][str(tio)]["iops"] for tio in x_ticks]
    fdp_threads = [results["nonfdp"][bs][precon]["1"][str(tio)]["iops"] for tio in x_ticks]
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





def main(folder: Path) -> None:
    results = parse_result(folder)
    plot_iops_iodepth_threads(results, "4096", "0")
    print(results)
    
if __name__ == "__main__":
    folder = Path(sys.argv[1])

    main(folder)
