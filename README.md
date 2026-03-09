# RepoWatcher

A lightweight macOS menu bar application that monitors your Git repository status at a glance.

## Overview

RepoWatcher lives in your macOS menu bar and displays a colored indicator showing the current status of your Git repository. No need to open a terminal or Git client to check if you have uncommitted changes, unpushed commits, or remote updates.

## Features

- **Visual Status Indicator**: Color-coded circle in the menu bar
  - 🔴 **Red**: No upstream branch or uncommitted changes
  - 🟡 **Yellow**: Unpushed commits or unpulled remote changes
  - ⚪ **Normal**: Clean repository (in sync with remote)

- **Automatic Monitoring**: Checks repository status every 5 minutes
- **Manual Refresh**: Force check via menu bar menu
- **Lightweight**: Uses `git ls-remote` for efficient remote change detection
- **Unobtrusive**: No dock icon, menu bar only

## Requirements

- macOS
- Xcode (for building)
- Git installed on your system

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd RepoWatcher
   ```

2. Open in Xcode:
   ```bash
   open RepoWatcher.xcodeproj
   ```

3. Build and run the project (⌘R)

## Configuration

The application stores its configuration in `~/.config/repowatcher/config.json`:

```json
{
  "repositoryPath": "/path/to/your/repository"
}
```

The configuration is automatically created when you run the app. You can edit this file to change which repository is being monitored.

## Development

The project uses a clean MVC-like architecture:

- **Controllers**: Menu bar UI management
- **Services**: Git operations and configuration handling
- **Models**: Data structures for status and config

### Development Environment

A Nix flake is provided for a reproducible development environment:

```bash
nix develop
```

Or use direnv for automatic environment loading:

```bash
direnv allow
```

## Project Structure

```
RepoWatcher/
├── RepoWatcher/
│   ├── main.swift              # Application entry point
│   ├── AppDelegate.swift       # App lifecycle
│   ├── Controllers/            # UI controllers
│   ├── Services/               # Git and config services
│   └── Models/                 # Data models
├── docs/                       # Documentation
└── flake.nix                   # Nix development environment
```

## How It Works

1. On startup, the app performs an initial `git fetch` to sync with remote
2. Every 5 minutes, it runs lightweight `git ls-remote` checks to detect remote changes
3. Local status is checked using `git status --porcelain`
4. The menu bar icon color updates based on the combined status

## License

This project is provided as-is for personal use.
