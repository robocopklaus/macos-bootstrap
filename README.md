# macos-bootstrap

My personal macOS setup scripts for bootstrapping a fresh installation with my preferred development tools, applications, and system configuration.

> **Note**: This is my personal configuration. Feel free to fork and customize for your own use.

## Features

- **Fresh macOS Compatible**: Works without pre-installed tools
- **Modular Design**: Focused, maintainable scripts
- **Full Setup**: macOS updates, Xcode tools, Homebrew, applications, dotfiles, Dock, and system preferences
- **Safe Preview**: Dry run mode and comprehensive logging
- **Configurable**: Customizable via configuration file
- **Resilient App Installs**: Base tooling is installed first; optional GUI and MAS apps are separate phases

## Project Structure

```
├── install.sh                  # One-liner installer
├── config.sh                   # Configuration
├── Brewfile                    # Applications
├── dotfiles/                   # Dotfiles (GNU Stow package)
└── scripts/
    ├── main.sh                 # Orchestrator
    ├── common.sh               # Shared utilities
    ├── core/                   # System setup
    ├── apps/setup-apps.sh               # Applications & Dock
    └── config/
        ├── setup-dotfiles.sh            # Dotfiles (GNU Stow)
        └── configure-macos-defaults.sh  # macOS preferences
```

## What Gets Installed

See `Brewfile` for the complete list. Includes:

- **Development tools**: Git, Volta, Antidote, Stow, GH CLI, Opencode, Oh My Posh, Postman
- **Security & privacy**: 1Password, 1Password CLI
- **Productivity**: Cursor, ChatGPT, Clockify, Mimestream, Ghostty, Docker, Google Drive, Raycast, Obsidian
- **Communication**: Slack, WhatsApp
- **Browsers & web**: Safari (system), Google Chrome, Zen, Finicky
- **Smart home**: Home Assistant
- **Media**: IINA
- **Mac App Store (optional by default)**: Numbers, Pages, Super Agent, 1Password for Safari, GCal for Google Calendar

## Application Install Phases

`scripts/apps/setup-apps.sh` installs applications in three phases for reliability:

1. **Base dependencies (blocking)**: Homebrew formulae/taps from `Brewfile`
2. **Cask apps (non-blocking)**: Installed one-by-one; failures are logged and bootstrap continues
3. **Mac App Store apps (optional, non-blocking)**: Disabled by default unless `INSTALL_MAS_APPS=true`

This keeps unattended bootstrap stable even if optional app installs fail.

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

Common toggles:

- `INSTALL_APPLICATIONS=true|false` - enable/disable all app setup
- `INSTALL_CASK_APPS=true|false` - enable/disable Homebrew cask phase
- `INSTALL_MAS_APPS=true|false` - enable/disable Mac App Store installs (default: `false`)
- `CUSTOMIZE_DOCK=true|false` - enable/disable Dock customization

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
