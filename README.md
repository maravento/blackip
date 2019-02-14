## [Blackip](http://www.maravento.com/p/blackip.html)

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)
[![GitHub version](https://img.shields.io/badge/Version-1.0-yellowgreen.svg)](http://www.maravento.com/p/blackip.html)

**Blackip** es un proyecto que pretende recopilar la mayor cantidad de listas negras públicas de IPs IPv4 (incluyendo bloqueo de zonas geográficas con [IPDeny](http://www.ipdeny.com/ipblocks/)) utilizando el módulo [IPSET](http://ipset.netfilter.org/) de [Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/). Este módulo nos permite realizar filtrado masivo (Vea [Filtrado por Geolocalización](http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). **Blackip** también puede ser utilizada en [Squid-Cache](http://www.squid-cache.org/) (Tested in v3.5.x)

**Blackip** is a project that aims to collect as many public blacklists of IPv4 IPs (including blocking geographic zones with [IPDeny](http://www.ipdeny.com/ipblocks/)) using the [IPSET](http://ipset.netfilter.org/) module from [Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/). This module allows us to perform mass filtering (See [Geolocation Filtering](http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), at a processing speed far superior to other Solutions (See the [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). **Blackip** can also be used in [Squid-Cache](http://www.squid-cache.org/) (Tested in v3.5.x)

### FICHA TECNICA / DATA SHEET
---

|ACL|Black IPs|txt size|tar.gz size|
|---|---------|--------|-----------|
|blackip.txt|1.435.989|19.0 Mb|4,3 Mb|

### DEPENDENCIAS / DEPENDENCIES
---

```
git ipset iptables bash tar zip wget squid subversion python
```

### GIT CLONE
---
```
git clone --depth=1 https://github.com/maravento/blackip.git
```

### MODO DE USO / HOW TO USE
---

La ACL **blackip.txt** ya viene optimizada. Descárguela y descomprimala en la ruta de su preferencia:

The ACL **blackip.txt** is already optimized. Download it and unzip it in the path of your preference:

#####  Download ACL

```
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz
cat blackip.tar.gz* | tar xzf -

```

#####  Checksum ACL

```
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/checksum.md5
md5sum blackip.txt | awk '{print $1}' && cat checksum.md5 | awk '{print $1}'
```

### ACTUALIZACIÓN / UPDATE
---

El script **bipupdate.sh** actualiza la ACL **blackip.txt**, realizando la captura, depuración y limpieza de IPs, sin embargo puede generar conflíctos. Tenga en cuenta que este script consume gran cantidad de recursos de hardware durante el procesamiento y puede tomar mucho tiempo.

The **bipupdate.sh** script updates **blackip.txt** ACL, doing the capture, debugging and cleaning of domains, however it can generate conflicts. Keep in mind that this script consumes a lot of hardware resources during processing and it can take a long time.

```
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && sudo chmod +x bipupdate.sh && sudo ./bipupdate.sh
```

##### Verifique la ejecución / Check execution (/var/log/syslog):

Ejecución exitosa / Successful execution
```
Blackip: Done 06/05/2017 15:47:14
```

##### Importante Antes de Usar / Important Before Use

- Blackip es una ACL IPv4. No incluye CIDR / Blackip is an ACL IPv4. Does not include CIDR
- Antes de utilizar **bipupdate.sh** debe activar las reglas en [Squid-Cache](http://www.squid-cache.org/) / You must activate the rules in [Squid-Cache](http://www.squid-cache.org/) before using **bipupdate.sh**
- La actualización debe ejecutarse en equipos de pruebas destinados para este propósito. Nunca en servidores en producción / The update must run on test equipment designed for this purpose. Never on servers in production
- Blackip excluye rangos privados [RFC1918](https://es.wikipedia.org/wiki/Red_privada) ([IPs reservadas](https://github.com/maravento/whiteip/raw/master/wipupdate/ianacidr.txt)) / Blackip excludes private ranges [RFC1918](https://en.wikipedia.org/wiki/Private_network) ([reserved IPs](https://github.com/maravento/whiteip/raw/master/wipupdate/ianacidr.txt))
- Tenga en cuenta que no se debe utilizar **Blackip** en [IPSET](http://ipset.netfilter.org/) y en [Squid-Cache](http://www.squid-cache.org/) al mismo tiempo (doble filtrado) / Note that **Blackip** should not be used in [IPSET](http://ipset.netfilter.org/) and in [Squid-Cache](http://www.squid-cache.org/) at the same time (double filtrate).
- Puede agregar su propia Blacklist IPs/CIDR a **blackip.txt**, pero tenga cuidado con los conflictos que pueda generar / You can add your own Blacklist IPs/CIDR to **blackip.txt**, but be careful with conflicts that may arise

### REGLAS / RULES
---

##### Para [Squid-Cache](http://www.squid-cache.org/) / For [Squid-Cache](http://www.squid-cache.org/)

Edite / Edit:
```
/etc/squid/squid.conf
```
Y agregue las siguientes líneas: / And add the following lines:

```
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
acl blackip dst "/path_to_acl/blackip.txt"
http_access deny blackip
```

##### Para [IPSET](http://ipset.netfilter.org/) / For [IPSET](http://ipset.netfilter.org/)

Edite su script de Iptables y agregue las siguientes líneas: / Edit your Iptables script and add the following lines:
```
ipset=/sbin/ipset
iptables=/sbin/iptables
route=/path_to_acl_blackip/
zone=/path_to_acl_zones/zones

# BLACKZONE RULE (select country to block and ip/range)
$ipset -F
$ipset -N -! blackzone hash:net maxelem 1000000
 for ip in $(cat $route/blackip.txt); do
  $ipset -A blackzone $ip
 done
$iptables -t mangle -A PREROUTING -m set --match-set blackzone src -j DROP
$iptables -A FORWARD -m set --match-set blackzone dst -j DROP
```
Puede incluir rangos completos de países (e.g. China, Rusia, etc) con [IPDeny](http://www.ipdeny.com/ipblocks/) agregando los países a la línea: / You can block entire countries ranges (e.g. China, Rusia, etc) with [IPDeny](http://www.ipdeny.com/ipblocks/) adding the countries to the line:
```
for ip in $(cat $zone/{cn,ru}.zone $route/blackip.txt); do
```
En caso de error o conflicto, ejecute: / In case of error or conflict, execute:
```
sudo ipset flush blackzone or sudo ipset flush
```

### FUENTES / SOURCES
---

##### IPs Public Blacklists

[Abuse.ch Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)

[adservers yoyo](https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0)

[Cinsscore](http://cinsscore.com/list/ci-badguys.txt)

[Emerging Threats Block](http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt)

[Emerging Threats compromised](http://rules.emergingthreats.net/blockrules/compromised-ips.txt)

[Firehold Forus Spam](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset)

[Greensnow](http://blocklist.greensnow.co/greensnow.txt)

[IPDeny](http://www.ipdeny.com/ipblocks/)

[Malc0de IP Blacklist](http://malc0de.com/bl/IP_Blacklist.txt)

[Malwaredomain IP List](https://www.malwaredomainlist.com/hostslist/ip.txt)

[Maxmind](https://www.maxmind.com/es/proxy-detection-sample-list)

[MyIP BL](https://myip.ms/files/blacklist/general/latest_blacklist.txt)

[Open BL](http://www.openbl.org/lists/base.txt)

[Project Honeypot](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)

[Ransomwaretracker](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)

[Rulez BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)

[Spamhaus](https://www.spamhaus.org/drop/drop.lasso)

[The LashBack UBL](http://www.unsubscore.com/blacklist.txt)

[uceprotect](http://wget-mirrors.uceprotect.net/)

[Ultimate Hosts IPs Blacklist](https://github.com/mitchellkrogza/Ultimate.Hosts.Blacklist). [Mirror](https://hosts.ubuntu101.co.za/ips.list)

[Zeustracker](https://zeustracker.abuse.ch/blocklist.php?download=badips)

##### TOR

[TOR BulkExitList](https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=1.1.1.1)

[TOR Node List](https://www.dan.me.uk/torlist/?exit)

##### IPs Public Blacklists (compressed)

[BL Myip](https://myip.ms/files/blacklist/general/full_blacklist_database.zip)

[StopForumSpam 180](https://www.stopforumspam.com/downloads/listed_ip_180_all.zip)

##### IPs Public Blacklists (Discontinued or Replaced)

[Blocklist](https://lists.blocklist.de/lists/all.txt) and [Blocklist Export](https://www.blocklist.de/downloads/export-ips_all.txt). Replaced by [Ultimate Hosts IPs Blacklist](https://github.com/mitchellkrogza/Ultimate.Hosts.Blacklist)

[Firehold Level 1](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset) (Excluded for containing CIDR)

[StopForumSpam Toxic CIDR](https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt) (Excluded for containing CIDR)

[OpenBL](https://www.openbl.org/lists/base.txt) (Server Down since Ago 2017)

##### Internal Tools

[cidr2ip](https://github.com/maravento/blackip/raw/master/bipupdate/cidr2ip.py)

[Debug IPs](https://github.com/maravento/blackip/raw/master/bipupdate/debugbip.py)

### CONTRIBUCIONES / CONTRIBUTIONS
---

Agradecemos a todos aquellos que han contribuido a este proyecto. Los interesados pueden contribuir, enviándonos enlaces de nuevas "Blacklist", para ser incluidas en este proyecto / We thank all those who contributed to this project. Those interested may contribute sending us new "Blacklist" links to be included in this project

### DONACION / DONATE
---

BTC: 3M84UKpz8AwwPADiYGQjT9spPKCvbqm4Bc

### LICENCIA / LICENCE
---

[GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)

[![License](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
[maravento.com](http://www.maravento.com), [gateproxy.com](http://www.gateproxy.com) and [dextroyer.com](http://www.dextroyer.com) is licensed under a [Creative Commons Reconocimiento-CompartirIgual 4.0 Internacional License](http://creativecommons.org/licenses/by-sa/4.0/).

© 2018 [Maravento Studio](http://www.maravento.com)

### EXENCION DE RESPONSABILIDAD / DISCLAIMER
---

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
