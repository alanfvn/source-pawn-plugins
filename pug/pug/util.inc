#include <cstrike>
#include "pug/game_manager.inc"

static const char lobbyCfg[][] = {
		"bot_quota 0", 
		"bot_kick", 
		"mp_autokick 0", 
		"mp_autoteambalance 0", 
		"mp_free_armor 2", 
		"mp_freezetime 1", 
		"mp_limitteams 0", 
		"mp_death_drop_gun 0", 
		"mp_respawn_immunitytime 0", 
		"mp_respawn_on_death_ct 1", 
		"mp_respawn_on_death_t 1", 
		"mp_round_restart_delay 0", 
		"mp_timelimit 0",
		"sv_alltalk 1", 
		"sv_auto_full_alltalk_during_warmup_half_end 1", 
		"sv_competitive_official_5v5 1", 
		"sv_full_alltalk 1"
};

static const char liveCfg[][] = {
		"ammo_grenade_limit_default 1", 
		"ammo_grenade_limit_flashbang 2", 
		"ammo_grenade_limit_total 4", 
		"bot_quota 0", 
		"bot_kick", 
		"mp_afterroundmoney 0", 
		"mp_autokick 0", 
		"mp_autoteambalance 0", 
		"mp_buytime 15", 
		"mp_c4timer 40", 
		"mp_death_drop_gun 1", 
		"mp_endmatch_votenextmap 0", 
		"mp_freezetime 10", 
		"mp_give_player_c4 1", 
		"mp_halftime_pausetimer 0", 
		"mp_ignore_round_win_conditions 0", 
		"mp_limitteams 0", 
		"mp_match_end_restart 1", 
		"mp_match_restart_delay 30", 
		"mp_maxmoney 16000", 
		"mp_maxrounds 30", 
		"mp_overtime_enable 1", 
		"mp_overtime_halftime_pausetimer 0", 
		"mp_overtime_maxrounds 6", 
		"mp_overtime_startmoney 10000", 
		"mp_respawn_immunitytime 0", 
		"mp_respawn_on_death_ct 0", 
		"mp_respawn_on_death_t 0", 
		"mp_round_restart_delay 5", 
		"mp_roundtime 1.92", 
		"mp_roundtime_defuse 1.92", 
		"mp_starting_losses 1", 
		"mp_startmoney 800", 
		"mp_timelimit 0", 
		"mp_weapons_allow_typecount 5", 
		"sv_allow_votes 0", 
		"sv_auto_full_alltalk_during_warmup_half_end 1", 
		"sv_competitive_official_5v5 1", 
		"sv_deadtalk 1", 
		"sv_talk_enemy_dead 0", 
		"sv_talk_enemy_living 0", 
		"sv_voiceenable 1"
};


stock void ExecuteConfigs(){
	if(!GameInProgress()){
		ExecuteCfg(lobbyCfg, sizeof(lobbyCfg));
	}else{
		ExecuteCfg(liveCfg, sizeof(liveCfg));
	}
}

stock void RestartGame(int delay) {
	ServerCommand("mp_restartgame %d", delay);
}

stock void StartWarmup(bool indefiniteWarmup = true, int warmupTime = 60) {
	ServerCommand("mp_do_warmup_period 1");
	ServerCommand("mp_warmuptime %d", warmupTime);
	ServerCommand("mp_warmup_start");
	
	if (indefiniteWarmup) {
		ServerCommand("mp_warmup_pausetimer 1");
		ServerCommand("mp_warmup_pausetimer 1");
	}
}

stock void EndWarmup() {
	ServerCommand("mp_warmup_end");
}

//Private methods
void ExecuteCfg(const char[][] cfg, int size) {
	for (int i = 0; i < size; i++) {
		ServerCommand("%s", cfg[i]);
	}
} 