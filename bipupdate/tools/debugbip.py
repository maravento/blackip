#!/usr/bin/env python
import sys

try:
    a = set(line.strip().lower() for line in open('blackip.txt').readlines())
    b = set(line.strip().lower() for line in open('debugip.txt').readlines())
    open("outip.txt", "w").write("\n".join(sorted(a.difference(b))) + "\n")
except FileNotFoundError as e:
    print("Error: %s" % e)
    sys.exit(1)
