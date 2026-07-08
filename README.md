# [BlackIP](https://www.maravento.com/p/blackip.html)

[![status-maintained](https://img.shields.io/badge/status-maintained-purple.svg)](https://github.com/maravento/blackip)
[![last commit](https://img.shields.io/github/last-commit/maravento/blackip)](https://github.com/maravento/blackip)
[![Twitter Follow](https://img.shields.io/twitter/follow/maraventostudio.svg?style=social)](https://twitter.com/maraventostudio)

<!-- markdownlint-disable MD033 -->

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <b>BlackIP</b> is a project that collects and unifies public blocklists of IP addresses, to make them compatible with <a href="http://www.squid-cache.org/" target="_blank">Squid</a> and <a href="http://ipset.netfilter.org/" target="_blank">IPSET</a> (<a href="http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html" target="_blank">Iptables</a> <a href="http://www.netfilter.org/" target="_blank">Netfilter</a>).
    </td>
    <td style="width: 50%; vertical-align: top;">
      <b>BlackIP</b> es un proyecto que recopila y unifica listas públicas de bloqueo de direcciones IP, para hacerlas compatibles con <a href="http://www.squid-cache.org/" target="_blank">Squid</a> e <a href="http://ipset.netfilter.org/" target="_blank">IPSET</a> (<a href="http://www.netfilter.org/documentation/HOWTO/es/packet-filtering-HOWTO-7.html" target="_blank">Iptables</a> <a href="http://www.netfilter.org/" target="_blank">Netfilter</a>).
    </td>
  </tr>
</table>

## DATA SHEET

---

| ACL | Blocked IP | File Size |
| :---: | :---: | :---: |
| blackip.txt | 448906 | 6,3 Mb |

## GIT CLONE

---

```bash
git clone --depth=1 https://github.com/maravento/blackip.git
```

## HOW TO USE

---

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <code>blackip.txt</code> is already optimized. Download it and unzip it in the path of your preference.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>blackip.txt</code> ya viene optimizada. Descárguela y descomprímala en la ruta de su preferencia.
    </td>
  </tr>
</table>

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

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Should not be used <code>blackip.txt</code> in <a href="http://ipset.netfilter.org/" target="_blank">IPSET</a> and in <a href="http://www.squid-cache.org/" target="_blank">Squid</a> at the same time (double filtrate).</li>
        <li><code>blackip.txt</code> is a list IPv4. Does not include CIDR.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>No debe utilizar <code>blackip.txt</code> en <a href="http://ipset.netfilter.org/" target="_blank">IPSET</a> y en <a href="http://www.squid-cache.org/" target="_blank">Squid</a> al mismo tiempo (doble filtrado).</li>
        <li><code>blackip.txt</code> es una lista IPv4. No incluye CIDR.</li>
      </ul>
    </td>
  </tr>
</table>

### [Ipset/Iptables](http://ipset.netfilter.org/) Rules

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Edit your Iptables bash script and add the following lines (run with root privileges):
    </td>
    <td style="width: 50%; vertical-align: top;">
      Edite su bash script de Iptables y agregue las siguientes líneas (ejecutar con privilegios root):
    </td>
  </tr>
</table>

```bash
#!/bin/bash
# https://linux.die.net/man/8/ipset
# dependencie: sudo apt install ipset

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
iptables -t raw -I OUTPUT     -m set --match-set blackip dst -j DROP
echo "done"
```

#### Ipset/Iptables Rules with IPDeny (Optional)

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      You can add the following lines to the bash above to include full country IP ranges with <a href="https://www.ipdeny.com/ipblocks/" target="_blank">IPDeny</a> adding the countries of your choice.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Puede agregar las siguientes líneas al bash anterior para incluir rangos de IPs completos de países con <a href="https://www.ipdeny.com/ipblocks/" target="_blank">IPDeny</a> agregando los países de su elección.
    </td>
  </tr>
</table>

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

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Ipset allows mass filtering, at a much higher processing speed than other solutions (check <a href="https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/" target="_blank">benchmark</a>).</li>
        <li>Blackip is a list containing millions of IPv4 lines and to be supported by Ipset, we had to arbitrarily increase the parameter <a href="https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is" target="_blank">maxelem</a> (for more information, check <a href="https://www.odi.ch/weblog/posting.php?posting=738" target="_blank">ipset's hashsize and maxelem parameters</a>).</li>
        <li>Ipset/iptables limitation: "<i>When entries added by the SET target of iptables/ip6tables, then the hash size is fixed and the set won't be duplicated, even if the new entry cannot be added to the set</i>" (for more information, check <a href="https://ipset.netfilter.org/ipset.man.html" target="_blank">Man Ipset</a>).</li>
        <li>Heavy use of these rules can slow down your PC to the point of crashing. Use them at your own risk.</li>
        <li>Tested on iptables v1.8.7, ipset v7.15, protocol version: 7.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Ipset permite realizar filtrado masivo, a una velocidad de procesamiento muy superior a otras soluciones (consulte <a href="https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/" target="_blank">benchmark</a>).</li>
        <li>Blackip es una lista que contiene millones de líneas IPv4 y para ser soportada por Ipset, hemos tenido que aumentar arbitrariamente el parámetro <a href="https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is" target="_blank">maxelem</a> (para más información, consulte <a href="https://www.odi.ch/weblog/posting.php?posting=738" target="_blank">ipset's hashsize and maxelem parameters</a>).</li>
        <li>Limitación de Ipset/iptables: "<i>Cuando las entradas agregadas por el objetivo SET de iptables/ip6tables, el tamaño del hash es fijo y el conjunto no se duplicará, incluso si la nueva entrada no se puede agregar al conjunto</i>" (para más información, consulte <a href="https://ipset.netfilter.org/ipset.man.html" target="_blank">Man Ipset</a>).</li>
        <li>El uso intensivo de estas reglas puede ralentizar su PC al punto de hacerlo colapsar. Úselas bajo su propio riesgo.</li>
        <li>Probado en: iptables v1.8.7, ipset v7.15, protocol version: 7.</li>
      </ul>
    </td>
  </tr>
</table>

### [Squid](http://www.squid-cache.org/) Rule

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Edit:
    </td>
    <td style="width: 50%; vertical-align: top;">
      Edite:
    </td>
  </tr>
</table>

```bash
/etc/squid/squid.conf
```

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      And add the following lines:
    </td>
    <td style="width: 50%; vertical-align: top;">
      Y agregue las siguientes líneas:
    </td>
  </tr>
</table>

```bash
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS

# Block Rule for BlackIP
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip
```

#### About Squid Rule

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <code>blackip.txt</code> has been tested in Squid v3.5.x and later.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>blackip.txt</code> ha sido testeada en Squid v3.5.x y posteriores.
    </td>
  </tr>
</table>

#### Advanced Rules

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      BlackIP contains millions of IP addresses, therefore it is recommended:
      <ul>
        <li>Use <code>blackcidr.txt</code> to add IP/CIDR that are not included in <code>blackip.txt</code> (By default it contains some Block CIDR).</li>
        <li>Use <code>allowip.txt</code> (a whitelist of IPv4 IP addresses such as Hotmail, Gmail, Yahoo. etc.).</li>
        <li>Use <code>aipextra.txt</code> to add whitelists of IP/CIDRs that are not included in <code>allowip.txt</code>.</li>
        <li>By default, <code>blackip.txt</code> excludes some private or reserved ranges <a href="https://en.wikipedia.org/wiki/Private_network" target="_blank">RFC1918</a>. Use IANA (<code>iana.txt</code>) to exclude them all.</li>
        <li>By default, <code>blackip.txt</code> excludes some DNS servers included in <code>dns.txt</code>. You can use this list and expand it to deny or allow DNS servers.</li>
        <li>To increase security, close Squid to any other request to IP addresses with ZTR.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      BlackIP contiene millones de direcciones IP, por tanto se recomienda:
      <ul>
        <li>Use <code>blackcidr.txt</code> para agregar IP/CIDR que no están incluidas en <code>blackip.txt</code> (Por defecto contiene algunos Block CIDR).</li>
        <li>Use <code>allowip.txt</code> (una lista blanca de direcciones IPv4 tales como Hotmail, Gmail, Yahoo, etc).</li>
        <li>Use <code>aipextra.txt</code> para agregar listas blancas de IP/CIDR que no están incluidas en <code>allowip.txt</code>.</li>
        <li>Por defecto, <code>blackip.txt</code> excluye algunos rangos privados o reservados <a href="https://es.wikipedia.org/wiki/Red_privada" target="_blank">RFC1918</a>. Use IANA (<code>iana.txt</code>) para excluirlos todos.</li>
        <li>Por defecto, <code>blackip.txt</code> excluye algunos servidores DNS incluidos en <code>dns.txt</code>. Puede usar esta lista y ampliarla, para denegar o permitir servidores DNS.</li>
        <li>Para incrementar la seguridad, cierre Squid a cualquier otra petición a direcciones IP con ZTR.</li>
      </ul>
    </td>
  </tr>
</table>

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

# Block: Direct IPv4
acl direct_ipv4 dstdom_regex -n -i ^([0-9]{1,3}\.){3}[0-9]{1,3}$
http_access deny direct_ipv4
# Block: Direct IPv6
acl direct_ipv6 dstdom_regex -n -i ^\[([0-9a-f:]+)\]$
http_access deny direct_ipv6
```

## BLACKIP UPDATE

---

### ⚠️ WARNING: BEFORE YOU CONTINUE

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      This section is only to explain how the update and optimization process works. It is not necessary for the user to run it. This process can take time and consume a lot of hardware and bandwidth resources, therefore it is recommended to use test equipment.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Esta sección es únicamente para explicar cómo funciona el proceso de actualización y optimización. No es necesario que el usuario la ejecute. Este proceso puede tardar y consumir muchos recursos de hardware y ancho de banda, por tanto se recomienda usar equipos de pruebas.
    </td>
  </tr>
</table>

#### Bash Update

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      The update process of <code>blackip.txt</code> is executed in sequence by the script <code>bipupdate.sh</code>. The script will request privileges when required.
    </td>
    <td style="width: 50%; vertical-align: top;">
      El proceso de actualización de <code>blackip.txt</code> es ejecutado en secuencia por el script <code>bipupdate.sh</code>. El script solicitará privilegios cuando lo requiera.
    </td>
  </tr>
</table>

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && chmod +x bipupdate.sh && ./bipupdate.sh
```

#### Dependencies

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Update requires python 3x and bash 5x.
    </td>
    <td style="width: 50%; vertical-align: top;">
      La actualización requiere python 3x y bash 5x.
    </td>
  </tr>
</table>

```bash
pkgs='wget git curl tar unzip zip gzip idn2 grepcidr squid python3 bind9-host'
```

#### Capture Public Blocklists

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Capture IPv4 from downloaded public blocklists (see <a href="#sources">SOURCES</a>) and unify them in a single file.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Captura las IPv4 de las listas de bloqueo públicas descargadas (ver <a href="#sources">FUENTES</a>) y las unifica en un solo archivo.
    </td>
  </tr>
</table>

#### DNS Lookup

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Most of the <a href="#sources">SOURCES</a> contain millions of invalid and nonexistent IP. Then, a double check of each IP is done (in 2 steps) via DNS and invalid and nonexistent are excluded from Blackip. This process may take time. By default it processes in parallel ≈ 6k to 12k x min, depending on the hardware and bandwidth.
    </td>
    <td style="width: 50%; vertical-align: top;">
      La mayoría de las <a href="#sources">FUENTES</a> contienen millones de IP inválidas e inexistentes. Entonces se hace una verificación doble de cada IP (en 2 pasos) vía DNS y los inválidos e inexistentes se excluyen de Blackip. Este proceso puede tardar. Por defecto procesa en paralelo ≈ 6k a 12k x min, en dependencia del hardware y ancho de banda.
    </td>
  </tr>
</table>

```bash
HIT 8.8.8.8
Host 8.8.8.8.in-addr.arpa domain name pointer dns.google
FAULT 0.0.9.1
Host 1.9.0.0.in-addr.arpa. not found: 3(NXDOMAIN)
```

#### Run Squid-Cache with BlackIP

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Run Squid-Cache with BlackIP and any error sends it to <code>SquidError.txt</code> on your desktop.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Corre Squid-Cache con BlackIP y cualquier error lo envía a <code>SquidError.txt</code> en su escritorio.
    </td>
  </tr>
</table>

#### Log

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Both <code>bipupdate.sh</code> and <code>aipupdate.sh</code> generate a log file (<code>bipupdate.log</code> / <code>aipupdate.log</code>) in the same directory where they are executed.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>bipupdate.sh</code> y <code>aipupdate.sh</code> generan un archivo de log (<code>bipupdate.log</code> / <code>aipupdate.log</code>) en el mismo directorio donde se ejecutan.
    </td>
  </tr>
</table>

#### Important about BlackIP Update

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li><code>tw.txt</code> containing IPs of teamviewer servers. By default they are commented. To block or authorize them, activate them in <code>bipupdate.sh</code>. To update it use <code>tw.sh</code>.</li>
        <li>You must activate the rules in <a href="http://www.squid-cache.org/" target="_blank">Squid</a> before using <code>bipupdate.sh</code>.</li>
        <li>Some lists have download restrictions, so do not run <code>bipupdate.sh</code> more than once a day.</li>
        <li>During the execution of <code>bipupdate.sh</code> it will request privileges when needed.</li>
        <li>If you use <code>aufs</code>, temporarily change it to <code>ufs</code> during the upgrade, to avoid: <code>ERROR: Can't change type of existing cache_dir aufs /var/spool/squid to ufs. Restart required</code>.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li><code>tw.txt</code> contiene IPs de servidores teamviewer. Por defecto están comentadas. Para bloquearlas o autorizarlas actívelas en <code>bipupdate.sh</code>. Para actualizarla use <code>tw.sh</code>.</li>
        <li>Antes de utilizar <code>bipupdate.sh</code> debe activar las reglas en <a href="http://www.squid-cache.org/" target="_blank">Squid</a>.</li>
        <li>Algunas listas tienen restricciones de descarga, entonces no ejecute <code>bipupdate.sh</code> más de una vez al día.</li>
        <li>Durante la ejecución de <code>bipupdate.sh</code> solicitará privilegios cuando los necesite.</li>
        <li>Si usa <code>aufs</code>, cámbielo temporalmente a <code>ufs</code> durante la actualización, para evitar: <code>ERROR: Can't change type of existing cache_dir aufs /var/spool/squid to ufs. Restart required</code>.</li>
      </ul>
    </td>
  </tr>
</table>

#### AllowIP Update

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <code>allowip.txt</code> is already updated and optimized. The update process of <code>allowip.txt</code> is executed in sequence by the script <code>aipupdate.sh</code>.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>allowip.txt</code> ya está actualizada y optimizada. El proceso de actualización de <code>allowip.txt</code> es ejecutado en secuencia por el script <code>aipupdate.sh</code>.
    </td>
  </tr>
</table>

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/wlst/aipupdate.sh && chmod +x aipupdate.sh && ./aipupdate.sh
```

## SOURCES

---

### BLOCKLISTS

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

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>This project includes third-party components.</li>
        <li>Changes must be submitted via Issues. Pull requests are not accepted.</li>
        <li>Blackip is not a blacklist service itself. It does not independently verify IP addresses. Its purpose is to consolidate and reformat public blacklist sources to make them compatible with Squid/Iptables/Ipset.</li>
        <li>If your IP address is listed on Blackip and you believe this is an error, you should check the public sources in <a href="#sources">SOURCES</a>, identify which one(s) it appears in, and contact the person responsible for that list to request its removal. Once the IP address is removed from the original source, it will automatically disappear from Blackip with the next update.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Este proyecto incluye componentes de terceros.</li>
        <li>Los cambios deben proponerse mediante Issues. No se aceptan Pull Requests.</li>
        <li>Blackip no es un servicio de listas negras como tal. No verifica de forma independiente las direcciones IP. Su función es consolidar y formatear listas negras públicas para hacerlas compatibles con Squid/Iptables/Ipset.</li>
        <li>Si su dirección IP aparece en Blackip y considera que esto es un error, debe revisar las fuentes públicas en <a href="#sources">SOURCES</a>, identificar en cuál(es) aparece, y contactar al responsable de dicha lista para solicitar su eliminación. Una vez que la dirección IP sea eliminada en la fuente original, desaparecerá automáticamente de Blackip en la siguiente actualización.</li>
      </ul>
    </td>
  </tr>
</table>

## STARGAZERS

---

[![Stargazers](https://bytecrank.com/nastyox/reporoster/php/stargazersSVG.php?user=maravento&repo=blackip)](https://github.com/maravento/blackip/stargazers)

## CONTRIBUTIONS

---

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      We thank all those who contributed to this project. Those interested may contribute sending us new "Blocklist" links to be included in this project.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Agradecemos a todos aquellos que han contribuido a este proyecto. Los interesados pueden contribuir, enviándonos enlaces de nuevas "Blocklist", para ser incluidas en este proyecto.
    </td>
  </tr>
</table>

Special thanks to: [Jhonatan Sneider](https://github.com/sney2002)

## SPONSOR THIS PROJECT

---

[![Image](https://raw.githubusercontent.com/maravento/winexternal/master/img/maravento-paypal.png)](https://paypal.me/maravento)

## PROJECT LICENSES

---

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      This project uses a dual-licensing model to balance software freedom with content protection:
    </td>
    <td style="width: 50%; vertical-align: top;">
      Este proyecto utiliza un modelo de licencia dual para equilibrar la libertad del software con la protección del contenido:
    </td>
  </tr>
</table>

| Content | Licensed Under |
|---|---|
|Scripts, Binaries, Infrastructure|[![GPL-3.0](https://img.shields.io/badge/Open_Core-GPLv3-blue.svg?style=for-the-badge&labelWidth=120&logoWidth=20)](https://www.gnu.org/licenses/gpl.txt)|
|RAG, Workers, Specialized Modules, Docs|[![CC](https://img.shields.io/badge/Core_Engine-CC_BY--NC--ND_4.0-lightgrey.svg?style=for-the-badge&labelWidth=120&logoWidth=20)](https://creativecommons.org/licenses/by-nc-nd/4.0/)|

## DISCLAIMER

---

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## OBJECTION

---

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Due to recent arbitrary changes in computer terminology, it is necessary to clarify the meaning and connotation of the term <b>blacklist</b>, associated with this project:
      <br><br>
      <i>In computing, a blacklist, denylist or blocklist is a basic access control mechanism that allows through all elements (email addresses, users, passwords, URLs, IP addresses, domain names, file hashes, etc.), except those explicitly mentioned. Those items on the list are denied access. The opposite is a whitelist, which means only items on the list are let through whatever gate is being used.</i> Source <a href="https://en.wikipedia.org/wiki/Blacklist_(computing)" target="_blank">Wikipedia</a>
      <br><br>
      Therefore, <b>blacklist</b>, <b>blocklist</b>, <b>blackweb</b>, <b>blackip</b>, <b>whitelist</b> and similar, are terms that have nothing to do with racial discrimination.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Debido a los recientes cambios arbitrarios en la terminología informática, es necesario aclarar el significado y connotación del término <b>blacklist</b>, asociado a este proyecto:
      <br><br>
      <i>En informática, una lista negra, lista de denegación o lista de bloqueo es un mecanismo básico de control de acceso que permite a través de todos los elementos (direcciones de correo electrónico, usuarios, contraseñas, URL, direcciones IP, nombres de dominio, hashes de archivos, etc.), excepto los mencionados explícitamente. Esos elementos en la lista tienen acceso denegado. Lo opuesto es una lista blanca, lo que significa que solo los elementos de la lista pueden pasar por cualquier puerta que se esté utilizando.</i> Fuente <a href="https://en.wikipedia.org/wiki/Blacklist_(computing)" target="_blank">Wikipedia</a>
      <br><br>
      Por tanto, <b>blacklist</b>, <b>blocklist</b>, <b>blackweb</b>, <b>blackip</b>, <b>whitelist</b> y similares, son términos que no tienen ninguna relación con la discriminación racial.
    </td>
  </tr>
</table>
