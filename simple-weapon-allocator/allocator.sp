#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <clientprefs>
#include "allocator/util.inc"
#include "allocator/round.inc"
#include "allocator/weapons.inc"

// ** ClientPrefs **
Handle HPWeapon = INVALID_HANDLE;
Handle HSWeapon = INVALID_HANDLE;
char PWeapon[MAXPLAYERS + 1][15];
char SWeapon[MAXPLAYERS + 1][15];

public Plugin myinfo =  {
  name = "SimpleWeaponAllocator", 
  author = "alanfvn", 
  description = "Simple weapon allocator for retakes", 
  version = "1.0.1", 
  url = "https://github.com/alanfvn"
};

// ===================
// * EVENTS *
// ===================
public void OnPluginStart() {
  HPWeapon = RegClientCookie("prim_cookie", "Save primary weapon preference", CookieAccess_Private);
  HSWeapon = RegClientCookie("sec_cookie", "Save secondary weapon preference", CookieAccess_Private);
  RegConsoleCmd("sm_guns", Command_Guns, "Choose what guns you want to receive.");
  HookEvent("round_start", E_RoundStart, EventHookMode_Pre);
}

public void OnPluginEnd(){
  for (int i = 1; i <= MaxClients; i++){
    OnClientDisconnect(i);
  } 
}

public void OnClientDisconnect(int client){
  SetClientCookie(client, HPWeapon, PWeapon[client]);
  SetClientCookie(client, HSWeapon, SWeapon[client]);
}

public void OnClientCookiesCached(int client){
  GetClientCookie(client, HPWeapon, PWeapon[client], sizeof(PWeapon[]));
  GetClientCookie(client, HSWeapon, SWeapon[client], sizeof(SWeapon[]));
}

public void E_RoundStart(Event event, const char[] name, bool dontBroadcast) {
  if (IsWarmup()) { return; }
  char message[64];
  prepareNewRound(message);
  int money = getRoundMoney();
  PrintToChatAll(message);	

  for (int i = 1; i <= MaxClients; i++) {
    if (!ValidPlayer(i)) { continue; }
    ClearPlayer(i);
    GiveEquipment(i, GetClientTeam(i), money);
  }
}

// ===================
// * COMMANDS *
// ===================
public Action Command_Guns(int client, int args) {
  MainMenu(client);
  return Plugin_Handled;
}

// ===================
// * METHODS *
// ===================
void GiveEquipment(int client, int team, int money) {
  bool isCt = team == CS_TEAM_CT;
  char gunNames[4][32];
  int gunPrices[4];
  int selectedGuns[2];

  // Adjust weapons
  selectedGuns[0] = StringToInt(PWeapon[client]);
  selectedGuns[1] = StringToInt(SWeapon[client]);
  if(selectedGuns[1] < 5){ selectedGuns[1] = 5; }

  // Get loadout and it's price
  getRoundLoadout(selectedGuns);
  getLoadout(isCt, selectedGuns, gunNames);
  getLoadoutPrice(client, gunNames, gunPrices);

  // Give actual items: 0 knife, 1 primary, 2 secondary
  for(int i=0; i < 3; i++){
    GivePlayerItem(client, gunNames[i]);
  }

  // Calculate money
  money -= (gunPrices[1]+gunPrices[2]);
  int nadeCost = gunPrices[3];

  if(money >= 650){
    SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
    money -= 650;
    if(money >= 350){
      SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
      money -= 350;
    }
  }
  if(money >= nadeCost && nadeCost != 0){
    money -= nadeCost;
    GivePlayerItem(client, gunNames[3]);
  }
  if (money >= 400 && isCt) {
    money -= 400;
    SetEntProp(client, Prop_Send, "m_bHasDefuser", 1);
  }
}

// ===================
// * MENUS *
// ===================
void MainMenu(int client) {
  Menu menu = new Menu(Main_Callback);
  menu.ExitButton = true;
  menu.SetTitle("Guns Menu");
  menu.AddItem("primary", "Primary");
  menu.AddItem("secondary", "Secondary");
  menu.Display(client, MENU_TIME_FOREVER);
}

void PrimaryMenu(int client) {
  Menu menu = new Menu(Primary_Callback);
  menu.ExitButton = true;
  menu.SetTitle("Primary");
  menu.AddItem("0", "AK-47 / M4A1-S", isEnabled("0", PWeapon[client]));
  menu.AddItem("1", "AK-47 / M4A1", isEnabled("1", PWeapon[client]));
  menu.AddItem("2", "GALIL AR / FAMAS", isEnabled("2", PWeapon[client]));
  menu.AddItem("3", "SG 553 / AUG", isEnabled("3", PWeapon[client]));
  menu.AddItem("4", "SSG 08", isEnabled("4", PWeapon[client]));
  menu.Display(client, MENU_TIME_FOREVER);
}

void SecondaryMenu(int client) {
  Menu menu = new Menu(Secondary_Callback);
  menu.ExitButton = true;
  menu.SetTitle("Secondary");
  menu.AddItem("5", "Glock-18 / USP-s", isEnabled("5", SWeapon[client]));
  menu.AddItem("6", "Glock-18 / P2000", isEnabled("6", SWeapon[client]));
  menu.AddItem("7", "Desert Eagle", isEnabled("7", SWeapon[client]));
  menu.AddItem("8", "R8 Revolver", isEnabled("8", SWeapon[client]));
  menu.AddItem("9", "Tec-9 / Five-Seven", isEnabled("9", SWeapon[client]));
  menu.AddItem("10", "CZ75-Auto", isEnabled("10", SWeapon[client]));
  menu.AddItem("11", "P250", isEnabled("11", SWeapon[client]));
  menu.AddItem("12", "Dual Berettas", isEnabled("12", SWeapon[client]));
  menu.Display(client, MENU_TIME_FOREVER);
}

int isEnabled(char value[15], char value2[15]){
	return StrEqual(value, value2) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
}

// - MENU CALLBACKS -
int Main_Callback(Menu menu, MenuAction action, int client, int selection) {
  if (action != MenuAction_Select) {
    delete menu;
    return;
  }
  if(selection == 0){
    PrimaryMenu(client);
  }else if(selection == 1){
    SecondaryMenu(client);
  }else {
    delete menu;
  }
}

int Primary_Callback(Menu menu, MenuAction action, int client, int selection) {
  if (action != MenuAction_Select) {
    delete menu;
    return;
  }
  menu.GetItem(selection, PWeapon[client], sizeof(PWeapon[]));
}

int Secondary_Callback(Menu menu, MenuAction action, int client, int selection) {
  if (action != MenuAction_Select) {
    delete menu;
    return;
  }
  menu.GetItem(selection, SWeapon[client], sizeof(SWeapon[]));
}
