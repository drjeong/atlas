# ATLAS - Assessment Tracking and Learning Analytics System

A comprehensive web-based system for managing course assessments, ABET documentation, and academic reporting.

<<<<<<< Updated upstream
The system uses the default user "atlasadmin" when installing packages. If the user doesn't exist, it will be created automatically. The user "atlasadmin" will be added to the www-data group. If you wish to use a different username, please revise the following shell files:

- `package_install.sh`
- `user_management.sh`
- `config_setup.sh`
- `directory_setup.sh`

# Installation
=======

# ATLAS Installation

## Installation Steps
>>>>>>> Stashed changes

1. **Download the installer:**
   Clones the ATLAS repository from GitHub and navigates to the installer directory.

   ```bash
   git clone https://github.com/drjeong/atlas.git
<<<<<<< Updated upstream
   cd atlas

2. **Make scripts executable:**
=======
   cd atlas/installer



2. **Change modes:**
>>>>>>> Stashed changes
   Grants execute permissions to all shell scripts in the current directory and the modules subfolder, allowing them to run as programs.

   chmod +x *.sh modules/*.sh

<<<<<<< Updated upstream
3. **Run installer:**
   Executes the main installation script to set up ATLAS on your system.

   sudo ./install.sh

4. **Select installation option**

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
   | Select an option [1-8]:


Recommended: Select option 7 to run the complete installation process automatically.
This option automatically runs all installation steps required to set up ATLAS.


Default systemadmin: admin@atlas.edu / atlas123##

=======
>>>>>>> Stashed changes
