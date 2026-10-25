#!/bin/bash

setup_directories() {
    print_header "Directory Setup"
    echo ""
    
    # Get directory configuration
    print_info "Directory Configuration"
    echo ""
    
    read -p "Enter base directory [/var/www]: " BASE_DIR
    BASE_DIR=${BASE_DIR:-/var/www}
    
    read -p "Enter web directory [${BASE_DIR}/html]: " WEB_DIR
    WEB_DIR=${WEB_DIR:-${BASE_DIR}/html}
    
    read -p "Enter repository base [/var/www/data]: " REPO_BASE
    REPO_BASE=${REPO_BASE:-/var/www/data}
    
    # Normalize paths - ensure they start with / and remove trailing /
    BASE_DIR=$(echo "$BASE_DIR" | sed 's#^/*#/#' | sed 's#/$##')
    WEB_DIR=$(echo "$WEB_DIR" | sed 's#^/*#/#' | sed 's#/$##')
    REPO_BASE=$(echo "$REPO_BASE" | sed 's#^/*#/#' | sed 's#/$##')
    
    # Validate directories (safety check)
    PROTECTED_DIRS=("/" "/bin" "/boot" "/dev" "/etc" "/lib" "/lib64" "/proc" "/root" "/sbin" "/sys" "/usr")
    
    for protected in "${PROTECTED_DIRS[@]}"; do
        if [ "$BASE_DIR" = "$protected" ] || [ "$WEB_DIR" = "$protected" ] || [ "$REPO_BASE" = "$protected" ]; then
            print_error "Cannot use system directory: $protected"
            print_info "Please choose a safe location like /var/www or /opt"
            return 1
        fi
    done
    
    echo ""
    print_info "The following data directories will be created:"
    echo "  - ${REPO_BASE}/assessments/"
    echo "  - ${REPO_BASE}/assessmentsurvey/"
    echo "  - ${REPO_BASE}/abetsyllabi/"
    echo "  - ${REPO_BASE}/coursesyllabi/"
    echo "  - ${REPO_BASE}/instructionalmaterials/"
    echo "  - ${REPO_BASE}/courseassignmentsamples/"
    echo "  - ${REPO_BASE}/coursebinders/"
    echo "  - ${REPO_BASE}/courseassessmentreports/"
    echo "  - ${REPO_BASE}/getcourseinfo/"
    echo "  - ${REPO_BASE}/recyclebin/"
    echo ""
    
    print_info "IMPORTANT: Do not use the same directory as your website directory!"
    echo ""
    
    read -p "Continue with directory creation? (Y/n): " CONTINUE
    CONTINUE=${CONTINUE:-Y}
    
    if [ "$CONTINUE" != "Y" ] && [ "$CONTINUE" != "y" ]; then
        print_info "Directory setup cancelled"
        return 0
    fi
    
    # Verify atlasadmin user exists
    if ! id "atlasadmin" &>/dev/null; then
        print_error "User 'atlasadmin' does not exist. Please create it first (Menu Option 3)"
        return 1
    fi
    
    # Create base directories
    echo ""
    print_info "Creating base directories..."
    
    if [ ! -d "$BASE_DIR" ]; then
        mkdir -p "$BASE_DIR"
        if [ $? -eq 0 ]; then
            print_success "Created: $BASE_DIR"
        else
            print_error "Failed to create: $BASE_DIR"
            return 1
        fi
    else
        print_info "Already exists: $BASE_DIR"
    fi
    
    if [ ! -d "$WEB_DIR" ]; then
        mkdir -p "$WEB_DIR"
        if [ $? -eq 0 ]; then
            print_success "Created: $WEB_DIR"
        else
            print_error "Failed to create: $WEB_DIR"
            return 1
        fi
    else
        print_info "Already exists: $WEB_DIR"
    fi
    
    # Create data directories
    echo ""
    print_info "Creating data directories..."
    
    DIRECTORIES=(
        "assessments"
        "assessmentsurvey"
        "abetsyllabi"
        "coursesyllabi"
        "instructionalmaterials"
        "courseassignmentsamples"
        "coursebinders"
        "courseassessmentreports"
        "getcourseinfo"
        "recyclebin"
    )
    
    FAILED_DIRS=()
    
    for DIR in "${DIRECTORIES[@]}"; do
        DIR_PATH="${REPO_BASE}/${DIR}"
        
        if [ ! -d "$DIR_PATH" ]; then
            mkdir -p "$DIR_PATH"
            if [ $? -eq 0 ]; then
                print_success "Created: $DIR_PATH"
            else
                print_error "Failed to create: $DIR_PATH"
                FAILED_DIRS+=("$DIR_PATH")
                continue
            fi
        else
            print_info "Already exists: $DIR_PATH"
        fi
        
        # Set ownership and permissions
        chown atlasadmin:${APACHE_USER} "$DIR_PATH"
        chmod 775 "$DIR_PATH"
    done
    
    if [ ${#FAILED_DIRS[@]} -gt 0 ]; then
        echo ""
        print_error "Failed to create some directories:"
        for dir in "${FAILED_DIRS[@]}"; do
            echo "  - $dir"
        done
        return 1
    fi
    
    # Generate RSA keys
    echo ""
    print_info "Generating RSA key pair..."
    
    RSA_PRIV_KEY="${BASE_DIR}/rsa_1024_priv.pem"
    RSA_PUB_KEY="${BASE_DIR}/rsa_1024_pub.pem"
    
    if [ -f "$RSA_PRIV_KEY" ] || [ -f "$RSA_PUB_KEY" ]; then
        print_info "RSA keys already exist"
        read -p "Regenerate keys? (y/N): " REGEN_KEYS
        REGEN_KEYS=${REGEN_KEYS:-N}
        
        if [ "$REGEN_KEYS" != "y" ] && [ "$REGEN_KEYS" != "Y" ]; then
            print_info "Keeping existing keys"
        else
            rm -f "$RSA_PRIV_KEY" "$RSA_PUB_KEY"
            print_info "Generating new keys..."
        fi
    fi
    
    if [ ! -f "$RSA_PRIV_KEY" ]; then
        # Generate private key
        openssl genrsa -out "$RSA_PRIV_KEY" 1024 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "Private key generated: $RSA_PRIV_KEY"
        else
            print_error "Failed to generate private key"
            return 1
        fi
        
        # Generate public key
        openssl rsa -in "$RSA_PRIV_KEY" -pubout -out "$RSA_PUB_KEY" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "Public key generated: $RSA_PUB_KEY"
        else
            print_error "Failed to generate public key"
            return 1
        fi
        
        # Set proper permissions
        chown atlasadmin:${APACHE_USER} "$RSA_PRIV_KEY"
        chown atlasadmin:${APACHE_USER} "$RSA_PUB_KEY"
        chmod 640 "$RSA_PRIV_KEY"
        chmod 644 "$RSA_PUB_KEY"
        
        print_success "Key permissions set"
    fi
    
    # Summary
    echo ""
    print_info "Directory Setup Summary:"
    echo "  Base Directory: $BASE_DIR"
    echo "  Web Directory: $WEB_DIR"
    echo "  Repository Base: $REPO_BASE"
    echo "  Private Key: $RSA_PRIV_KEY"
    echo "  Public Key: $RSA_PUB_KEY"
    echo "  Ownership: atlasadmin:${APACHE_USER}"
    echo "  Permissions: drwxrwxr-x (775)"
    
    echo ""
    print_success "Directory setup completed!"
    
    # Save configuration to temp file for later use
    cat > /tmp/atlas_install_config.sh << EOF
BASE_DIR="$BASE_DIR"
WEB_DIR="$WEB_DIR"
REPO_BASE="$REPO_BASE"
EOF
    
    chmod 600 /tmp/atlas_install_config.sh
    
    return 0
}