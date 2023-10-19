static const char grenades [][] = {
  "weapon_none", "weapon_flashbang", "weapon_hegrenade",
  "weapon_incgrenade", "weapon_smokegrenade"
};

static const char weapons[][] = {
  // fullbuy rifles
  "weapon_ak47", "weapon_m4a1_silencer", "weapon_m4a1",
  // eco rifles
  "weapon_galilar", "weapon_famas",
  // scope rifles
  "weapon_sg556", "weapon_aug", 
  // precision
  "weapon_ssg08", "weapon_awp",
  // primary pistols
  "weapon_glock", "weapon_usp_silencer", "weapon_hkp2000",
  // heavy pistols
  "weapon_deagle", "weapon_revolver",
  // interchangable pistols
  "weapon_tec9", "weapon_fiveseven", "weapon_cz75a",
  // other pistols
  "weapon_elite", "weapon_p250"
};

static const int wIds[][] = {
  {
    // primary ids ct
    1, 2, 4, 6, 7,
    // secondary ids ct
    10, 11, 12, 13, 15, 16, 18, 17
  },
  {
    // primary ids  t
    0, 0, 3, 5, 7, 
    // secondary ids t
    9, 9, 12, 13, 14, 16, 18, 17
  }
};

stock void getLoadout(bool isCt, int selectedGuns[2], char outGuns[4][32]){
  int primary = selectedGuns[0];
  int secondary = selectedGuns[1];
  int random = GetRandomInt(0,4);

  strcopy(outGuns[0], sizeof(outGuns[]), isCt ? "weapon_knife" : "weapon_knife_t");
  strcopy(outGuns[1], sizeof(outGuns[]), primary >= 0 ? weapons[getWeaponId(isCt, primary)] : "weapon_none");
  strcopy(outGuns[2], sizeof(outGuns[]), weapons[getWeaponId(isCt, secondary)]);
  strcopy(outGuns[3], sizeof(outGuns[]), grenades[random]);
}

stock int getWeaponId(bool isCt, int id){
  return isCt ? wIds[0][id] : wIds[1][id];
}
