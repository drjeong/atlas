# ATLAS Installation Manager

Current ATLAS source package version: **1.5.2**.

## Platform support

The installer detects `/etc/os-release` and loads an explicit profile:

- Ubuntu 22.04/24.04: apt-get, Apache, MySQL.
- Amazon Linux 2023: dnf, httpd, PHP-FPM, MariaDB 10.5.

Other OS versions are rejected before installation. Run with
`sudo bash install.sh`, not `sh install.sh`. Keep `platforms/` beside
`install.sh`. Shared helpers are in `modules/platform.sh`; OS-specific
settings are in `platforms/`. Add a profile and detection entry to extend
support. The installer refreshes metadata but does not upgrade the OS.

Amazon Linux uses MariaDB rather than Oracle MySQL; verify compatibility
with your ATLAS package. No external repositories are enabled automatically.
Optional TeX package availability depends on enabled repositories; installation
failures are reported. Target-host end-to-end testing is still required.
Review firewall, SELinux, TLS, database hardening, and Apache virtual-host
and AllowOverride settings for your deployment; security controls are not
disabled automatically.

## Installation

1. **Download the installer**

   Clones the ATLAS repository from GitHub and navigates to the installer directory.

```bash
   git clone https://github.com/drjeong/atlas.git
   cd atlas
```

2. **Make sure packages are in place**

   Place the source archive `atlas-1.5.2.tar.gz` and its matching database archive
      `atlas-1.5.2-db.sql.gz` under the `packages` folder.

3. **Make scripts executable**

   Grants execute permissions to all shell scripts in the current directory and the modules subfolder, allowing them to run as programs.

```bash
   chmod +x *.sh modules/*.sh
```

4. **Run installer**

   Executes the main installation script to set up ATLAS on your system.

```bash
   sudo bash install.sh
```

5. **Select installation option**

   The installer will present the following menu:

   **ATLAS Installation Manager**

   | Option | Description |
   |--------|-------------|
   | 1 | Install Basic Software (Apache, PHP, MySQL) |
   | 2 | Install Additional Software (Java, Ghostscript, LaTeX) |
   | 3 | Create Atlas Admin User |
   | 4 | Setup Directories and Permissions |
   | 5 | Configure Application Settings |
   | 6 | Install ATLAS Package |
   | 7 | Complete Installation (Run All Steps) |
   | 8 | Exit |

   Select an option `[1-8]`.

   **Recommended:** If you do not have any software packages installed on your server machine, please select option `7` to run the complete installation process automatically. This option automatically runs all installation steps required to set up ATLAS.
   
Default ATLAS system administrator: `admin@atlas.edu` / `atlas123##`.
Change the default password immediately after installation.


## Database import encoding and compatibility

Database import uses `mysql --default-character-set=utf8mb4`. Before importing,
the installer checks whether the target server supports `utf8mb4_0900_ai_ci`.
If supported (for example, MySQL 8), it replaces `utf8mb4_unicode_ci` in the
SQL stream with that collation. Otherwise (including MariaDB 10.5), it uses
`utf8mb4_unicode_ci` and converts `utf8mb4_0900_ai_ci` references back to it.
The selected collation is also used when creating a new database.

The import stream removes backtick-quoted clauses such as
``DEFINER=`old_user`@`localhost` `` to avoid depending on source-server accounts.
Views and routines then default to the importing account as definer; review
`SQL SECURITY` behavior and privileges before production use. Conversion uses
text replacement, not a SQL parser; matching text in SQL data is also replaced.
Keep the original backup and verify imported data and stored objects.

Both progress and non-progress imports detect decompression/filter/client
failures and display MySQL errors. Imports are not atomic: a failed import may
leave a partially populated database that needs recovery before retrying.
The installer does not rewrite dump `SET NAMES` statements; use a dump whose
declared source encoding matches its actual bytes.

## Application and storage configuration

Select menu option `5` (or the configuration step in option `7`) to generate
`config.php` in the selected base directory (default: `/var/www/config.php`).
The installer asks before overwriting an existing file and makes a timestamped
backup if you proceed. Protect backups because they contain credentials.

The prompts cover web domain, timezone, semester pattern, database connection,
email delivery, Banner integration, and storage. The generated configuration
contains database and email credentials; keep it outside the public web root.
It is assigned to `atlasadmin` and the platform's Apache group with mode `640`.

### Local storage (default)

Choose `local` at the storage backend prompt. Application data paths use the
selected repository base directory (default: `/var/www/data`). No AWS settings
are required.

### Amazon S3 storage

Choose `s3` and provide:

- **Bucket:** an existing S3 bucket name, not an `s3://` URL.
- **Region:** the bucket's AWS region (default: `us-east-1`).
- **Prefix:** an optional object-key prefix, for example `atlas/`.

The generated file defines `__STORAGE_BACKEND__`, `__AWS_S3_BUCKET__`,
`__AWS_S3_REGION__`, and `__AWS_S3_PREFIX__`. Storage-aware paths use logical
values such as `s3://assessments/`; the application's storage adapter resolves
these using the bucket and prefix. These are not literal bucket URLs.

S3-aware directories are `abetsyllabi`, `assessments`, `assessmentsurvey`,
`courseassessmentreports`, `courseassessmentsamples`, `courseassignmentsamples`,
`coursebinders`, `coursesyllabi`, and `instructionalmaterials`.
`getcourseinfo` and `recyclebin` remain local, as do configuration, RSA keys,
application files, and external tools. The generated config also includes
`isS3Path()` and `getStorageBackend()` helper functions.

#### Install Composer and the AWS SDK for PHP

S3 storage requires **Composer** and the **AWS SDK for PHP**. The Composer
package is named `aws/aws-sdk-php` (not `amazon-sdk-php`). The installer does
not install these dependencies automatically.

1. Install Composer using the official [Composer download instructions](https://getcomposer.org/download/).
   Follow the installer checksum verification steps on that page. To make
   Composer available system-wide after verification and installation:

   ```bash
   sudo install -m 0755 composer.phar /usr/local/bin/composer
   composer --version
   ```

2. After extracting/deploying ATLAS, open the application's Composer project
   directory—the directory containing its `composer.json`, not this installer
   repository. Run Composer as the application/deployment owner (`atlasadmin`),
   not as root.

   If ATLAS already declares `aws/aws-sdk-php` in `composer.json`, install the
   project's dependencies using its existing lock file:

   ```bash
   composer install --no-dev --prefer-dist --optimize-autoloader
   ```

   Otherwise, add the SDK to the application project:

   ```bash
   composer require aws/aws-sdk-php
   ```

   Keep the resulting `composer.json` and `composer.lock` with your application
   deployment so subsequent installations use the same dependency versions.
   Composer needs network access to download dependencies. Resolve any PHP
   version or extension requirements it reports; do not bypass platform checks.

3. Confirm that Composer's autoloader can load the S3 client from that directory:

   ```bash
   php -r 'require "vendor/autoload.php"; exit(class_exists("Aws\\S3\\S3Client") ? 0 : 1);'
   ```

   ATLAS must load this `vendor/autoload.php` before using its S3 adapter.
   Ensure the web-server user can read the installed dependencies. This check
   verifies SDK availability only, not AWS credentials or bucket access.

**Prerequisites and security:**

- The deployed ATLAS package must include its S3 storage adapter and AWS SDK.
- On EC2, attach an IAM instance role with least-privilege access to the selected
  bucket/prefix. Elsewhere, configure credentials through the application's AWS
  SDK credential chain. The installer does not write AWS access keys to PHP.
- IAM and bucket policies must permit the operations the application needs,
  including object reads/writes/deletes and any required bucket listing. If
  using SSE-KMS, grant the required KMS permissions too.
- S3 sends application data to AWS and may incur storage, request, and transfer
  charges. Review region, retention, privacy, and access requirements.

The installer does not create the bucket, configure IAM, test S3 connectivity,
or migrate existing local files. Changing the backend only changes generated
configuration; plan any data migration separately and verify uploads, downloads,
and deletion before production use.

## File Structure

```
atlas/
├── install.sh
├── LICENSE
├── README.md
├── modules/
│   ├── additional_software.sh
│   ├── basic_software.sh
│   ├── config_setup.sh
│   ├── database_import.sh
│   ├── directory_setup.sh
│   ├── package_components.sh
│   ├── package_download.sh
│   ├── package_extract.sh
│   ├── package_install.sh
│   ├── package_permissions.sh
│   ├── platform.sh
│   └── user_management.sh
├── platforms/
│   ├── ubuntu.sh
│   └── amazon_linux_2023.sh
└── packages/
    ├── atlas-1.5.2.tar.gz
    └── atlas-1.5.2-db.sql.gz
```
