# [BlackIP](https://www.maravento.com/p/blackip.html)

<!-- markdownlint-disable MD033 -->

[![status-stable](https://img.shields.io/badge/status-stable-green.svg)](https://github.com/maravento/blackip)
[![last commit](https://img.shields.io/github/last-commit/maravento/blackip)](https://github.com/maravento/blackip)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/maravento/blackip)
[![Twitter Follow](https://img.shields.io/twitter/follow/maraventostudio.svg?style=social)](https://twitter.com/maraventostudio)

<table align="center">
  <tr>
    <td align="center">
      <a href="README.md">English</a> | <span>Español</span>
    </td>
  </tr>
</table>

BlackIP es un proyecto que recopila y unifica listas públicas de bloqueo de direcciones IPs, para hacerlas compatibles con [Squid](http://www.squid-cache.org/) e [IPSET](http://ipset.netfilter.org/) ([Iptables](http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html) [Netfilter](http://www.netfilter.org/)).

## DATA SHEET

---

| ACL | Blocked IP | File Size |
| :---: | :---: | :---: |
| blackip.txt | 470504 | 6,7 Mb |

## GIT CLONE

---

```bash
git clone --depth=1 https://github.com/maravento/blackip.git
```

## HOW TO USE

---

`blackip.txt` ya viene optimizada. Descárguela y descomprimala en la ruta de su preferencia.

### Download

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz && cat blackip.tar.gz* | tar xzf -
```

### Checksum

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz && cat blackip.tar.gz* | tar xzf -
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.txt.sha256
LOCAL=$(sha256sum blackip.txt | awk '{print $1}'); REMOTE=$(awk '{print $1}' blackip.txt.sha256); echo "$LOCAL" && echo "$REMOTE" && [ "$LOCAL" = "$REMOTE" ] && echo OK || echo FAIL
```

#### Important about BlackIP

- No debe utilizar `blackip.txt` en [IPSET](http://ipset.netfilter.org/) y en [Squid](http://www.squid-cache.org/) al mismo tiempo (doble filtrado).
- `blackip.txt` es una lista IPv4. No incluye CIDR.

### [Ipset/Iptables](http://ipset.netfilter.org/) Rules

Edite su bash script de Iptables y agregue las siguientes líneas (ejecutar con privilegios root):

```bash
#!/bin/bash
# https://linux.die.net/man/8/ipset

# Replace with your path to blackip.txt
ips=/path_to_lst/blackip.txt

# ipset rules
ipset -L blackip >/dev/null 2>&1
if [ $? -ne 0 ]; then
        echo "set blackip does not exist. create set..."
        ipset -! create blackip hash:net family inet hashsize 1024 maxelem 10000000
    else
        echo "set blackip exist. flush set..."
        ipset -! flush blackip
fi
ipset -! save > /tmp/ipset_blackip.txt
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
ipset -! restore < /tmp/ipset_blackip.txt

# iptables rules
iptables -t raw -I PREROUTING -m set --match-set blackip src -j DROP
iptables -t raw -I PREROUTING -m set --match-set blackip dst -j DROP
iptables -t raw -I OUTPUT -m set --match-set blackip dst -j DROP
echo "done"
```

#### Ipset/Iptables Rules with IPDeny (Optional)

Puede agregar las siguientes líneas al bash anterior para incluir rangos de IPs completos de países con [IPDeny](https://www.ipdeny.com/ipblocks/) agregando los países de su elección.

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

- Ipset permite realizar filtrado masivo, a una velocidad de procesamiento muy superior a otras soluciones (consulte [benchmark](https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/)).
- Blackip es una lista que contiene millones de líneas IPv4 y para ser soportada por Ipset, hemos tenido que aumentar arbitrariamente el parámetro [maxelem](https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is) (para más información, consulte [ipset's hashsize and maxelem parameters](https://www.odi.ch/weblog/posting.php?posting=738)).
- Limitación de Ipset/iptables: "*Cuando las entradas agregadas por el objetivo SET de iptables/ip6tables, el tamaño del hash es fijo y el conjunto no se duplicará, incluso si la nueva entrada no se puede agregar al conjunto*" (para más información, consulte [Man Ipset](https://ipset.netfilter.org/ipset.man.html)).
- El uso intensivo de estas reglas puede ralentizar su PC al punto de hacerlo colapsa. Úselas bajo su propio riesgo.
- Probado en: iptables v1.8.7, ipset v7.15, protocol version: 7.

### [Squid](http://www.squid-cache.org/) Rule

Edit:

```bash
/etc/squid/squid.conf
```

Y agregue las siguientes líneas:

```bash
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS

# Block Rule for BlackIP
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip
```

#### About Squid Rule

- `blackip.txt` ha sido testeada en Squid v3.5.x y posteriores.

#### Advanced Rules

BlackIP contiene millones de direcciones IP, por tanto se recomienda:

- Use `blackcidr.txt` para agregar IP/CIDR que no están incluidas en `blackip.txt` (Por defecto contiene algunos Block CIDR).
- Use `allowip.txt` (una lista blanca de direcciones IPs IPv4 tales como Hotmail, Gmail, Yahoo. etc).
- Use `aipextra.txt` para agregar listas blancas de IP/CIDR que no están incluidas en `allowip.txt`.
- Por defecto, `blackip.txt` excluye algunos rangos privados o reservados [RFC1918](https://es.wikipedia.org/wiki/Red_privada). Use IANA (`iana.txt`) para excluirlos todos.
- Por defecto, `blackip.txt` excluye algunos servidores DNS incluidos en `dns.txt`. Puede usar esta lista y ampliarla, para denegar o permitir servidores DNS.
- Para incrementar la seguridad, cierre Squid a cualquier otra petición a direcciones IP con ZTR.

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

## Block IP
acl no_ip url_regex -i ^(http|https)://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
http_access deny no_ip
```

## BLACKIP UPDATE

---

### ⚠️ WARNING: BEFORE YOU CONTINUE

Esta sección es únicamente para explicar cómo funciona el proceso de actualización y optimización. No es necesario que el usuario la ejecute. Este proceso puede tardar y consumir muchos recursos de hardware y ancho de banda, por tanto se recomienda usar equipos de pruebas.

#### Bash Update

>El proceso de actualización de `blackip.txt` es ejecutado en secuencia por el script `bipupdate.sh`. El script solicitará privilegios cuando lo requiera.

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && chmod +x bipupdate.sh && ./bipupdate.sh
```

#### Dependencies

>La actualización requiere python 3x y bash 5x

```bash
wget git curl idn2 perl tar rar unrar unzip zip python-is-python3 ipset squid
```

#### Capture Public Blocklists

>Captura las IPv4 de las listas de bloqueo públicas descargadas (ver [FUENTES](https://github.com/maravento/blackip#sources)) y las unifica en un solo archivo.

#### DNS Loockup

>La mayoría de las [FUENTES](https://github.com/maravento/blackip#sources) contienen millones de IP inválidas e inexistentes. Entonces se hace una verificación doble de cada IP (en 2 pasos) vía DNS y los inválidos e inexistentes se excluyen de Blackip. Este proceso puede tardar. Por defecto procesa en paralelo ≈ 6k a 12k x min, en dependencia del hardware y ancho de banda.

```bash
HIT 8.8.8.8
Host 8.8.8.8.in-addr.arpa domain name pointer dns.google
FAULT 0.0.9.1
Host 1.9.0.0.in-addr.arpa. not found: 3(NXDOMAIN)
```

#### Run Squid-Cache with BlackIP

>Corre Squid-Cache con BlackIP y cualquier error lo envía a `SquidError.txt` en su escritorio.

#### Check execution (/var/log/syslog)

```bash
BlackIP: Done 02/02/2024 15:47:14
```

#### Important about BlackIP Update

- `tw.txt` contiene IPs de servidores teamviewer. Por defecto están comentadas. Para bloquearlas o autorizarlas activelas en `bipupdate.sh`. Para actualizarla use `tw.sh`.
- Antes de utilizar `bipupdate.sh` debe activar las reglas en [Squid](http://www.squid-cache.org/).
- Algunas listas tienen restricciones de descarga, entonces no ejecute `bipupdate.sh` más de una vez al día.
- Durante la ejecución de `bipupdate.sh` solicitará privilegios cuando los necesite.
- Si usa `aufs`, cámbielo temporalmente a `ufs` durante la actualización, para evitar: `ERROR: Can't change type of existing cache_dir aufs /var/spool/squid to ufs. Restart required`.

#### AllowIP Update

>`allowip.txt` ya esta actualizada y optimizada. El proceso de actualización de `allowip.txt` es ejecutado en secuencia por el script `aipupdate.sh`.

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
- [duggytuxy - Data-Shield_IPv4_Blocklist](https://github.com/duggytuxy/Data-Shield_IPv4_Blocklist)
- [duggytuxy - Intelligence_IPv4_Blocklist](https://github.com/duggytuxy/Intelligence_IPv4_Blocklist/blob/main/agressive_ips_dst_fr_be_blocklist.txt)
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
- [romainmarcoux - malicious-ip](https://github.com/romainmarcoux/malicious-ip/blob/main/full-aa.txt)
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

## NOTICE

---

- Este proyecto incluye componentes de terceros.
- Los cambios deben proponerse mediante Issues. No se aceptan Pull Requests.
- Blackip no es un servicio de listas negras como tal. No verifica de forma independiente las direcciones IP. Su función es consolidar y formatear listas negras públicas para hacerlas compatibles con Squid/Iptables/Ipset.
- Si su dirección IP aparece en Blackip, y considera que esto es un error, debe revisar las fuentes públicas [SOURCES](https://github.com/maravento/blackip/blob/master/README-es.md#sources), identificar en cuál(es) aparece, y contactar al responsable de dicha lista para solicitar su eliminación. Una vez que la dirección IP sea eliminada en la fuente original, desaparecerá automáticamente de Blackip en la siguiente actualización.

## STARGAZERS

---

[![Stargazers](https://bytecrank.com/nastyox/reporoster/php/stargazersSVG.php?user=maravento&repo=blackip)](https://github.com/maravento/blackip/stargazers)

## CONTRIBUTIONS

---

Agradecemos a todos aquellos que han contribuido a este proyecto. Los interesados pueden contribuir, enviándonos enlaces de nuevas "Blocklist", para ser incluidas en este proyecto.

Special thanks to: [Jhonatan Sneider](https://github.com/sney2002)

## SPONSOR THIS PROJECT

---

[![Image](https://raw.githubusercontent.com/maravento/winexternal/master/img/maravento-paypal.png)](https://paypal.me/maravento)

## PROJECT LICENSES

---

[![GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl.txt)
[![CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.en)

## DISCLAIMER

---

EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O IMPLÍCITA, INCLUYENDO, ENTRE OTRAS, LAS GARANTÍAS DE COMERCIABILIDAD, IDONEIDAD PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO LOS AUTORES O TITULARES DE LOS DERECHOS DE AUTOR SERÁN RESPONSABLES DE NINGUNA RECLAMACIÓN, DAÑO U OTRA RESPONSABILIDAD, YA SEA EN UNA ACCIÓN CONTRACTUAL, EXTRACONTRACTUAL O DE OTRO MODO, QUE SURJA DE, A PARTIR DE O EN CONEXIÓN CON EL SOFTWARE O EL USO U OTRAS OPERACIONES EN EL SOFTWARE.

## OBJECTION

---

Debido a los recientes cambios arbitrarios en la terminología informática, es necesario aclarar el significado y connotación del término **blacklist**, asociado a este proyecto:

*En informática, una lista negra, lista de denegación o lista de bloqueo es un mecanismo básico de control de acceso que permite a través de todos los elementos (direcciones de correo electrónico, usuarios, contraseñas, URL, direcciones IP, nombres de dominio, hashes de archivos, etc.), excepto los mencionados explícitamente. Esos elementos en la lista tienen acceso denegado. Lo opuesto es una lista blanca, lo que significa que solo los elementos de la lista pueden pasar por cualquier puerta que se esté utilizando.* Fuente [Wikipedia](https://en.wikipedia.org/wiki/Blacklist_(computing))

Por tanto, **blacklist**, **blocklist**, **blackweb**, **blackip**, **whitelist** y similares, son términos que no tienen ninguna relación con la discriminación racial.
