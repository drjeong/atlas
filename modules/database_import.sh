#!/bin/bash

import_atlas_database() {
    echo ""
    print_header "Database Import"
    echo ""
    
    read -p "Would you like to import the database now? (Y/n): " IMPORT_DB
    IMPORT_DB=${IMPORT_DB:-Y}
    
    if [ "$IMPORT_DB" != "Y" ] && [ "$IMPORT_DB" != "y" ]; then
        print_info "Database import skipped"
        print_info "You can import the database later using Menu Option 7"
        return 0
    fi
    
    # Step 1: Download/Locate Database File
    if ! download_database_file; then
        return 1
    fi
    
    # Step 2: Import Database
    if ! import_database_file; then
        return 1
    fi
    
    return 0
}

download_database_file() {
    # Use package version if already set, otherwise ask
    if [ -z "$PACKAGE_VERSION" ]; then
        read -p "Enter database version [1.0.0]: " DB_VERSION
        DB_VERSION=${DB_VERSION:-1.0.0}
    else
        DB_VERSION=$PACKAGE_VERSION
        print_info "Using package version: $DB_VERSION"
    fi
    
    # GitHub repository information
    GITHUB_REPO="drjeong/atlas"
    DB_FILE_NAME="atlas-${DB_VERSION}-db.sql.gz"
    
    echo ""
    print_info "ATLAS Database Download Configuration"
    echo "  GitHub Repository: https://github.com/${GITHUB_REPO}"
    echo "  Releases: https://github.com/${GITHUB_REPO}/releases"
    echo "  Database File: ${DB_FILE_NAME}"
    echo ""
    
    # Look for database file in common locations
    DB_FILE=""
    FOUND_LOCALLY=false
    
    if [ -f "${WEB_DIR}/${DB_FILE_NAME}" ]; then
        DB_FILE="${WEB_DIR}/${DB_FILE_NAME}"
        FOUND_LOCALLY=true
        print_info "Found database file in web directory: $DB_FILE"
    elif [ -f "${SCRIPT_DIR}/${DB_FILE_NAME}" ]; then
        DB_FILE="${SCRIPT_DIR}/${DB_FILE_NAME}"
        FOUND_LOCALLY=true
        print_info "Found database file in script directory: $DB_FILE"
    elif [ -f "./${DB_FILE_NAME}" ]; then
        DB_FILE="./${DB_FILE_NAME}"
        FOUND_LOCALLY=true
        print_info "Found database file in current directory: $DB_FILE"
    fi
    
    # If found locally, ask if user wants to use it
    if [ "$FOUND_LOCALLY" = true ]; then
        echo ""
        read -p "Use this local database file? (Y/n): " USE_LOCAL
        USE_LOCAL=${USE_LOCAL:-Y}
        
        if [ "$USE_LOCAL" = "Y" ] || [ "$USE_LOCAL" = "y" ]; then
            print_info "Using local database file"
            
            # Verify it's a valid gzip file
            if ! gunzip -t "$DB_FILE" 2>/dev/null; then
                print_error "File is not a valid gzip archive: $DB_FILE"
                print_info "Will prompt for alternative source"
                DB_FILE=""
                FOUND_LOCALLY=false
            else
                # Export variables and return success
                export DB_FILE
                export DB_FILE_NAME
                export DB_VERSION
                return 0
            fi
        else
            DB_FILE=""
            FOUND_LOCALLY=false
        fi
    fi
    
    # Database file not found or user declined local file
    if [ "$FOUND_LOCALLY" != true ]; then
        echo ""
        print_info "How would you like to provide the database file?"
        echo "1) Download from GitHub Releases"
        echo "2) Enter custom download URL"
        echo "3) Provide local file path"
        echo "4) Skip database import"
        read -p "Select option [1-4]: " DB_OPTION
        DB_OPTION=${DB_OPTION:-1}
        
        case $DB_OPTION in
            1)
                DB_DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${DB_VERSION}/${DB_FILE_NAME}"
                print_info "Using GitHub Releases URL"
                ;;
            2)
                read -p "Enter database download URL: " DB_DOWNLOAD_URL
                if [ -z "$DB_DOWNLOAD_URL" ]; then
                    print_error "No URL provided"
                    return 1
                fi
                print_info "Using custom URL: $DB_DOWNLOAD_URL"
                ;;
            3)
                read -p "Enter path to database file: " DB_FILE
                if [ ! -f "$DB_FILE" ]; then
                    print_error "File not found: $DB_FILE"
                    return 1
                fi
                
                # Verify it's a valid gzip file
                if ! gunzip -t "$DB_FILE" 2>/dev/null; then
                    print_error "File is not a valid gzip archive: $DB_FILE"
                    
                    if command -v file &> /dev/null; then
                        print_info "File type detected: $(file "$DB_FILE")"
                    fi
                    
                    return 1
                fi
                
                print_info "Using local file: $DB_FILE"
                
                # Export variables and return success
                export DB_FILE
                export DB_FILE_NAME
                export DB_VERSION
                return 0
                ;;
            4)
                print_info "Database import skipped"
                print_info "You can import the database later using Menu Option 6 (Option 2) or Menu Option 7"
                return 1
                ;;
            *)
                print_error "Invalid option"
                return 1
                ;;
        esac
    fi
    
    # Download database file if URL provided
    if [ -n "$DB_DOWNLOAD_URL" ]; then
        echo ""
        print_info "Downloading database file..."
        echo "  File: ${DB_FILE_NAME}"
        echo "  URL: ${DB_DOWNLOAD_URL}"
        echo ""
        
        # Create temporary download directory
        DB_DOWNLOAD_DIR="/tmp/atlas_db_download_$$"
        mkdir -p "$DB_DOWNLOAD_DIR"
        
        DB_FILE="$DB_DOWNLOAD_DIR/$DB_FILE_NAME"
        
        # Check which download tool is available
        if command -v wget &> /dev/null; then
            print_info "Using wget for download..."
            wget --progress=bar:force -O "$DB_FILE" "$DB_DOWNLOAD_URL" 2>&1
            DOWNLOAD_RESULT=$?
            
        elif command -v curl &> /dev/null; then
            print_info "Using curl for download..."
            curl -L --progress-bar -o "$DB_FILE" "$DB_DOWNLOAD_URL"
            DOWNLOAD_RESULT=$?
        else
            print_error "Neither wget nor curl is available"
            print_info "Installing wget..."
            apt-get update && apt-get install -y wget
            
            if command -v wget &> /dev/null; then
                wget --progress=bar:force -O "$DB_FILE" "$DB_DOWNLOAD_URL" 2>&1
                DOWNLOAD_RESULT=$?
            else
                print_error "Failed to install wget"
                rm -rf "$DB_DOWNLOAD_DIR"
                return 1
            fi
        fi
        
        # Check download result
        if [ $DOWNLOAD_RESULT -ne 0 ]; then
            print_error "Download failed"
            
            echo ""
            print_info "Possible reasons for download failure:"
            echo "  1. The database file doesn't exist at that URL"
            echo "  2. Network connectivity issues"
            echo "  3. The URL structure is incorrect"
            echo ""
            print_info "Please verify:"
            echo "  - Check releases: https://github.com/${GITHUB_REPO}/releases"
            echo "  - Expected filename: ${DB_FILE_NAME}"
            echo ""
            
            rm -rf "$DB_DOWNLOAD_DIR"
            
            read -p "Do you have the database file locally? (y/N): " HAS_LOCAL
            HAS_LOCAL=${HAS_LOCAL:-N}
            
            if [ "$HAS_LOCAL" = "y" ] || [ "$HAS_LOCAL" = "Y" ]; then
                read -p "Enter path to database file: " DB_FILE
                if [ ! -f "$DB_FILE" ]; then
                    print_error "File not found: $DB_FILE"
                    return 1
                fi
            else
                print_info "Please download the database file manually and run this step again"
                print_info "You can use Menu Option 6, choose Option 2 (Database setup only)"
                return 1
            fi
        else
            print_success "Download completed"
        fi
    fi
    
    # Verify database file exists and is valid
    if [ ! -f "$DB_FILE" ]; then
        print_error "Database file not found: $DB_FILE"
        return 1
    fi
    
    # Verify it's a valid gzip file
    echo ""
    print_info "Verifying database file integrity..."
    if ! gunzip -t "$DB_FILE" 2>/dev/null; then
        print_error "File is not a valid gzip archive: $DB_FILE"
        
        if command -v file &> /dev/null; then
            print_info "File type detected: $(file "$DB_FILE")"
        fi
        
        if [ -n "$DB_DOWNLOAD_DIR" ] && [ -d "$DB_DOWNLOAD_DIR" ]; then
            rm -rf "$DB_DOWNLOAD_DIR"
        fi
        
        return 1
    else
        print_success "Database file verified successfully"
    fi
    
    # Show database file info
    echo ""
    print_info "Database File Details:"
    echo "  File: $DB_FILE"
    echo "  Compressed Size: $(du -h "$DB_FILE" | cut -f1)"
    
    # Try to get uncompressed size
    UNCOMPRESSED_SIZE=$(gunzip -l "$DB_FILE" 2>/dev/null | tail -1 | awk '{print $2}')
    if [ -n "$UNCOMPRESSED_SIZE" ]; then
        echo "  Uncompressed Size: $(numfmt --to=iec-i --suffix=B $UNCOMPRESSED_SIZE 2>/dev/null || echo "${UNCOMPRESSED_SIZE} bytes")"
    fi
    echo ""
    
    # Export variables for use in import function
    export DB_FILE
    export DB_FILE_NAME
    export DB_VERSION
    export DB_DOWNLOAD_DIR
    
    return 0
}

import_database_file() {
    echo ""
    print_header "Database Import Process"
    echo ""
    
    # Get MySQL root credentials
    print_info "MySQL root credentials required for database import"
    read -p "MySQL root password: " -s MYSQL_ROOT_PASS
    echo ""
    
    # Test MySQL connection
    print_info "Testing MySQL connection..."
    if ! mysql -u root -p"$MYSQL_ROOT_PASS" -e "SELECT 1;" &>/dev/null; then
        print_error "Failed to connect to MySQL. Please check your password."
        
        # Cleanup download directory if exists
        if [ -n "$DB_DOWNLOAD_DIR" ] && [ -d "$DB_DOWNLOAD_DIR" ]; then
            rm -rf "$DB_DOWNLOAD_DIR"
        fi
        
        return 1
    fi
    print_success "MySQL connection successful"
    
    # Get database configuration
    echo ""
    print_info "Database configuration:"
    read -p "Database name [atlas_db]: " DB_NAME
    DB_NAME=${DB_NAME:-atlas_db}
    
    read -p "Database user [atlasdbadmin]: " DB_USER
    DB_USER=${DB_USER:-atlasdbadmin}
    
    read -p "Database user password: " -s DB_PASS
    echo ""
    
    # Confirm settings
    echo ""
    print_info "Database Import Settings:"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  File: $DB_FILE"
    echo "  Compressed Size: $(du -h "$DB_FILE" | cut -f1)"
    echo ""
    
    read -p "Proceed with database import? (Y/n): " PROCEED_IMPORT
    PROCEED_IMPORT=${PROCEED_IMPORT:-Y}
    
    if [ "$PROCEED_IMPORT" != "Y" ] && [ "$PROCEED_IMPORT" != "y" ]; then
        print_info "Database import cancelled"
        
        # Cleanup download directory if exists
        if [ -n "$DB_DOWNLOAD_DIR" ] && [ -d "$DB_DOWNLOAD_DIR" ]; then
            rm -rf "$DB_DOWNLOAD_DIR"
        fi
        
        return 1
    fi
    
    # Create database
    echo ""
    print_info "Creating database '$DB_NAME'..."
    mysql -u root -p"$MYSQL_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create database"
        
        # Cleanup download directory if exists
        if [ -n "$DB_DOWNLOAD_DIR" ] && [ -d "$DB_DOWNLOAD_DIR" ]; then
            rm -rf "$DB_DOWNLOAD_DIR"
        fi
        
        return 1
    fi
    print_success "Database created"
    
    # Create database user
    print_info "Creating database user '$DB_USER'..."
    mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF 2>/dev/null
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Database user created and privileges granted"
    else
        print_error "Failed to create database user"
        print_info "You may need to create the user manually"
    fi
    
    # Import database
    echo ""
    print_info "Importing database... (this may take several minutes)"
    print_info "Please wait..."
    echo ""
    
    # Show progress indicator if pv is available
    if command -v pv &> /dev/null; then
        gunzip < "$DB_FILE" | pv -p -t -e -r -b 2>&1 | mysql -u root -p"$MYSQL_ROOT_PASS" "$DB_NAME" 2>/dev/null
        IMPORT_RESULT=$?
    else
        # No pv available, show a simple progress message
        print_info "Importing (no progress indicator available)..."
        gunzip < "$DB_FILE" | mysql -u root -p"$MYSQL_ROOT_PASS" "$DB_NAME" 2>/dev/null
        IMPORT_RESULT=$?
    fi
    
    echo ""
    
    # Cleanup download directory if exists
    if [ -n "$DB_DOWNLOAD_DIR" ] && [ -d "$DB_DOWNLOAD_DIR" ]; then
        rm -rf "$DB_DOWNLOAD_DIR"
        print_info "Cleaned up temporary download directory"
    fi
    
    if [ $IMPORT_RESULT -eq 0 ]; then
        print_success "Database imported successfully"
        
        # Update config.php if it exists
        if [ -n "$WEB_DIR" ]; then
            CONFIG_FILE="${WEB_DIR}/php_include/config.php"
        else
            CONFIG_FILE="/var/www/html/php_include/config.php"
        fi
        
        if [ -f "$CONFIG_FILE" ]; then
            echo ""
            print_info "Updating database configuration in config.php..."
            
            # Create backup
            cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
            
            # Update database settings
            sed -i "s/\$dbname\s*=\s*['\"].*['\"]/\$dbname = '$DB_NAME'/" "$CONFIG_FILE"
            sed -i "s/\$dbuser\s*=\s*['\"].*['\"]/\$dbuser = '$DB_USER'/" "$CONFIG_FILE"
            sed -i "s/\$dbpass\s*=\s*['\"].*['\"]/\$dbpass = '$DB_PASS'/" "$CONFIG_FILE"
            sed -i "s/\$dbhost\s*=\s*['\"].*['\"]/\$dbhost = 'localhost'/" "$CONFIG_FILE"
            
            print_success "Configuration file updated"
            print_info "Backup saved: ${CONFIG_FILE}.bak"
        else
            echo ""
            print_info "Configuration file not found: $CONFIG_FILE"
            print_info "You may need to configure database settings manually"
        fi
        
        # Display database info
        echo ""
        print_success "Database setup completed!"
        echo ""
        print_info "Database Connection Details:"
        echo "  Host: localhost"
        echo "  Database: $DB_NAME"
        echo "  User: $DB_USER"
        echo "  Password: [configured]"
        echo ""
        
        # Export for use in summary
        export DB_NAME
        export DB_USER
        
        return 0
    else
        print_error "Failed to import database"
        echo ""
        print_info "You can try importing manually:"
        echo "  gunzip < $DB_FILE | mysql -u root -p $DB_NAME"
        echo ""
        print_info "Or run database import again:"
        echo "  Menu Option 6 → Choose Option 2 (Database setup only)"
        
        return 1
    fi
}
