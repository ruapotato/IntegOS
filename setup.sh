#!/bin/bash
set -e

# Clean previous build environment
echo "Cleaning previous build environment..."
sudo lb clean --purge
rm -rf config/

# Create necessary directories
echo "Creating directories..."
mkdir -p config/includes.chroot/etc/skel
mkdir -p config/package-lists
mkdir -p config/hooks/normal
mkdir -p config/hooks/live

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
# Desktop Environment
cinnamon-desktop-environment
lightdm
lightdm-gtk-greeter

# System Base
linux-image-amd64
firmware-linux
sudo
curl
wget
network-manager
network-manager-gnome

# Browser and Common Apps
firefox-esr
evince
vlc

# Development and Utilities
git
vim
build-essential
gdebi
apt-transport-https
ca-certificates
software-properties-common
EOF

# Create Cinnamon configuration hook
echo "Creating Cinnamon hook..."
cat > config/hooks/normal/0010-desktop-config.hook.chroot << 'EOF'
#!/bin/sh
set -e

# Configure LightDM
mkdir -p /etc/lightdm/lightdm.conf.d/
cat > /etc/lightdm/lightdm.conf.d/50-cinnamon.conf << EEOF
[Seat:*]
user-session=cinnamon
greeter-session=lightdm-gtk-greeter
EEOF

# Set LightDM as default display manager
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager

# Remove conflicting display managers
apt-get remove -y gdm3 || true

# Enable services
systemctl enable lightdm.service
systemctl disable gdm.service || true

# Configure Cinnamon
mkdir -p /etc/skel/.config/cinnamon
mkdir -p /etc/skel/.config/autostart

# Set Cinnamon as default session
if [ -f /usr/bin/cinnamon-session ]; then
    update-alternatives --install /usr/bin/x-session-manager \
        x-session-manager /usr/bin/cinnamon-session 90
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
wget https://zoom.us/client/6.4.1.587/zoom_amd64.deb

# Install dependencies
apt-get update
apt-get install -y libglib2.0-0 libxcb-shape0 libxcb-shm0 libxcb-xfixes0 \
    libxcb-randr0 libxcb-image0 libfontconfig1 libgl1-mesa-glx libxi6 libsm6 \
    libxrender1 libpulse0 libxcomposite1 libxslt1.1 libsqlite3-0 \
    libxcb-keysyms1 libxcb-xtest0 ibus

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

# Initialize the live-build configuration
echo "Initializing live-build configuration..."
lb config \
    --distribution bookworm \
    --architectures amd64 \
    --binary-images iso-hybrid \
    --archive-areas "main contrib non-free non-free-firmware" \
    --debian-installer live \
    --debian-installer-gui false \
    --apt-indices false \
    --apt-recommends true \
    --memtest none \
    --iso-application "IntegOS" \
    --iso-publisher "Integotec" \
    --iso-volume "IntegOS 1.0"

echo "Setup complete. Run './build.sh' to create the ISO."
