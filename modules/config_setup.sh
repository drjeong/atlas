#!/bin/bash

# Escape values embedded in PHP single-quoted string literals.
config_php_string() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\'/\\\'}
    printf '%s' "$value"
}

configure_application() {
    print_header "Application Configuration"
    echo ""
    
    # Load saved configuration if exists
    if [ -f /tmp/atlas_install_config.sh ]; then
        source /tmp/atlas_install_config.sh
        print_info "Loaded previous configuration"
    else
        read -r -p "Enter base directory [/var/www]: " BASE_DIR
        BASE_DIR=${BASE_DIR:-/var/www}
        
        read -r -p "Enter web directory [${BASE_DIR}/html]: " WEB_DIR
        WEB_DIR=${WEB_DIR:-${BASE_DIR}/html}
        
        read -r -p "Enter repository base [/var/www/data]: " REPO_BASE
        REPO_BASE=${REPO_BASE:-/var/www/data}
    fi
    
    CONFIG_FILE="${BASE_DIR}/config.php"
   
    # Check if config file exists
    if [ -f "$CONFIG_FILE" ]; then
        print_info "Configuration file already exists: $CONFIG_FILE"
        read -r -p "Overwrite existing configuration? (y/N): " OVERWRITE
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
    read -r -p "Primary web domain [atlas.myuniversity.edu]: " WEB_HOME
    WEB_HOME=${WEB_HOME:-atlas.myuniversity.edu}
    
    read -r -p "System timezone [America/New_York]: " USER_TIMEZONE
    USER_TIMEZONE=${USER_TIMEZONE:-America/New_York}
    
    read -r -p "Assistant user code [999999998]: " ASSISTANT_CODE
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
    read -r -p "Select semester pattern [standard]: " SEMESTER_PATTERN
    SEMESTER_PATTERN=${SEMESTER_PATTERN:-standard}
    
    # Validate semester pattern
    case "$SEMESTER_PATTERN" in
        standard|alternative|sequential|quarters|trimester|mini_terms|international)
            print_success "Using semester pattern: $SEMESTER_PATTERN"
            ;;
        *)
            print_info "Invalid pattern '$SEMESTER_PATTERN', defaulting to 'standard'"
            SEMESTER_PATTERN="standard"
            ;;
    esac
    
    # Storage settings are deliberately not saved in the shared /tmp shell config.
    echo ""
    read -r -p "Storage backend (local/s3) [local]: " STORAGE_BACKEND
    STORAGE_BACKEND=${STORAGE_BACKEND:-local}
    case "$STORAGE_BACKEND" in
        local|s3) ;;
        *) print_error "Storage backend must be local or s3"; return 1 ;;
    esac
    AWS_S3_BUCKET=
    AWS_S3_REGION=
    AWS_S3_PREFIX=
    if [ "$STORAGE_BACKEND" = s3 ]; then
        read -r -p "S3 bucket name (required): " AWS_S3_BUCKET
        read -r -p "S3 region [us-east-1]: " AWS_S3_REGION
        AWS_S3_REGION=${AWS_S3_REGION:-us-east-1}
        read -r -p "S3 key prefix (optional, e.g. atlas/): " AWS_S3_PREFIX
        if [[ ! "$AWS_S3_BUCKET" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]] ||
           [[ "$AWS_S3_BUCKET" == *..* ]] ||
           [[ ! "$AWS_S3_REGION" =~ ^[a-z0-9]+(-[a-z0-9]+)+-[0-9]+$ ]]; then
            print_error "Enter a valid S3 bucket name (not an s3:// URL) and AWS region"
            return 1
        fi
        print_info "S3 uses the application's AWS SDK credential chain; on EC2 attach an IAM role with bucket/prefix permissions."
        print_info "No AWS access keys are written. Ensure the ATLAS package includes its S3 storage adapter and AWS SDK."
    fi

    if [[ ! "$ASSISTANT_CODE" =~ ^[0-9]+$ ]]; then
        print_error "Assistant user code must contain only digits"
        return 1
    fi

    # Database Configuration
    echo ""
    print_info "Database Configuration:"
    read -r -p "Database hostname [localhost]: " DB_HOSTNAME
    DB_HOSTNAME=${DB_HOSTNAME:-localhost}
    
    read -r -p "Database name [atlas_db]: " DB_DBNAME
    DB_DBNAME=${DB_DBNAME:-atlas_db}
    
    read -r -p "Database user [atlasdbadmin]: " DB_USERID
    DB_USERID=${DB_USERID:-atlasdbadmin}
    
    read -r -sp "Database password: " DB_USERPWD
    echo ""
    
    # Generate encryption key
    print_info "Generating database encryption key..."
    DB_ENCRYPTION_KEY=$(openssl rand -hex 32)
    print_success "Encryption key generated"
    
    # Email Configuration
    echo ""
    print_info "Email Configuration (gmail is preferred):"
    read -r -p "Email method (sendmail/gmail) [gmail]: " EMAIL_METHOD
    EMAIL_METHOD=${EMAIL_METHOD:-gmail}
    
    read -r -p "Server sendmail address [web-master@myuniv.edu]: " SERVER_SENDMAIL
    SERVER_SENDMAIL=${SERVER_SENDMAIL:-web-master@myuniv.edu}
    
    read -r -p "Admin notification email [admin@atlas.edu]: " ADMIN_ACCOUNT_EMAIL
    ADMIN_ACCOUNT_EMAIL=${ADMIN_ACCOUNT_EMAIL:-admin@atlas.edu}
    
    read -r -p "Admin reply-to email [admin.replyto@atlas.edu]: " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin.replyto@atlas.edu}
    
    if [ "$EMAIL_METHOD" = "gmail" ]; then
        read -r -p "Gmail account [gmailadmin.notification@gmail.com]: " GMAIL_ACCOUNT
        GMAIL_ACCOUNT=${GMAIL_ACCOUNT:-gmailadmin.notification@gmail.com}
        
        read -r -sp "Gmail app password: " GMAIL_APP_PWD
        echo ""
    else
        GMAIL_ACCOUNT="gmailadmin.notification@gmail.com"
        GMAIL_APP_PWD="gmailadminpassword"
    fi
    
    # Banner Integration
    echo ""
    print_info "Banner Self-Service Configuration:"
    read -r -p "Banner SSB URL [https://reg-prod.ec.myuniv.edu/StudentRegistrationSsb]: " BANNER_SSB_URL
    BANNER_SSB_URL=${BANNER_SSB_URL:-https://reg-prod.ec.myuniv.edu/StudentRegistrationSsb}
    
    # Generate config.php
    echo ""
    print_info "Generating configuration file..."
    
    (
    umask 077
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
    define('__WEB_HOME__', '$(config_php_string "$WEB_HOME")');

    /**
     * System timezone for all operations
     */
    define('__USER_TIMEZONE', '$(config_php_string "$USER_TIMEZONE")');

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

    // STORAGE CONFIGURATION
    define('__STORAGE_BACKEND__', '${STORAGE_BACKEND}');
    define('__AWS_S3_BUCKET__', '$(config_php_string "$AWS_S3_BUCKET")');
    define('__AWS_S3_REGION__', '$(config_php_string "$AWS_S3_REGION")');
    define('__AWS_S3_PREFIX__', '$(config_php_string "$AWS_S3_PREFIX")');
    // AWS credentials come from the SDK credential chain (EC2 IAM role recommended).

    // ========================================================================
    // DIRECTORY STRUCTURE
    // ========================================================================

    /**
     * Primary server directory configuration
     */
    define('__DIRECTORY_HOME__', '$(config_php_string "$BASE_DIR")');
    define('__DIRECTORY_WEBHOME__', '$(config_php_string "$WEB_DIR")');
    define('__DIRECTORY_REPOSITORY_HOME__', '$(config_php_string "$REPO_BASE")');

    /**
     * Application Data Directories
     *
     * IMPORTANT: All directories below must have atlasadmin:${APACHE_USER} ownership
     * Run: sudo chown -R atlasadmin:${APACHE_USER} /var/www/[directory]
     */

    // Logical S3 paths are resolved by the application's storage adapter.
    // Bucket and prefix are configured above, not embedded in these paths.
    if (__STORAGE_BACKEND__ === 's3') {
        define('__DIRECTORY_ABETASSESSMENTS__', 's3://assessments/');
        define('__DIRECTORY_ABETASSESSMENTSURVEY__', 's3://assessmentsurvey/');
        define('__DIRECTORY_ABETSYLLABI__', 's3://abetsyllabi/');
        define('__DIRECTORY_INSTRUCTIONAL_MATERIALS__', 's3://instructionalmaterials/');
        define('__DIRECTORY_COURSEASSIGNMENT_SAMPLES__', 's3://courseassignmentsamples/');
        define('__DIRECTORY_COURSEBI__', 's3://coursesyllabi/');
        define('__DIRECTORY_COURSEBINDERS__', 's3://coursebinders/');
        define('__DIRECTORY_COURSEASSESSMENTREPORTS__', 's3://courseassessmentreports/');
        define('__DIRECTORY_COURSEASSESSMENTSAMPLES__', 's3://courseassessmentsamples/');
    } else {
        define('__DIRECTORY_ABETASSESSMENTS__', __DIRECTORY_REPOSITORY_HOME__ . '/assessments/');
        define('__DIRECTORY_ABETASSESSMENTSURVEY__', __DIRECTORY_REPOSITORY_HOME__ . '/assessmentsurvey/');
        define('__DIRECTORY_ABETSYLLABI__', __DIRECTORY_REPOSITORY_HOME__ . '/abetsyllabi/');
        define('__DIRECTORY_INSTRUCTIONAL_MATERIALS__', __DIRECTORY_REPOSITORY_HOME__ . '/instructionalmaterials/');
        define('__DIRECTORY_COURSEASSIGNMENT_SAMPLES__', __DIRECTORY_REPOSITORY_HOME__ . '/courseassignmentsamples/');
        define('__DIRECTORY_COURSEBI__', __DIRECTORY_REPOSITORY_HOME__ . '/coursesyllabi/');
        define('__DIRECTORY_COURSEBINDERS__', __DIRECTORY_REPOSITORY_HOME__ . '/coursebinders/');
        define('__DIRECTORY_COURSEASSESSMENTREPORTS__', __DIRECTORY_REPOSITORY_HOME__ . '/courseassessmentreports/');
        define('__DIRECTORY_COURSEASSESSMENTSAMPLES__', __DIRECTORY_REPOSITORY_HOME__ . '/courseassessmentsamples/');
    }

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
    define('__DB_HOSTNAME', '$(config_php_string "$DB_HOSTNAME")');
    define('__DB_DBNAME', '$(config_php_string "$DB_DBNAME")');
    define('__DB_USERID', '$(config_php_string "$DB_USERID")');
    define('__DB_USERPWD', '$(config_php_string "$DB_USERPWD")');

    /**
     * Database encryption key (AES-256)
     */
    define('__DB_ENCRYPTION_KEY', '$(config_php_string "$DB_ENCRYPTION_KEY")');


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

    define('__EMAIL_METHOD__', '$(config_php_string "$EMAIL_METHOD")');
    define('__SERVER_SENDMAIL', '$(config_php_string "$SERVER_SENDMAIL")');
    define('__ADMIN_ACCOUNT_EMAILADDRESS', '$(config_php_string "$ADMIN_ACCOUNT_EMAIL")');
    define('__ADMIN_EMAILADDRESS', '$(config_php_string "$ADMIN_EMAIL")');
    define('__SMTP_GMAILACCOUNT__', '$(config_php_string "$GMAIL_ACCOUNT")');
    define('__SMTP_GMAILAPPPWD__', '$(config_php_string "$GMAIL_APP_PWD")');

    // ========================================================================
    // UNIVERSITY COURSE INFORMATION SYSTEM
    // ========================================================================

    define('__COURSE_LISTING_METHOD__', 'BANNER9');
    define('__BANNER_SSB_URL__', '$(config_php_string "$BANNER_SSB_URL")');
    define('__BANNER_TERMS_API_URL__', __BANNER_SSB_URL__ . '/ssb/classSearch/getTerms?searchTerm=&offset=1&max=50');
}

// ============================================================================
// STORAGE HELPERS
// Guards allow config.php to be included repeatedly without redeclaration.
if (!function_exists('isS3Path')) {
    function isS3Path(\$path) {
        return strpos(\$path, 's3://') === 0;
    }
}
if (!function_exists('getStorageBackend')) {
    function getStorageBackend() {
        return __STORAGE_BACKEND__;
    }
}

// END OF CONFIGURATION
// ============================================================================
EOF
    ) || { print_error "Failed to write configuration file"; return 1; }

    # Set proper permissions
    chown "atlasadmin:${APACHE_USER}" "$CONFIG_FILE" || return 1
    chmod 640 "$CONFIG_FILE" || return 1
    
    print_success "Configuration file created: $CONFIG_FILE"
    
    # Display summary
    echo ""
    print_info "Configuration Summary:"
    echo "  Web Domain: $WEB_HOME"
    echo "  Timezone: $USER_TIMEZONE"
    echo "  Semester Pattern: $SEMESTER_PATTERN"
    echo "  Storage Backend: $STORAGE_BACKEND"
    if [ "$STORAGE_BACKEND" = s3 ]; then
        echo "  S3 Bucket: $AWS_S3_BUCKET"
        echo "  S3 Region: $AWS_S3_REGION"
        echo "  S3 Prefix: $AWS_S3_PREFIX"
    fi
    echo "  Database: $DB_DBNAME@$DB_HOSTNAME"
    echo "  Email Method: $EMAIL_METHOD"
    echo "  Config File: $CONFIG_FILE"
    
    echo ""
    print_success "Application configuration completed!"
}