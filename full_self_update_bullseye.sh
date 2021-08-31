
#Check if we need sudo
if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi
${SUDO} export LC_ALL=$LANG

# Install pre-requirements
${SUDO} apt-get -y install apt-transport-https lsb-release ca-certificates curl localepurge aria2c

#Export Variables we want to use
${SUDO} export DEBIAN_FRONTEND=noninteractive
${SUDO} export APT_LISTCHANGES_FRONTEND=none

#test of files, that i want to have removed
${SUDO} test -f /etc/apt/apt.conf.d/20listchanges && tee /etc/apt/apt.conf.d/20listchanges
${SUDO} rm /etc/apt/apt.conf.d/*proxy*; echo Acquire::http::proxy "http://10.0.0.1:9999"; 				| tee /etc/apt/apt.conf.d/99_default_proxy

#disable apt caching behavior due we use apt-cacher-ng and want to save the space
${SUDO} echo   'Binary::apt::APT::Keep-Downloaded-Packages "false";' 									| tee /etc/apt/apt.conf.d/dont_keep_download_files
${SUDO} echo   'Dir::Cache "";nDir::Cache::archives "";' 												| tee  /etc/apt/apt.conf.d/00_disable-cache-directories


#add default compress options to /etc/logroate.d
${SUDO} echo -e compress\\ncompresscmd /usr/bin/xz\\nuncompresscmd /usr/bin/unxz\\ncompressext .xz\\ncompressoptions -T6 -9\\nmaxsize 50M | tee /etc/logrotate.d/0000_compress_all
${SUDO} apt-get update

#bind 9 source

${SUDO} wget -O /etc/apt/trusted.gpg.d/bind.gpg https://packages.sury.org/bind/apt.gpg
${SUDO} sh -c 'echo "deb https://packages.sury.org/bind/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/bind.list'




#Update source.list (make it empty)
${SUDO} echo 																							| tee /etc/apt/sources.list 

#Update sources.list.d
${SUDO} echo deb     http://deb.debian.org/debian bullseye main contrib non-free						| tee /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian bullseye main contrib non-free 						| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb     http://deb.debian.org/debian-security/ bullseye-security main contrib non-free 	| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free 	| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb     http://deb.debian.org/debian bullseye-updates main contrib non-free 				| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free 				| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb     http://deb.debian.org/debian bullseye-backports main contrib non-free 				| tee -a /etc/apt/sources.list.d/main.list
${SUDO} echo deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free 				| tee -a /etc/apt/sources.list.d/main.list



${SUDO} echo -e USE_DPKG\\nMANDELETE\\nDONTBOTHERNEWLOCALE\\nSHOWFREEDSPACE\\nde\\nde_DE\\nde_DE.UTF-8\\nde_DE@euro\\nen\\nen_US\\nen_US.ISO-8859-15\\nen_US.UTF-8




# start apt stuff
${SUDO} apt-get update
${SUDO} apt-get dist-upgrade
${SUDO} apt-get autoremove
${SUDO} rm /var/cache/apt/archives/*
${SUDO} /usr/sbin/localepurge
