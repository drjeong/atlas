#!/bin/bash

# ATLAS Installation Manager
# Version: 1.0.0
# Repository: https://github.com/drjeong/atlas

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_question() {
    echo -e "${BLUE}[?]${NC} $1"
}

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if modules directory exists
if [ ! -d "$SCRIPT_DIR/modules" ]; then
    print_error "Modules directory not found: $SCRIPT_DIR/modules"
    print_info "Expected structure:"
    echo "  atlas-installer/"
    echo "  ├── install.sh"
    echo "  └── modules/"
    echo "      ├── basic_software.sh"
    echo "      ├── additional_software.sh"
    echo "      ├── user_management.sh"
    echo "      ├── directory_setup.sh"
    echo "      ├── config_setup.sh"
    echo "      ├── package_install.sh"
    echo "      ├── package_download.sh"
    echo "      ├── package_extract.sh"
    echo "      ├── package_permissions.sh"
    echo "      ├── package_components.sh"
    echo "      └── database_import.sh"
    exit 1
fi

# Check for required modules
REQUIRED_MODULES=(
    "basic_software" 
    "additional_software" 
    "user_management" 
    "directory_setup" 
    "config_setup" 
    "package_install"
    "package_download"
    "package_extract"
    "package_permissions"
    "package_components"
    "database_import"
)

MISSING_MODULES=()
for module in "${REQUIRED_MODULES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/modules/${module}.sh" ]; then
        MISSING_MODULES+=("${module}.sh")
    fi
done

if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    print_error "Missing required modules:"
    for module in "${MISSING_MODULES[@]}"; do
        echo "  - $module"
    done
    echo ""
    print_info "Please download from: https://github.com/drjeong/atlas"
    exit 1
fi

# Source all module scripts
print_info "Loading modules..."
MODULE_LOAD_FAILED=false

for module in "$SCRIPT_DIR/modules"/*.sh; do
    if [ -f "$module" ]; then
        if source "$module" 2>/dev/null; then
            print_info "Loaded: $(basename "$module")"
        else
            print_error "Failed to load: $(basename "$module")"
            MODULE_LOAD_FAILED=true
        fi
    fi
done

if [ "$MODULE_LOAD_FAILED" = true ]; then
    print_error "Some modules failed to load. Please check the module files."
    exit 1
fi

echo ""

# Display welcome message
clear
print_header "ATLAS Installation Manager"
echo ""
print_info "Assessment Tracking and Learning Analytics System"
print_info "Repository: https://github.com/drjeong/atlas"
echo ""

# Main menu function
show_menu() {
    clear
    print_header "ATLAS Installation Manager"
    echo ""
    echo "1) Install Basic Software (Apache, PHP, MySQL)"
    echo "2) Install Additional Software (Java, Ghostscript, LaTeX)"
    echo "3) Create Atlas Admin User"
    echo "4) Setup Directories and Permissions"
    echo "5) Configure Application Settings"
    echo "6) Install ATLAS Package (Package + Database)"
    echo "7) Complete Installation (Run All Steps 1-6)"
    echo "8) Exit"
    echo ""
    print_info "Current Status:"
    
    # Check status of each component
    if command -v apache2 &> /dev/null && command -v php &> /dev/null && command -v mysql &> /dev/null; then
        echo "  [✓] Basic Software: Installed"
    else
        echo "  [✗] Basic Software: Not Installed"
    fi
    
    if command -v java &> /dev/null && command -v gs &> /dev/null; then
        echo "  [✓] Additional Software: Installed"
    else
        echo "  [✗] Additional Software: Not Installed"
    fi
    
    if id "atlasadmin" &>/dev/null; then
        echo "  [✓] Atlas User: Created"
    else
        echo "  [✗] Atlas User: Not Created"
    fi
    
    if [ -f "/tmp/atlas_install_config.sh" ]; then
        source /tmp/atlas_install_config.sh
        if [ -d "/${REPO_BASE}" ]; then
            echo "  [✓] Directories: Setup Complete"
        else
            echo "  [✗] Directories: Not Setup"
        fi
        
        if [ -f "${BASE_DIR}/config.php" ]; then
            echo "  [✓] Configuration: Complete"
        else
            echo "  [✗] Configuration: Not Complete"
        fi
    else
        echo "  [✗] Directories: Not Setup"
        echo "  [✗] Configuration: Not Complete"
    fi
    
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Select an option [1-8]: " choice
    echo ""
    
    case $choice in
        1)
            install_basic_software
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            install_additional_software
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            create_atlas_user
            echo ""
            read -p "Press Enter to continue..."
            ;;
        4)
            setup_directories
            echo ""
            read -p "Press Enter to continue..."
            ;;
        5)
            configure_application
            echo ""
            read -p "Press Enter to continue..."
            ;;
        6)
            install_atlas_package
            echo ""
            read -p "Press Enter to continue..."
            ;;
        7)
            print_header "Complete Installation"
            echo ""
            print_info "This will run all installation steps in sequence:"
            echo "  1. Basic Software (Apache, PHP, MySQL)"
            echo "  2. Additional Software (Java, Ghostscript, LaTeX)"
            echo "  3. Create Atlas Admin User"
            echo "  4. Setup Directories"
            echo "  5. Configure Application"
            echo "  6. Install ATLAS Package and Database"
            echo ""
            print_info "You can skip individual steps if already completed."
            echo ""
            read -p "Continue with complete installation? (Y/n): " confirm
            confirm=${confirm:-Y}
            
            if [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
                print_info "Complete installation cancelled"
                read -p "Press Enter to continue..."
                continue
            fi
            
            # Step 1: Basic Software
            echo ""
            print_header "Step 1/6: Basic Software"
            echo ""
            if install_basic_software; then
                print_success "Step 1 completed successfully"
            else
                print_error "Step 1 failed"
                read -p "Continue anyway? (y/N): " cont
                cont=${cont:-N}
                if [ "$cont" != "y" ] && [ "$cont" != "Y" ]; then
                    read -p "Press Enter to continue..."
                    continue
                fi
            fi
            
            # Step 2: Additional Software
            echo ""
            read -p "Continue to Step 2/6 (Additional Software)? (Y/n): " cont
            cont=${cont:-Y}
            if [ "$cont" = "Y" ] || [ "$cont" = "y" ]; then
                print_header "Step 2/6: Additional Software"
                echo ""
                if install_additional_software; then
                    print_success "Step 2 completed successfully"
                else
                    print_error "Step 2 failed"
                    read -p "Continue anyway? (y/N): " cont
                    cont=${cont:-N}
                    if [ "$cont" != "y" ] && [ "$cont" != "Y" ]; then
                        read -p "Press Enter to continue..."
                        continue
                    fi
                fi
            fi
            
            # Step 3: User Creation
            echo ""
            read -p "Continue to Step 3/6 (Create Atlas User)? (Y/n): " cont
            cont=${cont:-Y}
            if [ "$cont" = "Y" ] || [ "$cont" = "y" ]; then
                print_header "Step 3/6: Create Atlas User"
                echo ""
                if create_atlas_user; then
                    print_success "Step 3 completed successfully"
                else
                    print_error "Step 3 failed"
                    read -p "Continue anyway? (y/N): " cont
                    cont=${cont:-N}
                    if [ "$cont" != "y" ] && [ "$cont" != "Y" ]; then
                        read -p "Press Enter to continue..."
                        continue
                    fi
                fi
            fi
            
            # Step 4: Directory Setup
            echo ""
            read -p "Continue to Step 4/6 (Setup Directories)? (Y/n): " cont
            cont=${cont:-Y}
            if [ "$cont" = "Y" ] || [ "$cont" = "y" ]; then
                print_header "Step 4/6: Setup Directories"
                echo ""
                if setup_directories; then
                    print_success "Step 4 completed successfully"
                else
                    print_error "Step 4 failed"
                    read -p "Continue anyway? (y/N): " cont
                    cont=${cont:-N}
                    if [ "$cont" != "y" ] && [ "$cont" != "Y" ]; then
                        read -p "Press Enter to continue..."
                        continue
                    fi
                fi
            fi
            
            # Step 5: Configuration
            echo ""
            read -p "Continue to Step 5/6 (Configure Application)? (Y/n): " cont
            cont=${cont:-Y}
            if [ "$cont" = "Y" ] || [ "$cont" = "y" ]; then
                print_header "Step 5/6: Configure Application"
                echo ""
                if configure_application; then
                    print_success "Step 5 completed successfully"
                else
                    print_error "Step 5 failed"
                    read -p "Continue anyway? (y/N): " cont
                    cont=${cont:-N}
                    if [ "$cont" != "y" ] && [ "$cont" != "Y" ]; then
                        read -p "Press Enter to continue..."
                        continue
                    fi
                fi
            fi
            
            # Step 6: Package Installation
            echo ""
            read -p "Continue to Step 6/6 (Install ATLAS Package)? (Y/n): " cont
            cont=${cont:-Y}
            if [ "$cont" = "Y" ] || [ "$cont" = "y" ]; then
                print_header "Step 6/6: Install ATLAS Package"
                echo ""
                if install_atlas_package; then
                    print_success "Step 6 completed successfully"
                else
                    print_error "Step 6 failed or incomplete"
                fi
            fi
            
            echo ""
            print_header "Complete Installation Finished"
            echo ""
            print_success "All steps completed!"
            print_info "Please review the output above for any warnings or errors."
            echo ""
            read -p "Press Enter to continue..."
            ;;
        8)
            echo ""
            print_info "Thank you for using ATLAS Installation Manager"
            
            # Cleanup temporary files
            if [ -f "/tmp/atlas_install_config.sh" ]; then
                read -p "Remove temporary configuration file? (y/N): " cleanup
                cleanup=${cleanup:-N}
                if [ "$cleanup" = "y" ] || [ "$cleanup" = "Y" ]; then
                    rm -f /tmp/atlas_install_config.sh
                    print_info "Temporary files cleaned up"
                fi
            fi
            
            exit 0
            ;;
        *)
            print_error "Invalid option. Please select 1-8"
            sleep 2
            ;;
    esac
done