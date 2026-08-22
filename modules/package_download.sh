#!/bin/bash

download_atlas_package() {
    # GitHub repository information
    GITHUB_REPO="drjeong/atlas"
    DEFAULT_VERSION="1.0.0"
    
    echo ""
    print_info "ATLAS Package Download Configuration"
    echo "  GitHub Repository: https://github.com/${GITHUB_REPO}"
    echo "  Releases: https://github.com/${GITHUB_REPO}/releases"
    echo ""
    
    # Ask for version
    read -p "Enter package version [$DEFAULT_VERSION]: " PACKAGE_VERSION
    PACKAGE_VERSION=${PACKAGE_VERSION:-$DEFAULT_VERSION}
    
    PACKAGE_NAME="atlas-${PACKAGE_VERSION}.tar.gz"
    
    # Ask for download method
    echo ""
    print_info "How would you like to provide the package?"
    echo "1) Download from GitHub Releases"
    echo "2) Enter custom download URL"
    echo "3) Use local file"
    read -p "Select option [1-3]: " DOWNLOAD_OPTION
    DOWNLOAD_OPTION=${DOWNLOAD_OPTION:-1}
    
    PACKAGE_FILE=""
    DOWNLOAD_URL=""
    
    case $DOWNLOAD_OPTION in
        1)
            DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${PACKAGE_VERSION}/${PACKAGE_NAME}"
            print_info "Using GitHub Releases URL"
            ;;
        2)
            read -p "Enter download URL: " DOWNLOAD_URL
            if [ -z "$DOWNLOAD_URL" ]; then
                print_error "No URL provided"
                return 1
            fi
            ;;
        3)
            read -p "Enter path to package file: " PACKAGE_FILE
            if [ ! -f "$PACKAGE_FILE" ]; then
                print_error "File not found: $PACKAGE_FILE"
                return 1
            fi
            print_info "Using local file: $PACKAGE_FILE"
            ;;
        *)
            print_error "Invalid option"
            return 1
            ;;
    esac
    
    echo ""
    print_info "Package Information:"
    echo "  Package: ${PACKAGE_NAME}"
    echo "  Version: ${PACKAGE_VERSION}"
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "  Download URL: ${DOWNLOAD_URL}"
    elif [ -n "$PACKAGE_FILE" ]; then
        echo "  Local File: ${PACKAGE_FILE}"
    fi
    echo ""
    
    # Check if package already exists locally (if not already using local file)
    if [ -z "$PACKAGE_FILE" ]; then
        if [ -f "$PACKAGE_NAME" ]; then
            print_info "Package found in current directory: $PACKAGE_NAME"
            read -p "Use this local package instead of downloading? (Y/n): " USE_LOCAL
            USE_LOCAL=${USE_LOCAL:-Y}
            
            if [ "$USE_LOCAL" = "Y" ] || [ "$USE_LOCAL" = "y" ]; then
                PACKAGE_FILE="$PACKAGE_NAME"
                DOWNLOAD_URL=""
            fi
        elif [ -f "$SCRIPT_DIR/$PACKAGE_NAME" ]; then
            print_info "Package found in script directory: $SCRIPT_DIR/$PACKAGE_NAME"
            read -p "Use this local package instead of downloading? (Y/n): " USE_LOCAL
            USE_LOCAL=${USE_LOCAL:-Y}
            
            if [ "$USE_LOCAL" = "Y" ] || [ "$USE_LOCAL" = "y" ]; then
                PACKAGE_FILE="$SCRIPT_DIR/$PACKAGE_NAME"
                DOWNLOAD_URL=""
            fi
        fi
    fi
    
    # Download package if needed
    if [ -n "$DOWNLOAD_URL" ] && [ -z "$PACKAGE_FILE" ]; then
        echo ""
        print_info "Downloading package..."
        
        # Create temporary download directory
        DOWNLOAD_DIR="/tmp/atlas_download_$$"
        mkdir -p "$DOWNLOAD_DIR"
        
        PACKAGE_FILE="$DOWNLOAD_DIR/$PACKAGE_NAME"
        
        # Check which download tool is available
        if command -v wget &> /dev/null; then
            print_info "Using wget for download..."
            wget --progress=bar:force -O "$PACKAGE_FILE" "$DOWNLOAD_URL" 2>&1
            DOWNLOAD_RESULT=$?
            
        elif command -v curl &> /dev/null; then
            print_info "Using curl for download..."
            curl -L --progress-bar -o "$PACKAGE_FILE" "$DOWNLOAD_URL"
            DOWNLOAD_RESULT=$?
        else
            print_error "Neither wget nor curl is available"
            print_info "Installing wget..."
            apt-get update && apt-get install -y wget
            
            if command -v wget &> /dev/null; then
                wget --progress=bar:force -O "$PACKAGE_FILE" "$DOWNLOAD_URL" 2>&1
                DOWNLOAD_RESULT=$?
            else
                print_error "Failed to install wget"
                rm -rf "$DOWNLOAD_DIR"
                return 1
            fi
        fi
        
        # Check download result
        if [ $DOWNLOAD_RESULT -ne 0 ]; then
            print_error "Download failed"
            
            echo ""
            print_info "Possible reasons for download failure:"
            echo "  1. The package doesn't exist at that URL"
            echo "  2. Network connectivity issues"
            echo "  3. The URL structure is incorrect"
            echo ""
            print_info "Please verify:"
            echo "  - Check releases: https://github.com/${GITHUB_REPO}/releases"
            echo "  - Expected filename: ${PACKAGE_NAME}"
            echo ""
            
            rm -rf "$DOWNLOAD_DIR"
            
            read -p "Do you have the package file locally? (y/N): " HAS_LOCAL
            HAS_LOCAL=${HAS_LOCAL:-N}
            
            if [ "$HAS_LOCAL" = "y" ] || [ "$HAS_LOCAL" = "Y" ]; then
                read -p "Enter path to package file: " PACKAGE_FILE
                if [ ! -f "$PACKAGE_FILE" ]; then
                    print_error "File not found: $PACKAGE_FILE"
                    return 1
                fi
            else
                print_info "Please download the package manually and run this step again"
                return 1
            fi
        else
            print_success "Download completed"
        fi
    fi
    
    # Verify package file exists and is valid
    if [ ! -f "$PACKAGE_FILE" ]; then
        print_error "Package file not found: $PACKAGE_FILE"
        return 1
    fi
    
    # Verify it's a valid tar.gz file
    echo ""
    print_info "Verifying package integrity..."
    if ! tar -tzf "$PACKAGE_FILE" &>/dev/null; then
        print_error "File is not a valid tar.gz archive: $PACKAGE_FILE"
        
        if command -v file &> /dev/null; then
            print_info "File type detected: $(file "$PACKAGE_FILE")"
        fi
        
        if [ -n "$DOWNLOAD_DIR" ] && [ -d "$DOWNLOAD_DIR" ]; then
            rm -rf "$DOWNLOAD_DIR"
        fi
        
        return 1
    else
        print_success "Package verified successfully"
    fi
    
    # Show package info
    echo ""
    print_info "Package Details:"
    echo "  File: $PACKAGE_FILE"
    echo "  Size: $(du -h "$PACKAGE_FILE" | cut -f1)"
    echo ""
    
    # Show package contents preview
    print_info "Package contents (first 15 files):"
    tar -tzf "$PACKAGE_FILE" 2>/dev/null | head -n 15 | while read file; do
        echo "    $file"
    done
    FILE_COUNT=$(tar -tzf "$PACKAGE_FILE" 2>/dev/null | wc -l)
    if [ $FILE_COUNT -gt 15 ]; then
        echo "    ... and $(($FILE_COUNT - 15)) more files"
    fi
    echo "  Total: $FILE_COUNT files"
    echo ""
    
    # Export variables for use in other modules
    export PACKAGE_FILE
    export PACKAGE_NAME
    export PACKAGE_VERSION
    export DOWNLOAD_DIR
    
    return 0
}