#!/usr/bin/env python
a=set(line.strip().lower() for line in open('blackip.txt').readlines())
b=set(line.strip().lower() for line in open('cleanip.txt').readlines())
open("biptmp.txt", "w").write("\n".join(a.difference(b)))
