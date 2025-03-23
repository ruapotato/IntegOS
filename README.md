# IntegOS

IntegOS is a custom Debian 12-based distribution with Cinnamon Desktop Environment, Office 365 integration, and preinstalled software for Integotec.

## Features

- Based on Debian 12 (Bookworm)
- Cinnamon Desktop Environment as default
- Zoom client pre-installed
- Office 365 account integration
- Customized for Integotec workflow
- Easy installation process

## Building IntegOS

### Prerequisites

- Debian 12 (or Ubuntu 22.04+) system
- Root/sudo access
- At least 20GB of free disk space
- Internet connection
- Required packages:
  ```bash
  sudo apt install live-build cdebootstrap debian-archive-keyring
  ```

### Build Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/ruapotato/IntegOS.git
   cd IntegOS
   ```

2. Run the setup script to initialize the build environment:
   ```bash
   sudo ./setup.sh
   ```
   This script:
   - Cleans any previous build
   - Creates necessary configuration structure
   - Sets up package lists and hooks
   - Configures live-build settings

3. Build the ISO:
   ```bash
   sudo ./build.sh
   ```

4. After successful completion, you'll find `IntegOS-1.0.iso` in the current directory

## Project Structure

```
IntegOS/
├── setup.sh      # Main configuration script
├── build.sh      # Build script
└── README.md     # Documentation
```

The setup script automatically creates and configures:
- Package lists for the live system
- Desktop environment configuration
- Zoom installation
- System customizations

## Customization

### Modifying the Build

To customize the build, modify `setup.sh`. It contains all configurations in a single file:
- Package selections
- Desktop environment settings
- Custom software installation
- System configurations

### Office 365 Integration

To configure Office 365 integration:
1. Register an app in your Azure Active Directory
2. Get your tenant ID and client ID
3. Update the relevant sections in setup.sh

## Development Notes

- The build process creates a `config/` directory that is ignored by git
- All configurations are managed through setup.sh for consistency
- Build logs are available in the project directory after building

## License

See the [LICENSE](LICENSE) file for details.
