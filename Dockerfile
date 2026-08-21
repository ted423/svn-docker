# Alpine Linux with s6 service management
FROM alpine:3.24.1

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
    apk add --no-cache wget unzip php83 php83-apache2 php83-session php83-json php83-ldap apache2-ldap &&\
    sed -i 's/;extension=ldap/extension=ldap/' /etc/php83/php.ini &&\
    apk add --no-cache php83-xml &&\    
    mkdir -p /run/apache2/ &&\
    mkdir /home/svn/ &&\
    mkdir /etc/subversion &&\
    touch /etc/subversion/passwd

# If you want to use a local file, please comment out the following line
RUN wget --no-check-certificate https://github.com/ted423/iF.SVNAdmin/archive/refs/heads/master.zip && unzip master.zip -d /opt && rm master.zip && mv /opt/iF.SVNAdmin-master /opt/svnadmin

# use file local(unzip and put in svnadmin manual)
# ADD svnadmin /opt/svnadmin
 

RUN ln -s /opt/svnadmin /var/www/localhost/htdocs/svnadmin &&\
    chmod -R 777 /opt/svnadmin/data 

# Add services configurations
ADD apache/ /etc/services.d/apache/
ADD subversion/ /etc/services.d/subversion/

# Add SVNAuth file
ADD subversion-access-control /etc/subversion/subversion-access-control
RUN chmod a+w /etc/subversion/* && chmod a+w /home/svn && chmod +x /etc/services.d/apache/run && chmod +x /etc/services.d/subversion/run

# Add WebDav configuration
ADD dav_svn.conf /etc/apache2/conf.d/dav_svn.conf

# update apache2 default config
RUN sed -i \
    -e 's/^\(Timeout\s\+\)[0-9]\+/\112000/' \
    -e 's/^\(KeepAliveTimeout\s\+\)[0-9]\+/\115/' \
    "/etc/apache2/conf.d/default.conf"

# Set HOME in non /root folder
ENV HOME /home

# Expose ports for http and custom protocol access
EXPOSE 80 443 3690
ENTRYPOINT ["/init"]
CMD []