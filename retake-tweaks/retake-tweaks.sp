#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

// **AUTO DEFUSE STUFF**
float c4PlantTime = 0.0;
bool alreadyDefused = false;
bool couldDefuse = false;

// **AUTO PLANT STUFF**
enum {
  BOMBSITE_INVALID = -1,
  BOMBSITE_A = 0,
  BOMBSITE_B = 1
}

ConVar freezeTime;
Handle bombTimer;
bool hasBombBeenDeleted;
float bombPosition[3];
int bomber, bombsite, bombTicking;


public Plugin myinfo = {
  name = "RetakeTweaks",
  author = "alanfvn",
  description = "Insta defuse the bomb and autoplant the bomb",
  version = "0.0.2",
  url = "https://github.com/alanfvn"
}

public void OnPluginStart() {
  // auto plant
  freezeTime = FindConVar("mp_freezetime");
  bombTicking = FindSendPropInfo("CPlantedC4", "m_bBombTicking");
  //event register
  HookEvent("bomb_begindefuse", Event_BombBeginDefuse, EventHookMode_Post);
  HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_Pre);
  HookEvent("player_death", Event_AttemptInstantDefuse, EventHookMode_PostNoCopy);
  HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
  HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
}

// ======================
// HookEvents
// ======================
public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
  //auto defuse
  alreadyDefused = false;
  couldDefuse = false;
  //auto plant
  hasBombBeenDeleted = false;
  bomber = GetBomber();

  if (IsValidClient(bomber)){
    bombsite = GetNearestBombsite(bomber);
    int bomb = GetPlayerWeaponSlot(bomber, 4);
    hasBombBeenDeleted = SafeRemoveWeapon(bomber, bomb);
    GetClientAbsOrigin(bomber, bombPosition);
    delete bombTimer;
    bombTimer = CreateTimer(freezeTime.FloatValue, PlantBomb, bomber);
  }
  return Plugin_Continue;
}

public Action Event_BombPlanted(Handle event, const char[] name, bool dontBroadcast) {
  c4PlantTime = GetGameTime();
}

public Action Event_BombBeginDefuse(Handle event, const char[] name, bool dontBroadcast) {
  if (alreadyDefused) { 
    return Plugin_Handled; 
  }
  RequestFrame(Event_BombBeginDefusePlusFrame, GetEventInt(event, "userid"));
  return Plugin_Continue;
}

public Action Event_AttemptInstantDefuse(Handle event, const char[] name, bool dontBroadcast) {
  int defuser = GetDefusingPlayer();
  if (defuser != 0) {
    AttemptInstantDefuse(defuser);
  }
}

// ======================
// Event Handlers
// ======================
public void Event_BombBeginDefusePlusFrame(int userId) {
  couldDefuse = false;
  int client = GetClientOfUserId(userId);
  if (IsValidClient(client)) {
    AttemptInstantDefuse(client);
  }
}

public void OnRoundEnd(Event event, const char[] sName, bool bDontBroadcast) {
  delete bombTimer;
  GameRules_SetProp("m_bBombPlanted", 0);
}

void AttemptInstantDefuse(int client) {
  if (alreadyDefused || !GetEntProp(client, Prop_Send, "m_bIsDefusing") || HasAlivePlayer(CS_TEAM_T)) {
    return;
  }

  int StartEnt = MaxClients + 1;
  int c4 = FindEntityByClassname(StartEnt, "planted_c4");
  if (c4 == -1) { return; }

  bool hasDefuseKit = HasDefuseKit(client);
  float c4TimeLeft = GetConVarFloat(FindConVar("mp_c4timer")) - (GetGameTime() - c4PlantTime);

  if (!couldDefuse) {
    couldDefuse = (c4TimeLeft >= 10.0 && !hasDefuseKit) || (c4TimeLeft >= 5.0 && hasDefuseKit);
  }

  // Force Terrorist to win because they do not have enough time to defuse the bomb.
  if (!couldDefuse) {
    alreadyDefused = true;
    PrintToChatAll(" \x01[\x03Legion7\x01] \x07CT's couldn't defuse the bomb!");
    EndRound(CS_TEAM_T);
    return;
  }

  // Force CT's to win
  PrintToChatAll(" \x01[\x03Legion7\x01] \x05CT's successfully defused the bomb!");
  alreadyDefused = true;
  EndRound(CS_TEAM_CT);
}

void EndRound(int team, bool waitFrame = true) {
  if (waitFrame) {
    RequestFrame(Frame_EndRound, team);
    return;
  }
  Frame_EndRound(team);
}

void Frame_EndRound(int team) {
  int roundEndEntity = CreateEntityByName("game_round_end");
  DispatchSpawn(roundEndEntity);
  SetVariantFloat(1.0);
  AcceptEntityInput(roundEndEntity, team == CS_TEAM_CT ? "EndRound_CounterTerroristsWin" :  "EndRound_TerroristsWin");
  AcceptEntityInput(roundEndEntity, "Kill");
}

//auto defuse//
public void SendBombPlanted(int client){
  Event event = CreateEvent("bomb_planted");
  if (event != null) {
    event.SetInt("userid", GetClientUserId(client));
    event.SetInt("site", bombsite);
    event.Fire();
  }
}

public Action PlantBomb(Handle timer, int client) {
  bombTimer = INVALID_HANDLE;
  if (IsValidClient(client) || !hasBombBeenDeleted) {
    if (hasBombBeenDeleted) {
      int bombEntity = CreateEntityByName("planted_c4");
      GameRules_SetProp("m_bBombPlanted", 1);
      SetEntData(bombEntity, bombTicking, 1, 1, true);
      SendBombPlanted(client);

      if (DispatchSpawn(bombEntity)) {
        ActivateEntity(bombEntity);
        TeleportEntity(bombEntity, bombPosition, NULL_VECTOR, NULL_VECTOR);
        GroundEntity(bombEntity);
      }
    }
  }else{
    CS_TerminateRound(1.0, CSRoundEnd_Draw);
  }
}



// ======================
// UTILITY FUNCTIONS auto defuse
// ======================
int GetDefusingPlayer() {
  for (int i = 1; i <= MaxClients; i++) {
    if (IsValidClient(i) && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_bIsDefusing")) {
      return i;
    }
  }
  return 0;
}

bool HasDefuseKit(int client) {
  return GetEntProp(client, Prop_Send, "m_bHasDefuser") == 1; 
}

bool HasAlivePlayer(int team) {
  for (int i = 1; i <= MaxClients; i++) {
    if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) {
      return true;
    }
  }
  return false;
}

bool IsValidClient(int client) {
  return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

// ======================
// UTILITY FUNCTIONS auto defuse
// ======================
int GetBomber() {
  for (int i = 1; i <= MaxClients; i++) {
    if (IsValidClient(i) && HasBomb(i)) {
      return i;
    }
  }
  return -1;
}

int GetNearestBombsite(int client) {
  float pos[3];
  GetClientAbsOrigin(client, pos);
  int playerResource = GetPlayerResourceEntity();
  if (playerResource == -1){
    return BOMBSITE_INVALID;
  }
  float aCenter[3], bCenter[3];
  GetEntPropVector(playerResource, Prop_Send, "m_bombsiteCenterA", aCenter);
  GetEntPropVector(playerResource, Prop_Send, "m_bombsiteCenterB", bCenter);

  float aDist = GetVectorDistance(aCenter, pos, true);
  float bDist = GetVectorDistance(bCenter, pos, true);

  return aDist < bDist ? BOMBSITE_A : BOMBSITE_B;
}

void GroundEntity(int entity) {
  float flPos[3], flAng[3];
  GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flPos);
  flAng[0] = 90.0;
  flAng[1] = 0.0;
  flAng[2] = 0.0;

  Handle hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, entity);

  if (hTrace != INVALID_HANDLE && TR_DidHit(hTrace)) {
    float endPos[3];
    TR_GetEndPosition(endPos, hTrace);
    CloseHandle(hTrace);
    TeleportEntity(entity, endPos, NULL_VECTOR, NULL_VECTOR);
  } else {
    PrintToServer("Attempted to put entity on ground, but no end point found!");
  }
}

bool SafeRemoveWeapon(int client, int weapon) {
  if (!IsValidEntity(weapon) || !IsValidEdict(weapon) || !HasEntProp(weapon, Prop_Send, "m_hOwnerEntity")){
    return false;
  }
  int ownerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
  if (ownerEntity != client) {
    SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
  }
  SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
  if (HasEntProp(weapon, Prop_Send, "m_hWeaponWorldModel")){
    int worldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
    if (IsValidEdict(worldModel) && IsValidEntity(worldModel)) {
      if (!AcceptEntityInput(worldModel, "Kill")) {
        return false;
      }
    }
  }
  return AcceptEntityInput(weapon, "Kill");
}

public bool TraceFilterIgnorePlayers(int entity, int contentsMask, int client){
  return !(entity >= 1 && entity <= MaxClients);
} 

bool HasBomb(int client){
  return GetPlayerWeaponSlot(client, 4) != -1;
}
