#!/bin/bash
set -e

# Completely clean previous build
echo "Cleaning previous build environment..."
sudo rm -rf .build/
sudo rm -rf cache/
sudo rm -rf config/
sudo lb clean --purge

# Create necessary directories
mkdir -p config/package-lists
mkdir -p config/includes.chroot/etc/skel
mkdir -p config/hooks/normal
mkdir -p .build

# Create the configuration
echo "Initializing live-build configuration..."
lb config noauto \
    --mode debian \
    --system live \
    --architectures amd64 \
    --binary-images iso-hybrid \
    --distribution bookworm \
    --archive-areas "main contrib non-free non-free-firmware" \
    --updates true \
    --security true \
    --cache-packages true \
    --apt-recommends true \
    --debian-installer live \
    --debian-installer-gui false \
    --linux-packages "linux-image" \
    --iso-application "IntegOS" \
    --iso-publisher "Integotec" \
    --iso-volume "IntegOS 1.0"

# Generate .build/config
lb config

# Create basic package list
cat > config/package-lists/my.list.chroot << EOF
task-desktop
cinnamon
firefox-esr
EOF

# Make hook executable
touch config/hooks/normal/0010-custom.hook.chroot
chmod +x config/hooks/normal/0010-custom.hook.chroot

echo "Setup complete. Configuration saved."
