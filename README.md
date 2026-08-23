## Installation

1. **Download the installer**

   Clones the ATLAS repository from GitHub and navigates to the installer directory.

```bash
   git clone https://github.com/drjeong/atlas.git
   cd atlas
```

2. **Make sure packages are in place**

   Two package files, `atlas-1.0.0.tar.gz` and `atlas-1.0.0-db.sql.gz`, should be placed under the `packages` folder.

3. **Make scripts executable**

   Grants execute permissions to all shell scripts in the current directory and the modules subfolder, allowing them to run as programs.

```bash
   chmod +x *.sh modules/*.sh
```

4. **Run installer**

   Executes the main installation script to set up ATLAS on your system.

```bash
   sudo ./install.sh
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

   **Recommended:** Select option `7` to run the complete installation process automatically. This option automatically runs all installation steps required to set up ATLAS.
   
Default ATLAS systemadmin: admin@atlas.edu / atlas123##


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
│   └── user_management.sh
└── packages/
    ├── atlas-1.0.0.tar.gz
    └── atlas-1.0.0-db.sql.gz
```
