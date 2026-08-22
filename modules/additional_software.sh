#!/bin/bash

install_additional_software() {
    print_header "Additional Software Installation"
    echo ""
    
    print_info "The following software will be checked/installed:"
    echo "  - OpenJDK (Java Development Kit)"
    echo "  - Ghostscript (gs) - PDF processing"
    echo "  - pdfjam - PDF manipulation"
    echo "  - Poppler-utils (pdfinfo) - PDF utilities"
    echo "  - TexLive-XeLaTeX - LaTeX compiler"
    echo ""
    
    read -p "Continue with installation? (Y/n): " CONTINUE
    CONTINUE=${CONTINUE:-Y}
    
    if [ "$CONTINUE" != "Y" ] && [ "$CONTINUE" != "y" ]; then
        print_info "Installation cancelled"
        return 0
    fi
    
    # Update package list
    print_info "Updating package list..."
    apt update
    
    # Install OpenJDK
    echo ""
    if command -v java &> /dev/null; then
        print_info "Java is already installed: $(java -version 2>&1 | head -n 1)"
        read -p "Reinstall OpenJDK? (y/N): " REINSTALL_JAVA
        REINSTALL_JAVA=${REINSTALL_JAVA:-N}
        if [ "$REINSTALL_JAVA" = "y" ] || [ "$REINSTALL_JAVA" = "Y" ]; then
            apt install default-jdk -y
        fi
    else
        print_info "Installing OpenJDK..."
        apt install default-jdk -y
        if [ $? -eq 0 ]; then
            print_success "OpenJDK installed: $(java -version 2>&1 | head -n 1)"
        else
            print_error "Failed to install OpenJDK"
        fi
    fi
    
    # Install Ghostscript
    echo ""
    if command -v gs &> /dev/null; then
        print_info "Ghostscript is already installed: $(gs --version)"
        read -p "Reinstall Ghostscript? (y/N): " REINSTALL_GS
        REINSTALL_GS=${REINSTALL_GS:-N}
        if [ "$REINSTALL_GS" = "y" ] || [ "$REINSTALL_GS" = "Y" ]; then
            apt install ghostscript -y
        fi
    else
        print_info "Installing Ghostscript..."
        apt install ghostscript -y
        if [ $? -eq 0 ]; then
            print_success "Ghostscript installed"
        else
            print_error "Failed to install Ghostscript"
        fi
    fi
    
    # Install pdfjam
    echo ""
    if command -v pdfjam &> /dev/null; then
        print_info "pdfjam is already installed"
        read -p "Reinstall pdfjam? (y/N): " REINSTALL_PDFJAM
        REINSTALL_PDFJAM=${REINSTALL_PDFJAM:-N}
        if [ "$REINSTALL_PDFJAM" = "y" ] || [ "$REINSTALL_PDFJAM" = "Y" ]; then
            apt install texlive-extra-utils -y
        fi
    else
        print_info "Installing pdfjam (part of texlive-extra-utils)..."
        apt install texlive-extra-utils -y
        if [ $? -eq 0 ]; then
            print_success "pdfjam installed"
        else
            print_error "Failed to install pdfjam"
        fi
    fi
    
    # Install pdfinfo (poppler-utils)
    echo ""
    if command -v pdfinfo &> /dev/null; then
        print_info "pdfinfo is already installed"
        read -p "Reinstall poppler-utils? (y/N): " REINSTALL_PDFINFO
        REINSTALL_PDFINFO=${REINSTALL_PDFINFO:-N}
        if [ "$REINSTALL_PDFINFO" = "y" ] || [ "$REINSTALL_PDFINFO" = "Y" ]; then
            apt install poppler-utils -y
        fi
    else
        print_info "Installing poppler-utils (pdfinfo)..."
        apt install poppler-utils -y
        if [ $? -eq 0 ]; then
            print_success "pdfinfo installed"
        else
            print_error "Failed to install poppler-utils"
        fi
    fi
    
    # Install XeLaTeX
    echo ""
    if command -v xelatex &> /dev/null; then
        print_info "XeLaTeX is already installed"
        read -p "Reinstall TexLive-XeLaTeX? (y/N): " REINSTALL_XELATEX
        REINSTALL_XELATEX=${REINSTALL_XELATEX:-N}
        if [ "$REINSTALL_XELATEX" = "y" ] || [ "$REINSTALL_XELATEX" = "Y" ]; then
            apt install texlive-xetex texlive-fonts-recommended texlive-plain-generic -y
        fi
    else
        print_info "Installing XeLaTeX..."
        print_info "Note: This may take several minutes..."
        apt install texlive-xetex texlive-fonts-recommended texlive-plain-generic -y
        if [ $? -eq 0 ]; then
            print_success "XeLaTeX installed"
        else
            print_error "Failed to install XeLaTeX"
        fi
    fi
    
    # Verify installations
    echo ""
    print_info "Verifying installations..."
    
    MISSING_TOOLS=""
    
    if ! command -v java &> /dev/null; then
        MISSING_TOOLS="${MISSING_TOOLS}OpenJDK, "
    fi
    
    if ! command -v gs &> /dev/null; then
        MISSING_TOOLS="${MISSING_TOOLS}Ghostscript, "
    fi
    
    if ! command -v pdfjam &> /dev/null; then
        MISSING_TOOLS="${MISSING_TOOLS}pdfjam, "
    fi
    
    if ! command -v pdfinfo &> /dev/null; then
        MISSING_TOOLS="${MISSING_TOOLS}pdfinfo, "
    fi
    
    if ! command -v xelatex &> /dev/null; then
        MISSING_TOOLS="${MISSING_TOOLS}XeLaTeX, "
    fi
    
    if [ -n "$MISSING_TOOLS" ]; then
        print_error "Some tools are missing: ${MISSING_TOOLS%, }"
        return 1
    else
        print_success "All additional software verified"
    fi
    
    echo ""
    print_success "Additional software installation completed!"
}