#!/bin/bash

create_atlas_user() {
    print_header "Create ATLAS Admin User"
    echo ""
    
    USERNAME="atlasadmin"
    
    # Check if user exists
    if id "$USERNAME" &>/dev/null; then
        print_info "User '$USERNAME' already exists"
        read -p "Do you want to reset this user? (y/N): " RESET_USER
        RESET_USER=${RESET_USER:-N}
        
        if [ "$RESET_USER" != "y" ] && [ "$RESET_USER" != "Y" ]; then
            print_info "Skipping user creation"
            return 0
        fi
        
        print_info "Removing existing user..."
        userdel -r "$USERNAME" 2>/dev/null
    fi
    
    # Create user
    print_info "Creating user '$USERNAME'..."
    
    # Create user with home directory
    useradd -m -s /bin/bash "$USERNAME"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create user"
        return 1
    fi
    
    print_success "User '$USERNAME' created"
    
    # Add user to www-data group
    print_info "Adding user to www-data group..."
    usermod -a -G www-data "$USERNAME"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to add user to www-data group"
        return 1
    fi
    
    print_success "User added to www-data group"
    
    # Set password
    echo ""
    print_info "Setting password for '$USERNAME'..."
    passwd "$USERNAME"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to set password"
        return 1
    fi
    
    print_success "Password set successfully"
    
    # Display user information
    echo ""
    print_info "User Information:"
    echo "  Username: $USERNAME"
    echo "  Home Directory: $(eval echo ~$USERNAME)"
    echo "  Groups: $(groups $USERNAME)"
    
    # Ask if user should have sudo access
    echo ""
    read -p "Grant sudo privileges to '$USERNAME'? (y/N): " GRANT_SUDO
    GRANT_SUDO=${GRANT_SUDO:-N}
    
    if [ "$GRANT_SUDO" = "y" ] || [ "$GRANT_SUDO" = "Y" ]; then
        usermod -aG sudo "$USERNAME"
        print_success "Sudo privileges granted"
    fi
    
    echo ""
    print_success "User setup completed!"
}