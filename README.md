## [Blackip] (http://www.maravento.com/p/blackip.html)

<a target="_blank" href=""><img src="https://img.shields.io/badge/Development-ALPHA-blue.svg"></a>

[Blackip] (http://www.maravento.com/p/blackip.html) es una lista negra (blacklist) de IPs IPv4. El script descarga listas negras públicas y listas de IPs para bloquear zonas geográficas de [IPDeny] (http://www.ipdeny.com/ipblocks/) para el módulo [IPSET] (http://ipset.netfilter.org/) de [Iptables] (http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html), ambos de [Netfilter] (http://www.netfilter.org/). Este módulo nos permite realizar filtrado masivo (Vea [Filtrado por Geolocalización] (http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark] (http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).

[Blackip] (http://www.maravento.com/p/blackip.html) is a blacklist of IPv4 IPs. The script downloads public blacklists and IP lists to block geographic zones of [IPDeny] (http://www.ipdeny.com/ipblocks/) for the [IPSET] module (http://ipset.netfilter.org/) From [Iptables] (http://www.netfilter.org/documentation/HOWTO/en/packet-filtering-HOWTO-7.html), both from [Netfilter] (http://www.netfilter.org/). This module allows us to perform mass filtering (See [Geolocation Filtering] (http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), at a processing speed far superior to other Solutions (See the [benchmark] (http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).

### Descripción/Description

|File|BL IPs|
|----|------|
|blackip.txt|4.847.688|

### Dependencias/Dependencies

```
git ipset iptables bash tar zip wget
```

### Modo de uso/How to use

Descarga/Download:
```
git clone https://github.com/maravento/blackip.git
```
Copie el script y ejecútelo/Copy the script and run:
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
 for ip in $(cat $route/blackip.txt); do
  $ipset -A blackzone $ip
 done
$iptables -t mangle -A PREROUTING -m set --match-set blackzone src -j DROP
$iptables -A FORWARD -m set --match-set blackzone dst -j DROP
```
Puede bloquear rangos completos de países/You can block entire countries ranges (e.g. China, Rusia, etc):
```
for ip in $(cat $zone/{cn,ru}.zone $route/blackip.txt); do
```
Para mayor información visite/For more information visit [IPDeny] (http://www.ipdeny.com/ipblocks/).

En caso de error o conflicto/In case of error or conflict **Ipset** con/with **iptables**:
```
sudo ipset flush blackzone
o
sudo ipset flush
```
### Importante/Important

- El uso excesivo de los programas, reglas y ACLs descritas, pueden llevar al colapso de su sistema, debido a la gran cantidad de recursos que consumen. Úselas con moderación / Overuse of programs, rules and ACLs described, can lead to collapse of its system due to the large amount of resources they consume. Use them sparingly
- Blackip solo da soporte a IPs IPv4 / Blackip only supports IPs IPv4
- La ruta usadas por **blackip.sh** para almacenar las ACLs (route=/etc/acl) es opcional. Reemplace el path por su elección / The route used by blackip.sh to store ACLs (route = /etc/acl) is optional. Replace path by your choice.
- Si cuenta con pocos recursos de servidor y utiliza un proxy no-transparente basado en [Squid-Cache] (http://www.squid-cache.org/), en reemplazo de Blackip, puede utilizar el proyecto [Whiteip] (http://www.maravento.com/p/whiteip.html). No se recomienda usar ambos proyectos al tiempo en el mismo servidor (doble filtrado) / If you have limited resources and server uses a non-transparent proxy based on [Squid-Cache] (http://www.squid-cache.org/), replacing Blackip, you can use the [Whiteip] (http://www.maravento.com/p/whiteip.html) project. It is not recommended to use both projects at the same time on the same server (double filtering)

### Lista propia/Own list

Puede incluir su propia Blacklist IPs, que quiera bloquear con **Ipset**, y que no se encuentre en **blackip.txt**, editando **blackip.sh** y descomentando en **ADD OWN LIST** la línea **/path/blackip_own.txt** y reemplazandola por la ruta hacia su propia lista / You can include your own Blacklist IPs, which you want to block with **Ipset**, and that is not on **blackip.txt**, editing **blackip.sh** and uncommenting in **ADD OWN LIST** line **/path/blackip_own.txt** and replacing it with the path to your own list

### IPs vs CIDR

Blackip es una acl que solo incluye IPs. Si va a incluir rangos CIDR (dentro de **blackip.txt** o en su propia lista **blackip_own.txt**), para evitar conflictos IPs vs CIDR, utilice el bash script **cleancidr.sh**. También se recomienda excluir los rangos [RFC1918] (https://es.wikipedia.org/wiki/Red_privada) / Blackip is an acl that only includes IPs. If you are going to include CIDR ranges (within **blackip.txt** or in your own list **blackip_own.txt**), to avoid IPs vs. CIDR conflicts, use the bash script **cleancidr.sh**. It is also recommended to exclude the ranges [RFC1918] (https://es.wikipedia.org/wiki/Red_private)

#### Depurando conflictos CIDR/Debugging conflicts CIDR

- Unir las listas (**blackip.txt**, **RFC1918.txt** and **blackip_own.txt**), ejecutar **cleancidr.sh** y el resultado es **clearcidr.txt**  / Join the lists (**blackip.txt**, **RFC1918.txt** and **blackip_own.txt**), run **cleancidr.sh** and result is **clearcidr.txt**
- Elimine los rangos privados CIDR [RFC1918] (https://es.wikipedia.org/wiki/Red_privada) / Delete private ranges CIDR  [RFC1918] (https://es.wikipedia.org/wiki/Red_private)

```
cat blackip.txt blackip_own.txt RFC1918.txt > capture.txt && chmod +x clearcidr.sh && ./clearcidr.sh capture.txt
cat RFC1918.txt | while read output; do
  sed -i "\|$output|d" cidrclean.txt && sort -u cidrclean.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > blackip.txt
done
```
El proceso de depuración de conflictos IPs/CIDR consume gran cantidad de recursos de hardware durante el procesamiento y puede tomar más de 24 horas / The IPs/CIDR Debugging Process consumes a large amount of hardware resources during processing and can take more than 24 hours

### Data sheet (BLs IPs including)

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

[The LashBack UBL] (http://www.unsubscore.com/blacklist.txt)

[MyIP BL] (https://myip.ms/files/blacklist/general/latest_blacklist.txt)

[Open BL] (http://www.openbl.org/lists/base.txt)

[Project Honeypot] (https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)

**Own lists (inside project)**

[RFC1918] (https://github.com/maravento/blackip/raw/master/RFC1918.txt)

[blackip] (https://github.com/maravento/blackip/raw/master/blackip.tar.gz)

### Licence

[GPL-3.0] (https://www.gnu.org/licenses/gpl-3.0.en.html)

This Project is educational purposes. Este proyecto es con fines educativos. Agradecemos a todos aquellos que han contribuido a este proyecto. We thank all those who contributed to this project. Special thanks to [novatoz.com] (http://www.novatoz.com)

© 2016 [Gateproxy] (http://www.gateproxy.com) by [maravento] (http://www.maravento.com)

#### Disclaimer

Este script puede dañar su sistema si se usa incorrectamente. Úselo bajo su propio riesgo. This script can damage your system if used incorrectly. Use it at your own risk. [HowTO Gateproxy] (https://goo.gl/ZT4LTi)
