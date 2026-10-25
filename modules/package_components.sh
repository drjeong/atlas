#!/bin/bash

install_atlas_components() {
    echo ""
    print_header "Installing Components"
    echo ""
    
    # Verify web directory exists
    if [ ! -d "$WEB_DIR" ]; then
        print_error "Web directory does not exist: $WEB_DIR"
        return 1
    fi
    
    # Download PDFBox if needed
    print_info "Checking PDFBox installation..."
    
    if [ ! -d "${WEB_DIR}/toolbox/pdfbox" ]; then
        mkdir -p "${WEB_DIR}/toolbox/pdfbox"
        if [ $? -ne 0 ]; then
            print_error "Failed to create PDFBox directory"
            return 1
        fi
        chown -R atlasadmin:${APACHE_USER} "${WEB_DIR}/toolbox"
    fi
    
    PDFBOX_VERSION="3.0.2"
    PDFBOX_JAR="${WEB_DIR}/toolbox/pdfbox/pdfbox-app-${PDFBOX_VERSION}.jar"
    
    if [ ! -f "$PDFBOX_JAR" ]; then
        print_info "Downloading PDFBox ${PDFBOX_VERSION}..."
        PDFBOX_URL="https://downloads.apache.org/pdfbox/${PDFBOX_VERSION}/pdfbox-app-${PDFBOX_VERSION}.jar"
        
        if command -v wget &> /dev/null; then
            wget -q --show-progress -O "$PDFBOX_JAR" "$PDFBOX_URL"
        elif command -v curl &> /dev/null; then
            curl -L --progress-bar -o "$PDFBOX_JAR" "$PDFBOX_URL"
        else
            print_error "Neither wget nor curl is available"
            print_info "Please download manually from: $PDFBOX_URL"
            print_info "Place in: ${WEB_DIR}/toolbox/pdfbox/"
            return 1
        fi
        
        if [ -f "$PDFBOX_JAR" ]; then
            chown atlasadmin:${APACHE_USER} "$PDFBOX_JAR"
            chmod 644 "$PDFBOX_JAR"
            print_success "PDFBox installed"
        else
            print_error "Failed to download PDFBox"
            print_info "Download manually from: $PDFBOX_URL"
            print_info "Place in: ${WEB_DIR}/toolbox/pdfbox/"
        fi
    else
        print_info "PDFBox already installed: $PDFBOX_JAR"
    fi
    
    # Verify Java is available for PDFBox
    if command -v java &> /dev/null; then
        print_success "Java is available for PDFBox"
    else
        print_error "Java is not installed - PDFBox requires Java"
        print_info "Install Java using Menu Option 2"
    fi
    
    # Check for images directory
    echo ""
    print_info "Checking images directory..."
    
    if [ ! -d "${WEB_DIR}/images" ]; then
        mkdir -p "${WEB_DIR}/images"
        if [ $? -eq 0 ]; then
            chown -R atlasadmin:${APACHE_USER} "${WEB_DIR}/images"
            chmod 755 "${WEB_DIR}/images"
            print_success "Images directory created: ${WEB_DIR}/images"
        else
            print_error "Failed to create images directory"
            return 1
        fi
    else
        print_success "Images directory exists: ${WEB_DIR}/images"
    fi
    
    # Check for logo files
    MISSING_LOGOS=false
    if [ ! -f "${WEB_DIR}/images/universitylogo.png" ]; then
        print_info "Missing: universitylogo.png"
        MISSING_LOGOS=true
    else
        print_success "Found: universitylogo.png"
    fi
    
    if [ ! -f "${WEB_DIR}/images/collegelogo.png" ]; then
        print_info "Missing: collegelogo.png"
        MISSING_LOGOS=true
    else
        print_success "Found: collegelogo.png"
    fi
    
    if [ "$MISSING_LOGOS" = true ]; then
        echo ""
        print_info "Logo files needed:"
        echo "  Place the following files in ${WEB_DIR}/images/:"
        echo "    - universitylogo.png (recommended size: 400x400 px)"
        echo "    - collegelogo.png (recommended size: 400x400 px)"
        echo ""
        print_info "You can add these files later before using the application"
    fi
    
    echo ""
    print_success "Component installation completed!"
    
    return 0
}