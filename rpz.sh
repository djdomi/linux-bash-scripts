#!/bin/bash

source_file="/etc/squid/ad_block.txt"    # Pfad zur Datei mit den Domänen
rpz_file="/etc/bind/db/rpz.zone"          # Pfad zur RPZ-Zonendatei
catchall_ip="192.168.0.12"                # IP-Adresse für den Catch-All-Eintrag
dns_server="192.168.0.10"                 # DNS-Zielserver

# this files converts
# domain
# ip domain
# sub.domain
# hashtag is ignored
# ip only is ignored
#to domain.tld in rpz.format



# Überprüfen, ob die RPZ-Zonendatei bereits vorhanden ist
if [[ ! -f "$rpz_file" ]]; then
    # RPZ-Zonendatei erstellen, falls sie nicht existiert
    echo "\$TTL 3600" > "$rpz_file"
    echo "@ IN SOA ns.example.com. hostmaster.example.com. (" >> "$rpz_file"
    echo "        $(date +%Y%m%d) ; Serial" >> "$rpz_file"
    echo "        3600       ; Refresh" >> "$rpz_file"
    echo "        1800       ; Retry" >> "$rpz_file"
    echo "        604800     ; Expire" >> "$rpz_file"
    echo "        86400 )    ; Negative Cache TTL" >> "$rpz_file"
    echo "" >> "$rpz_file"
    echo "@            IN NS  ns.example.com." >> "$rpz_file"
    echo "" >> "$rpz_file"
else
    # Überprüfen, ob das Format der RPZ-Zonendatei korrekt ist, und falls nicht, die Datei neu erstellen
    if ! grep -q "^@ IN SOA" "$rpz_file"; then
        echo "Invalid format of RPZ zone file. Creating a new one..."
        echo "\$TTL 3600" > "$rpz_file"
        echo "@ IN SOA ns.example.com. hostmaster.example.com. (" >> "$rpz_file"
        echo "        $(date +%Y%m%d) ; Serial" >> "$rpz_file"
        echo "        3600       ; Refresh" >> "$rpz_file"
        echo "        1800       ; Retry" >> "$rpz_file"
        echo "        604800     ; Expire" >> "$rpz_file"
        echo "        86400 )    ; Negative Cache TTL" >> "$rpz_file"
        echo "" >> "$rpz_file"
        echo "@            IN NS  ns.example.com." >> "$rpz_file"
        echo "" >> "$rpz_file"
    fi
fi

# Überprüfen, ob die Domänen aus einer Host-Datei stammen
if grep -q "^host-file" "$source_file"; then
    host_file=$(grep "^host-file" "$source_file" | cut -d " " -f 2)
    if [[ -f "$host_file" ]]; then
        source_file="$host_file"
    else
        echo "Error: Host-Datei nicht gefunden."
        exit 1
    fi
fi

# Variable zum Speichern der Domänen erstellen
domains=""

# Domänen zur Variable hinzufügen
while IFS= read -r line; do
    if [[ ! "$line" =~ ^# ]]; then           # Ignoriere Zeilen, die mit "#" beginnen (Kommentare)
        if [[ "$line" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            continue  # Ignoriere Zeilen mit nur IP-Adressen
        fi
        domain=$(echo "$line" | awk '{print $1}')  # Extrahiere die Domäne aus der Zeile
        if [[ ! "$domain" =~ ^# ]]; then           # Ignoriere Zeilen, die mit "#" beginnen (Kommentare)
            if ! grep -Fxq "$domain" "$rpz_file"; then
                domains+="$(echo "$domain IN CNAME .")"$'\n'
            fi
        fi
    fi
done < "$source_file"

# Domänen in die RPZ-Zonendatei schreiben
echo "$domains" >> "$rpz_file"

# Aktualisieren der Serial-Nummer in der SOA-Zeile
sed -i "s/^\(.*\)\s; Serial/\1 $(date +%Y%m%d%H%M%S) ; Serial/" "$rpz_file"

# Neustarten des DNS-Servers, um die Änderungen zu übernehmen
systemctl restart bind9

echo "Domain processing completed."
