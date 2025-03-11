ip link show | awk -F': ' '/^[0-9]+: / {print $2}'
read -p "vyberte WIFI kartu: " wlancard

echo """ctrl_interface=/run/wpa_supplicant
update_config=1 """ > /etc/wpa_supplicant/wpa_supplicant-${wlancard}.conf
read -p "SSID: " ssid
read -p "PSK: " psk
wpa_passphrase ${ssid} ${psk} >> /etc/wpa_supplicant/wpa_supplicant-${wlancard}.conf
wpa_supplicant -B -i ${wlancard} -c /etc/wpa_supplicant/wpa_supplicant-${wlancard}.conf
