import subprocess
import sys
import time
import os
import re
from datetime import datetime

xnvme_cmd = "/home/pinar/.local/xnvme/builddir/tools/xnvme"
xnvme_driver_cmd = "/home/pinar/.local/xnvme/builddir/toolbox/xnvme-driver"
device = "0000:ec:00.0"
id_log = "0x1"

def get_waf():
    cmd = f"""{xnvme_cmd} log-fdp-stats "0000:ec:00.0" --lsi {id_log} --be spdk"""
    print(cmd)
    res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE).stdout.decode("utf-8")
    host = 0
    media = 0

    for i, line in enumerate(res.split('\n')):
        if i == 3:
            print(line)
            num = re.search(r"""\d+""", line).group()
            host = int(num) if num else 0
        elif i == 4:
            num = re.search(r"""\d+""", line).group()
            media = int(num) if num else 0
    if host == 0: return 0
    return media/host 

    
def measure_waf(out):
    points = 0
    while points < 20:
        time.sleep(15)
        with open(out, "a") as f:
            num = get_waf()
            f.write(f"{datetime.now()} - {num}\n")
        points += 1

if __name__ == "__main__":
    out = sys.argv[1]
    measure_waf(out)
