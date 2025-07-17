#!/bin/sh
set -eu

killall -q wisp_wpa3.sh 2>/dev/null || true
killall wpa_supplicant 2>/dev/null || true
killall udhcpc 2>/dev/null || true



SSID="Main Router"
PSK="Main Password"
ENC="sae"

# optional fields
SSID_B="Backup Router"
PSK_B="Backup Password"
ENC_B="psk2"

AP_SSID="AP Name"
AP_PSK="AP Password"


WIFI_IF="sta0"
CONF_FILE="/tmp/run/wpa_supplicant-${WIFI_IF}.conf"
LOG_FILE="/tmp/${WIFI_IF}.log"

echo "[*] Removing all Wi-Fi interfaces..."
while uci -q get wireless.@wifi-iface[0] >/dev/null 2>&1; do
  uci delete wireless.@wifi-iface[0]
done

uci commit wireless
wifi reload
sleep 3


echo "[*] Creating STA interface (2.4GHz)..."
uci set wireless.sta="wifi-iface"
uci set wireless.sta.device="wifi0"
uci set wireless.sta.ifname="sta0"
uci set wireless.sta.network="wan"
uci set wireless.sta.mode="sta"
uci set wireless.sta.ssid="${SSID}"
uci set wireless.sta.encryption="${ENC}"
uci set wireless.sta.key="${PSK}"
uci set wireless.sta.ieee80211w='1'
uci set wireless.sta.disabled="0"



echo "[*] Adding access point (5GHz)..."
uci set wireless.ap="wifi-iface"
uci set wireless.ap.device="wifi1"
uci set wireless.ap.ifname="wl0"
uci set wireless.ap.network="lan"
uci set wireless.ap.mode="ap"
uci set wireless.ap.ssid="${AP_SSID}"
uci set wireless.ap.encryption="ccmp"
uci set wireless.ap.key="${AP_PSK}"
uci set wireless.ap.sae="1"
uci set wireless.ap.sae_password="${AP_PSK}"
uci set wireless.ap.ieee80211w="2"
uci set wireless.ap.disabled="0"


uci commit wireless
wifi reload
sleep 4


if ip link show "$WIFI_IF" > /dev/null 2>&1; then
  echo "[*] Disabling power_save on ${WIFI_IF}..."
  iw dev "$WIFI_IF" set power_save off
else
  echo "[!] Interface ${WIFI_IF} not found, skipping power_save disable"
fi

echo "[*] Checking and creating network.wan section..."
uci -q delete network.wan || true
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.ifname="${WIFI_IF}"
uci set network.wan.peerdns='0'
uci set network.wan.dns='94.140.14.14 94.140.15.15'
uci commit network

sleep 3

echo "[*] Generating WPA3 config..."
cat <<EOF > "${CONF_FILE}"
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
update_config=1

network={
    ssid="${SSID}"
    key_mgmt=SAE
    psk="${PSK}"
    ieee80211w=2
    priority=10
}
EOF

if [ -n "${SSID_B}" ] && [ -n "${PSK_B}" ]; then
cat <<EOF >> "${CONF_FILE}"

network={
    ssid="${SSID_B}"
    key_mgmt=SAE WPA-PSK
    psk="${PSK_B}"
    ieee80211w=1
    priority=5
}
EOF
fi

# bgscan="simple:30:-65:300" maybe add later

echo "[*] Setting region to US..."
iw reg set US


echo "[*] Enabling ip_forward..."
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "[*] Killing old wpa_supplicant..."
killall wpa_supplicant 2>/dev/null || true
sleep 1

echo "[*] Starting wpa_supplicant in background..."
wpa_supplicant -i "${WIFI_IF}" -c "${CONF_FILE}" -D nl80211 -d -f "${LOG_FILE}" &
sleep 6

echo "[*] Requesting IP via DHCP..."
udhcpc -i "${WIFI_IF}" -q -t 10 -T 4 || echo "[!] DHCP failed, check the log."


iptables -t nat -F
iptables -F

iptables -t nat -A POSTROUTING -o sta0 -j MASQUERADE
iptables -A FORWARD -i br-lan -o sta0 -j ACCEPT
iptables -A FORWARD -i sta0 -o br-lan -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

echo "[+] NAT configured. Connect to 5GHz AP: '${AP_SSID}'"

echo "[+] Configuring firewall"

uci set firewall.wan=zone
uci set firewall.wan.name='wan'
uci set firewall.wan.network='wan'
uci set firewall.wan.input='REJECT'
uci set firewall.wan.output='ACCEPT'
uci set firewall.wan.forward='REJECT'
uci set firewall.wan.masq='1'
uci set firewall.wan.mtu_fix='1'

uci set firewall.lan=zone
uci set firewall.lan.name='lan'
uci set firewall.lan.network='lan'
uci set firewall.lan.input='ACCEPT'
uci set firewall.lan.output='ACCEPT'
uci set firewall.lan.forward='ACCEPT'


# Remove old lan->wan forwardings if they exist
while uci -q get firewall.@forwarding[0]; do
  [ "$(uci get firewall.@forwarding[0].src)" = "lan" ] && [ "$(uci get firewall.@forwarding[0].dest)" = "wan" ] && uci delete firewall.@forwarding[0] || break
done

uci add firewall forwarding
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].dest='wan'

uci commit firewall
/etc/init.d/firewall restart
