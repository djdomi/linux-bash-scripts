#!/bin/bash

# Variablen
ENABLE_IPV6=TRUE
WIREGUARD_SRV_FQDN="hostname.tld"
WIREGUARD_SRV_PORT=443
IPv4_LAN_ADDRESS0_SRV="10.8.0.1/24"
IPv4_LAN_ADDRESS0_FIRST_CLIENT="10.8.0.2/24"
IPv4_LAN_ADDRESS0_ALLOWEDIP="10.8.0.0/24"

IPv6_LAN_ADDRESS1_SRV="fd00:abcd::1/64"
IPv6_LAN_ADDRESS1_FIRST_CLIENT="fd00:abcd::2/128"
IPv6_LAN_ADDRESS1_ALLOWEDIP="fd00:abcd::/64"

IPv6_LAN_ADDRESS2_SRV="2a03:4000:A:B::1/64"
IPv6_LAN_ADDRESS2_FIRST_CLIENT="2a03:4000:A:B::2/64"
IPv6_LAN_ADDRESS2_ALLOWEDIP="2a03:4000:A:B::/64"

IPv6_LAN_ADDRESS3_SRV="fd42:42:42::1/64"
IPv6_LAN_ADDRESS3_FIRST_CLIENT="fd42:42:42::2/64"
IPv6_LAN_ADDRESS3_ALLOWEDIP="fd42:42:42::/64"

IPv6_LAN_ADDRESS4_SRV="FE80::1/10"
IPv6_LAN_ADDRESS4_FIRST_CLIENT="FE80::2/10"
IPv6_LAN_ADDRESS4_ALLOWEDIP="FE80::/10"

CLIENT_CONFIG_DIR="/etc/wireguard/clients"

# Funktion zum Anzeigen der Skriptverwendung
usage() {
  echo "Usage: $0 [-6] -u <username>"
  echo "Options:"
  echo "  -6  Enable IPv6 support"
  echo "  -u  Username for the new WireGuard user"
  exit 1
}

# Verarbeitung von Optionen
while getopts ":6u:" opt; do
  case $opt in
    6)
      ENABLE_IPV6=TRUE
      ;;
    u)
      USERNAME=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done

# Überprüfe, ob der Benutzername angegeben wurde
if [ -z "$USERNAME" ]; then
  echo "Error: Username not provided."
  usage
fi

# Installation von WireGuard (falls nicht bereits installiert)
if ! command -v wg &> /dev/null; then
  echo "Installing WireGuard..."
  sudo apt update
  sudo apt install -y wireguard
fi

# Konfiguration des WireGuard-Servers
echo "Configuring WireGuard server..."

# Überprüfe, ob das WireGuard-Interface bereits existiert
if ! ip link show dev wg0 &> /dev/null; then
  # WireGuard-Interface erstellen
  sudo ip link add wg0 type wireguard
fi

# Server Private Key erstellen (falls nicht bereits vorhanden)
if [ ! -f "/etc/wireguard/privatekey" ]; then
  SERVER_PRIVATE_KEY=$(wg genkey)
  echo "$SERVER_PRIVATE_KEY" | sudo tee /etc/wireguard/privatekey > /dev/null
else
  SERVER_PRIVATE_KEY=$(sudo cat /etc/wireguard/privatekey)
fi

# Server Public Key erstellen (falls nicht bereits vorhanden)
if [ ! -f "/etc/wireguard/publickey" ]; then
  SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
  echo "$SERVER_PUBLIC_KEY" | sudo tee /etc/wireguard/publickey > /dev/null
else
  SERVER_PUBLIC_KEY=$(sudo cat /etc/wireguard/publickey)
fi

# Server-Konfiguration in die Datei schreiben
echo "[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $IPv4_LAN_ADDRESS0_SRV,$IPv6_LAN_ADDRESS1_SRV,$IPv6_LAN_ADDRESS2_SRV,$IPv6_LAN_ADDRESS3_SRV,$IPv6_LAN_ADDRESS4_SRV
ListenPort = $WIREGUARD_SRV_PORT" | sudo tee /etc/wireguard/wg0.conf > /dev/null

# IPv6-Unterstützung aktivieren, wenn ausgewählt
if [ "$ENABLE_IPV6" == "TRUE" ]; then
  echo "Enabling IPv6 support..."
  # Füge hier die IPv6-Konfiguration mit den öffentlichen Adressen hinzu
  echo "Address = $IPv6_LAN_ADDRESS1_SRV,$IPv6_LAN_ADDRESS2_SRV,$IPv6_LAN_ADDRESS3_SRV,$IPv6_LAN_ADDRESS4_SRV" | sudo tee -a /etc/wireguard/wg0.conf > /dev/null
fi

# WireGuard-Interface starten
sudo wg setconf wg0 /etc/wireguard/wg0.conf
sudo ip link set wg0 up

# Funktion zum Hinzufügen eines Benutzers
add_user() {
  CLIENT_NAME=$1
  CLIENT_PRIVATE_KEY=$(wg genkey)
  CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
  CLIENT_IPv4="$IPv4_LAN_ADDRESS0_FIRST_CLIENT"
  CLIENT_IPv6="$IPv6_LAN_ADDRESS1_FIRST_CLIENT,$IPv6_LAN_ADDRESS2_FIRST_CLIENT,$IPv6_LAN_ADDRESS3_FIRST_CLIENT,$IPv6_LAN_ADDRESS4_FIRST_CLIENT"

  # Benutzer zur Server-Konfiguration hinzufügen
  echo "
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IPv4,$CLIENT_IPv6" | sudo tee -a /etc/wireguard/wg0.conf > /dev/null

  # Verzeichnis für Client-Konfigurationen erstellen
  sudo mkdir -p $CLIENT_CONFIG_DIR
  # Ausgabe der Client-Konfiguration in eine Datei schreiben
  echo "[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IPv4,$CLIENT_IPv6

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $WIREGUARD_SRV_FQDN:$WIREGUARD_SRV_PORT
AllowedIPs = 0.0.0.0/0, ::/0" | sudo tee $CLIENT_CONFIG_DIR/$CLIENT_NAME.conf > /dev/null
}

# Benutzer hinzufügen
add_user $USERNAME

echo "User $USERNAME added successfully. Client configuration saved to $CLIENT_CONFIG_DIR/$USERNAME.conf"
