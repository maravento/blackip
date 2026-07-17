#!/bin/bash
# maravento.com
#
################################################################################
#
# AllowIP for Reverse Squid
# log: aipupdate.log (generated in the execution directory)
# https://unix.stackexchange.com/questions/550796/bash-to-launching-multiple-queries-with-xargs
# 
# used:	host -t a / or / dig +short -f
# dig example.com +nostats +nocomments +nocmd
#
################################################################################

set -uo pipefail

# check no-root
if [ "$(id -u)" == "0" ]; then
    echo "[ERROR] This script should not be run as root."
    exit 1
fi

# prevent overlapping runs
SCRIPT_LOCK="/var/lock/$(basename "$0" .sh).lock"
exec 200>"$SCRIPT_LOCK"
if ! flock -n 200; then
    echo "[ERROR] Script $(basename "$0") is already running"
    exit 1
fi

# DEPENDENCIES
pkgs='wget bind9-host grepcidr'
for pkg in $pkgs; do
  if ! dpkg -s "$pkg" &>/dev/null && ! command -v "$pkg" &>/dev/null; then
    echo "'$pkg' is not installed. Run:"
    echo "sudo apt install $pkg"
    exit 1
  fi
done

# Language spa-eng
cm1=("This process can take a long time. Be patient..." "Este proceso puede tardar mucho tiempo. Sea paciente...")
cm2=("Downloading Allow URLs..." "Descargando Allow URLs...")
cm3=("Debugging AllowIP..." "Depurando AllowIP...")
cm4=("Copy Allow IP to Squid and eliminate the conflicts" "Copie Allow IP a Squid y elimine los conflictos")
lang=$([[ "${LANG,,}" =~ ^es ]] && echo 1 || echo 0)

# VARIABLES
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
LOGFILE="$(basename "$0" .sh).log"
exec > >(tee "$LOGFILE") 2>&1
lst="$SCRIPT_DIR/../lst"
wip="$lst/allowip.txt"
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u"
wgetd='wget -q -c --no-check-certificate --retry-connrefused --timeout=10 --tries=4'
trap 'rm -f urls.txt out.txt progress.txt' INT TERM

echo "AllowIP Project"
echo "${cm1[$lang]}"

# DOWNLOAD URLS
echo "${cm2[$lang]}"
function intacls() {
    $wgetd "$1" -O - | sed '/^$/d; /#/d' | sed 's:^\.::' | sort -u > urls.txt
}
intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/debugwl.txt' && sleep 1
echo "OK"

# DEBBUGGING Allow WhiteIP (CIDR)
echo "${cm3[$lang]}"
PROCS=$(($(nproc) * 4))
if [ ! -s urls.txt ]; then
    echo "ERROR: urls file is empty or missing. Aborting."
    exit 1
fi
total=$(wc -l < urls.txt)
: > progress.txt
(
    while sleep 1; do
        processed=$(wc -l < progress.txt 2>/dev/null)
        percent=$(awk -v p="$processed" -v t="$total" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
        printf "Processed: %d / %d (%s%%)\r" "$processed" "$total" "$percent"
    done
) &
progress_pid=$!
cat urls.txt | xargs -I {} -P $PROCS bash -c 'for sub in "" "www." "ftp."; do host -t a "${sub}$1"; done; echo >> progress.txt' _ {} | grep "has address" | awk '{ print $4 }' > out.txt
kill "$progress_pid" 2>/dev/null
echo "OK"
# Remove conflicts (iana.txt, dns.txt)
grepcidr -vf "$lst/iana.txt" out.txt | grep -vFxf <(sed '/^#/d' "$lst/dns.txt") | $reorganize > $wip
sort -u $wip -o $wip

# END
echo "${cm4[$lang]}"
rm -f urls.txt out.txt progress.txt
echo "AllowIP Done: $(date)"
command -v notify-send &>/dev/null && notify-send "AllowIP Update Done" "$(date)" -i checkbox
