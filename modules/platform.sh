#!/bin/bash

# Called explicitly after module loading; sourcing modules must not change the OS.
detect_platform() {
    if [ ! -r /etc/os-release ]; then
        print_error "Cannot detect operating system: /etc/os-release is missing"
        return 1
    fi

    local ID VERSION_ID PRETTY_NAME profile
    . /etc/os-release
    case "$ID:${VERSION_ID:-}" in
        ubuntu:22.04|ubuntu:24.04|ubuntu:26.04|ubuntu:26.04.1)
            profile=ubuntu
            PACKAGE_MANAGER=apt-get
            ;;
        amzn:2023)
            profile=amazon_linux_2023
            PACKAGE_MANAGER=dnf
            ;;
        *)
            print_error "Unsupported operating system: ${PRETTY_NAME:-$ID}"
            print_info "Supported: Ubuntu 22.04/24.04/26.04 (including 26.04.1) and Amazon Linux 2023"
            return 1
            ;;
    esac

    if ! command -v "$PACKAGE_MANAGER" >/dev/null 2>&1; then
        print_error "Required package manager not found: $PACKAGE_MANAGER"
        return 1
    fi
    if [ ! -r "$SCRIPT_DIR/platforms/$profile.sh" ]; then
        print_error "Missing platform profile: platforms/$profile.sh"
        return 1
    fi
    source "$SCRIPT_DIR/platforms/$profile.sh" || return 1
    print_info "Detected ${PRETTY_NAME:-$ID}; using $PACKAGE_MANAGER"
    if [ "$ID" = amzn ]; then
        print_info "Amazon Linux uses MariaDB (MySQL-compatible) and PHP-FPM. Database compatibility must be verified for your ATLAS package."
    fi
}

refresh_package_metadata() {
    case "$PACKAGE_MANAGER" in
        apt-get) apt-get update ;;
        dnf) dnf makecache ;;
        *) print_error "Platform has not been initialized"; return 1 ;;
    esac
}

install_packages() {
    if [ "$#" -eq 0 ] || [ -z "${PACKAGE_MANAGER:-}" ]; then
        print_error "No packages specified or platform not initialized"
        return 1
    fi
    if ! "$PACKAGE_MANAGER" install -y "$@"; then
        print_error "Package installation failed: $*. Check enabled repositories and package availability for this OS version."
        return 1
    fi
}
