#!/bin/bash

configure_application() {
    print_header "Application Configuration"
    echo ""
    
    # Load saved configuration if exists
    if [ -f /tmp/atlas_install_config.sh ]; then
        source /tmp/atlas_install_config.sh
        print_info "Loaded previous configuration"
    else
        read -p "Enter base directory [/var/www]: " BASE_DIR
        BASE_DIR=${BASE_DIR:-/var/www}
        
        read -p "Enter web directory [${BASE_DIR}/html]: " WEB_DIR
        WEB_DIR=${WEB_DIR:-${BASE_DIR}/html}
        
        read -p "Enter repository base [/var/www/data]: " REPO_BASE
        REPO_BASE=${REPO_BASE:-/var/www/data}
    fi
    
    CONFIG_FILE="${BASE_DIR}/config.php"
   
    # Check if config file exists
    if [ -f "$CONFIG_FILE" ]; then
        print_info "Configuration file already exists: $CONFIG_FILE"
        read -p "Overwrite existing configuration? (y/N): " OVERWRITE
        OVERWRITE=${OVERWRITE:-N}
        
        if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
            print_info "Configuration update cancelled"
            return 0
        fi
        
        # Backup existing config
        BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        print_success "Backed up existing config to: $BACKUP_FILE"
    fi
    
    # Gather configuration values
    echo ""
    print_info "Please provide the following configuration values:"
    echo ""
    
    # Web Configuration
    read -p "Primary web domain [atlas.myuniversity.edu]: " WEB_HOME
    WEB_HOME=${WEB_HOME:-atlas.myuniversity.edu}
    
    read -p "System timezone [America/New_York]: " USER_TIMEZONE
    USER_TIMEZONE=${USER_TIMEZONE:-America/New_York}
    
    read -p "Assistant user code [999999998]: " ASSISTANT_CODE
    ASSISTANT_CODE=${ASSISTANT_CODE:-999999998}
    
    # Semester Pattern Configuration
    echo ""
    print_info "Semester Pattern Configuration:"
    echo "This determines how semester codes are generated (e.g., 202520 for Spring 2025)."
    echo ""
    echo "Available patterns:"
    echo "  standard      - Traditional Banner 9 (Fall=10, Spring=20, Summer=30)"
    echo "                  Most common. Fall uses next calendar year (Fall 2025 = 202610)"
    echo ""
    echo "  alternative   - Extended sessions (Winter=05, Spring=10, Summer=20, Fall=40)"
    echo "                  Includes community and Saturday sessions"
    echo ""
    echo "  sequential    - Simple numbering (Fall=01, Spring=02, Summer=03)"
    echo ""
    echo "  quarters      - 4 terms per year (Fall=10, Winter=20, Spring=30, Summer=40)"
    echo "                  Common in UC system, Stanford, Northwestern"
    echo ""
    echo "  trimester     - 3 equal terms (Fall=10, Winter=20, Spring=30)"
    echo ""
    echo "  mini_terms    - Full semesters plus A/B/C sub-sessions"
    echo ""
    echo "  international - Calendar year based (all terms use same year)"
    echo ""
    echo "For detailed pattern information, see: SemesterCodeConfig.php"
    echo ""
    read -p "Select semester pattern [standard]: " SEMESTER_PATTERN
    SEMESTER_PATTERN=${SEMESTER_PATTERN:-standard}
    
    # Validate semester pattern
    case "$SEMESTER_PATTERN" in
        standard|alternative|sequential|quarters|trimester|mini_terms|international)
            print_success "Using semester pattern: $SEMESTER_PATTERN"
            ;;
        *)
            print_warning "Invalid pattern '$SEMESTER_PATTERN', defaulting to 'standard'"
            SEMESTER_PATTERN="standard"
            ;;
    esac
    
    # Database Configuration
    echo ""
    print_info "Database Configuration:"
    read -p "Database hostname [localhost]: " DB_HOSTNAME
    DB_HOSTNAME=${DB_HOSTNAME:-localhost}
    
    read -p "Database name [atlas_db]: " DB_DBNAME
    DB_DBNAME=${DB_DBNAME:-atlas_db}
    
    read -p "Database user [atlasdbadmin]: " DB_USERID
    DB_USERID=${DB_USERID:-atlasdbadmin}
    
    read -sp "Database password: " DB_USERPWD
    echo ""
    
    # Generate encryption key
    print_info "Generating database encryption key..."
    DB_ENCRYPTION_KEY=$(openssl rand -hex 32)
    print_success "Encryption key generated"
    
    # Email Configuration
    echo ""
    print_info "Email Configuration (gmail is preferred):"
    read -p "Email method (sendmail/gmail) [gmail]: " EMAIL_METHOD
    EMAIL_METHOD=${EMAIL_METHOD:-gmail}
    
    read -p "Server sendmail address [web-master@myuniv.edu]: " SERVER_SENDMAIL
    SERVER_SENDMAIL=${SERVER_SENDMAIL:-web-master@myuniv.edu}
    
    read -p "Admin notification email [admin@atlas.edu]: " ADMIN_ACCOUNT_EMAIL
    ADMIN_ACCOUNT_EMAIL=${ADMIN_ACCOUNT_EMAIL:-admin@atlas.edu}
    
    read -p "Admin reply-to email [admin.replyto@atlas.edu]: " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin.replyto@atlas.edu}
    
    if [ "$EMAIL_METHOD" = "gmail" ]; then
        read -p "Gmail account [gmailadmin.notification@gmail.com]: " GMAIL_ACCOUNT
        GMAIL_ACCOUNT=${GMAIL_ACCOUNT:-gmailadmin.notification@gmail.com}
        
        read -sp "Gmail app password: " GMAIL_APP_PWD
        echo ""
    else
        GMAIL_ACCOUNT="gmailadmin.notification@gmail.com"
        GMAIL_APP_PWD="gmailadminpassword"
    fi
    
    # Banner Integration
    echo ""
    print_info "Banner Self-Service Configuration:"
    read -p "Banner SSB URL [https://reg-prod.ec.myuniv.edu/StudentRegistrationSsb]: " BANNER_SSB_URL
    BANNER_SSB_URL=${BANNER_SSB_URL:-https://reg-prod.ec.myuniv.edu/StudentRegistrationSsb}
    
    # Generate config.php
    echo ""
    print_info "Generating configuration file..."
    
    cat > "$CONFIG_FILE" << EOF
<?php
// Prevent direct access to this file
if (!defined('__DIRECTORY_HOME__')) {

    // ========================================================================
    // WEB CONFIGURATION
    // ========================================================================

    /**
     * Primary web domain (CloudFront CDN)
     */
    define('__WEB_HOME__', '${WEB_HOME}');

    /**
     * System timezone for all operations
     */
    define('__USER_TIMEZONE', '${USER_TIMEZONE}');

    /**
     * Assistant user code (must match entry in database \`Positions\` table)
     */
    define('__ASSISTANT_USERCODE', ${ASSISTANT_CODE});

    /**
     * Semester Pattern - Determines how semester codes are generated
     * 
     * Valid options: 'standard', 'alternative', 'sequential', 'quarters',
     *                'trimester', 'mini_terms', 'international'
     * 
     * This setting must match your institution's Banner configuration.
     * See SemesterCodeConfig.php for detailed pattern documentation.
     * 
     * Selected pattern: ${SEMESTER_PATTERN}
     */
    define('__SCHOOL_SEMESTER_PATTERN', '${SEMESTER_PATTERN}');

    // ========================================================================
    // DIRECTORY STRUCTURE
    // ========================================================================

    /**
     * Primary server directory configuration
     */
    define('__DIRECTORY_HOME__', '${BASE_DIR}');
    define('__DIRECTORY_WEBHOME__', '${WEB_DIR}');
    define('__DIRECTORY_REPOSITORY_HOME__', '${REPO_BASE}');

    /**
     * Application Data Directories
     *
     * IMPORTANT: All directories below must have atlasadmin:www-data ownership
     * Run: sudo chown -R atlasadmin:www-data /var/www/[directory]
     */

    // ABET Assessment related directories
    define('__DIRECTORY_ABETASSESSMENTS__', __DIRECTORY_REPOSITORY_HOME__ . '/assessments/');
    define('__DIRECTORY_ABETASSESSMENTSURVEY__', __DIRECTORY_REPOSITORY_HOME__ . '/assessmentsurvey/');
    define('__DIRECTORY_ABETSYLLABI__', __DIRECTORY_REPOSITORY_HOME__ . '/abetsyllabi/');

    // Course related directories
    define('__DIRECTORY_INSTRUCTIONAL_MATERIALS__', __DIRECTORY_REPOSITORY_HOME__ . '/instructionalmaterials/');
    define('__DIRECTORY_COURSEASSIGNMENT_SAMPLES__', __DIRECTORY_REPOSITORY_HOME__ . '/courseassignmentsamples/');
    define('__DIRECTORY_COURSEBI__', __DIRECTORY_REPOSITORY_HOME__ . '/coursesyllabi/');
    define('__DIRECTORY_COURSEBINDERS__', __DIRECTORY_REPOSITORY_HOME__ . '/coursebinders/');
    define('__DIRECTORY_COURSEASSESSMENTREPORTS__', __DIRECTORY_REPOSITORY_HOME__ . '/courseassessmentreports/');

    // System related directories
    define('__DIRECTORY_GETCOURSEINFO__', __DIRECTORY_REPOSITORY_HOME__ . '/getcourseinfo/');
    define('__DIRECTORY_RECYCLEBIN__', __DIRECTORY_REPOSITORY_HOME__ . '/recyclebin/');

    // ========================================================================
    // EXTERNAL TOOLS & LIBRARIES
    // ========================================================================

    /**
     * PDF processing tools
     */
    define('__PDFBOX_PATH__', __DIRECTORY_WEBHOME__ . '/toolbox/pdfbox/pdfbox-app-3.0.2.jar');
    define('__GS_PATH__', '/usr/bin/gs');

    /**
     * System configuration file (self-reference)
     */
    define('__FILE_CONFIG__', __DIRECTORY_HOME__ . '/config.php');


    // ========================================================================
    // ENCRYPTION KEYS
    // ========================================================================

    /**
     * RSA key pair for encryption/decryption
     */
    define('__KEY_PRIVATE', __DIRECTORY_HOME__ . '/rsa_1024_priv.pem');
    define('__KEY_PUBLIC', __DIRECTORY_HOME__ . '/rsa_1024_pub.pem');


    // ========================================================================
    // DATABASE CONFIGURATION
    // ========================================================================

    /**
     * Database connection settings
     */
    define('__DB_HOSTNAME', '${DB_HOSTNAME}');
    define('__DB_DBNAME', '${DB_DBNAME}');
    define('__DB_USERID', '${DB_USERID}');
    define('__DB_USERPWD', '${DB_USERPWD}');

    /**
     * Database encryption key (AES-256)
     */
    define('__DB_ENCRYPTION_KEY', '${DB_ENCRYPTION_KEY}');


    // ========================================================================
    // UNIVERSITY BRANDING
    // ========================================================================

    define('__UNIV_LOGO_PATH__', __DIRECTORY_WEBHOME__ . '/images/universitylogo.png');
    define('__UNIV_COLLEGE_LOGO', 'images/collegelogo.png');
    define('__UNIV_COLLEGE_LOGO_PATH__', __DIRECTORY_WEBHOME__ . '/images/collegelogo.png');
    define('__UNIV_NAME__', 'University of ATLAS');
    define('__UNIV_ADDRESS__', '1004 Atlas Avenue | Washington, DC 00001');


    // ========================================================================
    // EMAIL CONFIGURATION
    // ========================================================================

    define('__EMAIL_METHOD__', '${EMAIL_METHOD}');
    define('__SERVER_SENDMAIL', '${SERVER_SENDMAIL}');
    define('__ADMIN_ACCOUNT_EMAILADDRESS', '${ADMIN_ACCOUNT_EMAIL}');
    define('__ADMIN_EMAILADDRESS', '${ADMIN_EMAIL}');
    define('__SMTP_GMAILACCOUNT__', '${GMAIL_ACCOUNT}');
    define('__SMTP_GMAILAPPPWD__', '${GMAIL_APP_PWD}');

    // ========================================================================
    // UNIVERSITY COURSE INFORMATION SYSTEM
    // ========================================================================

    define('__COURSE_LISTING_METHOD__', 'BANNER9');
    define('__BANNER_SSB_URL__', '${BANNER_SSB_URL}');
    define('__BANNER_TERMS_API_URL__', __BANNER_SSB_URL__ . '/ssb/classSearch/getTerms?searchTerm=&offset=1&max=50');
}

// ============================================================================
// END OF CONFIGURATION
// ============================================================================
EOF

    # Set proper permissions
    chown atlasadmin:www-data "$CONFIG_FILE"
    chmod 640 "$CONFIG_FILE"
    
    print_success "Configuration file created: $CONFIG_FILE"
    
    # Display summary
    echo ""
    print_info "Configuration Summary:"
    echo "  Web Domain: $WEB_HOME"
    echo "  Timezone: $USER_TIMEZONE"
    echo "  Semester Pattern: $SEMESTER_PATTERN"
    echo "  Database: $DB_DBNAME@$DB_HOSTNAME"
    echo "  Email Method: $EMAIL_METHOD"
    echo "  Config File: $CONFIG_FILE"
    
    echo ""
    print_success "Application configuration completed!"
}