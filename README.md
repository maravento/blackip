## [Blackip] (http://www.maravento.com/p/blackip.html)

<a target="_blank" href=""><img src="https://img.shields.io/badge/Development-ALPHA-blue.svg"></a>

[Blackip] (http://www.maravento.com/p/blackip.html) es una lista negra (blacklist) de IPs/CIDR, que contiene sitios porno, descargas, drogas, malware, spyware, trackers, bots, redes sociales, warez, venta de armas, etc, y adicionalmente puede incluirle IPs/CIDR para bloquear zonas geográficas. 

El script incluido descarga varias listas negras públicas, tales como las "geozones" de [IPDeny] (http://www.ipdeny.com/ipblocks/), entre otras, y las compila en una sola megalista resultante, la cual es filtrada con una lista blanca (whitelist) para eliminar falsos positivos y finalmente ser utilizada con el módulo [IPSET] (http://ipset.netfilter.org/) para [Iptables] (http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html), ambos de [Netfilter] (http://www.netfilter.org/). Este módulo nos permite realizar filtrado masivo (Vea [Filtrado por Geolocalización] (http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark] (http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).

### Dependencias/Dependencies

```
ipset bash
```

### Modo de uso - How to use

Descargue/Download:
```
git clone https://github.com/maravento/blackip.git
```
Copie el script y ejecútelo - Copy the script and run:
```
sudo cp -f blackip/blackip.sh /etc/init.d
sudo chown root:root /etc/init.d/blackip.sh
sudo chmod +x /etc/init.d/blackip.sh
sudo /etc/init.d/blackip.sh
```
Cron task:
```
sudo crontab -e
@weekly /etc/init.d/blackip.sh
```
Verifique la ejecución/Check execution: /var/log/syslog.log:
```
Blackip for Ipset: 14/06/2016 15:47:14
```
Agregue la regla **Ipset** a su script de iptables/Add the rule **Ipset** to your iptables script:
```
ipset=/sbin/ipset
iptables=/sbin/iptables
route=/etc/acl
zone=/etc/zones

# BLACKZONE RULE (select country to block and ip/range)
$ipset -F
$ipset -N -! blackzone hash:net maxelem 1000000
 for ip in $(cat $route/blackips.txt); do
  $ipset -A blackzone $ip
 done
$iptables -t mangle -A PREROUTING -m set --match-set blackzone src -j DROP
$iptables -A FORWARD -m set --match-set blackzone dst -j DROP
```
Puede bloquear rangos completos de países/You can block entire countries ranges (e.g. China, Rusia, etc):
```
for ip in $(cat $zone/{cn,ru}.zone $route/blackips); do
```
Para mayor información visite/For more information visit [IPDeny] (http://www.ipdeny.com/ipblocks/).

En caso de error o conflicto/In case of error or conflict **Ipset** con/with **iptables**:
```
sudo ipset flush blackzone
o
sudo ipset flush
```

### Edición/Edit

Edite la alc **blackip** para agregarle las IPs que quiera bloquear con **Ipset**, que no se encuentren incluidas (se recomienda bloquear rangos de [IPs Privadas] (https://es.wikipedia.org/wiki/Red_privada) que no vaya a utilizar). Puede excluir IPs con la acl [whiteip] (https://github.com/maravento/whiteip/raw/master/whiteip.txt)

Edit alc **blackip** to add the IPs you want to lock with ipset, which are not included (recommended block ranges [Private IP] (https://es.wikipedia.org/wiki/Red_privada) not to be used) . You can exclude IPs with the acl [whiteip] (https://github.com/maravento/whiteip/raw/master/whiteip.txt).

### Important

- El uso excesivo de los programas, reglas y ACLs descritas, pueden llevar al colapso de su sistema, debido a la gran cantidad de recursos que consumen. Úselas con moderación.
- Blackip solo da soporte IPv4
- La ruta usadas por **blackip.sh** para almacenar las ACLs (route=/etc/acl) es opcional. Reemplace el path por su elección.
- Si cuenta con pocos recursos de servidor y utiliza un proxy no-transparente basado en [Squid-Cache] (http://www.squid-cache.org/), en reemplazo de Blackip, puede utilizar el proyecto [Whiteip] (http://www.maravento.com/p/whiteip.html). No se recomienda usar ambos proyectos al tiempo en el mismo servidor (doble filtrado)
- Si usa rangos completos de IPs (CIDR) para realizar bloqueos, tenga especial cuidado de no generar conflictos de IPs en la misma lista.


- Overuse of programs, rules and ACLs described, can lead to collapse of its system due to the large amount of resources they consume. Use them sparingly.
- Blackip only supports IPv4
- The route used by blackip.sh to store ACLs (route = / etc / acl) is optional. Replace path by your choice.
- If you have limited resources and server uses a non-transparent proxy based on [Squid-Cache] (http://www.squid-cache.org/), replacing Blackip, you can use the [Whiteip] project ( http://www.maravento.com/p/whiteip.html). It is not recommended to use both projects at the same time on the same server (double filtering)
- If using full IP ranges (CIDR) for locks, take special care to avoid conflicts of IPs on the same list.

### Data sheet (BLs IPs incluidas)

[IPDeny] (http://www.ipdeny.com/ipblocks/)

[Zeustracker] (https://zeustracker.abuse.ch/blocklist.php?download=badips)

[Ransomwaretracker] (https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)

[TOR exit addresses] (https://check.torproject.org/exit-addresses)

[BL Myip] (https://myip.ms/files/blacklist/general/full_blacklist_database.zip)

[Firehold] (https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset)

[Greensnow] (http://blocklist.greensnow.co/greensnow.txt)

[Blocklist] (https://lists.blocklist.de/lists/all.txt)

[OpenBL] (https://www.openbl.org/lists/base.txt)

[Cinsscore] (http://cinsscore.com/list/ci-badguys.txt)

[Spamhaus] (https://www.spamhaus.org/drop/drop.lasso)

[Rulez BruteForceBlocker] (http://danger.rulez.sk/projects/bruteforceblocker/blist.php)

[Emergingthreats] (http://rules.emergingthreats.net/blockrules/compromised-ips.txt)

[Project Honeypot] (http://www.projecthoneypot.org/list_of_ips.php)

[Maxmind] (https://www.maxmind.com/es/proxy-detection-sample-list)

[StopForumSpam] (https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt)

[Feodo Tracker] (https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)

[Malc0de IP Blacklist] (http://malc0de.com/bl/IP_Blacklist.txt)

**Own lists (inside project)**

[whiteurls] (https://github.com/maravento/blackweb/raw/master/whiteurls.txt)

[whiteip] (https://github.com/maravento/whiteip/raw/master/whiteip.txt)

[blackip] (https://github.com/maravento/blackip/raw/master/blackip.txt)

### Licence

[GPL-3.0] (https://www.gnu.org/licenses/gpl-3.0.en.html)

This Project is educational purposes. Este proyecto es con fines educativos. Agradecemos a todos aquellos que han contribuido a este proyecto. We thank all those who contributed to this project. Special thanks to [novatoz.com] (http://www.novatoz.com)

© 2016 [Gateproxy] (http://www.gateproxy.com) by [maravento] (http://www.maravento.com)

#### Disclaimer

Este script puede dañar su sistema si se usa incorrectamente. Úselo bajo su propio riesgo. This script can damage your system if used incorrectly. Use it at your own risk. [HowTO Gateproxy] (https://goo.gl/ZT4LTi)
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
