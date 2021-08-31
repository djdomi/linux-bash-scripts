export LC_ALL=$LANG
#Check if we need sudo
if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

#Export Variables we want to use
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

#test of files, that i want to have removed



${SUDO} echo 'Binary::apt::APT::Keep-Downloaded-Packages "false";' | tee /etc/apt/apt.conf.d/dont_keep_download_files
${SUDO} echo  'Dir::Cache "";nDir::Cache::archives "";' | tee  /etc/apt/apt.conf.d/00_disable-cache-directories
${SUDO} echo -e compress\\ncompresscmd /usr/bin/xz\\nuncompresscmd /usr/bin/unxz\\ncompressext .xz\\ncompressoptions -T6 -9\\nmaxsize 50M
${SUDO} apt-get update

#bind 9
${SUDO} apt-get -y install apt-transport-https lsb-release ca-certificates curl localepurge
${SUDO} wget -O /etc/apt/trusted.gpg.d/bind.gpg https://packages.sury.org/bind/apt.gpg
${SUDO} sh -c 'echo "deb https://packages.sury.org/bind/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/bind.list'



#Update source.list
#Update source.list

${SUDO} echo 																						| tee /etc/apt/sources.list 
${SUDO} echo deb     http://deb.debian.org/debian bullseye main contrib non-free					| tee /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian bullseye main contrib non-free 					| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb     http://deb.debian.org/debian-security/ bullseye-security main contrib non-free | tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free | tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb     http://deb.debian.org/debian bullseye-updates main contrib non-free 			| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free 			| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb     http://deb.debian.org/debian bullseye-backports main contrib non-free 			| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free 			| tee -a /etc/apt/sources.list.d/main.list



${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8




# start apt stuff
${SUDO} apt-get update

/usr/sbin/localepurge

