#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "pug/util.inc"

int countdown = 5;

public Plugin myinfo = {
  name = "SimplePug",
  author = "alanfvn",
  description = "Simple and plain pug plugin.",
  version = "1.0.0",
  url = "https://github.com/alanfvn"
};

//EVENTS
public void OnPluginStart(){
  //event hooks.
  HookEvent("cs_win_panel_match", Event_MatchOver);
  HookEvent("server_cvar", Event_CvarChanged, EventHookMode_Pre); 
  //commands
  RegAdminCmd("sm_start", Command_Start, ADMFLAG_GENERIC, "Start the match");
  RegAdminCmd("sm_stop", Command_Stop, ADMFLAG_GENERIC, "Stop the match");
  //friendly fire
  for (int i = 1; i <= MaxClients; i++){
    if (IsClientInGame(i)) {
      OnClientPutInServer(i);
    }
  }
}

public void OnMapStart(){
  StartWarmup(true);
  ExecuteConfigs();
}

public Action Event_MatchOver(Event event, const char[] name, bool dontBroadcast){
  SetGameState(LOBBY);
  return Plugin_Continue;
}

public Action Event_CvarChanged(Event event, const char[] name, bool dontBroadcast) {
  event.BroadcastDisabled = true;
  return Plugin_Continue;
}

//COMMANDS
public Action Command_Start(int client, int args){
  if(GameInProgress()){
    PrintToChat(client, "Game is already in progress!");
    return Plugin_Handled;
  }
  PrintToChat(client, "Starting the game...");
  SetGameState(IN_GAME);
  CreateTimer(1.0, Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
  return Plugin_Handled;
}

public Action Command_Stop(int client, int args){
  if(!GameInProgress()){
    PrintToChat(client, "Game is not in progress!");
    return Plugin_Handled;
  }
  StopGame();
  return Plugin_Handled;
}

//CALLBACKS
public Action Countdown(Handle value){
  if(countdown <= 0){
    StartGame();
    return Plugin_Stop;
  }
  if(countdown % 5 == 0 || countdown < 5){
    PrintToChatAll(" \x0E[L7] Starting in %d...", countdown);
  }
  countdown--;
  return Plugin_Handled;
}

//OTHER METHODS
public void StartGame(){
  ExecuteConfigs();
  EndWarmup();
}

public void StopGame(){
  SetGameState(LOBBY);
  ExecuteConfigs();
  StartWarmup(true);
  countdown = 5;
}


// ===================================
// FACEIT-FRIENDLY-FIRE
// ===================================
public void OnClientPutInServer(int client){
	SDKHook(client, SDKHook_TraceAttack, SDK_OnTraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
}

public void OnClientDisconnect(int client){
	SDKUnhook(client, SDKHook_TraceAttack, SDK_OnTraceAttack);
	SDKUnhook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
}


public Action SDK_OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup){
  if (!IsClientInGame(victim) || !IsEntityClient(attacker) || !IsClientInGame(attacker)){
    return Plugin_Continue;
  }

  if (GetClientTeam(attacker) == GetClientTeam(victim)){
    char inflictorClass[64];
    if (GetEdictClassname(inflictor, inflictorClass, sizeof(inflictorClass))){
      if (StrEqual(inflictorClass, "inferno")){
        return Plugin_Continue;
      }

      if (StrEqual(inflictorClass, "hegrenade_projectile")){
        return Plugin_Continue;
      }
    }
  }

  if (GetClientTeam(attacker) == GetClientTeam(victim))
    return Plugin_Handled;

  return Plugin_Continue;
}

public Action SDK_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]){
  // Invalid attacker or self damage
  if (attacker < 1 || attacker > MaxClients || attacker == victim || inflictor < 1)
    return Plugin_Continue;

  if (GetClientTeam(attacker) == GetClientTeam(victim)){
    char inflictorClass[64];
    if (GetEdictClassname(inflictor, inflictorClass, sizeof(inflictorClass))){
      if (StrEqual(inflictorClass, "inferno")){
        damage *= 1.0;
        return Plugin_Changed;
      }

      if (StrEqual(inflictorClass, "hegrenade_projectile")){
        damage *= 1.0;
        return Plugin_Changed;
      }
    }
  }

  if (GetClientTeam(attacker) == GetClientTeam(victim))
    return Plugin_Handled;

  return Plugin_Continue;
}

bool IsEntityClient(int client){
  return (client > 0 && client <= MaxClients);
}
