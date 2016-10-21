## [Blackip] (http://www.maravento.com/p/blackip.html)

<a target="_blank" href=""><img src="https://img.shields.io/badge/Development-ALPHA-blue.svg"></a>

[Blackip] (http://www.maravento.com/p/blackip.html) es una lista negra (blacklist) de IPs/CIDR, que contiene sitios porno, descargas, drogas, malware, spyware, trackers, bots, redes sociales, warez, venta de armas, etc, y adicionalmente puede incluirle IPs/CIDR para bloquear zonas geográficas. 

El script incluido descarga varias listas negras públicas, tales como las "geozones" de [IPDeny] (http://www.ipdeny.com/ipblocks/), entre otras, y las compila en una sola megalista resultante, la cual es filtrada con una lista blanca (whitelist) para eliminar falsos positivos y finalmente ser utilizada con el módulo [IPSET] (http://ipset.netfilter.org/) para [Iptables] (http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html), ambos de [Netfilter] (http://www.netfilter.org/). Este módulo nos permite realizar filtrado masivo (Vea [Filtrado por Geolocalización] (http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html)), a una velocidad de procesamiento muy superior a otras soluciones (Vea el [benchmark] (http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).

### Dependencias

```
ipset bash
```

### Modo de Uso

Descargue el repositorio **Blackip**, copie el script a **init.d** y ejecútelo:
```
git clone https://github.com/maravento/blackip.git
sudo cp -f blackip/blackip.sh /etc/init.d
sudo chown root:root /etc/init.d/blackip.sh
sudo chmod +x /etc/init.d/blackip.sh
sudo /etc/init.d/blackip.sh
```
Puede programar su ejecución semanal en el **cron**:
```
sudo crontab -e
@weekly /etc/init.d/blackip.sh
```
Verifique la ejecución programada del script en **/var/log/syslog.log**. Ejemplo:
```
Blackip for Ipset: ejecucion 14/06/2016 15:47:14
```
Agregue la siguiente regla **Ipset** a su script de iptables:
```
# Parametros
ipset=/sbin/ipset
iptables=/sbin/iptables
route=/etc/acl #la ruta es a criterio del usuario
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
Adicionalmente puede bloquear rangos completos de países (ej: China, Rusia, etc), reemplazando la línea "for ip..." por:
```
for ip in $(cat $zone/{cn,ru}.zone $route/blackips); do
```
Para mayor información sobre cómo añadir más países para bloquear, visite [IPDeny] (http://www.ipdeny.com/ipblocks/).

Si se presenta algún error y/o conflicto con **Ipset** durante la ejecución del script de **iptables**, se recomienda vaciar la zona creada:
```
sudo ipset flush blackzone
o
sudo ipset flush
```

### Edición

Puede editar manualmente la alc **blackip** y agregarle las IPs que quiera bloquear con **Ipset** y que no se encuentren incluidas en **blackip**. Adicionalmente, se recomienda bloquear rangos de [IPs Privadas] (https://es.wikipedia.org/wiki/Red_privada) que no vaya a utilizar dentro de su red local. También puede excluir IPs en la acl **whiteip**

Si ya tiene su propia lista negra de IPs, unifiquela con blackip, descomentando en el script "ADD OWN LIST" y reemplazando la línea **/ruta/blacklist_propia.txt** por la ruta a su lista.

### Importante

- El uso excesivo de los programas, reglas y ACLs descritas, pueden llevar al colapso de su sistema, debido a la gran cantidad de recursos que consumen. Úselas con moderación.
- Blackip solo da soporte IPv4
- La ruta usadas por **blackip.sh** para almacenar las ACLs (route=/etc/acl) es opcional. Reemplace el path por su elección.
- Si cuenta con pocos recursos de servidor y utiliza un proxy no-transparente basado en [Squid-Cache] (http://www.squid-cache.org/), en reemplazo de Blackip, puede utilizar el proyecto [Whiteip] (http://www.maravento.com/p/whiteip.html). No se recomienda usar ambos proyectos al tiempo en el mismo servidor (doble filtrado)
- Si usa rangos completos de IPs (CIDR) para realizar bloqueos, tenga especial cuidado de no generar conflictos de IPs en la misma lista.

### Ficha Técnica (BLs IPs incluidas)

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

blackip

### Legal

This Project is educational purposes. Este proyecto es con fines educativos. Agradecemos a todos los que han contribuido a este proyecto, en especial a [Netfilter] (http://www.netfilter.org/) y [novatoz.com] (http://www.novatoz.com)

© 2016 [Blackip] (http://www.maravento.com/p/blackip.html) por [maravento] (http://www.maravento.com), es un componente del proyecto [Gateproxy] (http://www.gateproxy.com)
