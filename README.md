# IntegOS

IntegOS is a custom Debian 12-based distribution with Cinnamon Desktop Environment, Office 365 integration, and preinstalled software for Integotec.

## Features

- Based on Debian 12 (Bookworm)
- Cinnamon Desktop Environment
- Office 365 account integration
- Preinstalled software including Zoom
- Custom branding and theming
- Easy installation with predefined user accounts

## Building IntegOS

### Prerequisites

- Debian 12 (or Ubuntu 22.04+) system
- Root or sudo access
- At least 20GB of free disk space
- Internet connection

### Build Instructions

1. Clone this repository and enter the directory:
   ```bash
   git clone https://github.com/ruapotato/IntegOS.git
   cd IntegOS
   ```

2. Run the setup script to initialize the build environment:
   ```bash
   sudo ./setup.sh
   ```

3. Build the ISO:
   ```bash
   sudo ./build.sh
   ```

4. After completion, you'll find `IntegOS-1.0.iso` in the current directory

## Customization

### Office 365 Integration

To configure Office 365 integration:

1. Register an app in your Azure Active Directory
2. Get your tenant ID and client ID
3. Update `config/includes.chroot/etc/aad/aad.conf` with your values

### Adding Custom Packages

Modify the package lists in `config/package-lists/` to add or remove software.

### Custom Branding

Custom branding files are located in:
- Wallpapers: `config/includes.chroot/usr/share/backgrounds/integos/`
- Branding hooks: `config/hooks/normal/`

## License

See the [LICENSE](LICENSE) file for details.
