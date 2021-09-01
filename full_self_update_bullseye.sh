#!/bin/bash 

#fail the script, in case on error
#set -euxo pipefail

# /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/djdomi/linux-bash-scripts/master/full_self_update_bullseye.sh)"
#Check if we need sudo
if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

#pre-run dpkg, if it failed previously

dpkg --configure -a --force-confold --force-confdef

#Export Variables
${SUDO} export DEBIAN_FRONTEND=noninteractive
${SUDO} export APT_LISTCHANGES_FRONTEND=none

#${SUDO} export LC_ALL=$LANG
${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge
# Install pre-requirements

${SUDO} apt-get -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" -yqqqq install apt-transport-https lsb-release ca-certificates curl localepurge aria2 software-properties-common debconf-apt-progress


#test of files, that i want to have removed
${SUDO} test -f /etc/apt/apt.conf.d/20listchanges && apt -y remove --purge apt-listchanges
${SUDO} rm -f /etc/apt/apt.conf.d/*proxy* 
${SUDO} echo 'Acquire::http::proxy "http://10.0.0.1:9999"; ' | tee /etc/apt/apt.conf.d/99_default_proxy 2>&1 >/dev/null

#disable apt caching behavior due we use apt-cacher-ng and want to save the space
${SUDO} echo 'Binary::apt::APT::Keep-Downloaded-Packages "false";' | tee /etc/apt/apt.conf.d/dont_keep_download_files 2>&1 >/dev/null
${SUDO} echo 'Dir::Cache "";nDir::Cache::archives "";' | tee  /etc/apt/apt.conf.d/00_disable-cache-directories 2>&1 >/dev/null


#add default compress options to /etc/logroate.d
${SUDO} echo -e compress\\ncompresscmd /usr/bin/xz\\nuncompresscmd /usr/bin/unxz\\ncompressext .xz\\ncompressoptions -T6 -9\\nmaxsize 50M | tee /etc/logrotate.d/0000_compress_all

#sury.org packages
rm -f /etc/apt/trusted.gpg.d/bind.gpg /etc/apt/trusted.gpg.d/php.gpg
${SUDO} wget -qO /etc/apt/trusted.gpg.d/bind.gpg https://packages.sury.org/bind/apt.gpg 
${SUDO} wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
${SUDO} echo 'deb https://packages.sury.org/php/ bullseye main'   | tee /etc/apt/sources.list.d/bind.list 2>&1 >/dev/null
${SUDO} echo 'deb https://packages.sury.org/bind/ bullseye main' | tee /etc/apt/sources.list.d/bind.list 2>&1 >/dev/null

tput clear

echo '(re-)adding sources'


#Update source.list (make it empty)
${SUDO} echo ''																							| tee /etc/apt/sources.list 2>&1 >/dev/null

#Update sources.list.d
${SUDO} echo 'deb     http://deb.debian.org/debian bullseye main contrib non-free'							| tee /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye main contrib non-free'							| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb     http://deb.debian.org/debian-security/ bullseye-security main contrib non-free' 		| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free' 		| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb     http://deb.debian.org/debian bullseye-updates main contrib non-free' 					| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free' 					| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb     http://deb.debian.org/debian bullseye-backports main contrib non-free' 				| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free' 				| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free'				| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free'			| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null


#we re-set the Options we want to use
${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge 2>&1 >/dev/null



# start apt stuff
echo Done, updating sources.
${SUDO} apt-get -qqqqq update 
tput clear
echo fine, starting system upgrade... Please be Patient
DEBIAN_FRONTEND=noninteractive 
${SUDO} apt-get dist-upgrade -qqqqqy -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold"
tput clear
echo Fine also, lets remove unneded stuff
${SUDO} apt-get -qqqqqy autoremove 
${SUDO} rm -fr /var/cache/apt/archives/*
${SUDO} /usr/sbin/localepurge
tput clear
# Self Explaining, Testing if Reboot is  requrired, and if, we DO it 
if [ -f /var/run/reboot-required ] 
then
    echo "[*** reboot is required for your machine ***]"
	reboot
	else
	tput clear
	clear
	echo "[*** all is fine, no reboot required ***]"
fi
