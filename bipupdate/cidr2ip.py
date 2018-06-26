#!/usr/bin/env python
def ip2int(ip):
    ip = [int(p) for p in ip.split(".")]
    return ip[0] << 24 | ip[1] << 16 | ip[2] << 8 | ip[3]

def int2ip(i):
    return "{0}.{1}.{2}.{3}".format(
        i >> 24 & 0xff,
        i >> 16 & 0xff,
        i >> 8  & 0xff,
        i       & 0xff)

def toRange(ip):
    if "-" in ip:
        ip1, ip2 = ip.split("-")
        return [int2ip(i) for i in range(ip2int(ip1), ip2int(ip2)+1)]
    elif "/" in ip:
        ip1, mask = ip.split("/")
        ip1 = ip2int(ip1)
        # netmask
        netmask   = ip2int('255.255.255.255') << (32 - int(mask))
        broadcast = ip2int('255.255.255.255') >> int(mask) | ip1
        network   = ip1 & netmask
        return [int2ip(i) for i in range(ip1, broadcast)]
    else:
        return [ip]

if __name__ == '__main__':
    import sys

    if len(sys.argv) < 2:
        print("Error: falta archivo")
        exit(1)

    try:
        
        lines = open(sys.argv[1]).readlines()
        ips   = []
        
        for line in lines:
            if line.startswith("#"): continue
            for ip in toRange(line.strip()):
                print(ip)
        
        exit(0)
    except Exception as e:
        print("Error: El archivo \"%s\" no existe" % sys.argv[1])
        exit(1)