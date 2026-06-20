#!/usr/bin/env python3
import sys

try:
    with open('blackip_preview.txt') as f:
        a = set(line.strip().lower() for line in f)
    with open('cleanip.txt') as f:
        b = set(line.strip().lower() for line in f)
    with open("outip.txt", "w") as f:
        f.write("\n".join(sorted(a.difference(b))) + "\n")
except FileNotFoundError as e:
    print("Error: %s" % e)
    sys.exit(1)
