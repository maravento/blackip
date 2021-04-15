# [BlackIP](https://www.maravento.com/p/blackip.html)

**BlackIP** is a project that collects and unifies public blocklists of IP addresses, to make them compatible with [Squid](http://www.squid-cache.org/) and [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))

**BlackIP** es un proyecto que recopila y unifica listas públicas de bloqueo de direcciones IPs, para hacerlas compatibles con [Squid](http://www.squid-cache.org/) e [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))


## DATA SHEET

---

|ACL|Blocked IP|File Size|
| :---: | :---: | :---: |
|blackip.txt|3152478|45.1 Mb|

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

### Checksum

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/checksum.md5
md5sum blackip.txt | awk '{print $1}' && cat checksum.md5 | awk '{print $1}'
```

### IPSET-SQUID RULES


#### [IPSET](http://ipset.netfilter.org/) Rules

This module allows us to perform mass filtering, at a processing speed far superior to other Solutions (See the [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). It includes geographical areas with [IPDeny](http://www.ipdeny.com/ipblocks/)) / Este módulo nos permite realizar filtrado masivo, a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). Se incluye zonas geográficas con [IPDeny](http://www.ipdeny.com/ipblocks/))

Donwload Zones / Descarga de Zonas

```zone=/path_to_folder/zones
if [ ! -d $zone ]; then mkdir -p $zone; fi
wget -q -N http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1
rm -f all-zones.tar.gz >/dev/null 2>&1
```

Edit your Iptables script and add the following lines: / Edite su script de Iptables y agregue las siguientes líneas:

```bash
# IPSET BLOCKZONE (select country to block and ip/range) ###
# http://www.ipdeny.com/ipblocks/
ipset=/sbin/ipset
iptables=/sbin/iptables
route=/path_to_blackip/
zone=/path_to_folder/zones
if [ ! -d $zone ]; then mkdir -p $zone; fi

$ipset -F
$ipset -N -! blockzone hash:net maxelem 1000000
# Uncomment this line if you want to block entire countries
#for ip in $(cat $zone/{cn,ru}.zone $route/blackip.txt); do
# Uncomment this line if you want to block only ips (recommended)
for ip in $(cat $route/blackip.txt); do
    $ipset -A blockzone $ip
done
$iptables -t mangle -A PREROUTING -m set --match-set blockzone src -j NFLOG --nflog-prefix 'Blockzone'
$iptables -t mangle -A PREROUTING -m set --match-set blockzone src -j DROP
$iptables -A FORWARD -m set --match-set blockzone dst -j NFLOG --nflog-prefix 'Blockzone'
$iptables -A FORWARD -m set --match-set blockzone dst -j DROP
```

You can block entire countries ranges (e.g. China, Rusia, etc) with [IPDeny](http://www.ipdeny.com/ipblocks/) adding the countries to the line: / Puede incluir rangos completos de países (e.g. China, Rusia, etc) con [IPDeny](http://www.ipdeny.com/ipblocks/) agregando los países a la línea:

```bash
for ip in $(cat $zone/{cn,ru}.zone $route/blackip.txt); do
```

In case of error or conflict, execute: / En caso de error o conflicto, ejecute:

```bash
ipset flush blockzone # (or: ipset flush)
```

NFLOG: /var/log/ulog/syslogemu.log

```bash
chown root:root /var/log
apt -y install ulogd2
if [ ! -d /var/log/ulog/syslogemu.log ]; then mkdir -p /var/log/ulog && touch /var/log/ulog/syslogemu.log; fi
usermod -a -G ulog $USER
```

#### [Squid](http://www.squid-cache.org/) Rule

Edit:

```bash
/etc/squid/squid.conf
```

And add the following lines: / Y agregue las siguientes líneas:

```bash
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip
```

##### Important about BlackIP

- Should not be used `blackip.txt` in [IPSET](http://ipset.netfilter.org/) and in [Squid](http://www.squid-cache.org/) at the same time (double filtrate) / No debe utilizar `blackip.txt` en [IPSET](http://ipset.netfilter.org/) y en [Squid](http://www.squid-cache.org/) al mismo tiempo (doble filtrado)
- `blackip.txt` is a list IPv4. Does not include CIDR / `blackip.txt` es una lista IPv4. No incluye CIDR
- `blackip.txt` has been tested in Squid v3.5.x / `blackip.txt` ha sido testeada en Squid v3.5.x

##### [Squid-Cache](http://www.squid-cache.org/) Advanced Rules

**blackip** contains millions of IP addresses, therefore it is recommended: / **blackip** contiene millones de direcciones IP, por tanto se recomienda:

- Use `bipextra.txt` to add IP/CIDR that are not included in `blackip.txt` (By default it contains some Block CIDR) / Use `bipextra.txt` para agregar IP/CIDR que no están incluidas en `blackip.txt` (Por defecto contiene algunos Block CIDR)
- Use `allowip.txt` (a allow list of IPv4 IP addresses like a Hotmail, Gmail, Yahoo. Etc) / Use `allowip.txt` (una lista blanca de direcciones IPs IPv4 tales como Hotmail, Gmail, Yahoo. etc)
- Use `aipextra.txt` to add allowlists of IP/CIDRs that are not included in `allowip.txt` / Use `aipextra.txt` para agregar listas blancas de IP/CIDR que no están incluidas en `allowip.txt`
- By default `blackip.txt` does not exclude private or reserved ranges [RFC1918](https://en.wikipedia.org/wiki/Private_network). Use IANA (`iana.txt`) to exclude these ranges / Por defecto blackip.txt no excluye rangos privados o reservados [RFC1918](https://es.wikipedia.org/wiki/Red_privada). Use IANA (`iana.txt`) para excluir estos rangos
- To increase security, close Squid to any other request to IP addresses / Para incrementar la seguridad, cierre Squid a cualquier otra petición a direcciones IP

```bash
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
# Allow IP/CIDR list (not included in allowip) (Optional)
acl aipextra dst "/path_to/aipextra.txt"
http_access allow aipextra
# Allow IP list (Optional)
acl allowip dst "/path_to/allowip.txt"
http_access allow allowip
# IANA list (not included in allowip) (Optional)
acl iana dst "/path_to/iana.txt"
http_access allow iana
# Block IP/CIDR list (not included in blackip)
acl bipextra dst "/path_to/bipextra.txt"
http_access deny bipextra
# Blackip list
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip
# deny all IPs
acl no_ip url_regex -i [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
http_access deny no_ip
```

## UPDATE

---

### ⚠️ WARNING: BEFORE YOU CONTINUE

This section is only to explain how update and optimization process works. It is not necessary for user to run it. This process can take time and consume a lot of hardware and bandwidth resources, therefore it is recommended to use test equipment / Esta sección es únicamente para explicar cómo funciona el proceso de actualización y optimización. No es necesario que el usuario la ejecute. Este proceso puede tardar y consumir muchos recursos de hardware y ancho de banda, por tanto se recomienda usar equipos de pruebas

#### Blackip Update

>The update process of `blackip.txt` is executed in sequence by the script `bipupdate.sh` / El proceso de actualización de `blackip.txt` es ejecutado en secuencia por el script `bipupdate.sh`

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && chmod +x bipupdate.sh && ./bipupdate.sh
```

##### Dependencies

```bash
wget git subversion curl libnotify-bin idn2 perl tar rar unrar gzip unzip zip python squid ipset ulogd2 iptables
```

##### Important about BLackip Update

- `tw.txt` containing IPs of teamviewer servers. By default they are commented. To block or authorize them, activate them in `bipupdate.sh`. To update it use `tw.sh` / `tw.txt` contiene IPs de servidores teamviewer. Por defecto están comentadas. Para bloquearlas o autorizarlas activelas en `bipupdate.sh`. Para actualizarla use `tw.sh`
- You must activate the rules in [Squid](http://www.squid-cache.org/) before using `bipupdate.sh` / Antes de utilizar `bipupdate.sh` debe activar las reglas en [Squid](http://www.squid-cache.org/)

##### Check execution (/var/log/syslog):

```bash
BLackip: Done 06/05/2019 15:47:14
```

#### AllowIP Update

>`allowip.txt` is already updated and optimized. The update process of `allowip.txt` is executed in sequence by the script `aipupdate.sh` / `allowip.txt` ya esta actualizada y optimizada. El proceso de actualización de `allowip.txt` es ejecutado en secuencia por el script `aipupdate.sh`

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/aipupdate.sh && chmod +x aipupdate.sh && ./aipupdate.sh
```

## SOURCES

---

### Blacklists

#### Actives Blocklists IP

- [Abuse.ch Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)
- [adservers yoyo](https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0)
- [BL Myip](https://myip.ms/files/blacklist/general/full_blacklist_database.zip)
- [Blocklist Export](https://www.blocklist.de/downloads/export-ips_all.txt)
- [Blocklist](https://lists.blocklist.de/lists/all.txt)
- [Cinsscore](http://cinsscore.com/list/ci-badguys.txt)
- [Emerging Threats Block](http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt)
- [Emerging Threats compromised](http://rules.emergingthreats.net/blockrules/compromised-ips.txt)
- [Firehold Forus Spam](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset)
- [Firehold](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset)
- [Greensnow](http://blocklist.greensnow.co/greensnow.txt)
- [IPDeny](http://www.ipdeny.com/ipblocks/)
- [Malc0de IP Blocklist](http://malc0de.com/bl/IP_Blacklist.txt)
- [Malwaredomain IP List](https://www.malwaredomainlist.com/hostslist/ip.txt)
- [Maxmind](https://www.maxmind.com/en/high-risk-ip-sample-list)
- [MyIP BL](https://myip.ms/files/blacklist/general/latest_blacklist.txt)
- [Open BL](http://www.openbl.org/lists/base.txt)
- [opsxcq proxy-list](https://raw.githubusercontent.com/opsxcq/proxy-list/master/list.txt)
- [Project Honeypot](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)
- [Ransomwaretracker](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)
- [Rulez BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)
- [Spamhaus](https://www.spamhaus.org/drop/drop.lasso)
- [StopForumSpam 180](https://www.stopforumspam.com/downloads/listed_ip_180_all.zip)
- [StopForumSpam Toxic CIDR](https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt)
- [TOR BulkExitList](https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=1.1.1.1)
- [TOR Node List](https://www.dan.me.uk/torlist/?exit)
- [UCEPROTECT IP Blocklists / BACKSCATTERER.ORG Blocklist](http://wget-mirrors.uceprotect.net/) (includes: [Level 1](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz), [Level 2](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz), [Level3](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz))
- [Ultimate Hosts IPs Blocklist](https://github.com/mitchellkrogza/Ultimate.Hosts.Blacklist). [Mirror](https://hosts.ubuntu101.co.za/ips.list)
- [Zeustracker](https://zeustracker.abuse.ch/blocklist.php?download=badips)

#### Inactive Blocklists IP (Added to: `oldips.txt`)

- [OpenBL](https://www.openbl.org/lists/base.txt)
- [The LashBack UBL](http://www.unsubscore.com/blacklist.txt)

### Whitelists

#### Actives Allowlists IP

- [Amazon AWS](https://ip-ranges.amazonaws.com/ip-ranges.json) (Excluded for containing CIDR)
- [Microsoft Azure Datacenter](https://www.microsoft.com/en-us/download/details.aspx?id=41653) (Excluded for containing CIDR)

##### Inactives Allowlists IP

- [O365IPAddresses](https://support.content.office.net/en-us/static/O365IPAddresses.xml) (No longer support. [See This post](ocs.microsoft.com/es-es/office365/enterprise/urls-and-ip-address-ranges?redirectSourcePath=%252fen-us%252farticle%252fOffice-365-URLs-and-IP-address-ranges-8548a211-3fe7-47cb-abb1-355ea5aa88a2))

### Internal Worklists

- [Allow IP/CIDR extra](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/aipextra.txt)
- [Allow IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/allowip.txt)
- [Block IP/CIDR Extra](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/blst/bipextra.txt)
- [IANA](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/iana.txt)
- [Old IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/blst/oldips.txt)
- [Teamviewer IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/tw.txt)

### External Worklists

- [Allow URLs](https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/allowurls.txt)

### Worktools

- [cidr2ip](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/tools/cidr2ip.py)
- [Debug IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/tools/debugbip.py)
- [Teamviewer Capture](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/tw.sh)


## CONTRIBUTIONS

---

We thank all those who contributed to this project. Those interested may contribute sending us new "Blocklist" links to be included in this project / Agradecemos a todos aquellos que han contribuido a este proyecto. Los interesados pueden contribuir, enviándonos enlaces de nuevas "Blocklist", para ser incluidas en este proyecto

Special thanks to: [Jhonatan Sneider](https://github.com/sney2002)

## DONATE

---

BTC: 3M84UKpz8AwwPADiYGQjT9spPKCvbqm4Bc

## LICENCES

---

[![GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)

[![CreativeCommons](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
[maravento.com](https://www.maravento.com) is licensed under a [Creative Commons Reconocimiento-CompartirIgual 4.0 Internacional License](http://creativecommons.org/licenses/by-sa/4.0/).

© 2021 [Maravento Studio](https://www.maravento.com)

## OBJECTION

---

Due to recent arbitrary changes in computer terminology, it is necessary to clarify the meaning and connotation of the term **blacklist**, associated with this project: *In computing, a blacklist, denylist or blocklist is a basic access control mechanism that allows through all elements (email addresses, users, passwords, URLs, IP addresses, domain names, file hashes, etc.), except those explicitly mentioned. Those items on the list are denied access. The opposite is a whitelist, which means only items on the list are let through whatever gate is being used.*

Debido a los recientes cambios arbitrarios en la terminología informática, es necesario aclarar el significado y connotación del término **blacklist**, asociado a este proyecto: *En informática, una lista negra, lista de denegación o lista de bloqueo es un mecanismo básico de control de acceso que permite a través de todos los elementos (direcciones de correo electrónico, usuarios, contraseñas, URL, direcciones IP, nombres de dominio, hashes de archivos, etc.), excepto los mencionados explícitamente. Esos elementos en la lista tienen acceso denegado. Lo opuesto es una lista blanca, lo que significa que solo los elementos de la lista pueden pasar por cualquier puerta que se esté utilizando.*

Source [Wikipedia](https://en.wikipedia.org/wiki/Blacklist_(computing))

Therefore / Por tanto

**blacklist**, **blocklist**, **blackweb**, **blackip**, **whitelist**, **etc.**

are terms that have nothing to do with racial discrimination / son términos que no tienen ninguna relación con la discriminación racial

## DISCLAIMER

---

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
