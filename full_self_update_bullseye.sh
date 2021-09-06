#!/bin/bash 

#fail the script, in case on error
#set -euxo pipefail

#Export Variables
${SUDO} export DEBIAN_FRONTEND=noninteractive
${SUDO} export APT_LISTCHANGES_FRONTEND=none
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`
# screen -d -m /bin/bash -c "$(curl --compressed -sL https://raw.githubusercontent.com/djdomi/linux-bash-scripts/master/full_self_update_bullseye.sh?$(date +%s))"

#Check if we need sudo
if [ "$(whoami)" != "root" ]; then
    echo '[*** using sudo ***]'
	export SUDO=sudo
fi

if [ ! -e "/etc/.refresh_my_update_script" ]; then
	tput clear
		echo 'Step 01-[*** /etc/.refresh_my_update_script was missing ***]'
		echo 'Step 01-[*** Removing all generated files' ***]
	${SUDO} rm -f /etc/cron.d/self-update
	${SUDO} rm -f /etc/logrotate.d/0000_compress_all
	${SUDO} rm -f /etc/.locale.is_generated
	${SUDO} rm -f /etc/apt/sources.list.d/.main.list_was_set_automaticly_aready
	${SUDO} rm -f /etc/apt/apt.conf.d/.cache_disable_was_set_automaticly_already
	${SUDO} rm -f /etc/apt/apt.conf.d/.proxy_was_set_automaticly_already
	${SUDO} rm -f /etc/apt/sources.list.d/.packages.sury.org.list
	${SUDO} rm -f /etc/apt/apt.conf.d/*proxy*
	${SUDO} touch /etc/.refresh_my_update_script
		else 
			echo 'Step 01-[*** /etc/.refresh_my_update_script was there, we did not update all ***]'
fi
	
#pre-run dpkg, if it failed previously

echo 'Step 02-[*** Checking for already, broken installation ***]'
dpkg --configure -a --force-confold --force-confdef



# generate locales
if [ ! -e "/etc/.locale.is_generated" ]; then
		echo 'Step 03-[***  generating locales, please wait ***]'
${SUDO} echo -e de_DE ISO-8859-1\\nde_DE.UTF-8 UTF-8\\nde_DE@euro ISO-8859-15\\nen_US ISO-8859-1\\nen_US.ISO-8859-15 ISO-8859-15\\nen_US.UTF-8 UTF-8  | tee /etc/locale.gen  2>&1 >/dev/null
${SUDO} locale-gen   2>&1 >/dev/null
${SUDO} export LANGUAGE=$LC_ALL
${SUDO} export LANG=$LC_ALL
${SUDO} export LC_ALL=de_DE.UTF-8
touch /etc/.locale.is_generated
	#tput clear
	else
	echo 'Step 03-[*** Skipped ***]'
fi 

#${SUDO} export LC_ALL=$LANG

echo 'Step 04-[*** Always Creating locale.purge as pre-selection file. ***]'
${SUDO}  echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge  2>&1 >/dev/null


# Install pre-requirements
#tput clear

echo 'Step 05-[*** Always installing pre-requirement Packages via apt-get ***]'
${SUDO} apt-get -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" -yqqqq install screen apt-file locate apt-transport-https lsb-release ca-certificates curl localepurge aria2 software-properties-common
#tput clear

#test of files, that i want to have removed

if [ ! -e "/etc/cron.d/self-update" ]; then
	echo 'Step 06-[*** Adding cronjob for self updating ***]'
    ${SUDO} echo '@daily root screen -d -m /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/djdomi/linux-bash-scripts/master/full_self_update_bullseye.sh)" 2>&1>/dev/null' | tee /etc/cron.d/self-update
	${SUDO} chmod 644 /etc/cron.d/self-update
	#tput clear
	else
		echo 'Step 06-[*** Skipped ***]'
fi 

if [ ! -e "/etc/apt/apt.conf.d/.proxy_was_set_automaticly_already" ]; then
    echo 'Step 07-[*** Deleting old proxy config ***]'
		${SUDO} rm -f /etc/apt/apt.conf.d/*proxy*
		${SUDO} echo 'Acquire::ForceIPv4 "true";' >/etc/apt/apt.conf.d/99force-ipv4
		${SUDO} echo 'Acquire::http::proxy "http://10.0.0.1:9999"; ' | tee /etc/apt/apt.conf.d/99proxy 2>&1 >/dev/null 
		${SUDO} touch /etc/apt/apt.conf.d/.proxy_was_set_automaticly_already
	#tput clear
	else 
		echo 'Step 07-[*** Skipped ***]'
fi

#disable apt caching behavior due we use apt-cacher-ng and want to save the space

if [ ! -e "/etc/apt/apt.conf.d/.cache_disable_was_set_automaticly_already" ]; then
    echo 'Step 08-[******* deleting cache configurations *******]'
		${SUDO} rm -f etc/apt/apt.conf.d/dont_keep_download_files /etc/apt/apt.conf.d/00_disable-cache-directories
		${SUDO} echo 'Binary::apt::APT::Keep-Downloaded-Packages "false";'	| tee /etc/apt/apt.conf.d/dont_keep_download_files 2>&1 >/dev/null
		${SUDO} echo -e 'Dir::Cache "";\nDir::Cache::archives "";'			| tee  /etc/apt/apt.conf.d/00_disable-cache-directories 2>&1 >/dev/null
		${SUDO} touch /etc/apt/apt.conf.d/.cache_disable_was_set_automaticly_already
	#tput clear
	else
		echo 'Step 08-[*** Skipped ***]'
	
fi

#add default compress options to /etc/logroate.d

if [ ! -e "/etc/logrotate.d/0000_compress_all" ]; then
    echo 'Step 09-[** adding /etc/logrotate.d/0000_compress_all ***]'
		${SUDO} echo -e compress\\ncompresscmd /usr/bin/xz\\nuncompresscmd /usr/bin/unxz\\ncompressext .xz\\ncompressoptions -T6 -9\\nmaxsize 50M | tee /etc/logrotate.d/0000_compress_all  2>&1 >/dev/null
	#tput clear
	else
		echo 'Step 09-[*** Skipped ***]'
fi

#sury.org packages
echo 'step 10-[*** Always Updating 3rd party GPG-Keys ***]'
${SUDO} test -f /etc/apt/trusted.gpg.d/bind.gpg && rm -f /etc/apt/trusted.gpg.d/bind.gpg 
${SUDO} test -f /etc/apt/trusted.gpg.d/php.gpg && rm -f /etc/apt/trusted.gpg.d/php.gpg
${SUDO} wget -qO /etc/apt/trusted.gpg.d/bind.gpg https://packages.sury.org/bind-dev/apt.gpg 
${SUDO} wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

if [ ! -e "/etc/apt/sources.list.d/.packages.sury.org.list" ]; then
		echo 'Step 11-[*** Updating Third-Party Source ***]'
${SUDO} echo 'deb https://packages.sury.org/php/  bullseye main' | tee /etc/apt/sources.list.d/bind.list 2>&1 >/dev/null
${SUDO} echo 'deb https://packages.sury.org/bind-dev/ bullseye main' | tee /etc/apt/sources.list.d/php.list  2>&1 >/dev/null
	${SUDO}	echo > /etc/apt/sources.list.d/.packages.sury.org.list
	else
		echo 'Step 11-[*** Skipped ***]'
fi

#Update sources.list.d

if [ ! -e "/etc/apt/sources.list.d/.main.list_was_set_automaticly_aready" ]; then
		#tput clear
			echo 'Step 12-[*** Clearing sources.list since we use /etc/apt/sources.list.d/main.list ***]'
			${SUDO} echo > /etc/apt/sources.list
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
	else
		echo 'Step 12-[*** Skipped ***]'
	#tput clear
fi

# start apt stuff
echo Done, updating sources.
${SUDO} apt-get -qqqqq update 
#tput clear
echo '[*** Well... Lets Starting system upgrade... Please be Patient ***]'
DEBIAN_FRONTEND=noninteractive 
${SUDO} apt-get -qqqqqqy -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" dist-upgrade  2>&1 > /var/log/autoupdate.log
#tput clear


echo Fine also, lets remove unneded stuff
${SUDO} apt-get -qqqqqy autoremove 
${SUDO} rm -fr /var/cache/apt/archives/*
${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8 | tee /etc/locale.nopurge 2>&1 >/dev/null
${SUDO} /usr/sbin/localepurge 2>&1 >/dev/null
#tput clear
# Self Explaining, Testing if Reboot is  requrired, and if, we DO it 
if [ -f /var/run/reboot-required ] 
then
	#tput clear
			echo -e {RED}[*** reboot is required for your machine ***] {NC}
			echo -e '[*** 10 Seconds remainig ***]'
					sync
					sleep 10
				reboot
	else
		#tput clear
		sync
			echo ''
			echo "${GREEN}[*** no reboot required ***]${NC}"
			echo '[*** remind, when /etc/.refresh_my_update_script Exists, we dont force a full update ***]'
			echo ''
fi
