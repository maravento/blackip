## [Blackip](http://www.maravento.com/p/blackip.html)

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)
[![Version](https://img.shields.io/badge/Development-ALPHA-blue.svg)](https://img.shields.io/badge/Development-ALPHA-blue.svg)

[Blackip](http://www.maravento.com/p/blackip.html) es un proyecto que pretende recopilar la mayor cantidad de listas negras públicas de IPs IPv4 (incluyendo bloqueo de zonas geográficas con [IPDeny](http://www.ipdeny.com/ipblocks/)) utilizando el módulo [IPSET](http://ipset.netfilter.org/) de [Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/). Este módulo nos permite realizar filtrado masivo (Vea [Filtrado por Geolocalización](http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). [Blackip](http://www.maravento.com/p/blackip.html) también puede ser utilizada en [Squid-Cache](http://www.squid-cache.org/) (Tested in v3.5.x)

[Blackip](http://www.maravento.com/p/blackip.html) is a project that aims to collect as many public blacklists of IPv4 IPs (including blocking geographic zones with [IPDeny](http://www.ipdeny.com/ipblocks/)) using the [IPSET](http://ipset.netfilter.org/) module from [Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/). This module allows us to perform mass filtering (See [Geolocation Filtering](http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), at a processing speed far superior to other Solutions (See the [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)). [Blackip](http://www.maravento.com/p/blackip.html) can also be used in [Squid-Cache](http://www.squid-cache.org/) (Tested in v3.5.x)

### Descripción / Description

|File|IPs|File size|
|----|---|---------|
|blackip.txt|14.967.942|213,3 Mb|

### Dependencias / Dependencies

```
git ipset iptables bash tar zip wget squid subversion python
```
### Modo de uso / How to use

La ACL **blackip.txt** ya viene optimizada. Descárguela con **blackip.sh**. Por defecto, la ruta de **blackip.txt** es **/etc/acl** y del script **blackip.sh** es **/etc/init.d** / The ACL **blackip.txt** is already optimized. Download it with **blackip.sh**. By default, **blackip.txt** path is **/etc/acl** and the script **blackip.sh** is **/etc/init.d**

```
sudo wget https://raw.githubusercontent.com/maravento/blackip/master/blackip.sh -O /etc/init.d/blackip.sh
sudo chown root:root /etc/init.d/blackip.sh
sudo chmod +x /etc/init.d/blackip.sh
sudo /etc/init.d/blackip.sh
```
### Actualización BLs / Update BLs

También puede descargar el proyecto Blackip y actualizar la ACL **blackip.txt** en dependencia de sus necesidades / You can also download the Blackip project and update the **blackip.txt** ACL depending on your needs

```
git clone --depth=1 https://github.com/maravento/blackip.git
sudo cp -f blackip/bipupdate.sh /etc/init.d
sudo chown root:root /etc/init.d/blackip.sh
sudo chmod +x /etc/init.d/bipupdate.sh
sudo /etc/init.d/bipupdate.sh
```
##### Verifique la ejecución / Check execution (/var/log/syslog):

Ejecución exitosa / Successful execution
```
Blackip: Done 06/05/2017 15:47:14
```
Ejecución fallida / Execution failed

```
Blackip: Abort 06/05/2017 15:47:14 Check Internet Connection
```

##### Importante sobre la actualización BLs / Important about update BLs

- Blackip solo da soporte IPv4 / Blackip only supports IPv4
- Puede incluir su propia Blacklist IPs, que quiera bloquear y que no se encuentre en **blackip.txt**, editando el script **bipupdate.sh** y descomentando en **ADD OWN LIST** la línea **/path/blackip_own.txt** y reemplazandola por la ruta hacia su propia lista / You can include your own Blacklist IPs, which you want to block, and that is not on **blackip.txt**, editing **bipupdate.sh** script and uncommenting in **ADD OWN LIST** line **/path/blackip_own.txt** and replacing it with the path to your own list

### CIDR-IANA Clean

El bash **cidrclean.sh** realiza la depuración de IPs/CIDR de **blackip.txt** (/etc/acl), para evitar conflictos en [Squid-Cache](http://www.squid-cache.org/), y excluye rangos privados [RFC1918](https://es.wikipedia.org/wiki/Red_privada), sin embargo consume gran cantidad de recursos de hardware durante el procesamiento y puede tomar varios días (Requisitos Mínimos: 64GB RAM, Corei5, HD 40GB free), por tanto se recomienda hacer este proceso de depuración manualmente / The bash **cidrclean.sh** performs debugging of IPs/CIDR in **blackip.txt** (/etc/acl), to avoid conflicts in [Squid-Cache](http://www.squid-cache.org/), and excludes private ranges [RFC1918](https://en.wikipedia.org/wiki/Private_network), however it consumes a large amount of hardware resources during processing and can take several days (Minimum Requirements: 64GB RAM, Corei5, HD 40GB free), therefore it is recommended to do this debugging process manually

```
sudo wget -c https://raw.githubusercontent.com/maravento/blackip/master/cidrclean.sh -O /etc/init.d/cidrclean.sh
sudo chown root:root /etc/init.d/cidrclean.sh
sudo chmod +x /etc/init.d/cidrclean.sh
sudo /etc/init.d/cidrclean.sh
```

### Reglas / Rules

Tenga en cuenta que no se debe utilizar **Blackip** en [IPSET](http://ipset.netfilter.org/) y en [Squid-Cache](http://www.squid-cache.org/) al mismo tiempo (doble filtrado) / Note that **Blackip** should not be used in [IPSET](http://ipset.netfilter.org/) and in [Squid-Cache](http://www.squid-cache.org/) at the same time (double filtrate)

##### Regla de [Squid-Cache](http://www.squid-cache.org/) / [Squid-Cache](http://www.squid-cache.org/) Rule

Edit /etc/squid/squid.conf:
```
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
acl blackip dst "/etc/acl/blackip.txt"
http_access deny blackip
```

##### Regla de [IPSET](http://ipset.netfilter.org/) / [IPSET](http://ipset.netfilter.org/) Rule

Edite su script de Iptables y agregue: / Edit your Iptables script and add:
```
ipset=/sbin/ipset
iptables=/sbin/iptables
route=/etc/acl
zone=/etc/zones

# BLACKZONE RULE (select country to block and ip/range)
$ipset -F
$ipset -N -! blackzone hash:net maxelem 1000000
 for ip in $(cat $route/blackip.txt); do
  $ipset -A blackzone $ip
 done
$iptables -t mangle -A PREROUTING -m set --match-set blackzone src -j DROP
$iptables -A FORWARD -m set --match-set blackzone dst -j DROP
```
Puede incluir rangos completos de países (e.g. China, Rusia, etc) con [IPDeny](http://www.ipdeny.com/ipblocks/) / You can block entire countries ranges (e.g. China, Rusia, etc) with [IPDeny](http://www.ipdeny.com/ipblocks/)
```
for ip in $(cat $zone/{cn,ru}.zone $route/blackip.txt); do
```
En caso de error o conflicto, ejecute: / In case of error or conflict, execute:
```
sudo ipset flush blackzone or sudo ipset flush
```

### Data Sheet (Sources - Repositories)

##### IPs Blacklists

[IPDeny](http://www.ipdeny.com/ipblocks/)

[Zeustracker](https://zeustracker.abuse.ch/blocklist.php?download=badips)

[Ransomwaretracker](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)

[TOR exit addresses](https://check.torproject.org/exit-addresses)

[BL Myip](https://myip.ms/files/blacklist/general/full_blacklist_database.zip)

[Greensnow](http://blocklist.greensnow.co/greensnow.txt)

[Cinsscore](http://cinsscore.com/list/ci-badguys.txt)

[Spamhaus](https://www.spamhaus.org/drop/drop.lasso)

[Rulez BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)

[Emergingthreats](http://rules.emergingthreats.net/blockrules/compromised-ips.txt)

[Project Honeypot](http://www.projecthoneypot.org/list_of_ips.php)

[Maxmind](https://www.maxmind.com/es/proxy-detection-sample-list)

[Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)

[Malc0de IP Blacklist](http://malc0de.com/bl/IP_Blacklist.txt)

[The LashBack UBL](http://www.unsubscore.com/blacklist.txt)

[MyIP BL](https://myip.ms/files/blacklist/general/latest_blacklist.txt)

[Open BL](http://www.openbl.org/lists/base.txt)

[Project Honeypot](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)

[Malwaredomain IP List](https://www.malwaredomainlist.com/hostslist/ip.txt)

[Ultimate Hosts IPs Blacklist](https://github.com/mitchellkrogza/Ultimate.Hosts.Blacklist) ([ip-list (RAW)](https://hosts.ubuntu101.co.za/ips.list)) (It includes [Blocklist](https://lists.blocklist.de/lists/all.txt))

[blackip](https://github.com/maravento/blackip/raw/master/blackip.tar.gz)

[OpenBL](https://www.openbl.org/lists/base.txt) (Server Down since Ago 2017)

[Firehold](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset) (Excluded for containing CIDR)

[StopForumSpam](https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt) (Excluded for containing CIDR)

### Contributions

Agradecemos a todos aquellos que han contribuido a este proyecto. Los interesados pueden contribuir, enviándonos enlaces de nuevas "Blacklist", para ser incluidas en este proyecto / We thank all those who contributed to this project. Those interested may contribute sending us new "Blacklist" links to be included in this project

### Licence

[GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)

© 2017 [Maravento Studio](http://www.maravento.com)

#### Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
