# Restart On Update

A SourceMod plugin for Team Fortress 2 servers that creates a visible countdown and prevents player joins when Steam requests a server restart.

## Description

This plugin hooks into the SteamPawn API to detect when the Steam master servers report that your server is outdated. When this happens, the plugin will:

- Display a 60-second countdown on all players' HUD
- Prevent new players from joining during the countdown
- Execute the `_restart` command when the countdown ends

## Requirements

- SourceMod 1.11 or higher
- [nosoop's SteamPawn extension](https://github.com/nosoop/SM-SteamPawn/) (replaces the older SteamTools)

## Installation

1. Install nosoop's SteamPawn extension
2. Upload the plugin to your `addons/sourcemod/plugins` directory
3. Restart your server or load the plugin with `sm plugins load restartonupdate`
4. Edit the configuration in `cfg/sourcemod/restartonupdate.cfg` as needed

## Configuration

The following ConVars can be modified in the `cfg/sourcemod/restartonupdate.cfg` file:

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_restart_time` | `60` | Time in seconds before server restarts after receiving restart request (min: 10, max: 300) |
| `sm_restart_hud_message` | `SERVER RESTART IN %d SECONDS` | HUD message format (use %d for countdown) |
| `sm_restart_start_message` | `[SERVER] Server will restart in %d seconds!` | Message shown when restart countdown begins (use %d for time) |
| `sm_restart_end_message` | `[SERVER] Server is restarting now!` | Message shown when server is about to restart |
| `sm_restart_in_progress` | `[SERVER] A restart is already in progress!` | Message shown when trying to start a restart while one is in progress |
| `sm_restart_reject_message` | `Server is restarting in %d seconds. Please try again later.` | Message shown to players who try to connect during restart (use %d for time) |
| `sm_restart_test_message` | `[SERVER] Admin %s has initiated a test restart sequence!` | Message shown when admin initiates test restart (use %s for admin name) |

## Commands

| Command | Flag | Description |
|---------|------|-------------|
| `sm_testrestart` | Root (ADMFLAG_ROOT) | Simulates receiving a restart request from Steam |

## About SteamPawn

This plugin relies on [nosoop's SteamPawn extension](https://github.com/nosoop/SMExt-SteamPawn), which is a modern replacement for the older SteamTools extension. SteamPawn provides an API to interact with Steam-related functionality, including detecting when Steam requests a server restart.

SteamPawn provides the `SteamPawn_OnRestartRequested()` forward which is called when the Steam master servers report that your server is outdated and needs to be restarted.

## Credits

- Original plugin by [ampere](https://github.com/maxijabase)
- SteamPawn extension by [nosoop](https://github.com/nosoop)