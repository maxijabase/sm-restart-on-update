#include <sourcemod>
#include <steampawn>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_Cvar_RestartTime;
Handle g_hHudSync;
Handle g_hRestartTimer;
bool g_bRestartInProgress = false;
int g_iCountdown = 0;

public Plugin myinfo = 
{
  name = "Restart On Update", 
  author = "ampere", 
  description = "Triggers a countdown before server restart when Steam master servers report the server is outdated", 
  version = PLUGIN_VERSION, 
  url = "github.com/maxijabase"
};

public void OnPluginStart()
{
  LoadTranslations("restartonupdate.phrases");
  
  g_Cvar_RestartTime = CreateConVar("sm_restart_time", "60", "Time in seconds before server restarts after receiving restart request", _, true, 10.0, true, 300.0);
  
  g_hHudSync = CreateHudSynchronizer();
  
  RegAdminCmd("sm_testrestart", Command_TestRestart, ADMFLAG_ROOT, "Simulates receiving a restart request from Steam");
  RegAdminCmd("sm_cancelrestart", Command_CancelRestart, ADMFLAG_ROOT, "Cancels an ongoing restart countdown");
  
  AutoExecConfig(true, "restartonupdate");
}

public Action Command_TestRestart(int client, int args)
{
  if (g_bRestartInProgress)
  {
    ReplyToCommand(client, "%t", "RestartInProgress");
    return Plugin_Handled;
  }
  
  char clientName[64] = "Console";
  if (client > 0 && IsClientInGame(client))
  {
    GetClientName(client, clientName, sizeof(clientName));
  }
  
  PrintToChatAll("\x07FF4500%T", "TestRestartInitiated", LANG_SERVER, clientName);
  
  LogMessage("Test restart initiated by %s", clientName);
  
  StartRestartSequence();
  
  return Plugin_Handled;
}

public Action Command_CancelRestart(int client, int args)
{
  if (!g_bRestartInProgress)
  {
    ReplyToCommand(client, "%t", "NoRestartInProgress");
    return Plugin_Handled;
  }
  
  char clientName[64] = "Console";
  if (client > 0 && IsClientInGame(client))
  {
    GetClientName(client, clientName, sizeof(clientName));
  }
  
  CancelRestartSequence(clientName);
  
  return Plugin_Handled;
}

void StartRestartSequence()
{
  g_bRestartInProgress = true;
  g_iCountdown = g_Cvar_RestartTime.IntValue;
  
  PrintToServer("Starting %d second countdown to server restart.", g_iCountdown);
  
  PrintToChatAll("\x07FF0000%T", "RestartCountdownBegin", LANG_SERVER, g_iCountdown);
  
  g_hRestartTimer = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
  
  UpdateHudMessageForAllPlayers();
}

void CancelRestartSequence(const char[] adminName)
{
  LogMessage("Restart countdown cancelled by %s", adminName);
  
  PrintToChatAll("\x07FF4500%T", "RestartCancelled", LANG_SERVER, adminName);
  
  for (int i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i) && !IsFakeClient(i))
    {
      ClearSyncHud(i, g_hHudSync);
    }
  }
  
  if (g_hRestartTimer)
  {
    delete g_hRestartTimer;
    g_hRestartTimer = null;
  }
  
  g_bRestartInProgress = false;
}

public void SteamPawn_OnRestartRequested()
{
  if (g_bRestartInProgress)
  {
    return;
  }
  
  LogMessage("Official restart request received from Steam.");
  
  PrintToChatAll("\x07FF0000%T", "SteamRestartRequested", LANG_SERVER);
  
  StartRestartSequence();
}

void UpdateHudMessageForAllPlayers()
{
  for (int i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i) && !IsFakeClient(i))
    {
      SetHudTextParams(-1.0, 0.2, 5.0, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
      ShowSyncHudText(i, g_hHudSync, "%t", "HudRestartMessage", g_iCountdown);
    }
  }
}

public Action Timer_Countdown(Handle timer)
{
  g_iCountdown--;
  
  UpdateHudMessageForAllPlayers();
  
  if (g_iCountdown <= 0)
  {
    g_hRestartTimer = null;
    g_bRestartInProgress = false;
    
    PrintToChatAll("\x07FF0000%T", "RestartNow", LANG_SERVER);
    
    CreateTimer(0.5, Timer_ExecuteRestart);
    
    return Plugin_Stop;
  }
  
  return Plugin_Continue;
}

public Action Timer_ExecuteRestart(Handle timer)
{
  ServerCommand("_restart");
  return Plugin_Stop;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
  if (g_bRestartInProgress)
  {
    SetGlobalTransTarget(client);
    Format(rejectmsg, maxlen, "%t", "RejectConnection", g_iCountdown);
    return false;
  }
  
  return true;
}

public void OnPluginEnd()
{
  if (g_hRestartTimer)
  {
    delete g_hRestartTimer;
  }
}