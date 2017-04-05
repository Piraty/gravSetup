#!/bin/sh

## date: 2017-04-03
## 
## run as root
## 

## modify this if needed
readonly GRAV_VERSION="1.2.0"
readonly SUB_DIR="/grav" #/grav

readonly WEBROOT="/srv/www/lighttpd"
readonly WEBSERVER_CRED="_lighttpd"

readonly USERNAME="user"



## config files
readonly _LIGHTTP_GRAV_CONFIG="https://raw.githubusercontent.com/Piraty/gravSetup/master/files/lighttpd.grav.conf"
readonly _LIGHTTP_PHP_CONFIG="https://raw.githubusercontent.com/Piraty/gravSetup/master/files/lighttpd.php.conf"
readonly _LIGHTTP_LOG_CONFIG="https://raw.githubusercontent.com/Piraty/gravSetup/master/files/lighttpd.log.conf"
readonly _LIGHTTP_MIMETYPES_CONFIG="https://raw.githubusercontent.com/Piraty/gravSetup/master/files/lighttpd.mimetypes.conf"

## static
readonly _GRAV_DISTFILE="https://github.com/getgrav/grav/releases/download/${GRAV_VERSION}/grav-admin-v${GRAV_VERSION}.zip"


xbps-install -Syu && xbps-install -Syu && xbps-install -y xtools

## some tools needed
xi -y nano nmap curl unzip

## install webserver + tools
xi -y lighttpd php php-cgi php-gd

	## install certain php related tools
	

	## configuration: lighthttpd
	mkdir /etc/lighttpd/conf.d

		## load some modules (https://redmine.lighttpd.net/projects/lighttpd/wiki/Server_modulesDetails)	
		echo "server.modules = (\"mod_rewrite\",\"mod_redirect\",\"mod_alias\",\"mod_access\",\"mod_auth\")" >> /etc/lighttpd/lighttpd.conf
	
		## add mimetypes
		[ -d /etc/lighttpd/conf.d ] &&
		curl ${_LIGHTTP_MIMETYPES_CONFIG} > /etc/lighttpd/conf.d/mimetypes.conf &&
		sed -i "/mimetype.assign/s/^/#/" /etc/lighttpd/lighttpd.conf && #remove default mimetypes via comment
		echo "include \"conf.d/mimetypes.conf\"" >> /etc/lighttpd/lighttpd.conf || exit 1
	
	## configuration: php
	php-cgi --version &&
	[ -d /etc/lighttpd/conf.d ] &&
	curl ${_LIGHTTP_PHP_CONFIG} > /etc/lighttpd/conf.d/php.conf && 
	echo "include \"conf.d/php.conf\"" >> /etc/lighttpd/lighttpd.conf || exit 1
	
	
	## configuration: php.ini
	xi -y gd libzip
	[ -f /etc/php/php.ini ] &&
	sed -i 's/;extension=openssl.so/extension=openssl.so/g' /etc/php/php.ini &&
	sed -i 's/;extension=gd.so/extension=gd.so/g' /etc/php/php.ini && 
	sed -i 's/;extension=zip.so/extension=zip.so/g' /etc/php/php.ini &&
	sed -i 's/;extension=phar.so/extension=phar.so/g' /etc/php/php.ini &&
	sed -i 's/display_errors = Off/display_errors = On/g' /etc/php/php.ini || exit 1
	
	## configure the webserver to find grav
	## provide grav's specific configuration
	[ -d /etc/lighttpd/conf.d ] &&
	curl ${_LIGHTTP_GRAV_CONFIG} > /etc/lighttpd/conf.d/grav.conf &&
	echo "s,/grav_path,${SUB_DIR},g" &&
	sed -i  "s,/grav_path,${SUB_DIR},g" /etc/lighttpd/conf.d/grav.conf &&
	echo "include \"conf.d/grav.conf\"" >> /etc/lighttpd/lighttpd.conf || exit 1
	
	## configuration: basic logging
	[ -d /etc/lighttpd/conf.d ] &&
	curl ${_LIGHTTP_LOG_CONFIG} > /etc/lighttpd/conf.d/log.conf && 
	echo "include \"conf.d/log.conf\"" >> /etc/lighttpd/lighttpd.conf || exit 1

	
	## activate the service
	lighttpd -tt -f /etc/lighttpd/lighttpd.conf &&  #check lighttp's configuration
	ln -s /etc/sv/lighttpd /var/service ||
	exit 1


### install ftp server
#xi -y vsftpd
#	
#	## configuration
#	echo "seccomp_sandbox=NO" >> /etc/vsftpd.conf #connection drop issue
#	
#	## activate the service	
#	ln -s /etc/ev/vsftpd /var/service


## fetch grav

	xi -y wget
	mkdir "grav.tmp" &&
	wget ${_GRAV_DISTFILE} &&
	unzip ${_GRAV_DISTFILE##*/} -d grav.tmp &&
	cp -a "grav.tmp/grav-admin/." ${WEBROOT}/${SUB_DIR} && #mv  "grav.tmp/grav-admin/." ${WEBROOT}/${SUB_DIR} &&
	rm -r grav.tmp || exit 1

## install grav
	## set permissions
	
	chown -R ${USERNAME}:${WEBSERVER_CRED} ${WEBROOT}/${SUB_DIR}
	
	cd ${WEBROOT}/${SUB_DIR}
	find . -type f | xargs chmod 664
	find ./bin -type f | xargs chmod 775
	find . -type d | xargs chmod 775
	find . -type d | xargs chmod +s


	
	echo "---- DONE"
	echo "now: set the umask for your user (${USERNAME})to 0002"
	echo "even better: add it to .bashrc or similar"
