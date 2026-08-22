#!/bin/bash

extract_atlas_package() {
    echo ""
    print_header "Package Extraction"
    echo ""
    
    # Safety check - prevent accidental deletion of system directories
    PROTECTED_DIRS=("/" "/var" "/usr" "/bin" "/sbin" "/etc" "/lib" "/lib64" "/boot" "/dev" "/proc" "/sys" "/root" "/home")
    
    for protected in "${PROTECTED_DIRS[@]}"; do
        if [ "$WEB_DIR" = "$protected" ]; then
            print_error "Invalid WEB_DIR: $WEB_DIR (safety check failed)"
            print_error "Cannot extract to system directory"
            return 1
        fi
    done
    
    # Additional safety check - ensure WEB_DIR is set and not empty
    if [ -z "$WEB_DIR" ]; then
        print_error "WEB_DIR is not set"
        return 1
    fi
    
    # Check if target directory has files
    if [ "$(ls -A $WEB_DIR 2>/dev/null)" ]; then
        print_info "Warning: Target directory is not empty"
        ls -lah "$WEB_DIR" | head -n 20
        echo ""
        read -p "Backup existing files before extraction? (Y/n): " BACKUP_FILES
        BACKUP_FILES=${BACKUP_FILES:-Y}
        
        if [ "$BACKUP_FILES" = "Y" ] || [ "$BACKUP_FILES" = "y" ]; then
            BACKUP_DIR="${WEB_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
            print_info "Creating backup at: $BACKUP_DIR"
            cp -r "$WEB_DIR" "$BACKUP_DIR"
            
            if [ $? -eq 0 ]; then
                print_success "Backup created successfully"
                
                print_info "Cleaning target directory..."
                # More careful cleanup with additional safety
                if [ -d "$WEB_DIR" ] && [ "$WEB_DIR" != "/" ]; then
                    find "$WEB_DIR" -mindepth 1 -delete 2>/dev/null
                    
                    if [ $? -eq 0 ]; then
                        print_success "Target directory cleaned"
                    else
                        print_error "Failed to clean target directory"
                        read -p "Continue anyway? (y/N): " FORCE_CONTINUE
                        FORCE_CONTINUE=${FORCE_CONTINUE:-N}
                        if [ "$FORCE_CONTINUE" != "y" ] && [ "$FORCE_CONTINUE" != "Y" ]; then
                            return 1
                        fi
                    fi
                fi
            else
                print_error "Backup failed"
                read -p "Continue anyway? (y/N): " FORCE_CONTINUE
                FORCE_CONTINUE=${FORCE_CONTINUE:-N}
                if [ "$FORCE_CONTINUE" != "y" ] && [ "$FORCE_CONTINUE" != "Y" ]; then
                    return 1
                fi
            fi
        fi
    fi
    
    echo ""
    read -p "Proceed with package extraction? (Y/n): " CONTINUE
    CONTINUE=${CONTINUE:-Y}
    
    if [ "$CONTINUE" != "Y" ] && [ "$CONTINUE" != "y" ]; then
        print_info "Extraction cancelled"
        
        if [ -n "$DOWNLOAD_DIR" ] && [ -d "$DOWNLOAD_DIR" ]; then
            rm -rf "$DOWNLOAD_DIR"
        fi
        
        return 1
    fi
    
    # Extract package
    echo ""
    print_info "Extracting ATLAS package..."
    
    # Determine package structure
    ROOT_DIR=$(tar -tzf "$PACKAGE_FILE" | head -1 | cut -f1 -d"/")
    HAS_ROOT_DIR=$(tar -tzf "$PACKAGE_FILE" | grep -c "^$ROOT_DIR/$")
    
    if [ $HAS_ROOT_DIR -gt 0 ]; then
        print_info "Package contains root directory: $ROOT_DIR"
        
        # Extract to temporary location
        TEMP_EXTRACT="/tmp/atlas_extract_$$"
        mkdir -p "$TEMP_EXTRACT"
        
        print_info "Extracting to temporary location..."
        tar -xzf "$PACKAGE_FILE" -C "$TEMP_EXTRACT" 2>&1
        
        if [ $? -eq 0 ]; then
            if [ -d "$TEMP_EXTRACT/$ROOT_DIR" ]; then
                print_info "Copying files to web directory..."
                
                mkdir -p "$WEB_DIR"
                cp -r "$TEMP_EXTRACT/$ROOT_DIR/"* "$WEB_DIR/" 2>&1
                
                if [ $? -eq 0 ]; then
                    print_success "Files copied successfully"
                else
                    print_error "Failed to copy files"
                    rm -rf "$TEMP_EXTRACT"
                    return 1
                fi
                
                rm -rf "$TEMP_EXTRACT"
            else
                print_error "Expected directory structure not found"
                rm -rf "$TEMP_EXTRACT"
                return 1
            fi
        else
            print_error "Failed to extract package"
            rm -rf "$TEMP_EXTRACT"
            return 1
        fi
    else
        print_info "Package has flat structure, extracting directly..."
        
        mkdir -p "$WEB_DIR"
        tar -xzf "$PACKAGE_FILE" -C "$WEB_DIR" 2>&1
        
        if [ $? -eq 0 ]; then
            print_success "Package extracted successfully"
        else
            print_error "Failed to extract package"
            return 1
        fi
    fi
    
    # Verify extraction
    echo ""
    print_info "Verifying extraction..."
    
    if [ ! -d "$WEB_DIR" ] || [ -z "$(ls -A $WEB_DIR)" ]; then
        print_error "Extraction verification failed - directory is empty"
        return 1
    fi
    
    FILE_COUNT=$(find "$WEB_DIR" -type f | wc -l)
    DIR_COUNT=$(find "$WEB_DIR" -type d | wc -l)
    
    print_success "Extraction verified"
    print_info "  Files: $FILE_COUNT"
    print_info "  Directories: $DIR_COUNT"
    
    # Cleanup downloaded file if exists
    if [ -n "$DOWNLOAD_DIR" ] && [ -d "$DOWNLOAD_DIR" ]; then
        rm -rf "$DOWNLOAD_DIR"
        print_info "Cleaned up temporary download directory"
    fi
    
    return 0
}