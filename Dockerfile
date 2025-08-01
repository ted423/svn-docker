# Alpine Linux with s6 service management
FROM alpine:3.22.1

	# Install Apache2 and other stuff needed to access svn via WebDav
	# Install svn
	# Installing utilities for SVNADMIN frontend
	# Create required folders
	# Create the authentication file for http access
	# Getting SVNADMIN interface
RUN apk update
RUN apk upgrade
RUN apk add --no-cache apache2 apache2-utils apache2-webdav mod_dav_svn s6-overlay &&\
	apk add --no-cache subversion &&\
	apk add --no-cache wget unzip php83 php83-apache2 php83-session php83-json php83-ldap &&\
	sed -i 's/;extension=ldap/extension=ldap/' /etc/php83/php.ini &&\
	apk add --no-cache php83-xml &&\	
	mkdir -p /run/apache2/ &&\
	mkdir /home/svn/ &&\
	mkdir /etc/subversion &&\
	touch /etc/subversion/passwd &&\
    wget --no-check-certificate https://github.com/mfreiholz/iF.SVNAdmin/archive/refs/heads/master.zip &&\
	unzip master.zip -d /opt &&\
	rm master.zip &&\
	mv /opt/iF.SVNAdmin-master /opt/svnadmin &&\
	ln -s /opt/svnadmin /var/www/localhost/htdocs/svnadmin &&\
	chmod -R 777 /opt/svnadmin/data 



# Fixing https://github.com/mfreiholz/iF.SVNAdmin/issues/118
ADD svnadmin/classes/util/global.func.php /opt/svnadmin/classes/util/global.func.php

# Add services configurations
ADD apache/ /etc/services.d/apache/
ADD subversion/ /etc/services.d/subversion/

# Add SVNAuth file
ADD subversion-access-control /etc/subversion/subversion-access-control
RUN chmod a+w /etc/subversion/* && chmod a+w /home/svn && chmod +x /etc/services.d/apache/run && chmod +x /etc/services.d/subversion/run

# Add WebDav configuration
ADD dav_svn.conf /etc/apache2/conf.d/dav_svn.conf

# Set HOME in non /root folder
ENV HOME /home

# Expose ports for http and custom protocol access
EXPOSE 80 443 3690
ENTRYPOINT ["/init"]
CMD []