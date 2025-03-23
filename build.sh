#!/bin/bash
set -e

echo "Making hook scripts executable..."
if [ -d "config/hooks" ]; then
    find config/hooks -type f -name "*.hook.chroot" -exec chmod +x {} \;
fi

echo "Building IntegOS..."

# Remove any previous build artifacts
sudo rm -f live-image-amd64.hybrid.iso
sudo rm -f IntegOS-1.0.iso

# Run lb build with full debug output
sudo lb build --debug --verbose 2>&1 | tee build.log

# Check if build was successful
if [ -f "live-image-amd64.hybrid.iso" ]; then
    echo "Build successful!"
    echo "Renaming ISO to IntegOS-1.0.iso..."
    sudo mv live-image-amd64.hybrid.iso IntegOS-1.0.iso
    echo "Your IntegOS ISO is ready: $(pwd)/IntegOS-1.0.iso"
else
    echo "Build failed. Check build.log for errors."
    exit 1
fi
