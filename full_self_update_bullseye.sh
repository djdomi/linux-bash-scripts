#!/bin/bash -e

#fail the script, in case on error
#set -euxo pipefail

# screen -d -m /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/djdomi/linux-bash-scripts/master/full_self_update_bullseye.sh)"

#Check if we need sudo
if [ "$(whoami)" != "root" ]; then
    echo i need to use sudo
	export SUDO=sudo
	
	
fi

if [ ! -e "/etc/.refresh_my_update_script" ]; then
	echo 'Remvoing all generated files'
	rm /etc/cron.d/self-update
	rm /etc/.locale.is_generated
	rm 
fi
	


#pre-run dpkg, if it failed previously

dpkg --configure -a --force-confold --force-confdef

#Export Variables
echo Settings variables
${SUDO} export DEBIAN_FRONTEND=noninteractive
${SUDO} export APT_LISTCHANGES_FRONTEND=none
${SUDO} export cronfile=/etc/cron.d/self-update
tput clear
# generate locales
if [ ! -e "/etc/.locale.is_generated" ]; then
echo generating locales, please wait
${SUDO} echo -e de_DE ISO-8859-1\\nde_DE.UTF-8 UTF-8\\nde_DE@euro ISO-8859-15\\nen_US ISO-8859-1\\nen_US.ISO-8859-15 ISO-8859-15\\nen_US.UTF-8 UTF-8  | tee /etc/locale.gen  2>&1 >/dev/null
${SUDO} locale-gen   2>&1 >/dev/null
touch /etc/.locale.is_generated
	tput clear
fi 

${SUDO} export LANGUAGE=en_US.UTF-8
${SUDO} export LANG=en_US.UTF-8
${SUDO} export LC_ALL=en_US.UTF-8

#${SUDO} export LC_ALL=$LANG

echo creating locale.purge as pre-selection file.
${SUDO}  echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge  2>&1 >/dev/null


# Install pre-requirements
tput clear

echo 'installing pre-requirements'
${SUDO} apt-get -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" -yqqqq install apt-file locate apt-transport-https lsb-release ca-certificates curl localepurge aria2 software-properties-common
tput clear

#test of files, that i want to have removed

if [ ! -e "$cronfile" ]; then
    ${SUDO} echo '@daily root screen -d -m /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/djdomi/linux-bash-scripts/master/full_self_update_bullseye.sh)" 2>&1>/dev/null' | tee $cronfile	
	${SUDO} chmod 644 /etc/cron.d/self-update
	tput clear
fi 

echo 'removing apt-listchanges, it sucks a lot..'
${SUDO} test -f /etc/apt/apt.conf.d/20listchanges && ${SUDO}  apt -qqqqqqy remove --purge apt-listchanges; echo 'removed apt-listchanges, next step'

if [ ! -e "/etc/apt/apt.conf.d/.proxy_was_set_automaticly_already" ]; then
    echo deleting old proxy config
		${SUDO} rm -f /etc/apt/apt.conf.d/*proxy*
		${SUDO} touch /etc/apt/apt.conf.d/.proxy_was_set_automaticly_already
	tput clear
fi





if [ ! -e "$proxyfile" ]; then
    echo adding $proxyfile
		${SUDO} echo 'Acquire::http::proxy "http://10.0.0.1:9999"; ' | tee $proxyfile 2>&1 >/dev/null | tee $proxyfile	
	tput clear
fi


#disable apt caching behavior due we use apt-cacher-ng and want to save the space

if [ ! -e "/etc/apt/apt.conf.d/.cache_disable_was_set_automaticly_already" ]; then
    echo deleting old proxy config
		${SUDO} rm -f etc/apt/apt.conf.d/dont_keep_download_files /etc/apt/apt.conf.d/00_disable-cache-directories
		${SUDO} echo 'Binary::apt::APT::Keep-Downloaded-Packages "false";'	| tee /etc/apt/apt.conf.d/dont_keep_download_files 2>&1 >/dev/null
		${SUDO} echo -e 'Dir::Cache "";\nDir::Cache::archives "";'			| tee  /etc/apt/apt.conf.d/00_disable-cache-directories 2>&1 >/dev/null
		${SUDO} touch /etc/apt/apt.conf.d/.cache_disable_was_set_automaticly_already
	tput clear
fi


#add default compress options to /etc/logroate.d

if [ ! -e "/etc/logrotate.d/0000_compress_all" ]; then
    echo 'adding /etc/logrotate.d/0000_compress_all'
		${SUDO} echo -e compress\\ncompresscmd /usr/bin/xz\\nuncompresscmd /usr/bin/unxz\\ncompressext .xz\\ncompressoptions -T6 -9\\nmaxsize 50M | tee /etc/logrotate.d/0000_compress_all  2>&1 >/dev/null
	tput clear
fi


#sury.org packages
echo 'Updating 3rd party Sources'
${SUDO} test -f /etc/apt/trusted.gpg.d/bind.gpg && rm -f /etc/apt/trusted.gpg.d/bind.gpg 
${SUDO} test -f /etc/apt/trusted.gpg.d/php.gpg && rm -f /etc/apt/trusted.gpg.d/php.gpg
${SUDO} wget -qO /etc/apt/trusted.gpg.d/bind.gpg https://packages.sury.org/bind/apt.gpg 
${SUDO} wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
${SUDO} echo 'deb https://packages.sury.org/php/ bullseye main'   | tee /etc/apt/sources.list.d/bind.list 2>&1 >/dev/null
${SUDO} echo 'deb https://packages.sury.org/bind/ bullseye main' | tee /etc/apt/sources.list.d/bind.list 2>&1 >/dev/null
tput clear

#Update source.list (make it empty)

${SUDO} echo ''																								| tee /etc/apt/sources.list
tput clear

#Update sources.list.d

if [ ! -e "/etc/apt/sources.list.d/.main.list_was_set_automaticly_aready" ]; then
			echo 'clearing sources.list since we use /etc/apt/sources.list.d/main.list'
				rm -f /etc/apt/sources.list.d/main.list
		${SUDO} echo 'deb     http://deb.debian.org/debian bullseye main contrib non-free'							| tee    /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye main contrib non-free'							| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb     http://deb.debian.org/debian-security/ bullseye-security main contrib non-free' 		| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free' 		| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb     http://deb.debian.org/debian bullseye-updates main contrib non-free' 					| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free' 					| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb     http://deb.debian.org/debian bullseye-backports main contrib non-free' 				| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free' 				| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free'				| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} echo 'deb-src http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free'			| tee -a /etc/apt/sources.list.d/main.list 2>&1 >/dev/null
		${SUDO} touch /etc/apt/sources.list.d/.main.list_was_set_automaticly_aready


	tput clear
fi



#we re-set the Options we want to use



# start apt stuff
echo Done, updating sources.
${SUDO} apt-get -qqqqq update 
tput clear
echo fine, starting system upgrade... Please be Patient
DEBIAN_FRONTEND=noninteractive 
${SUDO} apt-get -qqqqqqy -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" dist-upgrade 
tput clear


echo Fine also, lets remove unneded stuff
${SUDO} apt-get -qqqqqy autoremove 
${SUDO} rm -fr /var/cache/apt/archives/*
${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge 2>&1 >/dev/null
${SUDO} /usr/sbin/localepurge
tput clear
# Self Explaining, Testing if Reboot is  requrired, and if, we DO it 
if [ -f /var/run/reboot-required ] 
then
	tput clear
			echo "[*** reboot is required for your machine ***]"
			echo "[*** 10 Seconds ***]"
				reboot
	else
		tput clear
			echo "[*** all is fine, no reboot required ***]"
fi
