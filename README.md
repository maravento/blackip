## [Blackip](http://www.maravento.com/p/blackip.html)

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)
[![Version](https://img.shields.io/badge/Development-ALPHA-blue.svg)](https://img.shields.io/badge/Development-ALPHA-blue.svg)

[Blackip](http://www.maravento.com/p/blackip.html) es un proyecto que pretende recopilar la mayor cantidad de listas negras públicas de IPs IPv4 (incluyendo bloqueo de zonas geográficas con [IPDeny](http://www.ipdeny.com/ipblocks/)) utilizando el módulo [IPSET](http://ipset.netfilter.org/) de [Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/). Este módulo nos permite realizar filtrado masivo (Vea [Filtrado por Geolocalización](http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark](http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).

[Blackip](http://www.maravento.com/p/blackip.html) is a project that aims to collect as many public blacklists of IPv4 IPs (including blocking geographic zones with [IPDeny](http://www.ipdeny.com/ipblocks/)) using the [IPSET](http://ipset.netfilter.org/) module from [Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/). This module allows us to perform mass filtering (See [Geolocation Filtering](http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), at a processing speed far superior to other Solutions (See the [benchmark](http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).

### Descripción / Description

|File|BL IPs|File size|
|----|----------|---------|
|blackip.txt|11.610.756|165,4 Mb|

### Dependencias / Dependencies

```
git ipset iptables bash tar zip wget
```
### Modo de uso / How to use

La ACL **blackip.txt** ya viene optimizada para [IPSET](http://ipset.netfilter.org/). Descárguela, descomprímala, ponga la ACL en el directorio de su preferencia y active la regla de [IPSET](http://ipset.netfilter.org/). (Puede utilizar el script **blackip.sh** para descargala. El directorio por defecto es **/etc/acl**) / The ACL **blackip.txt** is already optimized for [IPSET](http://ipset.netfilter.org/). Download it, decompress it, put the ACL in the directory of your preference and activate the [IPSET](http://ipset.netfilter.org/) rule (You can use the **blackip.sh** script to download it. The default directory is **/etc/acl**)

```
wget https://github.com/maravento/blackip/raw/master/blackip.sh -O /etc/init.d/blackip.sh
sudo chown root:root /etc/init.d/blackip.sh && sudo chmod +x /etc/init.d/blackip.sh
sudo /etc/init.d/blackip.sh
```
### Actualización Blackip / Update Blackip

También puede descargar el proyecto Blackip y actualizar la ACL **blackip.txt** en dependencia de sus necesidades / You can also download the Blackip project and update the **blackip.txt** ACL depending on your needs

```
git clone --depth=1 https://github.com/maravento/blackip.git
sudo cp -f blackip/bipupdate.sh /etc/init.d
sudo chown root:root /etc/init.d/blackip.sh
sudo chmod +x /etc/init.d/bipupdate.sh
sudo /etc/init.d/bipupdate.sh
```
##### Depurando IPs-CIDR / Debugging IPs-CIDR

Para evitar conflictos IPs-CIDR utilice el bash script **cleancidr.sh**. Se recomienda excluir los rangos privados [RFC1918](https://es.wikipedia.org/wiki/Red_privada) / To avoid IPs-CIDR conflicts use the bash script **cleancidr.sh**. It is recommended to exclude private ranges [RFC1918](https://es.wikipedia.org/wiki/Red_private)

```
chmod +x clearcidr.sh && ./clearcidr.sh blackip.txt
cat RFC1918.txt | while read output; do
  sed -i "\|$output|d" cidrclean.txt && sort -u cidrclean.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > blackip.txt
done
```
La depuración de conflictos IPs/CIDR consume gran cantidad de recursos de hardware durante el procesamiento y puede tomar más de 24 horas, por tanto se recomienda hacerlo manualmente / Conflict debugging IPs/CIDR consumes a lot of hardware resources during processing and can take more than 24 hours, so it is recommended to do it manually

##### Lista propia / Own list

Puede incluir su propia Blacklist IPs, que quiera bloquear con **Ipset**, y que no se encuentre en **blackip.txt**, editando el script **bipupdate.sh** y descomentando en **ADD OWN LIST** la línea **/path/blackip_own.txt** y reemplazandola por la ruta hacia su propia lista / You can include your own Blacklist IPs, which you want to block with **Ipset**, and that is not on **blackip.txt**, editing **bipupdate.sh** script and uncommenting in **ADD OWN LIST** line **/path/blackip_own.txt** and replacing it with the path to your own list

##### Verifique la ejecución / Check execution (/var/log/syslog):

Ejecución exitosa / Successful execution
```
Blackip for Ipset: Done 06/05/2017 15:47:14
```
Ejecución fallida / Execution failed

```
Blackip for Ipset: Abort 06/05/2017 15:47:14 Check Internet Connection
```
### Regla de **Ipset** / **Ipset** Rule

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
### Importante / Important

- El uso excesivo pueden llevar al colapso de su sistema, debido a la gran cantidad de recursos que consume. Úsela con moderación / Overuse of programs, rules and ACLs described, can lead to collapse of its system due to the large amount of resources they consume. Use them sparingly
- Blackip solo da soporte a IPs IPv4 / Blackip only supports IPs IPv4
- La ruta usadas por **blackip.sh** para almacenar la ACL (/etc/acl) es opcional. Reemplace con el path de su elección / The route used by **blackip.sh** to store ACLs (/etc/acl) is optional. Replace path by your choice.

### Data Sheet (Sources)

##### General Public IPs BLs

[IPDeny](http://www.ipdeny.com/ipblocks/)

[Zeustracker](https://zeustracker.abuse.ch/blocklist.php?download=badips)

[Ransomwaretracker](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)

[TOR exit addresses](https://check.torproject.org/exit-addresses)

[BL Myip](https://myip.ms/files/blacklist/general/full_blacklist_database.zip)

[Firehold](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset)

[Greensnow](http://blocklist.greensnow.co/greensnow.txt)

[Blocklist](https://lists.blocklist.de/lists/all.txt)

[OpenBL](https://www.openbl.org/lists/base.txt)

[Cinsscore](http://cinsscore.com/list/ci-badguys.txt)

[Spamhaus](https://www.spamhaus.org/drop/drop.lasso)

[Rulez BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)

[Emergingthreats](http://rules.emergingthreats.net/blockrules/compromised-ips.txt)

[Project Honeypot](http://www.projecthoneypot.org/list_of_ips.php)

[Maxmind](https://www.maxmind.com/es/proxy-detection-sample-list)

[StopForumSpam](https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt)

[Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)

[Malc0de IP Blacklist](http://malc0de.com/bl/IP_Blacklist.txt)

[The LashBack UBL](http://www.unsubscore.com/blacklist.txt)

[MyIP BL](https://myip.ms/files/blacklist/general/latest_blacklist.txt)

[Open BL](http://www.openbl.org/lists/base.txt)

[Project Honeypot](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)

[Malwaredomain IP List](https://www.malwaredomainlist.com/hostslist/ip.txt)

**Own lists (inside project)**

[RFC1918](https://github.com/maravento/blackip/raw/master/RFC1918.txt)

[blackip](https://github.com/maravento/blackip/raw/master/blackip.tar.gz)

### Licence

[GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)

Agradecemos a todos aquellos que han contribuido a este proyecto. We thank all those who contributed to this project.

© 2017 [Maravento Studio](http://www.maravento.com)

#### Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
