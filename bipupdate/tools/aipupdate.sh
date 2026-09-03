#!/bin/bash
# maravento.com
#
################################################################################
#
# AllowIP for Reverse Squid
# log: aipupdate.log (generated in the execution directory)
# 
# used:	host -t a / or / dig +short -f
# dig example.com +nostats +nocomments +nocmd
#
################################################################################

set -uo pipefail

# ------------------------------------------------------------------------------
# REQUIREMENTS
# ------------------------------------------------------------------------------

# check no-root
if [ "$(id -u)" == "0" ]; then
    echo "[ERROR] This script should not be run as root."
    exit 1
fi

# prevent overlapping runs
script_lock="/var/lock/$(basename "$0" .sh).lock"
exec 200>"$script_lock"
if ! flock -n 200; then
    echo "[ERROR] Script $(basename "$0") is already running"
    exit 1
fi

# dependencies
for dep_pkg in wget bind9-host grepcidr findutils gawk coreutils; do
    if ! dpkg -s "$dep_pkg" &>/dev/null; then
        echo "ERROR: Required dependency '$dep_pkg' is not installed." >&2
        exit 1
    fi
done

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir" || exit 1
log_file="$(basename "$0" .sh).log"
exec > >(tee "$log_file") 2>&1
lst_dir="$script_dir/../lst"
allowip_file="$lst_dir/allowip.txt"
sort_uniq="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u"
wget_opts='wget -q -c --no-check-certificate --retry-connrefused --timeout=10 --tries=4'
trap 'rm -f urls.txt out.txt progress.txt' INT TERM

echo "AllowIP Project"
echo "This process can take a long time. Be patient..."

# ------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------

echo "Downloading Allow URLs..."
function intacls() {
    $wget_opts "$1" -O - | sed '/^$/d; /#/d' | sed 's:^\.::' | sort -u > urls.txt
}
intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/debugwl.txt' && sleep 1
echo "OK"

# debbuging allow whiteIP (CIDR)
echo "Debugging AllowIP..."
parallel_procs=$(($(nproc) * 4))
if [ ! -s urls.txt ]; then
    echo "ERROR: urls file is empty or missing. Aborting."
    exit 1
fi
total_domains=$(wc -l < urls.txt)
: > progress.txt
(
    while sleep 1; do
        processed_count=$(wc -l < progress.txt 2>/dev/null)
        percent_done=$(awk -v p="$processed_count" -v t="$total_domains" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
        printf "Processed: %d / %d (%s%%)\r" "$processed_count" "$total_domains" "$percent_done"
    done
) &
progress_pid=$!
cat urls.txt | xargs -I {} -P "$parallel_procs" bash -c 'for host_prefix in "" "www." "ftp."; do host -t a "${host_prefix}$1"; done; echo >> progress.txt' _ {} | grep "has address" | awk '{ print $4 }' > out.txt
kill "$progress_pid" 2>/dev/null
echo "OK"
# Remove conflicts (iana.txt, dns.txt)
grepcidr -vf "$lst_dir/iana.txt" out.txt | grep -vFxf <(sed '/^#/d' "$lst_dir/dns.txt") | $sort_uniq > "$allowip_file"
sort -u "$allowip_file" -o "$allowip_file"

# ------------------------------------------------------------------------------
# END
# ------------------------------------------------------------------------------

echo "Copy Allow IP to Squid and eliminate the conflicts"
rm -f urls.txt out.txt progress.txt
echo "AllowIP Done: $(date)"
command -v notify-send &>/dev/null && notify-send "AllowIP Update Done" "$(date)" -i checkbox
