# [BlackIP](https://www.maravento.com/p/blackip.html)

[![GPL v3+](https://img.shields.io/badge/License-GPL%20v3%2B-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![last commit](https://img.shields.io/github/last-commit/maravento/blackip)](https://github.com/maravento/blackip/)
[![Twitter Follow](https://img.shields.io/twitter/follow/maraventostudio.svg?style=social)](https://twitter.com/maraventostudio)

**BlackIP** is a project that collects and unifies public blocklists of IP addresses, to make them compatible with [Squid](http://www.squid-cache.org/) and [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))

**BlackIP** es un proyecto que recopila y unifica listas públicas de bloqueo de direcciones IPs, para hacerlas compatibles con [Squid](http://www.squid-cache.org/) e [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))


## DATA SHEET

---

|ACL|Blocked IP|File Size|
| :---: | :---: | :---: |
|blackip.txt|3162915|45,2 Mb|


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

### [Ipset/Iptables](http://ipset.netfilter.org/) Rules

Edit your Iptables bash script and add the following lines (run with root privileges): / Edite su bash script de Iptables y agregue las siguientes líneas (ejecutar con privilegios root):

```bash
#!/bin/bash
# variables
ipset=/sbin/ipset
iptables=/sbin/iptables
# Replace with your path to blackip.txt
ips=/path_to_lst/blackip.txt

$ipset flush -! blackip
$ipset create -! blackip hash:net maxelem 10000000
rm -f /tmp/*.txt &> /dev/null
$ipset save > /tmp/ipset_blackip.txt
cat $ips | while read line; do
    echo "add blackip $line" >> /tmp/ipset_blackip.txt
done
$ipset restore -! < /tmp/ipset_blackip.txt

$iptables -t mangle -I PREROUTING -m set --match-set blackip src,dst -j DROP
$iptables -I INPUT -m set --match-set blackip src,dst -j DROP
$iptables -I FORWARD -m set --match-set blackip src,dst -j DROP
```

#### Optional: Ipset/Iptables IPDeny Rules

You can add the following lines to the bash above to include full country IP ranges with [IPDeny](https://www.ipdeny.com/ipblocks/) adding the countries of your choice. / Puede agregar las siguientes líneas al bash anterior para incluir rangos de IPs completos de países con [IPDeny](https://www.ipdeny.com/ipblocks/) agregando los países de su elección.

```bash
# Put these lines at the end of the "variables" section
# Replace with your path to zones folder
zone=/path_to_folder/zones
if [ ! -d $zone ]; then mkdir -p $zone; fi
wget -q -N http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1
rm -f all-zones.tar.gz >/dev/null 2>&1

# replace the line:
cat $ips | while read line; do
# with (e.g: Russia and China):
cat $zone/{cn,ru}.zone $ips | while read line; do
```

#### Important about Ipset/Iptables Rules

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
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip
```

#### Important about BlackIP

- Should not be used `blackip.txt` in [IPSET](http://ipset.netfilter.org/) and in [Squid](http://www.squid-cache.org/) at the same time (double filtrate) / No debe utilizar `blackip.txt` en [IPSET](http://ipset.netfilter.org/) y en [Squid](http://www.squid-cache.org/) al mismo tiempo (doble filtrado)
- `blackip.txt` is a list IPv4. Does not include CIDR / `blackip.txt` es una lista IPv4. No incluye CIDR
- `blackip.txt` has been tested in Squid v3.5.x and later / `blackip.txt` ha sido testeada en Squid v3.5.x y posteriores

#### Optional: [Squid-Cache](http://www.squid-cache.org/) Advanced Rules

**blackip** contains millions of IP addresses, therefore it is recommended: / **blackip** contiene millones de direcciones IP, por tanto se recomienda:

- Use `bipextra.txt` to add IP/CIDR that are not included in `blackip.txt` (By default it contains some Block CIDR) / Use `bipextra.txt` para agregar IP/CIDR que no están incluidas en `blackip.txt` (Por defecto contiene algunos Block CIDR)
- Use `allowip.txt` (a whitelist of IPv4 IP addresses such as Hotmail, Gmail, Yahoo. etc.) / Use `allowip.txt` (una lista blanca de direcciones IPs IPv4 tales como Hotmail, Gmail, Yahoo. etc)
- Use `aipextra.txt` to add whitelists of IP/CIDRs that are not included in `allowip.txt` / Use `aipextra.txt` para agregar listas blancas de IP/CIDR que no están incluidas en `allowip.txt`
- By default `blackip.txt` does not exclude private or reserved ranges [RFC1918](https://en.wikipedia.org/wiki/Private_network). Use IANA (`iana.txt`) to exclude these ranges / Por defecto blackip.txt no excluye rangos privados o reservados [RFC1918](https://es.wikipedia.org/wiki/Red_privada). Use IANA (`iana.txt`) para excluir estos rangos
- To increase security, close Squid to any other request to IP addresses / Para incrementar la seguridad, cierre Squid a cualquier otra petición a direcciones IP

```bash
### INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS ###

## ALLOW IP/CIDR ##
# Allow IP list (Optional)
acl allowip dst "/path_to/allowip.txt"
http_access allow allowip
# Allow IP/CIDR list (not included in allowip) (Optional)
acl aipextra dst "/path_to/aipextra.txt"
http_access allow aipextra
# IANA list (not included in allowip) (Optional)
acl iana dst "/path_to/iana.txt"
http_access allow iana

## BLOCK IP/CIDR ##
# Block IP/CIDR list (not included in blackip) (Optional)
acl bipextra dst "/path_to/bipextra.txt"
http_access deny bipextra
# Blackip
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip

## DENY ALL IP ##
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

>Update requires python 3x and bash 5x / La actualización requiere python 3x y bash 5x

```bash
pkgs='wget git subversion curl libnotify-bin idn2 perl tar rar unrar unzip zip python-is-python3 squid ipset'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  apt -y install $pkgs
fi
```

##### Important about BLackip Update

- `tw.txt` containing IPs of teamviewer servers. By default they are commented. To block or authorize them, activate them in `bipupdate.sh`. To update it use `tw.sh` / `tw.txt` contiene IPs de servidores teamviewer. Por defecto están comentadas. Para bloquearlas o autorizarlas activelas en `bipupdate.sh`. Para actualizarla use `tw.sh`
- You must activate the rules in [Squid](http://www.squid-cache.org/) before using `bipupdate.sh` / Antes de utilizar `bipupdate.sh` debe activar las reglas en [Squid](http://www.squid-cache.org/)
- Some lists have download restrictions, so do not run `bipupdate.sh` more than once a day / Algunas listas tienen restricciones de descarga, entonces no ejecute `bipupdate.sh` más de una vez al día
- During the execution of `bipupdate.sh` it will request privileges when needed / Durante la ejecución de `bipupdate.sh` solicitará privilegios cuando los necesite

##### Check execution (/var/log/syslog)

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

### BLOCKLISTS

#### Active

- [Abuse.ch Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)
- [adservers yoyo](https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0)
- [BBcan177 minerchk](https://raw.githubusercontent.com/BBcan177/minerchk/master/ip-only.txt)
- [BL Myip](https://myip.ms/files/blacklist/general/full_blacklist_database.zip)
- [Blocklist](https://www.blocklist.de/downloads/export-ips_all.txt)
- [Cinsscore](http://cinsscore.com/list/ci-badguys.txt)
- [Emerging Threats Block](http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt)
- [Emerging Threats compromised](http://rules.emergingthreats.net/blockrules/compromised-ips.txt)
- [Firehold Forus Spam](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset)
- [Firehold](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset)
- [Greensnow](http://blocklist.greensnow.co/greensnow.txt)
- [IPDeny](http://www.ipdeny.com/ipblocks/)
- [Malwaredomain IP List](https://www.malwaredomainlist.com/hostslist/ip.txt)
- [MyIP BL](https://myip.ms/files/blacklist/general/latest_blacklist.txt)
- [Open BL](http://www.openbl.org/lists/base.txt)
- [opsxcq proxy-list](https://raw.githubusercontent.com/opsxcq/proxy-list/master/list.txt)
- [Project Honeypot](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)
- [Public-Intelligence-Feeds](https://github.com/CriticalPathSecurity/Public-Intelligence-Feeds/)
- [Rulez BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)
- [Spamhaus](https://www.spamhaus.org/drop/drop.lasso)
- [StopForumSpam 180](https://www.stopforumspam.com/downloads/listed_ip_180_all.zip)
- [StopForumSpam Toxic CIDR](https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt)
- [TOR BulkExitList](https://check.torproject.org/torbulkexitlist?ip=1.1.1.1)
- [TOR Node List](https://www.dan.me.uk/torlist/?exit)
- [UCEPROTECT IP Blocklists / BACKSCATTERER.ORG Blocklist](http://wget-mirrors.uceprotect.net/) (includes: [Level 1](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz), [Level 2](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz), [Level3](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz))
- [Ultimate Hosts IPs Blocklist](https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/tree/master/ips)
- [Zeustracker](https://zeustracker.abuse.ch/blocklist.php?download=badips)

#### Inactive, Discontinued or Private

*Recovered by [Wayback Machine](https://archive.org/web/), debugged and added to: `oldip.txt`*

- [Malc0de IP Blocklist](http://malc0de.com/bl/IP_Blacklist.txt)
- [Maxmind](https://www.maxmind.com/en/high-risk-ip-sample-list)
- [OpenBL](https://www.openbl.org/lists/base.txt)
- [Ransomwaretracker](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)
- [The LashBack UBL](http://www.unsubscore.com/blacklist.txt)

### ALLOWLISTS

#### Active

*Debugged and added to: `aipextra.txt`*

- [Amazon AWS](https://ip-ranges.amazonaws.com/ip-ranges.json)
- [Microsoft Azure Datacenter](https://www.microsoft.com/en-us/download/details.aspx?id=41653)

#### Inactive, Discontinued or Private

*Recovered by [EOP](https://raw.githubusercontent.com/dnswl/eop/master/O365IPAddresses.xml), debugged and added to: `aipextra.txt`*

- [O365IPAddresses](https://support.content.office.net/en-us/static/O365IPAddresses.xml) (No longer support. [Read me](ocs.microsoft.com/es-es/office365/enterprise/urls-and-ip-address-ranges?redirectSourcePath=%252fen-us%252farticle%252fOffice-365-URLs-and-IP-address-ranges-8548a211-3fe7-47cb-abb1-355ea5aa88a2))

### Debug

- [Allow IP/CIDR extra](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/aipextra.txt)
- [Allow IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/allowip.txt)
- [Block IP/CIDR Extra](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/blst/bipextra.txt)
- [IANA](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/iana.txt)
- [Old IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/blst/oldips.txt)
- [Teamviewer IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/tw.txt)
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

## BUILD

---

[![CreativeCommons](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
[maravento.com](http://www.maravento.com) is licensed under a [Creative Commons Reconocimiento-CompartirIgual 4.0 Internacional License](http://creativecommons.org/licenses/by-sa/4.0/).

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
