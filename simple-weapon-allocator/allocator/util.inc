#include <cstrike>

stock bool ValidPlayer(int client) {
	return client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& !IsClientSourceTV(client)
		&& !IsClientReplay(client)
		&& IsPlayerAlive(client);
}

stock void ClearPlayer(int client) {
	int weapon;
	//clear inventory
	for (int i = 0; i <= 3; i++) {
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
	if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_GRENADE)) != -1) {
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
	//clear helmet and armor.
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
	SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
}

stock void getLoadoutPrice(int client, char guns[4][32], int prices[4]){
  prices[0] = 0;
  for(int i = 1; i <= 3; i++){
    CSWeaponID wid = CS_AliasToWeaponID(guns[i]);
    prices[i] = wid != CSWeapon_NONE ? CS_GetWeaponPrice(client, wid) : 0;
  }
}

stock bool IsWarmup() {
	return GameRules_GetProp("m_bWarmupPeriod") == 1;
}
