# macos-bootstrap

A comprehensive script to bootstrap a fresh macOS installation with essential development tools, applications, and custom settings.

## Features

- **Fresh macOS Compatible**: Works without pre-installed tools
- **Modular Design**: Focused, maintainable scripts
- **Full Setup**: macOS updates, Xcode tools, Homebrew, applications, SSH, Dock, and system preferences
- **Safe Preview**: Dry run mode and comprehensive logging
- **Configurable**: Customizable via configuration file

## Project Structure

```
├── install.sh                   # One-liner installer
├── config.sh                    # Configuration
├── Brewfile                     # Applications
├── files/ssh/config            # SSH template
└── scripts/
    ├── main.sh                 # Orchestrator
    ├── common.sh               # Shared utilities
    ├── core/                   # System setup
    ├── apps/setup-apps.sh      # Applications & Dock
    └── config/                 # Configuration
```

## What Gets Installed

See `Brewfile` for the complete list. Includes:

- **Development**: Git, Volta, Cursor, Ghostty
- **Security**: 1Password
- **Productivity**: Slack, Chrome, Zen browser, Home Assistant
- **Mac App Store**: Numbers, Pages, GCal

## Usage

### Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/robocopklaus/macos-bootstrap/main/install.sh | bash
```

### Local Usage

```bash
./scripts/main.sh                    # Full setup
./scripts/main.sh --dry-run          # Preview
./scripts/main.sh --verbose          # Detailed output
```



## Configuration

Edit `config.sh` to customize what gets installed. Use `--config custom-config.sh` for custom configurations.

### Adding Applications

Edit `Brewfile` to add/remove applications:

```bash
# CLI tool
brew "tool-name"

# GUI application
cask "app-name"

# Mac App Store
mas "App Name", id: 123456789
```


## Logging

Logs are saved to `/tmp/macos-bootstrap-YYYYMMDD-HHMMSS.log`. Use `--dry-run` to preview changes.


## Troubleshooting

- Check the log file for detailed errors
- Use `--verbose` for more output
- Use `--dry-run` to preview changes
- Ensure administrator privileges
