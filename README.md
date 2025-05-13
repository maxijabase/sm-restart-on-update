# Restart On Update

A SourceMod plugin for Source servers that creates a visible countdown and prevents player joins when Steam requests a server restart.

## Description

This plugin hooks into the SteamPawn API to detect when the Steam master servers report that your server is outdated. When this happens, the plugin will:

- Display a 60-second countdown on all players' HUD (customizable time)
- Prevent new players from joining during the countdown
- Execute the `_restart` command when the countdown ends

> [!WARNING]
> You're responsible for making sure your server gets updated when `_restart` is executed, this plugin only provides automation for that.

## Requirements

- SourceMod 1.11 or higher
- [nosoop's SteamPawn extension](https://github.com/nosoop/SM-SteamPawn/) (replaces the older SteamTools)

## Installation

1. Install nosoop's SteamPawn extension
2. Upload the plugin to your `addons/sourcemod/plugins` directory
3. Upload the translations file to your `addons/sourcemod/translations/restartonupdate.phrases.txt`
4. Restart your server or load the plugin with `sm plugins load restartonupdate`
5. Edit the configuration in `cfg/sourcemod/restartonupdate.cfg` as needed

## Configuration

The following ConVars can be modified in the `cfg/sourcemod/restartonupdate.cfg` file:

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_restart_time` | `60` | Time in seconds before server restarts after receiving restart request (min: 10, max: 300) |

## Commands

| Command | Flag | Description |
|---------|------|-------------|
| `sm_testrestart` | Root (ADMFLAG_ROOT) | Simulates receiving a restart request from Steam |
| `sm_cancelrestart` | Root (ADMFLAG_ROOT) | Cancels an ongoing restart countdown |

## Translation Support

The plugin supports multiple languages through SourceMod's translation system. All messages are displayed to players in their preferred language (if available). Currently supported languages:

- English
- Spanish
- Portuguese

To add more languages or modify messages, edit the `addons/sourcemod/translations/restartonupdate.phrases.txt` file.

## About SteamPawn

This plugin relies on [nosoop's SteamPawn extension](https://github.com/nosoop/SM-SteamPawn), which is a modern replacement for the older SteamTools extension. SteamPawn provides an API to interact with Steam-related functionality, including detecting when Steam requests a server restart.

SteamPawn provides the `SteamPawn_OnRestartRequested()` forward which is called when the Steam master servers report that your server is outdated and needs to be restarted.

## Credits

- Original plugin by [ampere](https://github.com/maxijabase)
- SteamPawn extension by [nosoop](https://github.com/nosoop)