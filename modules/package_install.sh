#!/bin/bash

install_atlas_package() {
    print_header "ATLAS Package Installation"
    echo ""
    
    # Load configuration
    if [ -f /tmp/atlas_install_config.sh ]; then
        source /tmp/atlas_install_config.sh
    else
        read -p "Enter base directory [/var/www]: " BASE_DIR
        BASE_DIR=${BASE_DIR:-/var/www}

        read -p "Enter web directory [/var/www/html]: " WEB_DIR
        WEB_DIR=${WEB_DIR:-/var/www/html}
    fi
    
    # Check if atlasadmin user exists
    if ! id "atlasadmin" &>/dev/null; then
        print_error "User 'atlasadmin' does not exist. Please create it first (Menu Option 3)"
        return 1
    fi
    
    # Ask user what they want to install
    echo ""
    print_info "What would you like to install?"
    echo ""
    echo "1) ATLAS Package only (Steps 1-5: Download, Extract, Configure)"
    echo "2) Database setup only (Step 6: Download and Import Database)"
    echo "3) Both ATLAS Package and Database (Complete Installation)"
    echo "4) Cancel"
    echo ""
    read -p "Select option [1-4]: " INSTALL_OPTION
    INSTALL_OPTION=${INSTALL_OPTION:-3}
    
    case $INSTALL_OPTION in
        1)
            print_info "Selected: ATLAS Package Installation"
            INSTALL_PACKAGE=true
            INSTALL_DATABASE=false
            ;;
        2)
            print_info "Selected: Database Setup Only"
            INSTALL_PACKAGE=false
            INSTALL_DATABASE=true
            ;;
        3)
            print_info "Selected: Complete Installation (Package + Database)"
            INSTALL_PACKAGE=true
            INSTALL_DATABASE=true
            ;;
        4)
            print_info "Installation cancelled"
            return 0
            ;;
        *)
            print_error "Invalid option. Using default: Complete Installation"
            INSTALL_PACKAGE=true
            INSTALL_DATABASE=true
            ;;
    esac
    
    echo ""
    
    # Modules should already be loaded by install.sh, but verify they exist
    if ! declare -f download_atlas_package &>/dev/null || \
       ! declare -f extract_atlas_package &>/dev/null || \
       ! declare -f set_atlas_permissions &>/dev/null || \
       ! declare -f install_atlas_components &>/dev/null || \
       ! declare -f import_atlas_database &>/dev/null; then
        print_error "Required functions not loaded. Module loading may have failed."
        return 1
    fi
    
    # Track which steps completed successfully
    DOWNLOAD_SUCCESS=false
    EXTRACT_SUCCESS=false
    PERMISSIONS_SUCCESS=false
    COMPONENTS_SUCCESS=false
    APACHE_SUCCESS=false
    DATABASE_SUCCESS=false
    
    # Execute Package Installation (Steps 1-5)
    if [ "$INSTALL_PACKAGE" = true ]; then
        print_header "Package Installation (Steps 1-5)"
        echo ""
        
        # Step 1: Download package
        print_info "=== Step 1/5: Download Package ==="
        if download_atlas_package; then
            DOWNLOAD_SUCCESS=true
            print_success "Step 1 completed"
        else
            print_error "Step 1 failed or was cancelled"
        fi
        
        # Step 2: Extract package (only if download succeeded)
        if [ "$DOWNLOAD_SUCCESS" = true ]; then
            echo ""
            print_info "=== Step 2/5: Extract Package ==="
            if extract_atlas_package; then
                EXTRACT_SUCCESS=true
                print_success "Step 2 completed"
            else
                print_error "Step 2 failed or was cancelled"
            fi
        else
            echo ""
            print_info "=== Step 2/5: Extract Package ==="
            print_info "Skipped (download not completed)"
        fi
        
        # Step 3: Set permissions (only if extraction succeeded)
        if [ "$EXTRACT_SUCCESS" = true ]; then
            echo ""
            print_info "=== Step 3/5: Set Permissions ==="
            if set_atlas_permissions; then
                PERMISSIONS_SUCCESS=true
                print_success "Step 3 completed"
            else
                print_error "Step 3 failed"
            fi
        else
            echo ""
            print_info "=== Step 3/5: Set Permissions ==="
            print_info "Skipped (extraction not completed)"
        fi
        
        # Step 4: Install components (only if permissions succeeded)
        if [ "$PERMISSIONS_SUCCESS" = true ]; then
            echo ""
            print_info "=== Step 4/5: Install Components ==="
            if install_atlas_components; then
                COMPONENTS_SUCCESS=true
                print_success "Step 4 completed"
            else
                print_error "Step 4 failed"
            fi
        else
            echo ""
            print_info "=== Step 4/5: Install Components ==="
            print_info "Skipped (permissions not set)"
        fi
        
        # Step 5: Restart Apache
        echo ""
        print_info "=== Step 5/5: Restart Apache ==="
        if [ "$COMPONENTS_SUCCESS" = true ]; then
            print_info "Restarting Apache web server..."
            systemctl restart ${APACHE_SERVICE}
            
            if [ $? -eq 0 ]; then
                APACHE_SUCCESS=true
                print_success "Apache restarted successfully"
                print_success "Step 5 completed"
            else
                print_error "Failed to restart Apache"
                print_info "You may need to restart it manually: sudo systemctl restart ${APACHE_SERVICE}"
            fi
        else
            print_info "Skipped (components not installed)"
        fi
        
        # Determine if package installation was successful
        PACKAGE_INSTALL_SUCCESS=false
        if [ "$DOWNLOAD_SUCCESS" = true ] && [ "$EXTRACT_SUCCESS" = true ] && [ "$PERMISSIONS_SUCCESS" = true ]; then
            PACKAGE_INSTALL_SUCCESS=true
            echo ""
            print_success "ATLAS package installation completed!"
        else
            echo ""
            print_info "Package installation incomplete. Completed steps:"
            [ "$DOWNLOAD_SUCCESS" = true ] && echo "  ✓ Download"
            [ "$EXTRACT_SUCCESS" = true ] && echo "  ✓ Extract"
            [ "$PERMISSIONS_SUCCESS" = true ] && echo "  ✓ Permissions"
            [ "$COMPONENTS_SUCCESS" = true ] && echo "  ✓ Components"
            [ "$APACHE_SUCCESS" = true ] && echo "  ✓ Apache restart"
        fi
    else
        # Package installation skipped
        PACKAGE_INSTALL_SUCCESS=false
        print_info "Package installation skipped (user selected database only)"
    fi
    
    # Execute Database Installation (Step 6)
    if [ "$INSTALL_DATABASE" = true ]; then
        echo ""
        print_header "Database Installation"
        echo ""
        print_info "=== Database Setup ==="
        
        # If package installation was incomplete or skipped, check if user still wants to proceed
        if [ "$INSTALL_PACKAGE" = true ] && [ "$PACKAGE_INSTALL_SUCCESS" != true ]; then
            echo ""
            print_info "Note: Package installation is incomplete."
            read -p "Would you like to continue with database import? (y/N): " CONTINUE_DB
            CONTINUE_DB=${CONTINUE_DB:-N}
            
            if [ "$CONTINUE_DB" = "y" ] || [ "$CONTINUE_DB" = "Y" ]; then
                if import_atlas_database; then
                    DATABASE_SUCCESS=true
                fi
            else
                print_info "Database import skipped"
                print_info "You can import the database later using Menu Option 6"
            fi
        else
            # Package installation succeeded or was skipped entirely
            if import_atlas_database; then
                DATABASE_SUCCESS=true
            fi
        fi
    else
        print_info "Database installation skipped by user"
    fi
    
    # Display final summary
    echo ""
    display_installation_summary "$PACKAGE_INSTALL_SUCCESS" "$DATABASE_SUCCESS" "$INSTALL_PACKAGE" "$INSTALL_DATABASE"
}

display_installation_summary() {
    local PACKAGE_SUCCESS=$1
    local DATABASE_SUCCESS=$2
    local INSTALLED_PACKAGE=$3
    local INSTALLED_DATABASE=$4
    
    print_header "Installation Summary"
    echo ""
    
    # Show what was requested vs what completed
    if [ "$INSTALLED_PACKAGE" = true ]; then
        if [ "$PACKAGE_SUCCESS" = true ]; then
            print_success "Package Installation: Complete ✓"
        else
            print_info "Package Installation: Incomplete ✗"
        fi
    else
        print_info "Package Installation: Not Requested"
    fi
    
    if [ "$INSTALLED_DATABASE" = true ]; then
        if [ "$DATABASE_SUCCESS" = true ]; then
            print_success "Database Installation: Complete ✓"
        else
            print_info "Database Installation: Incomplete ✗"
        fi
    else
        print_info "Database Installation: Not Requested"
    fi
    
    # Show package information if available
    if [ "$INSTALLED_PACKAGE" = true ] && [ -n "$PACKAGE_NAME" ]; then
        echo ""
        echo "Package Information:"
        echo "  Name: ${PACKAGE_NAME}"
        echo "  Version: ${PACKAGE_VERSION}"
        echo "  Location: ${WEB_DIR}"
    fi
    
    # Show permissions if set
    if [ "$PACKAGE_SUCCESS" = true ]; then
        echo ""
        echo "Permissions:"
        echo "  Owner: atlasadmin:${APACHE_USER}"
        echo "  Directories: 755 (drwxr-xr-x)"
        echo "  PHP Files: 755 (rwxr-xr-x)"
        echo "  Other Files: 644 (rw-r--r--)"
        echo "  Config File: 640 (rw-r-----)"
    fi
    
    # Show database information if imported
    if [ "$DATABASE_SUCCESS" = true ] && [ -n "$DB_NAME" ]; then
        echo ""
        echo "Database:"
        echo "  Name: $DB_NAME"
        echo "  User: $DB_USER"
        echo "  Status: Imported"
    fi
    
    # Show access URLs if installation completed
    if [ "$PACKAGE_SUCCESS" = true ]; then
        echo ""
        # Get server IP
        SERVER_IP=$(hostname -I | awk '{print $1}')
        
        echo "Access URLs:"
        echo "  http://${SERVER_IP}"
        echo "  http://localhost"
    fi
    
    # Show next steps based on what was completed
    echo ""
    print_info "Next steps:"
    
    local STEP_NUM=1
    
    # If package installation incomplete, that's first priority
    if [ "$INSTALLED_PACKAGE" = true ] && [ "$PACKAGE_SUCCESS" != true ]; then
        echo "  ${STEP_NUM}. Complete package installation (re-run Menu Option 6, choose Option 1)"
        STEP_NUM=$((STEP_NUM + 1))
    fi
    
    # If database not installed, suggest that
    if [ "$INSTALLED_DATABASE" = true ] && [ "$DATABASE_SUCCESS" != true ]; then
        echo "  ${STEP_NUM}. Complete database installation (re-run Menu Option 6, choose Option 2)"
        STEP_NUM=$((STEP_NUM + 1))
    elif [ "$INSTALLED_DATABASE" != true ]; then
        echo "  ${STEP_NUM}. Import database (Menu Option 6, choose Option 2)"
        STEP_NUM=$((STEP_NUM + 1))
    fi
    
    # Standard post-installation steps
    if [ "$DATABASE_SUCCESS" = true ] && [ -n "$DB_NAME" ]; then
        echo "  ${STEP_NUM}. Verify database settings in ${BASE_DIR}/config.php"
        STEP_NUM=$((STEP_NUM + 1))
    fi
    
    echo "  ${STEP_NUM}. Add logo files to ${WEB_DIR}/images/ (if not already present)"
    STEP_NUM=$((STEP_NUM + 1))
    
    if [ "$PACKAGE_SUCCESS" = true ]; then
        echo "  ${STEP_NUM}. Access the application in your web browser"
        STEP_NUM=$((STEP_NUM + 1))
        echo "  ${STEP_NUM}. Log in with your credentials"
    fi
    
    echo ""
}