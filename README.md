## [BlackIP](http://www.maravento.com/p/blackip.html)

**BlackIP** es un proyecto que recopila listas negras públicas de IPs para unificarlas y hacerlas compatibles con [Squid](http://www.squid-cache.org/) e [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))

**BlackIP** It is a project that collects public blacklists of IPs to unify and make them compatible with [Squid](http://www.squid-cache.org/) and [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/))

### FICHA TECNICA / DATA SHEET
---

|lst|Black IPs|txt size|tar.gz size|
| :---: | :---: | :---: | :---: |
|blackip.txt|3.338.838|47.7 Mb|9.9 Mb|

### DEPENDENCIAS / DEPENDENCIES
---

```
git ipset iptables bash tar zip wget squid subversion python ulogd2
```

### GIT CLONE
---
```
git clone --depth=1 https://github.com/maravento/blackip.git
```

### MODO DE USO / HOW TO USE
---

`blackip.txt` ya viene optimizada. Descárguela y descomprimala en la ruta de su preferencia / `blackip.txt` is already optimized. Download it and unzip it in the path of your preference

#####  Download and Checksum

```
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz && cat blackip.tar.gz* | tar xzf -
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/checksum.md5
md5sum blackip.txt | awk '{print $1}' && cat checksum.md5 | awk '{print $1}'
```

### REGLAS / RULES
---

#### Bloqueo para [IPSET](http://ipset.netfilter.org/) / Block for [IPSET](http://ipset.netfilter.org/)

Este módulo nos permite realizar filtrado masivo, a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). Se incluye zonas geográficas con [IPDeny](http://www.ipdeny.com/ipblocks/)) / This module allows us to perform mass filtering, at a processing speed far superior to other Solutions (See the [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). It includes geographical areas with [IPDeny](http://www.ipdeny.com/ipblocks/))

Edite su script de Iptables y agregue las siguientes líneas: / Edit your Iptables script and add the following lines:
```
# IPSET BLACKZONE (select country to block and ip/range) ###
# http://www.ipdeny.com/ipblocks/
ipset=/sbin/ipset
iptables=/sbin/iptables
route=/path_to_lst_blackip/
zone=/path_to_lst_zones/zones
if [ ! -d $zone ]; then mkdir -p $zone; fi

$ipset -F
$ipset -N -! blackzone hash:net maxelem 1000000
# Uncomment this line if you want to block entire countries
#for ip in $(cat $zone/{cn,ru}.zone $route/blackip.txt); do
# Uncomment this line if you want to block only ips (recommended)
for ip in $(cat $route/blackip.txt); do
    $ipset -A blackzone $ip
done
$iptables -t mangle -A PREROUTING -m set --match-set blackzone src -j NFLOG --nflog-prefix 'Blackzone Block'
$iptables -t mangle -A PREROUTING -m set --match-set blackzone src -j DROP
$iptables -A FORWARD -m set --match-set blackzone dst -j NFLOG --nflog-prefix 'Blackzone Block'
$iptables -A FORWARD -m set --match-set blackzone dst -j DROP
```
Puede incluir rangos completos de países (e.g. China, Rusia, etc) con [IPDeny](http://www.ipdeny.com/ipblocks/) agregando los países a la línea: / You can block entire countries ranges (e.g. China, Rusia, etc) with [IPDeny](http://www.ipdeny.com/ipblocks/) adding the countries to the line:
```
for ip in $(cat $zone/{cn,ru}.zone $route/blackip.txt); do
```
En caso de error o conflicto, ejecute: / In case of error or conflict, execute:
```
sudo ipset flush blackzone # (or: sudo ipset flush)
```
NFLOG: /var/log/ulog/syslogemu.log
```
chown root:root /var/log
apt -y install ulogd2
if [ ! -d /var/log/ulog/syslogemu.log ]; then mkdir -p /var/log/ulog && touch /var/log/ulog/syslogemu.log; fi
usermod -a -G ulog $USER
```

#### Bloqueo para [Squid](http://www.squid-cache.org/) (Tested in v3.5.x) / Block for [Squid](http://www.squid-cache.org/) (Tested in v3.5.x)

Edite / Edit:
```
/etc/squid/squid.conf
```
Y agregue las siguientes líneas: / And add the following lines:

```
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
acl blackip dst "/path_to_lst/blackip.txt"
http_access deny blackip
```

#### Actualización BlackIP / BlackIP Update

#### ⚠️ **ADVERTENCIA: ANTES DE CONTINUAR! / WARNING: BEFORE YOU CONTINUE!**

La actualización y depuración puede tardar y consumir muchos recursos de hardware y ancho de banda. No se recomienda ejecutarla en equipos en producción / Update and debugging can take and consume many hardware resources and bandwidth. It is not recommended to run it on production equipment

El proceso de actualización de `blackip.txt` es ejecutado en secuencia por el script `bipupdate.sh` / The update process of `blackip.txt` is executed in sequence by the script `bipupdate.sh`

```
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && chmod +x bipupdate.sh && ./bipupdate.sh
```

##### Verifique la ejecución / Check execution (/var/log/syslog):

Ejecución exitosa / Successful execution
```
BlackIP: Done 06/05/2019 15:47:14
```

##### Importante sobre BlackIP Update / Important about BlackIP Update

- `blackip.txt` es una lista IPv4. No incluye CIDR / `blackip.txt` is a list IPv4. Does not include CIDR
- Antes de utilizar `bipupdate.sh` debe activar las reglas en [Squid](http://www.squid-cache.org/) / You must activate the rules in [Squid](http://www.squid-cache.org/) before using `bipupdate.sh`
- `blackip.txt` excluye rangos privados/reservados [RFC1918](https://es.wikipedia.org/wiki/Red_privada) con `ianacidr.txt` / `blackip.txt` excludes private/reserved ranges [RFC1918](https://en.wikipedia.org/wiki/Private_network) with `ianacidr.txt`
- No se debe utilizar `blackip.txt` en [IPSET](http://ipset.netfilter.org/) y en [Squid](http://www.squid-cache.org/) al mismo tiempo (doble filtrado) / Should not be used `blackip.txt` in [IPSET](http://ipset.netfilter.org/) and in [Squid](http://www.squid-cache.org/) at the same time (double filtrate).
- `tw.txt` contiene IPs de servidores teamviewer. Por defecto están comentadas. Para bloquearlas o autorizarlas activelas en `bipupdate.sh`. Para actualizarla use `tw.sh` / `tw.txt` containing IPs of teamviewer servers. By default they are commented. To block or authorize them, activate them in `bipupdate.sh`. To update it use `tw.sh`
- `bwextra.txt` se utiliza para agregar IP/CIDR que no se encuentren en `blackip.txt`, pero puede generar conflictos / `betra.txt` is used to add IP/CIDR that are not in, but it can generate conflicts

```
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
acl bextra dst "/path_to_lst/bextra.txt"
http_access deny bextra
acl blackip dst "/path_to_lst/blackip.txt"
http_access deny blackip
```

#### Bloqueo Inverso para [Squid](http://www.squid-cache.org/) (Tested in v3.5.x) / For [Squid](http://www.squid-cache.org/) Reverse Block (Tested in v3.5.x)

Si considera que son muchas IPs a bloquear, se recomienda usar la regla de bloqueo inverso para Squid, que consiste en autorizar solamente listas blancas de IPs y denegar el resto de peticiones a direcciones IPs. Si va a usar esta regla, se recomienda desactivar BlackIP / If you consider that there are many IPs to block, it is recommended to use the reverse blocking rule for Squid, which is to authorize only white lists of IPs and deny all other requests to IP addresses. If you are going to use this rule, it is recommended to disable BlackIP

```
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
acl wextra dst "/path_to_lst/wextra.txt"
http_access allow wextra
acl whiteip dst "/path_to_lst/whiteip.txt"
http_access allow whiteip
#acl blackip dst "/path_to_lst/blackip.txt"
#http_access deny blackip
acl no_ip url_regex -i [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
http_access deny no_ip
```

##### Listas Blancas para regla de Bloqueo Inverso para Squid / White Lists for Inverse Blocking Rule for Squid

- `whiteip.txt` es una lista de IPs IPv4, optimizada para [Squid](http://www.squid-cache.org/). No incluye CIDR / `whiteip.txt` is a list of IPv4 IPs, optimized for [Squid](http://www.squid-cache.org/). Does not include CIDR
- `wextra.txt` es una lista IPv4 para agregar manualmente IP/CIDR blancas que no se encuentran en `whiteip.txt` / `wextra.txt` is an IPv4 list to manually add white IP/CIDR that are not found in` whiteip.txt`

#### Actualización WhiteIP / WhiteIP Update

#### ⚠️ **ADVERTENCIA: ANTES DE CONTINUAR! / WARNING: BEFORE YOU CONTINUE!**

`whiteip.txt` ya esta actualizada y optimizada. Para actualizarla se utiliza `wipupdate.sh`. La actualización y depuración puede tardar y consumir muchos recursos de hardware y ancho de banda. No se recomienda ejecutarla en equipos en producción / `whiteip.txt` is already updated and optimized. To update it, use `wipupdate.sh`. Upgrading and debugging can take and consume many hardware resources and bandwidth. It is not recommended to run it on production equipment

```
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/wipupdate.sh && chmod +x wipupdate.sh && ./wipupdate.sh
```

#####  Verifique su ejecución / Check execution (/var/log/syslog):

```
WhiteIP for Squid Reverse: 14/06/2019 15:47:14
```

### FUENTES / SOURCES
---

##### Black IPs

###### Actives

- [Abuse.ch Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)
- [adservers yoyo](https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0)
- [BL Myip](https://myip.ms/files/blacklist/general/full_blacklist_database.zip)
- [Cinsscore](http://cinsscore.com/list/ci-badguys.txt)
- [Emerging Threats Block](http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt)
- [Emerging Threats compromised](http://rules.emergingthreats.net/blockrules/compromised-ips.txt)
- [Firehold Forus Spam](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset)
- [Greensnow](http://blocklist.greensnow.co/greensnow.txt)
- [IPDeny](http://www.ipdeny.com/ipblocks/)
- [Malc0de IP Blacklist](http://malc0de.com/bl/IP_Blacklist.txt)
- [Malwaredomain IP List](https://www.malwaredomainlist.com/hostslist/ip.txt)
- [Maxmind](https://www.maxmind.com/es/proxy-detection-sample-list)
- [MyIP BL](https://myip.ms/files/blacklist/general/latest_blacklist.txt)
- [Open BL](http://www.openbl.org/lists/base.txt)
- [Project Honeypot](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)
- [Ransomwaretracker](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)
- [Rulez BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)
- [Spamhaus](https://www.spamhaus.org/drop/drop.lasso)
- [StopForumSpam 180](https://www.stopforumspam.com/downloads/listed_ip_180_all.zip)
- [The LashBack UBL](http://www.unsubscore.com/blacklist.txt)
- [TOR BulkExitList](https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=1.1.1.1)
- [TOR Node List](https://www.dan.me.uk/torlist/?exit)
- [Ultimate Hosts IPs Blacklist](https://github.com/mitchellkrogza/Ultimate.Hosts.Blacklist). [Mirror](https://hosts.ubuntu101.co.za/ips.list)
- [Zeustracker](https://zeustracker.abuse.ch/blocklist.php?download=badips)

###### Inactive

- [Blocklist](https://lists.blocklist.de/lists/all.txt) and [Blocklist Export](https://www.blocklist.de/downloads/export-ips_all.txt). Replaced by [Ultimate Hosts IPs Blacklist](https://github.com/mitchellkrogza/Ultimate.Hosts.Blacklist)
- [Firehold Level 1](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset) (Excluded for containing CIDR)
- [OpenBL](https://www.openbl.org/lists/base.txt) (Server Down. Last Updated Known Apr 1/2016. Added to: `oldips.txt`)
- [StopForumSpam Toxic CIDR](https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt) (Excluded for containing CIDR)
- [UCEPROTECT IP Blacklists / BACKSCATTERER.ORG Blacklist](http://wget-mirrors.uceprotect.net/) (Server Down. Last Updated Known Ago 17/2017. Added to: `oldips.txt`)

##### White IPs

###### Actives

- [Amazon AWS](https://ip-ranges.amazonaws.com/ip-ranges.json) (Excluded for containing CIDR)
- [Microsoft Azure Datacenter](https://www.microsoft.com/en-us/download/details.aspx?id=41653) (Excluded for containing CIDR)

###### Inactives

- [O365IPAddresses](https://support.content.office.net/en-us/static/O365IPAddresses.xml) (No longer support. [See This post](ocs.microsoft.com/es-es/office365/enterprise/urls-and-ip-address-ranges?redirectSourcePath=%252fen-us%252farticle%252fOffice-365-URLs-and-IP-address-ranges-8548a211-3fe7-47cb-abb1-355ea5aa88a2))

##### Work Lists

###### Internals

- [Black IP/CIDR Extra](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/blst/bextra.txt)
- [IANA CIDR](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/ianacidr.txt)
- [Old IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/blst/oldips.txt)
- [Teamviewer IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/tw.txt)
- [White IP/CIDR extra](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/wextra.txt)
- [White IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/whiteips.txt)

###### Externals

- [White URLs](https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/whiteurls.txt)

##### Work Tools

###### Internals

- [cidr2ip](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/tools/cidr2ip.py)
- [Debug IPs](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/tools/debugbip.py)
- [Teamviewer Capture](https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/tw.sh)


### CONTRIBUCIONES / CONTRIBUTIONS
---

Agradecemos a todos aquellos que han contribuido a este proyecto. Los interesados pueden contribuir, enviándonos enlaces de nuevas "Blacklist", para ser incluidas en este proyecto / We thank all those who contributed to this project. Those interested may contribute sending us new "Blacklist" links to be included in this project

Special thanks to: [Jhonatan Sneider](https://github.com/sney2002)

### DONACION / DONATE
---

BTC: 3M84UKpz8AwwPADiYGQjT9spPKCvbqm4Bc

### LICENCIAS / LICENCES
---

[![GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)

[![CreativeCommons](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
[maravento.com](http://www.maravento.com) is licensed under a [Creative Commons Reconocimiento-CompartirIgual 4.0 Internacional License](http://creativecommons.org/licenses/by-sa/4.0/).

© 2019 [Maravento Studio](http://www.maravento.com)

### EXENCION DE RESPONSABILIDAD / DISCLAIMER
---

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
