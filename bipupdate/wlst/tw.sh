#!/bin/bash
# https://serverfault.com/questions/780626/how-to-block-teamviewer/858290

tw=$(pwd)/tw.txt
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n"

# IPs server teamviewer
for i in `seq 10000 99999`;
do
    a="server"$i".teamviewer.com"
    b=`dig +short $a`
    if [[ "$b" == "" ]]; then
        continue
    fi
    echo "$b" | $reorganize > $tw
done
