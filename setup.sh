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
mkdir -p config/package-lists
mkdir -p config/hooks/normal
mkdir -p config/hooks/live
mkdir -p config/apt

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


# Create user configuration hook
cat > config/hooks/normal/0005-user-setup.hook.chroot << 'EOF'
#!/bin/sh
set -e

# Create a user with a known password
useradd -m -s /bin/bash intego
echo "intego:integotec123" | chpasswd

# Add to sudo group
usermod -aG sudo intego
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

# Create Zoom installation hook
echo "Creating Zoom hook..."
cat > config/hooks/normal/0020-install-zoom.hook.chroot << 'EOF'
#!/bin/sh
set -e

# Create temp directory
TEMPDIR=$(mktemp -d)
cd $TEMPDIR

# Download Zoom
echo "Downloading Zoom..."
wget https://zoom.us/client/latest/zoom_amd64.deb

# Install dependencies (including libxcb-cursor0 which was missing)
apt-get update
apt-get install -y libglib2.0-0 libxcb-shape0 libxcb-shm0 libxcb-xfixes0 \
    libxcb-randr0 libxcb-image0 libfontconfig1 libgl1-mesa-glx libxi6 libsm6 \
    libxrender1 libpulse0 libxcomposite1 libxslt1.1 libsqlite3-0 \
    libxcb-keysyms1 libxcb-xtest0 libxcb-cursor0 ibus

# Install Zoom
echo "Installing Zoom..."
dpkg -i zoom_amd64.deb || apt-get install -f -y

# Cleanup
cd /
rm -rf $TEMPDIR
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
    --debian-installer live \
    --debian-installer-gui false \
    --apt-indices false \
    --apt-recommends false \
    --apt-source-archives true \
    --memtest none \
    --iso-application "IntegOS" \
    --iso-publisher "Integotec" \
    --iso-volume "IntegOS 1.0"

echo "Setup complete. Run './build.sh' to create the ISO."
