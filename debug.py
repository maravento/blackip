#!/usr/bin/env python
a=set(line.strip().lower() for line in open('ipscidr.txt').readlines())
b=set(line.strip().lower() for line in open('iana.txt').readlines())
open("out.txt", "w").write("\n".join(a.difference(b)))
