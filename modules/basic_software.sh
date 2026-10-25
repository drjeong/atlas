#!/bin/bash

install_basic_software() {
    print_header "Basic Software Installation"
    echo ""
    
    # Check existing installations
    APACHE_INSTALLED=false
    PHP_INSTALLED=false
    MYSQL_INSTALLED=false
    
    if command -v "$APACHE_COMMAND" &> /dev/null; then
        APACHE_INSTALLED=true
        print_info "Apache2 is already installed ($("$APACHE_COMMAND" -v | head -n 1 | cut -d' ' -f3))"
    fi
    
    if command -v php &> /dev/null; then
        PHP_INSTALLED=true
        print_info "PHP is already installed ($(php -v | head -n 1 | cut -d' ' -f2))"
    fi
    
    if command -v mysql &> /dev/null; then
        MYSQL_INSTALLED=true
        print_info "MySQL-compatible client is already installed ($(mysql --version))"
    fi
    
    echo ""
    
    # Ask user about installations
    INSTALL_APACHE=false
    INSTALL_PHP=false
    INSTALL_MYSQL=false
    
    if [ "$APACHE_INSTALLED" = true ]; then
        read -p "Apache2 is already installed. Reinstall? (y/N): " REINSTALL_APACHE
        REINSTALL_APACHE=${REINSTALL_APACHE:-N}
        if [ "$REINSTALL_APACHE" = "y" ] || [ "$REINSTALL_APACHE" = "Y" ]; then
            INSTALL_APACHE=true
        fi
    else
        read -p "Install Apache2? (Y/n): " INSTALL_APACHE_INPUT
        INSTALL_APACHE_INPUT=${INSTALL_APACHE_INPUT:-Y}
        if [ "$INSTALL_APACHE_INPUT" = "Y" ] || [ "$INSTALL_APACHE_INPUT" = "y" ]; then
            INSTALL_APACHE=true
        fi
    fi
    
    if [ "$PHP_INSTALLED" = true ]; then
        read -p "PHP is already installed. Reinstall? (y/N): " REINSTALL_PHP
        REINSTALL_PHP=${REINSTALL_PHP:-N}
        if [ "$REINSTALL_PHP" = "y" ] || [ "$REINSTALL_PHP" = "Y" ]; then
            INSTALL_PHP=true
        fi
    else
        read -p "Install PHP and extensions? (Y/n): " INSTALL_PHP_INPUT
        INSTALL_PHP_INPUT=${INSTALL_PHP_INPUT:-Y}
        if [ "$INSTALL_PHP_INPUT" = "Y" ] || [ "$INSTALL_PHP_INPUT" = "y" ]; then
            INSTALL_PHP=true
        fi
    fi
    
    if [ "$MYSQL_INSTALLED" = true ]; then
        read -p "MySQL is already installed. Reinstall? (y/N): " REINSTALL_MYSQL
        REINSTALL_MYSQL=${REINSTALL_MYSQL:-N}
        if [ "$REINSTALL_MYSQL" = "y" ] || [ "$REINSTALL_MYSQL" = "Y" ]; then
            INSTALL_MYSQL=true
        fi
    else
        read -p "Install MySQL Server? (Y/n): " INSTALL_MYSQL_INPUT
        INSTALL_MYSQL_INPUT=${INSTALL_MYSQL_INPUT:-Y}
        if [ "$INSTALL_MYSQL_INPUT" = "Y" ] || [ "$INSTALL_MYSQL_INPUT" = "y" ]; then
            INSTALL_MYSQL=true
        fi
    fi
    
    # Refresh package metadata if needed
    if [ "$INSTALL_APACHE" = true ] || [ "$INSTALL_PHP" = true ] || [ "$INSTALL_MYSQL" = true ]; then
        echo ""
        print_info "Refreshing package metadata..."
        if refresh_package_metadata; then
            print_success "Package metadata refreshed"
        else
            print_error "Failed to refresh package metadata"
            return 1
        fi
    fi
    
    # Install Apache2
    if [ "$INSTALL_APACHE" = true ]; then
        echo ""
        print_info "Installing Apache2..."
        if install_packages "${APACHE_PACKAGES[@]}"; then
            print_success "Apache2 installed"
            systemctl enable "$APACHE_SERVICE" || return 1
            systemctl start "$APACHE_SERVICE" || return 1
        else
            print_error "Failed to install Apache2"
            return 1
        fi
    else
        if [ "$APACHE_INSTALLED" = true ]; then
            systemctl enable "$APACHE_SERVICE" || return 1
            systemctl start "$APACHE_SERVICE" || return 1
            print_info "Apache2 service ensured running"
        fi
    fi
    
    # Install PHP
    if [ "$INSTALL_PHP" = true ]; then
        echo ""
        print_info "Installing PHP and extensions..."
        if install_packages "${PHP_PACKAGES[@]}"; then
            print_success "PHP and extensions installed"
        else
            print_error "Failed to install PHP"
            return 1
        fi
    fi
    
    if [ -n "$PHP_FPM_SERVICE" ] && { [ "$INSTALL_PHP" = true ] || [ "$PHP_INSTALLED" = true ]; }; then
        systemctl enable "$PHP_FPM_SERVICE" || return 1
        systemctl start "$PHP_FPM_SERVICE" || return 1
    fi

    # Install MySQL (MariaDB on RPM distributions)
    if [ "$INSTALL_MYSQL" = true ]; then
        echo ""
        print_info "Installing MySQL Server..."
        if install_packages "${MYSQL_PACKAGES[@]}"; then
            print_success "MySQL Server installed"
            systemctl enable "$MYSQL_SERVICE" || return 1
            systemctl start "$MYSQL_SERVICE" || return 1
        else
            print_error "Failed to install MySQL Server"
            return 1
        fi
    else
        if [ "$MYSQL_INSTALLED" = true ]; then
            systemctl enable "$MYSQL_SERVICE" || return 1
            systemctl start "$MYSQL_SERVICE" || return 1
            print_info "MySQL service ensured running"
        fi
    fi
    
    # Verify installations
    echo ""
    print_info "Verifying installations..."
    
    if ! command -v "$APACHE_COMMAND" &> /dev/null; then
        print_error "Apache2 is not available"
        return 1
    fi
    
    if ! command -v php &> /dev/null; then
        print_error "PHP is not available"
        return 1
    fi
    
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL is not available"
        return 1
    fi
    
    print_success "All basic software verified"
    
    # Configure Apache
    echo ""
    print_info "Configuring Apache..."
    configure_apache_modules || return 1
    systemctl restart "$APACHE_SERVICE" || return 1
    print_success "Apache configured"
    
    echo ""
    print_success "Basic software installation completed!"
}