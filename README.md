# macos-bootstrap

A comprehensive script to bootstrap a fresh macOS installation with essential development tools, applications, and custom settings.

## Features

- **Modular Design**: Organized into focused, maintainable scripts
- **macOS Updates**: Safely checks for and installs available macOS updates
- **Xcode Command Line Tools**: Automatically installs Xcode CLI tools if not present
- **Homebrew**: Installs Homebrew package manager
- **Application Installation**: Installs applications via Brewfile
- **SSH Configuration**: Sets up SSH config with 1Password integration
- **Dock Customization**: Automatically configures Dock with organized application categories
- **Comprehensive Logging**: Detailed logging of all operations
- **Dry Run Mode**: Preview changes without making them
- **Error Handling**: Robust error handling and cleanup
- **Configuration File**: YAML-based configuration for customization

## Project Structure

```
├── config.sh                    # Configuration file
├── Brewfile                     # Homebrew applications
├── README.md                    # This file
├── files/                       # Configuration files
│   └── ssh/
│       └── config              # SSH configuration
└── scripts/
    ├── main.sh                 # Main orchestration script
    ├── common.sh               # Shared utilities and functions
    ├── core/                   # Core system setup
    │   ├── install-xcode-tools.sh
    │   ├── install-homebrew.sh
    │   └── update-macos.sh
    ├── apps/                   # Application installation
    │   ├── install-brewfile.sh
    │   └── setup-dock.sh
    └── config/                 # Configuration setup
        ├── setup-dotfiles.sh
        └── configure-ssh.sh
```

## What Gets Installed

The script installs the following tools and applications:

### Development Tools

- **Git**: Version control system
- **Volta**: JavaScript tool manager
- **Antidote**: Zsh plugin manager
- **Dockutil**: Dock customization utility

### Applications

#### Productivity & Security
- **1Password**: Password manager
- **1Password CLI**: Command-line password manager
- **Cursor**: AI-powered code editor
- **Slack**: Team communication
- **Google Chrome**: Web browser
- **Finicky**: URL redirector
- **Clockify**: Time tracking
- **Mimestream**: Email client
- **Zen**: Privacy-focused browser

#### Media & Entertainment
- **IINA**: Video player
- **Spotify**: Music streaming

#### Smart Home & Utilities
- **Home Assistant**: Smart home automation
- **Ghostty**: Terminal emulator

#### Mac App Store Applications
- **Numbers**: Spreadsheet application
- **Pages**: Word processor
- **Super Agent**: Browser automation
- **1Password for Safari**: Safari extension
- **GCal for Google Calendar**: Calendar integration

## Usage

### Quick Start

After a fresh macOS install:

1. Open Terminal
2. Run the following command:

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/robocopklaus/macos-bootstrap/main/scripts/main.sh)
   ```

### Local Development

If you have the repository cloned locally:

```bash
cd macos-bootstrap
./scripts/main.sh
```

### Running Individual Modules

You can run individual modules for specific tasks:

```bash
# Install only Xcode CLI tools
./scripts/core/install-xcode-tools.sh

# Install only Homebrew
./scripts/core/install-homebrew.sh

# Set up only the Dock
./scripts/apps/setup-dock.sh

# Configure only SSH
./scripts/config/configure-ssh.sh
```

### Options

- `--dry-run` or `-d`: Preview what the script will do without making changes
- `--verbose` or `-v`: Enable verbose output
- `--help` or `-h`: Show help information

Examples:

```bash
# Preview changes
./scripts/main.sh --dry-run

# Run with verbose output
./scripts/main.sh --verbose

# Show help
./scripts/main.sh --help
```

## Configuration

### Configuration File

The project uses `config.sh` for configuration. You can customize:

- Repository URL and branch
- Installation options (what to install)
- Dock customization settings
- SSH configuration
- Logging preferences

Example configuration:

```bash
# Repository Configuration
REPOSITORY_URL="https://github.com/your-username/macos-bootstrap.git"
REPOSITORY_BRANCH="main"
MACOS_BOOTSTRAP_DIR="$HOME/.macos-bootstrap"

# Installation Options
INSTALL_MACOS_UPDATES=true
INSTALL_XCODE_TOOLS=true
INSTALL_HOMEBREW=true
INSTALL_APPLICATIONS=true
SETUP_DOTFILES=true
CONFIGURE_SSH=true
CUSTOMIZE_DOCK=true

# Dock Configuration
DOCK_ENABLED=true
DOCK_CATEGORIES="smart_home,music,browser,communication,productivity,development,system"

# SSH Configuration
SSH_USE_1PASSWORD_AGENT=true
SSH_AGENT_SOCKET="~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

### Using Custom Configuration

You can specify a custom configuration file when running the script:

```bash
# Use custom configuration
./scripts/main.sh --config my-custom-config.sh

# Run with custom config and dry-run
./scripts/main.sh --config my-custom-config.sh --dry-run
```

### Environment Variables

You can also override configuration using environment variables:

```bash
# Override repository URL
REPOSITORY_URL="https://github.com/your-fork/macos-bootstrap.git" ./scripts/main.sh

# Disable specific modules
INSTALL_MACOS_UPDATES=false CUSTOMIZE_DOCK=false ./scripts/main.sh
```

### Adding More Applications

Edit the `Brewfile` to add or remove applications:

```bash
# Add a new application
echo 'brew "application-name"' >> Brewfile

# Remove an application
# Delete or comment out the line in Brewfile
```

### Brewfile Syntax

The Brewfile supports various Homebrew installation types:

```bash
# Install a formula
brew "formula-name"

# Install a cask (GUI application)
cask "application-name"

# Install from a tap
tap "user/repo"
brew "formula-name"

# Install a specific version
brew "formula-name@version"

# Install from Mac App Store
mas "App Name", id: 123456789
```

### SSH Configuration

The script sets up SSH configuration with 1Password integration. Edit `files/ssh/config` to customize:

- SSH host configurations
- Key management
- 1Password SSH agent integration

### Dock Customization

The script automatically organizes your Dock into categories:

- **Smart Home**: Home Assistant
- **Music**: Music app, Spotify
- **Browser**: Safari, Chrome, Zen
- **Communication**: Mail, Mimestream, Slack, Messages
- **Productivity**: ChatGPT, GCal, Calendar
- **Development**: Cursor, Ghostty
- **System**: System Settings

## Requirements

- macOS (tested on macOS 10.15+)
- Internet connection
- Administrator privileges (for some installations)

## Logging

The script creates detailed logs at `/tmp/macos-bootstrap-YYYYMMDD-HHMMSS.log` for troubleshooting and verification.

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure you have administrator privileges
2. **Homebrew Installation Fails**: Check your internet connection and try again
3. **Xcode CLI Tools Issues**: Run `xcode-select --install` manually if needed
4. **Dock Customization Fails**: Ensure dockutil is installed via Homebrew
5. **Module Script Not Found**: Ensure all scripts are executable (`chmod +x scripts/**/*.sh`)

### Getting Help

- Check the log file for detailed error information
- Run with `--verbose` for more detailed output
- Use `--dry-run` to preview changes before making them
- Run individual modules to isolate issues

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).
