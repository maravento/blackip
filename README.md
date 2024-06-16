# [BlackIP](https://www.maravento.com/p/blackip.html)

[![status-stable](https://img.shields.io/badge/status-stable-green.svg)](https://github.com/maravento/blackip)
[![last commit](https://img.shields.io/github/last-commit/maravento/blackip)](https://github.com/maravento/blackip)
[![Twitter Follow](https://img.shields.io/twitter/follow/maraventostudio.svg?style=social)](https://twitter.com/maraventostudio)

BlackIP is a project that collects and unifies public blocklists of IP addresses, to make them compatible with [Squid](http://www.squid-cache.org/) and [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))

BlackIP es un proyecto que recopila y unifica listas públicas de bloqueo de direcciones IPs, para hacerlas compatibles con [Squid](http://www.squid-cache.org/) e [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))

## DATA SHEET

---

|ACL|Blocked IP|File Size|
| :---: | :---: | :---: |
|blackip.txt|472773|6.6 Mb|

## GIT CLONE

---

```bash
git clone --depth=1 https://github.com/maravento/blackip.git
```

## HOW TO USE

---

`blackip.txt` is already optimized. Download it and unzip it in the path of your preference / `blackip.txt` ya viene optimizada. Descárguela y descomprimala en la ruta de su preferencia

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

- Should not be used `blackip.txt` in [IPSET](http://ipset.netfilter.org/) and in [Squid](http://www.squid-cache.org/) at the same time (double filtrate) / No debe utilizar `blackip.txt` en [IPSET](http://ipset.netfilter.org/) y en [Squid](http://www.squid-cache.org/) al mismo tiempo (doble filtrado)
- `blackip.txt` is a list IPv4. Does not include CIDR / `blackip.txt` es una lista IPv4. No incluye CIDR

### [Ipset/Iptables](http://ipset.netfilter.org/) Rules

Edit your Iptables bash script and add the following lines (run with root privileges): / Edite su bash script de Iptables y agregue las siguientes líneas (ejecutar con privilegios root):

```bash
#!/bin/bash
# https://linux.die.net/man/8/ipset
# variables
ipset=/sbin/ipset
iptables=/sbin/iptables

# Replace with your path to blackip.txt
ips=/path_to_lst/blackip.txt

# ipset rules
$ipset -L blackip >/dev/null 2>&1
if [ $? -ne 0 ]; then
        echo "set blackip does not exist. create set..."
        $ipset -! create blackip hash:net family inet hashsize 1024 maxelem 10000000
    else
        echo "set blackip exist. flush set..."
        $ipset -! flush blackip
fi
$ipset -! save > /tmp/ipset_blackip.txt
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
$ipset -! restore < /tmp/ipset_blackip.txt

# iptables rules
$iptables -t mangle -I PREROUTING -m set --match-set blackip src,dst -j DROP
$iptables -I INPUT -m set --match-set blackip src,dst -j DROP
$iptables -I FORWARD -m set --match-set blackip src,dst -j DROP
echo "done"
```

#### Ipset/Iptables Rules with IPDeny (Optional)

You can add the following lines to the bash above to include full country IP ranges with [IPDeny](https://www.ipdeny.com/ipblocks/) adding the countries of your choice. / Puede agregar las siguientes líneas al bash anterior para incluir rangos de IPs completos de países con [IPDeny](https://www.ipdeny.com/ipblocks/) agregando los países de su elección.

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

- Ipset allows mass filtering, at a much higher processing speed than other solutions (check [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). / Ipset permite realizar filtrado masivo, a una velocidad de procesamiento muy superior a otras soluciones (consulte [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).
- Blackip is a list containing millions of IPv4 lines and to be supported by Ipset, we had to arbitrarily increase the parameter [maxelem](https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is) (for more information, check [ipset's hashsize and maxelem parameters](https://www.odi.ch/weblog/posting.php?posting=738)). / Blackip es una lista que contiene millones de líneas IPv4 y para ser soportada por Ipset, hemos tenido que aumentar arbitrariamente el parámetro [maxelem](https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is) (para más información, consulte [ipset's hashsize and maxelem parameters](https://www.odi.ch/weblog/posting.php?posting=738)).
- Ipset/iptables limitation: "*When entries added by the SET target of iptables/ip6tables, then the hash size is fixed and the set won't be duplicated, even if the new entry cannot be added to the set*" (for more information, check [Man Ipset](https://ipset.netfilter.org/ipset.man.html)) / Limitación de Ipset/iptables: "*Cuando las entradas agregadas por el objetivo SET de iptables/ip6tables, el tamaño del hash es fijo y el conjunto no se duplicará, incluso si la nueva entrada no se puede agregar al conjunto*" (para más información, consulte [Man Ipset](https://ipset.netfilter.org/ipset.man.html)).
- Heavy use of these rules can slow down your PC to the point of crashing. Use them at your own risk. / El uso intensivo de estas reglas puede ralentizar su PC al punto de hacerlo colapsa. Úselas bajo su propio riesgo.
- tested on: / probado en: iptables v1.8.7, ipset v7.15, protocol version: 7

### [Squid](http://www.squid-cache.org/) Rule

Edit:

```bash
/etc/squid/squid.conf
```

And add the following lines: / Y agregue las siguientes líneas:

```bash
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS

# Block Rule for BlackIP
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip
```

#### About Squid Rule

- `blackip.txt` has been tested in Squid v3.5.x and later / `blackip.txt` ha sido testeada en Squid v3.5.x y posteriores

#### Advanced Rules

BlackIP contains millions of IP addresses, therefore it is recommended: / BlackIP contiene millones de direcciones IP, por tanto se recomienda:

- Use `blackcidr.txt` to add IP/CIDR that are not included in `blackip.txt` (By default it contains some Block CIDR) / Use `blackcidr.txt` para agregar IP/CIDR que no están incluidas en `blackip.txt` (Por defecto contiene algunos Block CIDR)
- Use `allowip.txt` (a whitelist of IPv4 IP addresses such as Hotmail, Gmail, Yahoo. etc.) / Use `allowip.txt` (una lista blanca de direcciones IPs IPv4 tales como Hotmail, Gmail, Yahoo. etc)
- Use `aipextra.txt` to add whitelists of IP/CIDRs that are not included in `allowip.txt` / Use `aipextra.txt` para agregar listas blancas de IP/CIDR que no están incluidas en `allowip.txt`
- By default, `blackip.txt` excludes some private or reserved ranges [RFC1918](https://en.wikipedia.org/wiki/Private_network). Use IANA (`iana.txt`) to exclude them all / Por defecto, `blackip.txt` excluye algunos rangos privados o reservados [RFC1918](https://es.wikipedia.org/wiki/Red_privada). Use IANA (`iana.txt`) para excluirlos todos
- By default, `blackip.txt` excludes some DNS servers included in `dns.txt`. You can use this list and expand it to deny or allow DNS servers / Por defecto, `blackip.txt` excluye algunos servidores DNS incluidos en `dns.txt`. Puede usar esta lista y ampliarla, para denegar o permitir servidores DNS
- To increase security, close Squid to any other request to IP addresses with ZTR / Para incrementar la seguridad, cierre Squid a cualquier otra petición a direcciones IP con ZTR

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

## Zero Trust Rule (ZTR)
acl no_ip url_regex -i [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
http_access deny no_ip
```

## BLACKIP UPDATE

---

### ⚠️ WARNING: BEFORE YOU CONTINUE

This section is only to explain how update and optimization process works. It is not necessary for user to run it. This process can take time and consume a lot of hardware and bandwidth resources, therefore it is recommended to use test equipment / Esta sección es únicamente para explicar cómo funciona el proceso de actualización y optimización. No es necesario que el usuario la ejecute. Este proceso puede tardar y consumir muchos recursos de hardware y ancho de banda, por tanto se recomienda usar equipos de pruebas

| Bash Update |
| ----------- |

>The update process of `blackip.txt` is executed in sequence by the script `bipupdate.sh`. The script will request privileges when required. / El proceso de actualización de `blackip.txt` es ejecutado en secuencia por el script `bipupdate.sh`. El script solicitará privilegios cuando lo requiera.

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && chmod +x bipupdate.sh && ./bipupdate.sh
```

| Dependencies |
| ------------ |

>Update requires python 3x and bash 5x / La actualización requiere python 3x y bash 5x

```bash
pkgs='wget git curl idn2 perl tar rar unrar unzip zip python-is-python3 squid ipset'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  apt -y install $pkgs
fi
```

| Capture Public Blocklists |
| ------------------------- |

>Capture IPv4 from downloaded public blocklists (see [SOURCES](https://github.com/maravento/blackip#sources)) and unifies them in a single file / Captura las IPv4 de las listas de bloqueo públicas descargadas (ver [FUENTES](https://github.com/maravento/blackip#sources)) y las unifica en un solo archivo

| DNS Loockup |
| ------------|

>Most of the [SOURCES](https://github.com/maravento/blackip#sources) contain millions of invalid and nonexistent IP. Then, a double check of each IP is done (in 2 steps) via DNS and invalid and nonexistent are excluded from Blackip. This process may take. By default it processes in parallel ≈ 6k to 12k x min, depending on the hardware and bandwidth / La mayoría de las [FUENTES](https://github.com/maravento/blackip#sources) contienen millones de IP inválidas e inexistentes. Entonces se hace una verificación doble de cada IP (en 2 pasos) vía DNS y los inválidos e inexistentes se excluyen de Blackip. Este proceso puede tardar. Por defecto procesa en paralelo ≈ 6k a 12k x min, en dependencia del hardware y ancho de banda

```bash
HIT 8.8.8.8
Host 8.8.8.8.in-addr.arpa domain name pointer dns.google
FAULT 0.0.9.1
Host 1.9.0.0.in-addr.arpa. not found: 3(NXDOMAIN)
```

| Run Squid-Cache with BlackIP |
| ----------------------------- |

>Run Squid-Cache with BlackIP and any error sends it to `SquidError.txt` on your desktop / Corre Squid-Cache con BlackIP y cualquier error lo envía a `SquidError.txt` en su escritorio

| Check execution (/var/log/syslog) |
| --------------------------------- |

```bash
BlackIP: Done 02/02/2024 15:47:14
```

#### Important about BlackIP Update

- `tw.txt` containing IPs of teamviewer servers. By default they are commented. To block or authorize them, activate them in `bipupdate.sh`. To update it use `tw.sh` / `tw.txt` contiene IPs de servidores teamviewer. Por defecto están comentadas. Para bloquearlas o autorizarlas activelas en `bipupdate.sh`. Para actualizarla use `tw.sh`
- You must activate the rules in [Squid](http://www.squid-cache.org/) before using `bipupdate.sh` / Antes de utilizar `bipupdate.sh` debe activar las reglas en [Squid](http://www.squid-cache.org/)
- Some lists have download restrictions, so do not run `bipupdate.sh` more than once a day / Algunas listas tienen restricciones de descarga, entonces no ejecute `bipupdate.sh` más de una vez al día
- During the execution of `bipupdate.sh` it will request privileges when needed / Durante la ejecución de `bipupdate.sh` solicitará privilegios cuando los necesite

#### AllowIP Update

>`allowip.txt` is already updated and optimized. The update process of `allowip.txt` is executed in sequence by the script `aipupdate.sh` / `allowip.txt` ya esta actualizada y optimizada. El proceso de actualización de `allowip.txt` es ejecutado en secuencia por el script `aipupdate.sh`

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

## STARGAZERS

---

[![Stargazers](https://bytecrank.com/nastyox/reporoster/php/stargazersSVG.php?user=maravento&repo=blackip)](https://github.com/maravento/blackip/stargazers)

## CONTRIBUTIONS

---

We thank all those who contributed to this project. Those interested may contribute sending us new "Blocklist" links to be included in this project / Agradecemos a todos aquellos que han contribuido a este proyecto. Los interesados pueden contribuir, enviándonos enlaces de nuevas "Blocklist", para ser incluidas en este proyecto

Special thanks to: [Jhonatan Sneider](https://github.com/sney2002)

## SPONSOR THIS PROJECT

---

[![Image](https://raw.githubusercontent.com/maravento/winexternal/master/img/maravento-paypal.png)](https://paypal.me/maravento)

## LICENSES

---

[![GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)
[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

## DISCLAIMER

---

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## OBJECTION

---

Due to recent arbitrary changes in computer terminology, it is necessary to clarify the meaning and connotation of the term **blacklist**, associated with this project: *In computing, a blacklist, denylist or blocklist is a basic access control mechanism that allows through all elements (email addresses, users, passwords, URLs, IP addresses, domain names, file hashes, etc.), except those explicitly mentioned. Those items on the list are denied access. The opposite is a whitelist, which means only items on the list are let through whatever gate is being used.*

Debido a los recientes cambios arbitrarios en la terminología informática, es necesario aclarar el significado y connotación del término **blacklist**, asociado a este proyecto: *En informática, una lista negra, lista de denegación o lista de bloqueo es un mecanismo básico de control de acceso que permite a través de todos los elementos (direcciones de correo electrónico, usuarios, contraseñas, URL, direcciones IP, nombres de dominio, hashes de archivos, etc.), excepto los mencionados explícitamente. Esos elementos en la lista tienen acceso denegado. Lo opuesto es una lista blanca, lo que significa que solo los elementos de la lista pueden pasar por cualquier puerta que se esté utilizando.*

Source [Wikipedia](https://en.wikipedia.org/wiki/Blacklist_(computing))

Therefore / Por tanto

**blacklist**, **blocklist**, **blackweb**, **blackip**, **whitelist**, **etc.**

are terms that have nothing to do with racial discrimination / son términos que no tienen ninguna relación con la discriminación racial.
