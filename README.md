# WISP mode on Xiaomi Router AX5400 Gaming Edition

### Be sure you unlocked ssh first: <>

# Problem
The repeater mode on the Redmi AX5400 tends to lose the main router for no reason. It may also forget to connect back at all and will have to be rebooted  

Also, every request (even local) goes to the main router, which creates extra delays, for example for VR

# Goal
Create a separate 5 GHz network without any restrictions  
Use the main router's 2.4 GHz network as a WAN

# Installation

You can connect to the router via LAN cable. The script will not disconnect you, unlike Wi-Fi

## Download wisp.sh

## Now lets edit for your need:

Setup main router SSID and Password
```
SSID="Main Router"
PSK="Main Password"
ENC="sae" # sae-mixed, psk2
```

You can also setup backup router if you want
```
SSID_B="Backup Router"
PSK_B="Backup Password"
ENC_B="psk2"
```

Your Access Point SSID and Password
```
AP_SSID="AP Name"
AP_PSK="AP Password"
```

### Optional: Change DNS from Adguard to your own

```
uci set network.wan.dns='94.140.14.14 94.140.15.15'
```

## Now you can try to put it in the router by ssh:  
> type wisp.sh | ssh -oHostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "cat > /tmp/wisp.sh && sh /tmp/wisp.sh"

Make sure you running that command in the same folder as `wisp.sh`

# How to check everything is working? My example

<details>
  <summary>Setting Wi-Fi interfaces and creating WAN config</summary>

   ```
   [*] Removing all Wi-Fi interfaces...
   Failed to connect to wpa_supplicant global interface: /var/run/wpa_supplicantglobal  error: No such file or directory
   OK
   device: wifi0 vifs:
   device: wifi1 vifs:
   Enable ol_stats by default for Lithium platforms
   sh: wl2: unknown operand
   Enable ol_stats by default for Lithium platforms
   sh: wl2: unknown operand
   Command failed: Not found
   Command failed: Not found
   /sbin/wifi: eval: line 1: iface_mgr_setup: not found
   device: wifi0 vifs:
   device: wifi1 vifs:
   [*] Creating STA interface (2.4GHz)...
   [*] Adding access point (5GHz)...
   device: wifi0 vifs: sta
   device: wifi1 vifs: ap
   Enable ol_stats by default for Lithium platforms
   error_handler received : -16
   Failed to send message to driver Error:-16
   cfg80211: ifname: sta0 mode: managed cfgphy: phy0
   error_handler received : -22
   Failed to send message to driver Error:-22
   sh: out of range
   wep40,wep104,tkip,aes-ocb,aes-ccmp-128,aes-ccmp-256,aes-gcmp-128,aes-gcmp-256,ckip,wapi,aes-cmac-128,aes-gmac-128,aes-gmac-256,none
   sh: out of range
   sh: out of range
   Failed to connect to wpa_supplicant global interface: /var/run/wpa_supplicantglobal  error: No such file or directory
   Enable ol_stats by default for Lithium platforms
   error_handler received : -16
   Failed to send message to driver Error:-16
   cfg80211: ifname: wl0 mode: __ap cfgphy: phy1
   sh: 1: unknown operand
   sh: out of range
   sh: auto: out of range
   sh: out of range
   sh: 1: unknown operand
   OK
   Command failed: Not found
   Command failed: Not found
   /sbin/wifi: eval: line 1: iface_mgr_setup: not found
   device: wifi0 vifs: sta
   device: wifi1 vifs: ap
   [*] Disabling power_save on sta0...
   [*] Checking and creating network.wan section...
   [*] Generating WPA3 config...
   [*] Setting region to US...
   [*] Enabling ip_forward...
   [*] Killing old wpa_supplicant...
   [*] Starting wpa_supplicant in background...
   ```  

</details>  


# 
# Important part:

```
[*] Requesting IP via DHCP...
udhcpc: started, v1.25.1
udhcpc: sending discover
udhcpc: sending select for 192.168.69.34
udhcpc: lease of 192.168.69.34 obtained, lease time 172800
udhcpc: ifconfig sta0 192.168.69.34 netmask 255.255.255.0 broadcast 192.168.69.255
udhcpc: setting default routers: 192.168.69.10
[+] NAT configured. Connect to 5GHz AP: 'Super 5GHz Network'
```

`If your router didnt get IP go to Troubleshooting part`

<details>

  <summary>Configuring firewall to isolate network</summary>
   
   ```
   [+] Configuring firewall
   forwarding
   cfg1dad58
   /usr/sbin/ip_conflict.sh: line 360: arithmetic syntax error
   Warning: Section @zone[1] (wan) cannot resolve device of network 'wan6'
   Warning: Section 'ready_zone' cannot resolve device of network 'ready'
   Warning: Section 'guest_8999' refers to not existing zone 'guest'
   Warning: Section 'guest_8300' refers to not existing zone 'guest'
   Warning: Section 'guest_7080' refers to not existing zone 'guest'
   INFO: FW3 LOCK ON.
   Warning: Section @zone[2] (ready) has no device, network, subnet or extra options
   * Flushing IPv4 filter table
   * Flushing IPv4 nat table
   * Flushing IPv4 mangle table
   * Flushing IPv6 filter table
   * Flushing IPv6 nat table
   * Flushing IPv6 mangle table
   * Flushing conntrack table ...
   * Populating IPv4 filter table
      * Rule 'Allow-DHCP-Renew'
      * Rule 'Allow-Ping'
      * Rule 'DHCP for ready'
      * Rule 'DHCP for ready'
      * Forward 'lan' -> 'wan'
      * Zone 'lan'
      * Zone 'wan'
      * Zone 'ready'
      * Zone 'wan'
      * Zone 'lan'
   * Populating IPv4 nat table
      * Zone 'lan'
      * Zone 'wan'
      * Zone 'ready'
      * Zone 'wan'
      * Zone 'lan'
   * Populating IPv4 mangle table
      * Zone 'lan'
      * Zone 'wan'
      * Zone 'ready'
      * Zone 'wan'
      * Zone 'lan'
   * Set tcp_ecn to off
   * Set tcp_syncookies to on
   * Set tcp_window_scaling to on
   * Running script '/lib/firewall.sysapi.loader webinitrdr'
   * Running script '/lib/firewall.sysapi.loader dnsmiwifi'
   * Running script '/lib/firewall.sysapi.loader macfilter'
   * Running script '/lib/firewall.sysapi.loader ipv6_masq'
   * Running script '/lib/firewall.sysapi.loader miot'
   * Running script '/usr/share/miniupnpd/firewall.include'
   * Running script '/etc/firewall.d/qca-nss-ecm'
   * Running script '/usr/sbin/dualwan.sh set'
   dualwan disabled, so do not set dualwan firewall
   * Running script '/usr/sbin/pluginmanager_firewall reload'
   * Running script '/usr/sbin/dualwifi.sh set_firewall'
   INFO: FW3 LOCK OFF.
   ```

</details>

# Troubleshooting

## Didnt get IP

### Try put `ieee80211w` to `2`

```
network={
    ssid="${SSID}"
    key_mgmt=SAE
    psk="${PSK}"
    ieee80211w=1 # here
    priority=10
}
```

### Try change encryption type of STA

```
ENC="sae" # "sae-mixed" or "psk2"
```


