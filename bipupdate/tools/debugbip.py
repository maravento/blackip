#!/usr/bin/env python3
# BlackIP Diff Debug
# FILE: bipupdate/tools/debugbip.py
import sys
import time

try:
    with open('blackip_preview.txt') as f:
        a = set(line.strip().lower() for line in f)
    with open('cleanip.txt') as f:
        b = set(line.strip().lower() for line in f)
    with open("outip.txt", "w") as f:
        f.write("\n".join(sorted(a.difference(b))) + "\n")
except FileNotFoundError as e:
    print(
        "%s ERROR: debugbip.py: %s not found"
        % (time.strftime('%Y-%m-%d %H:%M:%S'), e.filename),
        file=sys.stderr,
    )
    sys.exit(1)
