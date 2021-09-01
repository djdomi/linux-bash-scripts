#!/bin/bash
# /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/djdomi/linux-bash-scripts/master/full_self_update_bullseye.sh)"
#Check if we need sudo
if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi
${SUDO} export LC_ALL=$LANG
${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge
# Install pre-requirements
${SUDO} apt-get -y install apt-transport-https lsb-release ca-certificates curl localepurge aria2

#Export Variables we want to use
${SUDO} export DEBIAN_FRONTEND=noninteractive
${SUDO} export APT_LISTCHANGES_FRONTEND=none
apt 
#test of files, that i want to have removed
${SUDO} test -f /etc/apt/apt.conf.d/20listchanges && apt -y remove --purge apt-listchanges
${SUDO} rm -f /etc/apt/apt.conf.d/*proxy* 
${SUDO} echo 'Acquire::http::proxy "http://10.0.0.1:9999"; ' | tee /etc/apt/apt.conf.d/99_default_proxy 2&>1 >/dev/null

#disable apt caching behavior due we use apt-cacher-ng and want to save the space
${SUDO} echo 'Binary::apt::APT::Keep-Downloaded-Packages "false";' | tee /etc/apt/apt.conf.d/dont_keep_download_files 2&>1 >/dev/null
${SUDO} echo 'Dir::Cache "";nDir::Cache::archives "";' | tee  /etc/apt/apt.conf.d/00_disable-cache-directories 2&>1 >/dev/null


#add default compress options to /etc/logroate.d
${SUDO} echo -e compress\\ncompresscmd /usr/bin/xz\\nuncompresscmd /usr/bin/unxz\\ncompressext .xz\\ncompressoptions -T6 -9\\nmaxsize 50M | tee /etc/logrotate.d/0000_compress_all

#bind 9 source

${SUDO} wget -O /etc/apt/trusted.gpg.d/bind.gpg https://packages.sury.org/bind/apt.gpg
${SUDO} sh -c 'echo "deb https://packages.sury.org/bind/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/bind.list'

clear

echo adding sources


#Update source.list (make it empty)
${SUDO} echo ''																							| tee /etc/apt/sources.list 2&>1 >/dev/null

#Update sources.list.d
${SUDO} echo 'deb     http://deb.debian.org/debian bullseye main contrib non-free'							| tee /etc/apt/sources.list.d/main.list 2&>1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye main contrib non-free'							| tee -a /etc/apt/sources.list.d/main.list 2&>1 >/dev/null
${SUDO} echo 'deb     http://deb.debian.org/debian-security/ bullseye-security main contrib non-free' 		| tee -a /etc/apt/sources.list.d/main.list 2&>1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free' 		| tee -a /etc/apt/sources.list.d/main.list 2&>1 >/dev/null
${SUDO} echo 'deb     http://deb.debian.org/debian bullseye-updates main contrib non-free' 					| tee -a /etc/apt/sources.list.d/main.list 2&>1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free' 					| tee -a /etc/apt/sources.list.d/main.list 2&>1 >/dev/null
${SUDO} echo 'deb     http://deb.debian.org/debian bullseye-backports main contrib non-free' 				| tee -a /etc/apt/sources.list.d/main.list 2&>1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free' 				| tee -a /etc/apt/sources.list.d/main.list 2&>1 >/dev/null

${SUDO} clear
${SUDO} tput clear


${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge 2&>1 >/dev/null

clear


# start apt stuff
${SUDO} apt-get update -qy
${SUDO} apt-get dist-upgrade -y
${SUDO} apt-get autoremove -y
${SUDO} rm -fr /var/cache/apt/archives/*
${SUDO} /usr/sbin/localepurge


if [ -f /var/run/reboot-required ] 
then
    echo "[*** reboot is required for your machine ***]"
	reboot
	else
	echo "[*** all is fine, no reboot required ***]"
fi
