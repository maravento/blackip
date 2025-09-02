# [BlackIP](https://www.maravento.com/p/blackip.html)

<!-- markdownlint-disable MD033 -->

[![status-stable](https://img.shields.io/badge/status-stable-green.svg)](https://github.com/maravento/blackip)
[![last commit](https://img.shields.io/github/last-commit/maravento/blackip)](https://github.com/maravento/blackip)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/maravento/blackip)
[![Twitter Follow](https://img.shields.io/twitter/follow/maraventostudio.svg?style=social)](https://twitter.com/maraventostudio)

<table align="center">
  <tr>
    <td align="center">
      <span>English</span> | <a href="README-es.md">Español</a>
    </td>
  </tr>
</table>

BlackIP is a project that collects and unifies public blocklists of IP addresses, to make them compatible with [Squid](http://www.squid-cache.org/) and [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/)).

## DATA SHEET

---

| ACL | Blocked IP | File Size |
| :---: | :---: | :---: |
| blackip.txt | 439268 | 6,2 Mb |

## GIT CLONE

---

```bash
git clone --depth=1 https://github.com/maravento/blackip.git
```

## HOW TO USE

---

`blackip.txt` is already optimized. Download it and unzip it in the path of your preference.

### Download

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz && cat blackip.tar.gz* | tar xzf -
```

### Optional: Checksum

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/checksum.md5
md5sum blackip.txt | awk '{print $1}' && cat checksum.md5 | awk '{print $1}'
```

#### Important about BlackIP

- Should not be used `blackip.txt` in [IPSET](http://ipset.netfilter.org/) and in [Squid](http://www.squid-cache.org/) at the same time (double filtrate).
- `blackip.txt` is a list IPv4. Does not include CIDR.

### [Ipset/Iptables](http://ipset.netfilter.org/) Rules

Edit your Iptables bash script and add the following lines (run with root privileges):

```bash
#!/bin/bash
# https://linux.die.net/man/8/ipset

# Replace with your path to blackip.txt
ips=/path_to_lst/blackip.txt

# ipset rules
ipset -L blackip >/dev/null 2>&1
if [ $? -ne 0 ]; then
        echo "set blackip does not exist. create set..."
        ipset -! create blackip hash:net family inet hashsize 1024 maxelem 10000000
    else
        echo "set blackip exist. flush set..."
        ipset -! flush blackip
fi
ipset -! save > /tmp/ipset_blackip.txt
# read file and sort (v8.32 or later)
cat $ips | sort -V -u | while read line; do
    # optional: if there are commented lines
    if [ "${line:0:1}" = "#" ]; then
        continue
    fi
    # adding IPv4 addresses to the tmp list
    echo "add blackip $line" >> /tmp/ipset_blackip.txt
done
# adding the tmp list of IPv4 addresses to the blackip set of ipset
ipset -! restore < /tmp/ipset_blackip.txt

# iptables rules
iptables -t raw -I PREROUTING -m set --match-set blackip src -j DROP
iptables -t raw -I PREROUTING -m set --match-set blackip dst -j DROP
iptables -t raw -I OUTPUT -m set --match-set blackip dst -j DROP
echo "done"
```

#### Ipset/Iptables Rules with IPDeny (Optional)

You can add the following lines to the bash above to include full country IP ranges with [IPDeny](https://www.ipdeny.com/ipblocks/) adding the countries of your choice.

```bash
# Put these lines at the end of the "variables" section
# Replace with your path to zones folder
zones=/path_to_folder/zones
# download zones
if [ ! -d $zones ]; then mkdir -p $zones; fi
wget -q -N http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
tar -C $zones -zxvf all-zones.tar.gz >/dev/null 2>&1
rm -f all-zones.tar.gz >/dev/null 2>&1

# replace the line:
cat $ips | sort -V -u | while read line; do
# with (e.g: Russia and China):
cat $zones/{cn,ru}.zone $ips | sort -V -u | while read line; do
```

#### About Ipset/Iptables Rules

- Ipset allows mass filtering, at a much higher processing speed than other solutions (check [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).
- Blackip is a list containing millions of IPv4 lines and to be supported by Ipset, we had to arbitrarily increase the parameter [maxelem](https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is) (for more information, check [ipset's hashsize and maxelem parameters](https://www.odi.ch/weblog/posting.php?posting=738)).
- Ipset/iptables limitation: "*When entries added by the SET target of iptables/ip6tables, then the hash size is fixed and the set won't be duplicated, even if the new entry cannot be added to the set*" (for more information, check [Man Ipset](https://ipset.netfilter.org/ipset.man.html)).
- Heavy use of these rules can slow down your PC to the point of crashing. Use them at your own risk.
- Tested on iptables v1.8.7, ipset v7.15, protocol version: 7.

### [Squid](http://www.squid-cache.org/) Rule

Edit:

```bash
/etc/squid/squid.conf
```

And add the following lines:

```bash
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS

# Block Rule for BlackIP
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip
```

#### About Squid Rule

- `blackip.txt` has been tested in Squid v3.5.x and later.

#### Advanced Rules

BlackIP contains millions of IP addresses, therefore it is recommended:

- Use `blackcidr.txt` to add IP/CIDR that are not included in `blackip.txt` (By default it contains some Block CIDR).
- Use `allowip.txt` (a whitelist of IPv4 IP addresses such as Hotmail, Gmail, Yahoo. etc.).
- Use `aipextra.txt` to add whitelists of IP/CIDRs that are not included in `allowip.txt`.
- By default, `blackip.txt` excludes some private or reserved ranges [RFC1918](https://en.wikipedia.org/wiki/Private_network). Use IANA (`iana.txt`) to exclude them all.
- By default, `blackip.txt` excludes some DNS servers included in `dns.txt`. You can use this list and expand it to deny or allow DNS servers.
- To increase security, close Squid to any other request to IP addresses with ZTR.

```bash
### INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS ###

# Allow Rule for IP
acl allowip dst "/path_to/allowip.txt"
http_access allow allowip

# Allow Rule for IP/CIDR ACL (not included in allowip.txt)
acl aipextra dst "/path_to/aipextra.txt"
http_access allow aipextra

# Allow Rule for IANA ACL (not included in allowip.txt)
acl iana dst "/path_to/iana.txt"
http_access allow iana

# Allow Rule for DNS ACL (excluded from blackip.txt)
acl dnslst dst "/path_to/dns.txt"
http_access allow dnslst # or deny dnlst

# Block Rule for IP/CIDR ACL (not included in blackip.txt)
acl blackcidr dst "/path_to/blackcidr.txt"
http_access deny blackcidr

## Block Rule for BlackIP
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip

## Block IP
acl no_ip url_regex -i ^(http|https)://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
http_access deny no_ip
```

## BLACKIP UPDATE

---

### ⚠️ WARNING: BEFORE YOU CONTINUE

This section is only to explain how update and optimization process works. It is not necessary for user to run it. This process can take time and consume a lot of hardware and bandwidth resources, therefore it is recommended to use test equipment.

#### Bash Update

>The update process of `blackip.txt` is executed in sequence by the script `bipupdate.sh`. The script will request privileges when required.

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && chmod +x bipupdate.sh && ./bipupdate.sh
```

#### Dependencies

>Update requires python 3x and bash 5x.

```bash
wget git curl idn2 perl tar rar unrar unzip zip python-is-python3 ipset squid
```

#### Capture Public Blocklists

>Capture IPv4 from downloaded public blocklists (see [SOURCES](https://github.com/maravento/blackip#sources)) and unifies them in a single file.

#### DNS Loockup

>Most of the [SOURCES](https://github.com/maravento/blackip#sources) contain millions of invalid and nonexistent IP. Then, a double check of each IP is done (in 2 steps) via DNS and invalid and nonexistent are excluded from Blackip. This process may take. By default it processes in parallel ≈ 6k to 12k x min, depending on the hardware and bandwidth.

```bash
HIT 8.8.8.8
Host 8.8.8.8.in-addr.arpa domain name pointer dns.google
FAULT 0.0.9.1
Host 1.9.0.0.in-addr.arpa. not found: 3(NXDOMAIN)
```

#### Run Squid-Cache with BlackIP

>Run Squid-Cache with BlackIP and any error sends it to `SquidError.txt` on your desktop.

#### Check execution (/var/log/syslog)

```bash
BlackIP: Done 02/02/2024 15:47:14
```

#### Important about BlackIP Update

- `tw.txt` containing IPs of teamviewer servers. By default they are commented. To block or authorize them, activate them in `bipupdate.sh`. To update it use `tw.sh`.
- You must activate the rules in [Squid](http://www.squid-cache.org/) before using `bipupdate.sh`.
- Some lists have download restrictions, so do not run `bipupdate.sh` more than once a day.
- During the execution of `bipupdate.sh` it will request privileges when needed.
- If you use `aufs`, temporarily change it to `ufs` during the upgrade, to avoid: `ERROR: Can't change type of existing cache_dir aufs /var/spool/squid to ufs. Restart required`.

#### AllowIP Update

>`allowip.txt` is already updated and optimized. The update process of `allowip.txt` is executed in sequence by the script `aipupdate.sh`.

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/aipupdate.sh && chmod +x aipupdate.sh && ./aipupdate.sh
```

## SOURCES

---

### BLOCKLISTS

#### Active

- [abuse.ch - Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)
- [abuse.ch - Zeustracker blocklist](https://zeustracker.abuse.ch/blocklist.php?download=badips)
- [alienvault - reputation](https://reputation.alienvault.com/reputation.generic)
- [BBcan177 - minerchk](https://raw.githubusercontent.com/BBcan177/minerchk/master/ip-only.txt)
- [BBcan177 - pfBlockerNG Malicious Threats](https://gist.githubusercontent.com/BBcan177/d7105c242f17f4498f81/raw)
- [binarydefense - Artillery Threat Intelligence Feed and Banlist Feed](https://www.binarydefense.com/banlist.txt)
- [blocklist.de - export-ips_all](https://www.blocklist.de/downloads/export-ips_all.txt)
- [blocklist.de - IPs all](https://lists.blocklist.de/lists/all.txt)
- [Cinsscore - badguys](http://cinsscore.com/list/ci-badguys.txt)
- [CriticalPathSecurity - Public-Intelligence-Feeds](https://github.com/CriticalPathSecurity/Public-Intelligence-Feeds/)
- [dan.me.uk - TOR Node List](https://www.dan.me.uk/torlist/?exit)
- [darklist - raw](https://www.darklist.de/raw.php)
- [dshield.org - block](https://feeds.dshield.org/block.txt)
- [duggytuxy - Intelligence_IPv4_Blocklist](https://github.com/duggytuxy/Intelligence_IPv4_Blocklist/blob/main/agressive_ips_dst_fr_be_blocklist.txt)
- [ellio.tech - Threat List](https://cdn.ellio.tech/community-feed)
- [Emerging Threats - compromised ips](http://rules.emergingthreats.net/blockrules/compromised-ips.txt)
- [Emerging Threats Block](http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt)
- [Firehold - Forus Spam](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset)
- [Firehold - level1](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset)
- [Greensnow - blocklist](http://blocklist.greensnow.co/greensnow.txt)
- [IPDeny - ipblocks](http://www.ipdeny.com/ipblocks/)
- [Myip - full BL](https://myip.ms/files/blacklist/general/full_blacklist_database.zip)
- [MyIP - latest BL](https://myip.ms/files/blacklist/general/latest_blacklist.txt)
- [Nick Galbreath client9 - datacenters](https://raw.githubusercontent.com/client9/ipcat/master/datacenters.csv)
- [OpenBL - base](http://www.openbl.org/lists/base.txt)
- [opsxcq - proxy-list](https://raw.githubusercontent.com/opsxcq/proxy-list/master/list.txt)
- [Project Honeypot - list_of_ips](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)
- [romainmarcoux - malicious-ip](https://github.com/romainmarcoux/malicious-ip/blob/main/full-aa.txt)
- [Rulez - BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)
- [rulez.sk - bruteforceblocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)
- [SecOps-Institute - TOR Exit Node List](https://raw.githubusercontent.com/SecOps-Institute/Tor-IP-Addresses/master/tor-exit-nodes.lst)
- [Spamhaus - drop-lasso](https://www.spamhaus.org/drop/drop.lasso)
- [stamparm - ipsum](https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt)
- [StopForumSpam - 180](https://www.stopforumspam.com/downloads/listed_ip_180_all.zip)
- [StopForumSpam - Toxic CIDR](https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt)
- [torproject - TOR BulkExitList](https://check.torproject.org/torbulkexitlist?ip=1.1.1.1)
- [Uceprotect - backscatterer Level 1](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz)
- [Uceprotect - backscatterer Level 2](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz)
- [Uceprotect - backscatterer Level 3](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz)
- [Ultimate Hosts IPs Blocklist - ips](https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/tree/master/ips)
- [yoyo - adservers](https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0)

#### Inactive, Offline, Discontinued or Private

- [abuse.ch - Ransomwaretracker](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)
- [Malc0de - IP Blocklist](http://malc0de.com/bl/IP_Blacklist.txt)
- [Malwaredomain - IP List](https://www.malwaredomainlist.com/hostslist/ip.txt)
- [Maxmind - high-risk-ip-sample-list](https://www.maxmind.com/en/high-risk-ip-sample-list)
- [unsubscore - blacklist](http://www.unsubscore.com/blacklist.txt)

### DEBUG LISTS

- [Allow IP/CIDR extra](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [Allow IPs](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [Allow URLs](https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/allowurls.txt)
- [Amazon AWS](https://ip-ranges.amazonaws.com/ip-ranges.json)
- [Block IP/CIDR Extra](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [DNS](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [IANA](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [Microsoft Azure Datacenter](https://www.microsoft.com/en-us/download/details.aspx?id=41653)

### WORKTOOLS

- [cidr2ip](https://github.com/maravento/blackip/tree/master/bipupdate/tools)
- [Debug IPs](https://github.com/maravento/blackip/tree/master/bipupdate/tools)

## NOTICE

---

- This project includes third-party components.
- Changes must be submitted via Issues. Pull requests are not accepted.
- Blackip is not a blacklist service itself. It does not independently verify IPs addresses. Its purpose is to consolidate and reformat public blacklist sources to make them compatible with Squid/Iptables/Ipset.
- If your IP address is listed on Blackip and you believe this is an error, you should check the public sources [SOURCES](https://github.com/maravento/blackip/blob/master/README-es.md#sources), identify which one(s) it appears in, and contact the person responsible for that list to request its removal. Once the IP address is removed from the original source, it will automatically disappear from Blackip with the next update.

## STARGAZERS

---

[![Stargazers](https://bytecrank.com/nastyox/reporoster/php/stargazersSVG.php?user=maravento&repo=blackip)](https://github.com/maravento/blackip/stargazers)

## CONTRIBUTIONS

---

We thank all those who contributed to this project. Those interested may contribute sending us new "Blocklist" links to be included in this project.

Special thanks to: [Jhonatan Sneider](https://github.com/sney2002)

## SPONSOR THIS PROJECT

---

[![Image](https://raw.githubusercontent.com/maravento/winexternal/master/img/maravento-paypal.png)](https://paypal.me/maravento)

## PROJECT LICENSES

---

[![GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)
[![CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.en)

## DISCLAIMER

---

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## OBJECTION

---

Due to recent arbitrary changes in computer terminology, it is necessary to clarify the meaning and connotation of the term **blacklist**, associated with this project:

*In computing, a blacklist, denylist or blocklist is a basic access control mechanism that allows through all elements (email addresses, users, passwords, URLs, IP addresses, domain names, file hashes, etc.), except those explicitly mentioned. Those items on the list are denied access. The opposite is a whitelist, which means only items on the list are let through whatever gate is being used.* Source [Wikipedia](https://en.wikipedia.org/wiki/Blacklist_(computing))

Therefore, **blacklist**, **blocklist**, **blackweb**, **blackip**, **whitelist** and similar, are terms that have nothing to do with racial discrimination.
