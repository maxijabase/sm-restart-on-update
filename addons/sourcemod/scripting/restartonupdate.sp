#include <sourcemod>
#include <steampawn>
#include <tf2>
#include <tf2_stocks>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_Cvar_RestartTime;
ConVar g_Cvar_HudMessage;
ConVar g_Cvar_StartMessage;
ConVar g_Cvar_EndMessage;
ConVar g_Cvar_AlreadyInProgressMessage;
ConVar g_Cvar_RejectMessage;
ConVar g_Cvar_TestMessage;

Handle g_hHudSync;
Handle g_hRestartTimer;
bool g_bRestartInProgress = false;
int g_iCountdown = 0;

public Plugin myinfo = 
{
  name = "TF2 Restart On Update", 
  author = "ampere", 
  description = "Triggers a countdown before server restart when Steam master servers report the server is outdated", 
  version = PLUGIN_VERSION, 
  url = "github.com/maxijabase"
};

public void OnPluginStart()
{
  g_Cvar_RestartTime = CreateConVar("sm_restart_time", "60", "Time in seconds before server restarts after receiving restart request", _, true, 10.0, true, 300.0);
  
  g_Cvar_HudMessage = CreateConVar("sm_restart_hud_message", "SERVER RESTART IN %d SECONDS", "HUD message format (use %d for countdown)");
  g_Cvar_StartMessage = CreateConVar("sm_restart_start_message", "[SERVER] Server will restart in %d seconds!", "Message shown when restart countdown begins (use %d for time)");
  g_Cvar_EndMessage = CreateConVar("sm_restart_end_message", "[SERVER] Server is restarting now!", "Message shown when server is about to restart");
  g_Cvar_AlreadyInProgressMessage = CreateConVar("sm_restart_in_progress", "[SERVER] A restart is already in progress!", "Message shown when trying to start a restart while one is in progress");
  g_Cvar_RejectMessage = CreateConVar("sm_restart_reject_message", "Server is restarting in %d seconds. Please try again later.", "Message shown to players who try to connect during restart (use %d for time)");
  g_Cvar_TestMessage = CreateConVar("sm_restart_test_message", "[SERVER] Admin %s has initiated a test restart sequence!", "Message shown when admin initiates test restart (use %s for admin name)");
  
  g_hHudSync = CreateHudSynchronizer();
  
  RegAdminCmd("sm_testrestart", Command_TestRestart, ADMFLAG_ROOT, "Simulates receiving a restart request from Steam");
  
  AutoExecConfig(true, "tf2_restart_on_update");
}

public Action Command_TestRestart(int client, int args)
{
  if (g_bRestartInProgress)
  {
    char buffer[256];
    g_Cvar_AlreadyInProgressMessage.GetString(buffer, sizeof(buffer));
    ReplyToCommand(client, buffer);
    return Plugin_Handled;
  }
  
  char clientName[64] = "Console";
  if (client > 0 && IsClientInGame(client))
  {
    GetClientName(client, clientName, sizeof(clientName));
  }
  
  char buffer[256];
  g_Cvar_TestMessage.GetString(buffer, sizeof(buffer));
  PrintToChatAll("\x07FF4500%s", buffer, clientName);
  
  StartRestartSequence();
  
  return Plugin_Handled;
}

void StartRestartSequence()
{
  g_bRestartInProgress = true;
  g_iCountdown = g_Cvar_RestartTime.IntValue;
  
  PrintToServer("Starting %d second countdown to server restart.", g_iCountdown);
  
  char buffer[256];
  g_Cvar_StartMessage.GetString(buffer, sizeof(buffer));
  Format(buffer, sizeof(buffer), buffer, g_iCountdown);
  PrintToChatAll("\x07FF0000%s", buffer);
  
  g_hRestartTimer = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
  
  UpdateHudMessageForAllPlayers();
}

public void SteamPawn_OnRestartRequested()
{
  if (g_bRestartInProgress)
  {
    return;
  }
  
  LogMessage("Official restart request received from Steam.");
  PrintToChatAll("\x07FF0000[SERVER] Steam has requested a server restart!");
  
  StartRestartSequence();
}

void UpdateHudMessageForAllPlayers()
{
  char buffer[256];
  g_Cvar_HudMessage.GetString(buffer, sizeof(buffer));
  
  for (int i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i) && !IsFakeClient(i))
    {
      SetHudTextParams(-1.0, 0.2, 5.0, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
      ShowSyncHudText(i, g_hHudSync, buffer, g_iCountdown);
    }
  }
}

public Action Timer_Countdown(Handle timer)
{
  // Decrement the countdown
  g_iCountdown--;
  
  // Update the HUD message for all players every second
  UpdateHudMessageForAllPlayers();
  
  // When countdown reaches 0, execute restart
  if (g_iCountdown <= 0)
  {
    // Reset global variables
    g_hRestartTimer = null;
    g_bRestartInProgress = false;
    
    // Final message
    char buffer[256];
    g_Cvar_EndMessage.GetString(buffer, sizeof(buffer));
    PrintToChatAll("\x07FF0000%s", buffer);
    
    // Execute restart command after a short delay
    CreateTimer(0.5, Timer_ExecuteRestart);
    
    return Plugin_Stop;
  }
  
  return Plugin_Continue;
}

public Action Timer_ExecuteRestart(Handle timer)
{
  // Execute the restart command
  ServerCommand("_restart");
  return Plugin_Stop;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
  // If restart is in progress, prevent new players from joining
  if (g_bRestartInProgress)
  {
    char buffer[256];
    g_Cvar_RejectMessage.GetString(buffer, sizeof(buffer));
    Format(rejectmsg, maxlen, buffer, g_iCountdown);
    return false;
  }
  
  return true;
}

public void OnPluginEnd()
{
  // Clean up
  if (g_hRestartTimer)
  {
    delete g_hRestartTimer;
  }
}