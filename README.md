# [BlackIP](https://www.maravento.com/p/blackip.html)

[![status-maintained](https://img.shields.io/badge/status-maintained-purple.svg)](https://github.com/maravento/blackip)
[![last commit](https://img.shields.io/github/last-commit/maravento/blackip)](https://github.com/maravento/blackip)
[![Stargazers](https://img.shields.io/github/stars/maravento/blackip?label=Stargazers)](https://github.com/maravento/blackip/stargazers)
[![Twitter Follow](https://img.shields.io/twitter/follow/maraventostudio.svg)](https://twitter.com/maraventostudio)

<!-- markdownlint-disable MD033 -->

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <b>BlackIP</b> brings together public IPv4 blocklists and adapts them for use as ACLs in <a href="http://www.squid-cache.org/" target="_blank">Squid</a> or as an IP set in <a href="http://ipset.netfilter.org/" target="_blank">IPset</a>, which can be applied with iptables.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <b>BlackIP</b> reúne listas públicas de direcciones IPv4 y las adapta para usarlas como ACL en Squid o como conjunto de IP en IPset, que puede aplicarse mediante reglas de iptables.
    </td>
  </tr>
</table>

## REQUIREMENTS

---

To apply the list, at least one of the following is required, depending on the method: `ipset` or `squid`. To run `bipupdate.sh`, Squid must also be installed and configured with the `blackip` ACL. The script checks this rule and reloads Squid during updates, even if the list will later be used with IPset.

- `ipset` (for Ipset/Iptables Rules)
- `squid` (or `squid-openssl`) (for Squid Rule)

```bash
apt install -y ipset

# or

apt install -y squid
```

## HOW TO USE

---

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      The archive includes <code>blackip.txt</code>, prepared for use with Squid or IPset. Download the archive and save the file in a path accessible to the service that will use it.
    </td>
    <td style="width: 50%; vertical-align: top;">
      El archivo comprimido incluye <code>blackip.txt</code>, preparado para usarse en Squid o cargarse en IPset. Para aplicarlo, debe descargarse y guardarse en una ruta accesible para el servicio que lo utilizará.
    </td>
  </tr>
</table>

### Download

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz && cat blackip.tar.gz* | tar xzf -
```

### Checksum

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/blackip.txt.sha256
LOCAL=$(sha256sum blackip.txt | awk '{print $1}'); REMOTE=$(awk '{print $1}' blackip.txt.sha256); echo "$LOCAL" && echo "$REMOTE" && [ "$LOCAL" = "$REMOTE" ] && echo OK || echo FAIL
```

#### Important about BlackIP

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>It is recommended to apply <code>blackip.txt</code> with Squid or IPset, but not both at once. This avoids filtering the same traffic twice.</li>
        <li><code>blackip.txt</code> contains individual IPv4 addresses, one per line; it does not include CIDR ranges. Additional ranges can be managed in <code>blackcidr.txt</code>.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Se recomienda aplicar <code>blackip.txt</code> mediante Squid o IPset, pero no con ambos a la vez. Así se evita filtrar el mismo tráfico dos veces.</li>
        <li><code>blackip.txt</code> contiene direcciones IPv4 individuales, una por línea; no incluye rangos CIDR. Los rangos adicionales se pueden gestionar mediante <code>blackcidr.txt</code>.</li>
      </ul>
    </td>
  </tr>
</table>

### [Ipset/Iptables](http://ipset.netfilter.org/) Rules

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      In the iptables script, these rules can be added to load <code>blackip.txt</code> into IPset and drop traffic to or from the listed IPs. Loading the set and configuring iptables require administrator privileges.
    </td>
    <td style="width: 50%; vertical-align: top;">
      En el script de iptables, se pueden añadir estas reglas para cargar <code>blackip.txt</code> en IPset y descartar el tráfico hacia o desde las IP de la lista. La carga y la configuración de iptables requieren privilegios de administrador.
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
      IPDeny country zones can be added to the set of blocked IPs. The country codes are specified in the line that combines the zone files with <code>blackip.txt</code>.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Las zonas de países de IPDeny pueden añadirse al conjunto de IP bloqueadas. Para seleccionar países, se indica el código de cada país en la línea que combina los archivos de zonas con <code>blackip.txt</code>.
    </td>
  </tr>
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <b>Note:</b> <code>bipupdate.sh</code> can also download these zones (see <a href="#ipdeny-country-zones-optional">IPDeny Country Zones (Optional)</a>).
    </td>
    <td style="width: 50%; vertical-align: top;">
      <b>Nota:</b> <code>bipupdate.sh</code> también puede descargar estas zonas (más detalles en <a href="#ipdeny-country-zones-optional">IPDeny Country Zones (Optional)</a>).
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
        <li><code>blackip.txt</code> contains hundreds of thousands of IPv4 addresses. The example sets <a href="https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is" target="_blank">maxelem</a> to <code>10000000</code> to allow large sets; this value should be sized according to the list and available resources. For more information, see <a href="https://www.odi.ch/weblog/posting.php?posting=738" target="_blank">ipset's hashsize and maxelem parameters</a>.</li>
        <li>IPset documents that when iptables adds entries through the <code>SET</code> target, the hash table size is not increased automatically; an entry may fail to be added even while the rule remains active. See the <a href="https://ipset.netfilter.org/ipset.man.html" target="_blank">IPset manual</a> for details and limitations.</li>
        <li>A large set can increase memory use and affect performance. Test the configuration and check available resources before applying it in production.</li>
        <li>Tested on iptables v1.8.7, ipset v7.15, protocol version: 7.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Ipset permite realizar filtrado masivo a una velocidad de procesamiento muy superior a otras soluciones, como muestra este <a href="https://web.archive.org/web/20161014210553/http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/" target="_blank">benchmark</a>).</li>
        <li><code>blackip.txt</code> contiene cientos de miles de direcciones IPv4. En el ejemplo de IPset, <a href="https://ipset.netfilter.org/ipset.man.html#:~:text=hash%3Aip%20hashsize%201536-,maxelem,-This%20parameter%20is" target="_blank">maxelem</a> se fija en <code>10000000</code> para permitir conjuntos grandes; este valor debe dimensionarse según la lista y los recursos disponibles. Para más información, pueden consultarse <a href="https://www.odi.ch/weblog/posting.php?posting=738" target="_blank">los parámetros hashsize y maxelem de IPset</a>.</li>
        <li>IPset advierte que, cuando iptables añade entradas mediante el objetivo <code>SET</code>, el tamaño de la tabla hash no se amplía automáticamente; una entrada podría no agregarse aunque la regla siga activa. El <a href="https://ipset.netfilter.org/ipset.man.html" target="_blank">manual de IPset</a> describe este comportamiento y sus límites.</li>
        <li>Un conjunto grande puede aumentar el consumo de memoria y afectar el rendimiento. Conviene probar la configuración y comprobar los recursos disponibles antes de aplicarla en producción.</li>
        <li>Probado en: iptables v1.8.7, ipset v7.15, protocol version: 7.</li>
      </ul>
    </td>
  </tr>
</table>

### [Squid](http://www.squid-cache.org/) Rule

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Open:
    </td>
    <td style="width: 50%; vertical-align: top;">
      Abrir:
    </td>
  </tr>
</table>

```bash
/etc/squid/squid.conf
```

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Add the following lines at the indicated location. Replace <code>/path_to/blackip.txt</code> with the actual file path:
    </td>
    <td style="width: 50%; vertical-align: top;">
      Añadir estas líneas en el punto indicado. En <code>/path_to/blackip.txt</code>, sustituir el ejemplo por la ruta real del archivo:
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
      <code>blackip.txt</code> has been tested with Squid 3.5 and later.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>blackip.txt</code> se ha probado con Squid 3.5 y versiones posteriores.
    </td>
  </tr>
</table>

#### Advanced Rules

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      BlackIP contains a large IPv4 list. The following ACLs can extend or customize its filtering:
      <ul>
        <li><code>blackcidr.txt</code> adds CIDR ranges that are not in <code>blackip.txt</code>. It contains some ranges by default and is not modified by <code>bipupdate.sh</code>.</li>
        <li><code>allowip.txt</code> is a list of IPv4 exceptions generated by <code>aipupdate.sh</code> from resolving domains in <code>debugwl.txt</code>.</li>
        <li><code>aipextra.txt</code> adds IP addresses or CIDR ranges to the exception list; it is maintained separately and is not modified by <code>bipupdate.sh</code>.</li>
        <li><code>bipupdate.sh</code> excludes ranges listed in <code>iana.txt</code> when generating <code>blackip.txt</code>. The IANA ACL shown below can be placed before deny rules in Squid to exempt those ranges from blocking.</li>
        <li><code>bipupdate.sh</code> excludes the IPs listed in <code>dns.txt</code> when generating <code>blackip.txt</code>. The DNS ACL shown below can be configured to allow or deny those servers, depending on the chosen rule and its position.</li>
        <li>To prevent access to sites by literal IP address, the <code>direct_ipv4</code> and <code>direct_ipv6</code> rules shown below can be added.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      BlackIP contiene una lista extensa de direcciones IPv4. Las siguientes ACL permiten ampliar o personalizar el filtrado:
      <ul>
        <li><code>blackcidr.txt</code> permite añadir rangos CIDR que no están en <code>blackip.txt</code>. Contiene algunos rangos por defecto y <code>bipupdate.sh</code> no la modifica.</li>
        <li><code>allowip.txt</code> es una lista de excepciones IPv4 que <code>aipupdate.sh</code> genera a partir de los dominios de <code>debugwl.txt</code> que resuelven a direcciones IP.</li>
        <li><code>aipextra.txt</code> permite añadir direcciones IP o rangos CIDR a la lista de excepciones. Se mantiene por separado y <code>bipupdate.sh</code> no la modifica.</li>
        <li><code>bipupdate.sh</code> excluye los rangos de <code>iana.txt</code> al generar <code>blackip.txt</code>. La ACL de IANA que aparece abajo puede colocarse antes de las reglas de denegación en Squid para excluir esos rangos del bloqueo.</li>
        <li><code>bipupdate.sh</code> excluye las IP de <code>dns.txt</code> al generar <code>blackip.txt</code>. La ACL DNS que aparece abajo puede configurarse para permitir o bloquear esos servidores, según la regla elegida y su posición.</li>
        <li>Para evitar el acceso directo a sitios mediante una dirección IP, se pueden añadir las reglas <code>direct_ipv4</code> y <code>direct_ipv6</code> que aparecen más abajo.</li>
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
http_access allow dnslst # or deny dnslst

# Block Rule for IP/CIDR ACL (not included in blackip.txt)
acl blackcidr dst "/path_to/blackcidr.txt"
http_access deny blackcidr

## BLOCK RULE FOR BLACKIP
acl blackip dst "/path_to/blackip.txt"
http_access deny blackip

# Block: Direct IPv4
acl direct_ipv4 dstdom_regex -n -i ^([0-9]{1,3}\.){3}[0-9]{1,3}$
http_access deny direct_ipv4
# Block: Direct IPv6
acl direct_ipv6 dstdom_regex -n -i ^\[([0-9a-f:]+)\]$
http_access deny direct_ipv6
```

## DATA SHEET

---

| ACL | Blocked IP | File Size |
| :---: | :---: | :---: |
| blackip.txt | 468087 | 6,6 Mb |

## REPOSITORY STRUCTURE

---

```
bipupdate/
├── bipupdate.sh                # Descarga y depura listas, genera blackip.txt y recarga Squid
├── lst/                        # ACL y listas auxiliares que usa bipupdate.sh
│   ├── aipextra.txt                # Lista independiente de IP/CIDR permitidas; bipupdate.sh no la modifica
│   ├── allowip.txt                 # Lista generada por tools/aipupdate.sh
│   ├── blackcidr.txt               # Lista independiente de IP/CIDR bloqueadas; bipupdate.sh no la modifica
│   ├── blockip.txt                 # Se añade a la lista candidata de bloqueo
│   ├── dns.txt                     # Servidores DNS públicos excluidos de la lista final
│   └── iana.txt                    # Rangos reservados por IANA, excluidos de la lista final
└── tools/
    ├── aipupdate.sh             # Genera allowip.txt, una lista de excepciones para Squid
    └── debugbip.py              # Retira de la lista candidata las IP que Squid señala como válidas en cache.log
```

## BLACKIP UPDATE

---

### ⚠️ WARNING: BEFORE YOU CONTINUE

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      This section describes how <code>bipupdate.sh</code> generates and updates <code>blackip.txt</code>. Running the script is not required to use the published list. Updates can take time and use substantial CPU, memory, bandwidth and network resources; it is recommended to run the process on a test system first.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Esta sección describe el proceso que sigue <code>bipupdate.sh</code> para generar y actualizar <code>blackip.txt</code>. No es necesario ejecutar el script para usar la lista publicada. La actualización puede tardar y consumir CPU, memoria, ancho de banda y recursos de red; se recomienda ejecutarla primero en un equipo de pruebas.
    </td>
  </tr>
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <b>Note:</b> <code>bipupdate.sh</code> tested on Ubuntu 24.04/26.04 LTS. Use on other versions or distributions is at your own risk.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <b>Nota:</b> <code>bipupdate.sh</code> ha sido probado en Ubuntu 24.04/26.04 LTS. Su uso en otras versiones o distribuciones queda bajo su propio riesgo.
    </td>
  </tr>
</table>

### Dependencies (for `bipupdate.sh`)

- Python 3.x, Bash 5.x
- `wget`, `git`, `curl`, `tar`, `unzip`, `zip`, `gzip`, `idn2`, `grepcidr`, `squid` (or `squid-openssl`), `python3`, `bind9-host`, `findutils`, `grep`, `sed`, `coreutils`, `util-linux`, `sudo`

```bash
apt install -y wget git curl tar unzip zip gzip idn2 grepcidr squid python3 bind9-host findutils grep sed coreutils util-linux sudo
```

#### Bash Update

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <code>bipupdate.sh</code> runs the steps needed to generate <code>blackip.txt</code> in sequence and requests elevated privileges when an operation requires them.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>bipupdate.sh</code> ejecuta en secuencia los pasos necesarios para generar <code>blackip.txt</code> y solicita privilegios cuando una operación los requiere.
    </td>
  </tr>
</table>

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/bipupdate.sh && chmod +x bipupdate.sh && ./bipupdate.sh
```

#### IPDeny Country Zones (Optional)

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      When <code>bipupdate.sh</code> starts a run without the first-stage DNS data, it asks whether to download <a href="https://www.ipdeny.com/ipblocks/" target="_blank">IPDeny</a> country zones to <code>/etc/zones</code>. Enter <code>y</code> to download them, or press Enter (or enter <code>n</code>) to skip them and continue with the public blocklists.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Cuando <code>bipupdate.sh</code> inicia una ejecución sin los datos DNS de la primera etapa, pregunta si se deben descargar las zonas de países de <a href="https://www.ipdeny.com/ipblocks/" target="_blank">IPDeny</a> en <code>/etc/zones</code>. Con <code>y</code> se descargan; al pulsar Enter o responder <code>n</code>, se omiten y el proceso continúa con las listas públicas.
    </td>
  </tr>
</table>

```bash
Download and apply IPDeny country zones? [y/N]:
```

#### Capture Public Blocklists

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      Downloads the public blocklists listed under <b>SOURCES</b>, extracts IPv4 addresses and combines them for further processing.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Descarga las listas públicas indicadas en <b>SOURCES</b>, extrae las direcciones IPv4 y las reúne para continuar con la depuración.
    </td>
  </tr>
</table>

#### DNS Lookup

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      The process checks reverse DNS resolution for IP addresses in two stages. Addresses that receive a response are marked <code>HIT</code>; those that do not are marked <code>FAULT</code>. These labels report the reverse-DNS result; they do not by themselves confirm that an IP is active or malicious. Queries run in parallel, and elapsed time depends on the hardware and connection.
    </td>
    <td style="width: 50%; vertical-align: top;">
      El proceso consulta la resolución DNS inversa de las IP en dos etapas. Las que obtienen una respuesta se marcan como <code>HIT</code>; las que no, como <code>FAULT</code>. Estas etiquetas describen el resultado de la consulta inversa, pero no confirman por sí solas que una IP esté activa o sea maliciosa. Las consultas se ejecutan en paralelo y el tiempo depende del hardware y la conexión.
    </td>
  </tr>
</table>

```bash
HIT 8.8.8.8
FAULT 0.0.9.1
```

#### Run Squid-Cache with BlackIP

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      When Squid runs with BlackIP, errors are written to <code>SquidErrors.txt</code>.
    </td>
    <td style="width: 50%; vertical-align: top;">
      Al ejecutar Squid-Cache con BlackIP, los errores se escriben en <code>SquidErrors.txt</code>.
    </td>
  </tr>
</table>

#### Log

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <code>bipupdate.sh</code> writes a log file (<code>bipupdate.log</code>) in the script's directory and clears it at the start of each run.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>bipupdate.sh</code> escribe el registro en <code>bipupdate.log</code>, junto al script, y lo vacía al inicio de cada ejecución.
    </td>
  </tr>
</table>

#### Download Status

| Tag | Shows | English | Español |
|---|---|---|---|
| `SAVED:` | File name | The transfer completed and the file was written | La descarga terminó y el archivo se guardó |
| `PARTIAL:` | Full URL | The download started and was cut off before finishing | La descarga comenzó, pero se interrumpió antes de terminar |
| `BUSY:` | Full URL | The server answered 5xx: it is up but not serving the list right now | El servidor respondió con un error 5xx: está disponible, pero no entrega la lista en ese momento |
| `TIMEOUT:` | Full URL | The server did not answer at all | El servidor no respondió |
| `BROKEN:` | Full URL | The server answered 404 or 410: broken or nonexistent URL | El servidor respondió 404 o 410: el recurso no existe o la URL ya no es válida |

#### Important about BlackIP Update

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>The <code>blackip</code> ACL must be configured in <a href="http://www.squid-cache.org/" target="_blank">Squid</a> before running <code>bipupdate.sh</code>.</li>
        <li>Some source lists limit downloads; avoid running <code>bipupdate.sh</code> more than once a day.</li>
        <li><code>bipupdate.sh</code> requests elevated privileges when an operation requires them.</li>
        <li>When <code>aufs</code> is in use, it must be changed temporarily to <code>ufs</code> during the update to avoid: <code>ERROR: Can't change type of existing cache_dir aufs /var/spool/squid to ufs. Restart required</code>.</li>
        <li><code>bipupdate.sh</code> disables strict certificate verification because some public sources have certificate issues. This allows download attempts, but weakens verification of the server's identity; keep this in mind when reviewing or changing the sources.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Antes de ejecutar <code>bipupdate.sh</code>, debe estar configurada en <a href="http://www.squid-cache.org/" target="_blank">Squid</a> la ACL <code>blackip</code>.</li>
        <li>Algunas fuentes limitan las descargas; se recomienda no ejecutar <code>bipupdate.sh</code> más de una vez al día.</li>
        <li><code>bipupdate.sh</code> solicita privilegios cuando una operación los requiere.</li>
        <li>Si se usa <code>aufs</code>, debe cambiarse temporalmente a <code>ufs</code> durante la actualización para evitar: <code>ERROR: Can't change type of existing cache_dir aufs /var/spool/squid to ufs. Restart required</code>.</li>
        <li><code>bipupdate.sh</code> desactiva la verificación estricta de certificados porque algunas fuentes públicas tienen problemas con ellos. Esto permite intentar la descarga, pero reduce la verificación de la identidad del servidor; conviene tenerlo en cuenta al revisar o modificar las fuentes.</li>
      </ul>
    </td>
  </tr>
</table>

#### AllowIP Update

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <code>aipupdate.sh</code> generates <code>allowip.txt</code> from domains in <code>debugwl.txt</code> that resolve to IPv4 addresses. The output is filtered to exclude ranges in <code>iana.txt</code> and addresses in <code>dns.txt</code>.
    </td>
    <td style="width: 50%; vertical-align: top;">
      <code>aipupdate.sh</code> genera <code>allowip.txt</code> a partir de los dominios de <code>debugwl.txt</code> que resuelven a direcciones IPv4. El resultado se filtra para excluir los rangos de <code>iana.txt</code> y las direcciones de <code>dns.txt</code>.
    </td>
  </tr>
</table>

> Domain resolution uses `host -t a`, provided by `bind9-host`.
>
> La resolución de dominios usa `host -t a`, del paquete `bind9-host`.

```bash
wget -q -N https://raw.githubusercontent.com/maravento/blackip/master/bipupdate/tools/aipupdate.sh && chmod +x aipupdate.sh && ./aipupdate.sh
```

## SOURCES

---

### BLOCKLISTS

- [abuse.ch - Feodo Tracker](https://feodotracker.abuse.ch/downloads/ipblocklist_recommended.txt)
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
- [opsxcq - proxy-list](https://raw.githubusercontent.com/opsxcq/proxy-list/master/list.txt)
- [Project Honeypot - list_of_ips](https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1)
- [romainmarcoux - malicious-ip](https://github.com/romainmarcoux/malicious-ip/blob/main/full-aa.txt)
- [Rulez - BruteForceBlocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)
- [Spamhaus - drop-lasso](https://www.spamhaus.org/drop/drop.lasso)
- [stamparm - ipsum](https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt)
- [StopForumSpam - 180](https://www.stopforumspam.com/downloads/listed_ip_180_all.zip)
- [torproject - TOR BulkExitList](https://check.torproject.org/torbulkexitlist?ip=1.1.1.1)
- [Uceprotect - backscatterer Level 1](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz)
- [Uceprotect - backscatterer Level 2](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz)
- [Uceprotect - backscatterer Level 3](http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz)
- [Ultimate Hosts IPs Blocklist - ips](https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/tree/master/ips)
- [yoyo - adservers](https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0)

### DEBUG LISTS

- [Allow IP/CIDR extra](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [Allow IPs](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [Allow URLs](https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/debugwl.txt)
- [Block IP/CIDR Extra](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [DNS](https://github.com/maravento/blackip/tree/master/bipupdate/lst)
- [IANA](https://github.com/maravento/blackip/tree/master/bipupdate/lst)

## NOTICE

---

<table width="100%">
  <tr>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>This project includes third-party components.</li>
        <li>Changes must be submitted via Issues. Pull requests are not accepted.</li>
        <li>Blackip is not a blacklist service itself. It does not independently verify IP addresses. Its purpose is to consolidate and reformat public blacklist sources to make them compatible with Squid/Iptables/Ipset.</li>
        <li>If your IP address is listed on Blackip and you believe this is an error, you should check the public sources in <b>SOURCES</b>, identify which one(s) it appears in, and contact the person responsible for that list to request its removal. Once the IP address is removed from the original source, it will automatically disappear from Blackip with the next update.</li>
        <li>The available IPv4 address space is nearly exhausted, which forces increasingly frequent reassignment of addresses. Blackip may therefore contain false positives, and the number of IPv4 addresses worth blocking is expected to keep decreasing. If that trend continues at the current pace, Blackip could eventually stop serving its purpose, simply because no IPv4 addresses would be left to block.</li>
      </ul>
    </td>
    <td style="width: 50%; vertical-align: top;">
      <ul>
        <li>Este proyecto incluye componentes de terceros.</li>
        <li>Los cambios deben proponerse mediante Issues. No se aceptan Pull Requests.</li>
        <li>Blackip no es un servicio de listas negras como tal. No verifica de forma independiente las direcciones IP. Su función es consolidar y formatear listas negras públicas para hacerlas compatibles con Squid/Iptables/Ipset.</li>
        <li>Si su dirección IP aparece en Blackip y considera que esto es un error, debe revisar las fuentes públicas en <b>SOURCES</b>, identificar en cuál(es) aparece, y contactar al responsable de dicha lista para solicitar su eliminación. Una vez que la dirección IP sea eliminada en la fuente original, desaparecerá automáticamente de Blackip en la siguiente actualización.</li>
        <li>El espacio de direcciones IPv4 disponible está casi agotado, lo que obliga a reasignar direcciones cada vez con más frecuencia. Por eso Blackip puede contener falsos positivos, y se espera que la cantidad de direcciones IPv4 que conviene bloquear siga disminuyendo. Si esa tendencia continúa al ritmo actual, Blackip podría dejar de cumplir su objetivo, simplemente porque ya no quedarían direcciones IPv4 que bloquear.</li>
      </ul>
    </td>
  </tr>
</table>

## ACKNOWLEDGMENTS

---

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
|Scripts, Binaries, Infrastructure|[![GPL-3.0](https://img.shields.io/badge/Open_Core-GPLv3-blue.svg?style=for-the-badge&labelWidth=120&logoWidth=20)](LICENSE)|
|RAG, Workers, Specialized Modules, Docs|[![CC](https://img.shields.io/badge/Core_Engine-CC_BY--NC--ND_4.0-lightgrey.svg?style=for-the-badge&labelWidth=120&logoWidth=20)](docs/LICENSE-CC-BY-NC-ND-4.0.md)|

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
