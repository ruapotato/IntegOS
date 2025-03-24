#!/bin/bash
set -e

# Clean previous build environment
echo "Cleaning previous build environment..."
sudo lb clean --purge
rm -rf config/

# Make sure we create a completely fresh config directory
echo "Running lb config to initialize with basic settings..."
lb config \
    --clean \
    --distribution bookworm \
    --architectures amd64 \
    --archive-areas "main contrib non-free non-free-firmware"

# Create necessary directories
echo "Creating directories..."
mkdir -p config/includes.chroot/etc/skel
mkdir -p config/includes.chroot/usr/local/bin
mkdir -p config/includes.chroot/etc/skel/.config/autostart
mkdir -p config/includes.binary/install  # For installer files
mkdir -p config/includes.chroot/etc/calamares
mkdir -p config/package-lists
mkdir -p config/hooks/normal
mkdir -p config/hooks/live
mkdir -p config/apt
mkdir -p config/includes.chroot/etc/skel/Desktop
mkdir -p config/includes.chroot/usr/share/applications

# Create apt preferences to prevent GNOME packages
echo "Creating apt preferences..."
mkdir -p config/apt/preferences.d
cat > config/apt/preferences.d/no-gnome << 'EOF'
Package: gnome-shell
Pin: release *
Pin-Priority: -1

Package: gdm3
Pin: release *
Pin-Priority: -1
EOF

# Create live.list.chroot
echo "Creating live packages list..."
cat > config/package-lists/live.list.chroot << 'EOF'
live-boot
live-config
live-config-systemd
systemd-sysv
EOF

# Create desktop installer package list
echo "Creating desktop installer package list..."
cat > config/package-lists/installer.list.chroot << 'EOF'
calamares
calamares-settings-debian
squashfs-tools
qml-module-qtquick2
qml-module-qtquick-controls
qml-module-qtquick-controls2
qml-module-qtquick-layouts
qml-module-qtquick-window2
EOF

# Create main package list
echo "Creating main package list..."
cat > config/package-lists/my.list.chroot << 'EOF'
# Desktop Environment - Cinnamon specific packages
cinnamon
cinnamon-core
cinnamon-desktop-data
cinnamon-common
cinnamon-control-center
cinnamon-session
cinnamon-settings-daemon
lightdm
lightdm-gtk-greeter

# System Base
linux-image-amd64
# Updated firmware package names for Debian 12
firmware-linux-free
firmware-misc-nonfree
firmware-realtek
firmware-iwlwifi
firmware-atheros
firmware-ath9k-htc
sudo
curl
wget
network-manager
network-manager-gnome
squashfs-tools

# Browser and Common Apps
firefox-esr
evince
vlc

# Zoom Dependencies
libglib2.0-0
libxcb-shape0
libxcb-shm0
libxcb-xfixes0
libxcb-randr0
libxcb-image0
libfontconfig1
libgl1-mesa-glx
libxi6
libsm6
libxrender1
libpulse0
libxcomposite1
libxslt1.1
libsqlite3-0
libxcb-keysyms1
libxcb-xtest0
libxcb-cursor0
ibus

# Development and Utilities
git
vim
build-essential
gdebi
apt-transport-https
ca-certificates
software-properties-common
EOF

# Create sources.list to ensure proper repository setup
echo "Creating sources.list..."
mkdir -p config/includes.chroot/etc/apt
cat > config/includes.chroot/etc/apt/sources.list << 'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

# Create installer desktop icon
echo "Creating installer desktop icon..."
cat > config/includes.chroot/etc/skel/Desktop/integos-installer.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Install IntegOS
Comment=Install the operating system to disk
Exec=sudo calamares
Icon=calamares
Terminal=false
Categories=Qt;System;
StartupNotify=true
EOF
chmod +x config/includes.chroot/etc/skel/Desktop/integos-installer.desktop

# Create global application shortcut
cat > config/includes.chroot/usr/share/applications/integos-installer.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Install IntegOS
Comment=Install the operating system to disk
Exec=sudo calamares
Icon=calamares
Terminal=false
Categories=Qt;System;
StartupNotify=true
EOF

# Create Calamares branding for IntegOS
echo "Creating Calamares branding..."
mkdir -p config/includes.chroot/etc/calamares/branding/integos
cat > config/includes.chroot/etc/calamares/branding/integos/branding.desc << 'EOF'
---
componentName:  integos
welcomeStyleCalamares: true
welcomeExpandingLogo: true

strings:
    productName:         IntegOS
    shortProductName:    IntegOS
    version:             1.0
    shortVersion:        1.0
    versionedName:       IntegOS 1.0
    shortVersionedName:  IntegOS 1.0
    bootloaderEntryName: IntegOS
    productUrl:          https://integotec.com
    supportUrl:          https://integotec.com/support

images:
    productLogo:         "integos-logo.png"
    productIcon:         "integos-logo.png"
    productWelcome:      "welcome.png"

slideshow:               "show.qml"

style:
   sidebarBackground:    "#2c3133"
   sidebarText:          "#FFFFFF"
   sidebarTextSelect:    "#4d7079"
EOF

# Create user setup hook with updated username and password
echo "Creating user setup hook..."
cat > config/hooks/normal/0005-user-setup.hook.chroot << 'EOF'
#!/bin/sh
set -e

# Ensure squashfs-tools is installed
apt-get update
apt-get install -y squashfs-tools

# Create a user with a known password for the live session
useradd -m -s /bin/bash intego
echo "intego:integotec123" | chpasswd

# Add to sudo group
usermod -aG sudo intego

# Create home directories for user
mkdir -p /home/intego/.config/autostart
chmod -R 755 /home/intego/.config
chown -R intego:intego /home/intego/.config

# Allow calamares and sudo without password for the live user
echo "intego ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/intego-nopasswd
chmod 440 /etc/sudoers.d/intego-nopasswd

# Set default username and hostname in Calamares
mkdir -p /etc/calamares/modules
cat > /etc/calamares/modules/users.conf << EEOF
---
defaultGroups:
    - adm
    - cdrom
    - dip
    - lpadmin
    - plugdev
    - sudo
    - audio
    - video
    - netdev
autologinGroup: autologin
doAutologin: false
sudoersGroup: sudo
setRootPassword: true
doReusePassword: true
availableShells:
    - /bin/bash
    - /bin/zsh
    - /usr/bin/zsh
    - /usr/bin/fish
avatarFilePath: /usr/share/pixmaps/faces
defaultUserName: intego
userShell: /bin/bash
EEOF

cat > /etc/calamares/modules/locale.conf << EEOF
---
region: "America"
zone: "New_York"
EEOF

cat > /etc/calamares/modules/welcome.conf << EEOF
---
showSupportUrl:         true
showKnownIssuesUrl:     true
showReleaseNotesUrl:    true
showDonateUrl:          false

requirements:
    requiredStorage:    8
    requiredRam:        1.0
    internetCheckUrl:   https://debian.org

    check:
        - storage
        - ram
        - power
        - internet
        - root
    required:
        - storage
        - ram
        - root
EEOF

# Create a custom Calamares settings file to ensure proper installation
cat > /etc/calamares/settings.conf << EEOF
---
modules-search: [ /usr/lib/calamares/modules ]

sequence:
  - show:
      - welcome
      - locale
      - keyboard
      - partition
      - users
      - summary
  - exec:
      - partition
      - mount
      - unpackfs
      - machineid
      - fstab
      - locale
      - keyboard
      - localecfg
      - luksbootkeyfile
      - users
      - networkcfg
      - hwclock
      - services-systemd
      - packages
      - grubcfg
      - bootloader-config
      - bootloader
      - umount

branding: integos
prompt-install: true
dont-chroot: false
EEOF

# Make sure we have a modules directory for Calamares
mkdir -p /etc/calamares/modules
EOF
chmod +x config/hooks/normal/0005-user-setup.hook.chroot

# Create Cinnamon configuration hook
echo "Creating Cinnamon hook..."
cat > config/hooks/normal/0010-desktop-config.hook.chroot << 'EOF'
#!/bin/sh
set -e

# Remove any GNOME components that might interfere
apt-get remove -y --purge gnome-shell gnome-session gdm3 || true
apt-get autoremove -y

# Configure LightDM
mkdir -p /etc/lightdm/lightdm.conf.d/
cat > /etc/lightdm/lightdm.conf.d/50-cinnamon.conf << EEOF
[Seat:*]
user-session=cinnamon
greeter-session=lightdm-gtk-greeter
EEOF

# Set LightDM as default display manager
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager

# Configure Cinnamon
mkdir -p /etc/skel/.config/cinnamon
mkdir -p /etc/skel/.config/autostart

# Remove any session files that might conflict
rm -f /usr/share/xsessions/gnome*.desktop || true

# Make sure Cinnamon session file exists and is properly configured
cat > /usr/share/xsessions/cinnamon.desktop << EEOF
[Desktop Entry]
Name=Cinnamon
Comment=This session logs you into Cinnamon
Exec=/usr/bin/cinnamon-session
TryExec=/usr/bin/cinnamon-session
Type=Application
DesktopNames=X-Cinnamon
X-Ubuntu-Gettext-Domain=cinnamon-session
EEOF

# Make Cinnamon the default session manager
if [ -f /usr/bin/cinnamon-session ]; then
    update-alternatives --install /usr/bin/x-session-manager \
        x-session-manager /usr/bin/cinnamon-session 90
    update-alternatives --set x-session-manager /usr/bin/cinnamon-session || true
fi
EOF

# Create Zoom installation hook with improved approach
echo "Creating Zoom hook..."
cat > config/hooks/normal/0020-install-zoom.hook.chroot << 'EOF'
#!/bin/sh
set -e

# Create temp directory
TEMPDIR=$(mktemp -d)
cd $TEMPDIR

# Download Zoom
echo "Downloading Zoom..."
wget https://zoom.us/client/latest/zoom_amd64.deb -O zoom_amd64.deb

# Install dependencies (including libxcb-cursor0 which was missing)
apt-get update
apt-get install -y libglib2.0-0 libxcb-shape0 libxcb-shm0 libxcb-xfixes0 \
    libxcb-randr0 libxcb-image0 libfontconfig1 libgl1-mesa-glx libxi6 libsm6 \
    libxrender1 libpulse0 libxcomposite1 libxslt1.1 libsqlite3-0 \
    libxcb-keysyms1 libxcb-xtest0 libxcb-cursor0 ibus

# Install Zoom
echo "Installing Zoom..."
dpkg -i zoom_amd64.deb || apt-get install -f -y

# Copy the .deb to /usr/local/src for installation
mkdir -p /usr/local/src
cp zoom_amd64.deb /usr/local/src/

# Create install script for the installed system
cat > /usr/local/bin/install-zoom << EEOF
#!/bin/bash
# Check if Zoom is already installed
if [ ! -f /usr/bin/zoom ]; then
    # Install Zoom
    dpkg -i /usr/local/src/zoom_amd64.deb || apt-get install -f -y
fi
exit 0
EEOF
chmod +x /usr/local/bin/install-zoom

# Add script to customize the installed system
mkdir -p /etc/calamares/scripts
cat > /etc/calamares/scripts/packages.conf << EEOF
---
script:
  - command: "apt-get update"
  - command: "apt-get install -y squashfs-tools libxcb-cursor0"
  - command: "dpkg -i /usr/local/src/zoom_amd64.deb || apt-get install -f -y"
EEOF

# Add unpackfs module config for Calamares
cat > /etc/calamares/modules/unpackfs.conf << EEOF
---
unpack:
    -   source: "/run/live/medium/live/filesystem.squashfs"
        sourcefs: "squashfs"
        destination: ""
EEOF

# Create autostart entry for all users
cat > /etc/skel/.config/autostart/check-zoom.desktop << EEOF
[Desktop Entry]
Type=Application
Name=Check Zoom Installation
Exec=/usr/local/bin/install-zoom
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EEOF

# Also add it for the intego user
if [ -d /home/intego/.config/autostart ]; then
    cp /etc/skel/.config/autostart/check-zoom.desktop /home/intego/.config/autostart/
    chown intego:intego /home/intego/.config/autostart/check-zoom.desktop
fi

# Cleanup
cd /
rm -rf $TEMPDIR
EOF

# Create a hook to install Zoom in the final installation
cat > config/includes.chroot/usr/share/initramfs-tools/hooks/zoom-installer << 'EOF'
#!/bin/sh
# This file should be executed during install to install Zoom in the target system
set -e
PREREQ=""
prereqs()
{
   echo "$PREREQ"
}

case $1 in
# Get pre-requisites
prereqs)
   prereqs
   exit 0
   ;;
esac

. /usr/share/initramfs-tools/hook-functions

# Copy Zoom installation files
copy_file script /usr/local/src/zoom_amd64.deb
EOF
chmod +x config/includes.chroot/usr/share/initramfs-tools/hooks/zoom-installer

# Make a post-installation script to run in the target system
cat > config/includes.chroot/usr/sbin/integos-firstboot << 'EOF'
#!/bin/bash
# This script runs on first boot to finalize installation
set -e

# Check if Zoom is already installed
if [ ! -f /usr/bin/zoom ]; then
    # Install Zoom dependencies
    apt-get update
    apt-get install -y libxcb-cursor0
    
    # Install Zoom if the package exists
    if [ -f /usr/local/src/zoom_amd64.deb ]; then
        dpkg -i /usr/local/src/zoom_amd64.deb || apt-get install -f -y
    fi
fi
EOF
chmod +x config/includes.chroot/usr/sbin/integos-firstboot

# Create a systemd service to run the firstboot script
mkdir -p config/includes.chroot/etc/systemd/system/
cat > config/includes.chroot/etc/systemd/system/integos-firstboot.service << 'EOF'
[Unit]
Description=IntegOS First Boot Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/integos-firstboot
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Make hooks executable
chmod +x config/hooks/normal/0010-desktop-config.hook.chroot
chmod +x config/hooks/normal/0020-install-zoom.hook.chroot

# Full lb config with all necessary parameters
echo "Configuring live-build..."
lb config \
    --distribution bookworm \
    --architectures amd64 \
    --binary-images iso-hybrid \
    --archive-areas "main contrib non-free non-free-firmware" \
    --debian-installer none \
    --apt-indices false \
    --apt-recommends false \
    --apt-source-archives true \
    --memtest none \
    --iso-application "IntegOS" \
    --iso-publisher "Integotec" \
    --iso-volume "IntegOS 1.0"

echo "Setup complete. Run './build.sh' to create the ISO."
