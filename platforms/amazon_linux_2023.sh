#!/bin/bash

APACHE_COMMAND=httpd
APACHE_SERVICE=httpd
APACHE_USER=apache
SUDO_GROUP=wheel
MYSQL_SERVICE=mariadb
PHP_FPM_SERVICE=php-fpm
APACHE_PACKAGES=(httpd)
PHP_PACKAGES=(php php-fpm php-mysqlnd php-cli php-mbstring php-xml php-gd php-intl php-zip)
MYSQL_PACKAGES=(mariadb105-server mariadb105)
JAVA_PACKAGES=(java-17-amazon-corretto-devel)
PDFJAM_PACKAGES=(texlive-pdfjam)
XELATEX_PACKAGES=(texlive-xetex texlive-collection-fontsrecommended texlive-collection-plaingeneric)

configure_apache_modules() {
    # RPM Apache loads modules through conf.modules.d rather than a2enmod.
    if ! httpd -M 2>/dev/null | grep -q rewrite_module; then
        print_error "Apache rewrite_module is not loaded; check /etc/httpd/conf.modules.d"
        return 1
    fi
    # The packaged PHP-FPM pool runs as apache and integrates via php.conf.
    systemctl enable --now php-fpm
}
