#!/bin/bash

APACHE_COMMAND=apache2
APACHE_SERVICE=apache2
APACHE_USER=www-data
SUDO_GROUP=sudo
MYSQL_SERVICE=mysql
PHP_FPM_SERVICE=
APACHE_PACKAGES=(apache2)
PHP_PACKAGES=(php libapache2-mod-php php-mysql php-cli php-curl php-mbstring php-xml php-zip php-gd php-intl)
MYSQL_PACKAGES=(mysql-server)
JAVA_PACKAGES=(default-jdk)
PDFJAM_PACKAGES=(texlive-extra-utils)
XELATEX_PACKAGES=(texlive-xetex texlive-fonts-recommended texlive-plain-generic fonts-liberation fonts-liberation2)

configure_apache_modules() {
    a2enmod rewrite
}
