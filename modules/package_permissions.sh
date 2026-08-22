#!/bin/bash

set_atlas_permissions() {
    echo ""
    print_header "Setting Permissions"
    echo ""
    
    # Verify directory exists
    if [ ! -d "$WEB_DIR" ]; then
        print_error "Web directory does not exist: $WEB_DIR"
        return 1
    fi
    
    # Verify atlasadmin user exists
    if ! id "atlasadmin" &>/dev/null; then
        print_error "User 'atlasadmin' does not exist"
        return 1
    fi
    
    # Verify www-data group exists
    if ! getent group www-data &>/dev/null; then
        print_error "Group 'www-data' does not exist"
        return 1
    fi
    
    print_info "Configuring ownership and permissions..."
    
    # Set ownership
    print_info "Setting ownership (this may take a moment)..."
    chown -R atlasadmin:www-data "$WEB_DIR"
    if [ $? -eq 0 ]; then
        print_success "Owner: atlasadmin:www-data"
    else
        print_error "Failed to set ownership"
        return 1
    fi
    
    # Set directory permissions
    print_info "Setting directory permissions..."
    find "$WEB_DIR" -type d -exec chmod 755 {} \;
    if [ $? -eq 0 ]; then
        print_success "Directories: 755 (drwxr-xr-x)"
    else
        print_error "Failed to set directory permissions"
        return 1
    fi
    
    # Set file permissions
    print_info "Setting file permissions..."
    find "$WEB_DIR" -type f -exec chmod 644 {} \;
    if [ $? -eq 0 ]; then
        print_success "Files: 644 (rw-r--r--)"
    else
        print_error "Failed to set file permissions"
        return 1
    fi
    
    # Make PHP files executable
    print_info "Setting PHP file permissions..."
    find "$WEB_DIR" -type f -name "*.php" -exec chmod 755 {} \;
    if [ $? -eq 0 ]; then
        print_success "PHP files: 755 (rwxr-xr-x)"
    else
        print_error "Failed to set PHP file permissions"
        return 1
    fi
    
    # Set special permissions for config file if exists
    if [ -f "${WEB_DIR}/php_include/config.php" ]; then
        chmod 640 "${WEB_DIR}/php_include/config.php"
        print_success "Config file: 640 (rw-r-----)"
    else
        print_info "Config file not found (will be created later)"
    fi
    
    print_success "Permissions configured successfully"
    
    return 0
}