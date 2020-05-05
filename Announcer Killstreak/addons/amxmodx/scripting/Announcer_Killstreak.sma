#pragma semicolon 1

// В plugins.ini плагин желательно располагать НИЖЕ плагина, выполняющего функции чат-антифлуда (antiflood.amxx)

///////////////////////////////////////////// Настройки ///////////////////////////////////////////////

// Имя пака с голосом диктора
// Default - мужской голос (стандартный набор)
// Khepri - мужской голос с автотюном
// Nox - женский голос
// Russian - мужской голос (русский)
new const SOUND_PACK_FOLDER[] = "Default";

// Состояние анонсера по умолчанию
// 1 - Игроки получают все анонсы
// 2 - Игроки получают только собственные анонсы
// 3 - Выключен у всех
#define DEFAULT_STATE 1

// Установите 1, если хотите отображать диктора в HLTV
#define HLTV_SUPPORT 0

// Интервал для серии убийств (в секундах)
const Float: MULTIKILL_TIME = 3.0;

// Режим HUD'а
#define COLOR_MODE 1 // 1 - Одноцветный; 2 - Многоцветный; 3 - Случайный

// Цвет HUD при COLOR_MODE 1
stock const HUD_R = 250;
stock const HUD_G = 250;
stock const HUD_B = 250;

// Цвета HUD при COLOR_MODE 2
stock const g_iColor[][] = {

	{ 255, 0, 0 },		// DOUBLE_KILL
	{ 255, 0, 0 },		// TRIPLE_KILL
	{ 255, 0, 0 }, 		// QUADRA_KILL
	{ 255, 0, 0 }, 		// PENTA_KILL

	{ 255, 0, 0 }, 		// KILLING_SPREE
	{ 255, 0, 0 }, 		// RAMPAGE
	{ 255, 0, 0 }, 		// UNSTOPPABLE
	{ 255, 0, 0 }, 		// DIVINE
	{ 255, 0, 0 }, 		// IMMORTAL
	{ 255, 0, 0 }, 		// GODLIKE

	{ 255, 0, 0 }, 		// FIRST_BLOOD
	{ 255, 0, 0 }, 		// SHUTDOWN
	{ 255, 0, 0 } 		// DEICIDE
};

// Грани рандомизации цвета HUD при COLOR_MODE 3
stock const MIN_VALUE = 50;
stock const MAX_VALUE = 255;

// Позиция HUD
const Float: HUD_X = -1.0;
const Float: HUD_Y = 0.2;

// Длительность отображения HUD
const Float: HUD_TIME = 5.0;

// Метод сохранения состояния анонсера
#define SAVE_TYPE 0 // 0 - nVault; 1 - Trie

// Через сколько дней удалять настройку из nVault, если игрок не заходил
stock const VAULT_PRUNE_DAYS = 7;

// Файл для сохранения настроек (SAVE_TYPE 0)
stock const VAULT_FILE[] = "announcer_data";

///////////////////////////////////////////////////////////////////////////////////////////////////////

#define SAVE_TYPE_VAULT 0
#define SAVE_TYPE_TRIE 1

#include <amxmodx>
#include <reapi>
#include <time>
#if SAVE_TYPE == SAVE_TYPE_VAULT
	#include <nvault>
#endif

enum { R, G, B };

enum {
	AS__ALL = 1,
	AS__PERSONAL,
	AS__DISABLED
};

enum _:SOME_ENUM {

	DOUBLE_KILL,
	TRIPLE_KILL,
	QUADRA_KILL,
	PENTA_KILL,

	KILLING_SPREE,
	RAMPAGE,
	UNSTOPPABLE,
	DIVINE,
	IMMORTAL,
	GODLIKE,

	FIRST_BLOOD,
	SHUTDOWN,
	DEICIDE
};

new const g_szLangMsg[SOME_ENUM][] = {

	// Multikills
	"AK_DOUBLE_KILL", 	 // -2
	"AK_TRIPLE_KILL", 	 // -3
	"AK_QUADRA_KILL", 	 // -4
	"AK_PENTA_KILL", 	 // -5

	// Killstreaks
	"AK_KILLING_SPREE",  // -3
	"AK_RAMPAGE", 		 // -5
	"AK_UNSTOPPABLE", 	 // -7
	"AK_DIVINE", 		 // -9
	"AK_IMMORTAL", 	 	 // -11
	"AK_GODLIKE",		 // -13

	// Other
	"AK_FIRST_BLOOD",
	"AK_SHUTDOWN",
	"AK_DEICIDE"
};

new g_szSoundName[SOME_ENUM][] = {

	"doublekill",
	"triplekill",
	"quadrakill",
	"pentakill",

	"killingspree",
	"rampage",
	"unstoppable",
	"divine",
	"immortal",
	"godlike",

	"firstblood",
	"shutdown",
	"deicide"
};

const FILE_PATH_LEN = 96;
const AUTHID_LEN = 25;

new g_iKillStreak[MAX_PLAYERS +1], g_iMultiKill[MAX_PLAYERS +1], g_szBuffer[MAX_NAME_LENGTH], g_iMsgHudSync,
	g_iPlayers[MAX_PLAYERS], g_iPlayerCount, bool: g_bFirstBlood, g_iKiller, g_szSound[SOME_ENUM][FILE_PATH_LEN];

new  g_iAnnouncer[MAX_PLAYERS +1] = { DEFAULT_STATE, ... }, g_szAuthID[AUTHID_LEN];

stock g_hVault = INVALID_HANDLE, Trie:g_tTrie, g_iMsgId, g_hMsg, g_iFFA;

public plugin_init(){

	register_plugin("Announcer Killstreak", "2.1", "Jumper & mx?!");

	register_dictionary("Announcer_Killstreak.txt");

	new pCvar = get_cvar_pointer("mp_freeforall");

	g_iFFA = get_pcvar_num(pCvar);

	hook_cvar_change(pCvar, "hook_Cvar");

	register_clcmd("say /ak", "Command_Announce");
	register_clcmd("say_team /ak", "Command_Announce");

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Pre", 0);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "CSGameRules_OnRoundFreezeEnd_Pre", 0);

	g_iMsgHudSync = CreateHudSyncObj();

	g_iMsgId = get_user_msgid("SendAudio");

#if SAVE_TYPE == SAVE_TYPE_TRIE
	g_tTrie = TrieCreate();
#endif
}

public hook_Cvar(pCvar, szOldVal[], szNewVal[]){

	g_iFFA = str_to_num(szNewVal);
}

public plugin_end()
{
#if SAVE_TYPE == SAVE_TYPE_VAULT
	if(g_hVault != INVALID_HANDLE){
	
		nvault_close(g_hVault);
	}
#else
	TrieDestroy(g_tTrie);
#endif
}

#if SAVE_TYPE == SAVE_TYPE_VAULT
public plugin_cfg(){
	
	if((g_hVault = nvault_open(VAULT_FILE)) == INVALID_HANDLE){
		
		set_fail_state("ERROR: Opening nVault failed!");
	}
	nvault_prune(g_hVault, 0, get_systime() - (SECONDS_IN_DAY * VAULT_PRUNE_DAYS));
}
#endif

public plugin_precache(){

	for(new i; i < SOME_ENUM; i++){

		formatex( g_szSound[i], charsmax(g_szSound[]), "Announcer_Killstreak/%s/%s.wav",
			SOUND_PACK_FOLDER, g_szSoundName[i]	);

		precache_sound(g_szSound[i]);
	}
}

public client_authorized(iPlayer, const szAuthID[]){

#if HLTV_SUPPORT == 1
	if(is_user_hltv(iPlayer)){
	
		g_iAnnouncer[iPlayer] = AS__ALL;
		return;
	}
#endif

#if SAVE_TYPE == SAVE_TYPE_VAULT
	if(!(g_iAnnouncer[iPlayer] = nvault_get(g_hVault, szAuthID))){
#else
	if(!TrieGetCell(g_tTrie, szAuthID, g_iAnnouncer[iPlayer])){
#endif
		g_iAnnouncer[iPlayer] = DEFAULT_STATE;
	}
}

public client_disconnected(iPlayer){

	g_iKillStreak[iPlayer] = g_iMultiKill[iPlayer] = 0;
}

public Command_Announce(iPlayer){

	if(++g_iAnnouncer[iPlayer] > AS__DISABLED){
	
		g_iAnnouncer[iPlayer] = AS__ALL;
	}

	get_user_authid(iPlayer, g_szAuthID, charsmax(g_szAuthID));
#if SAVE_TYPE == SAVE_TYPE_VAULT
	formatex(g_szBuffer, charsmax(g_szBuffer), "%d", g_iAnnouncer[iPlayer]);
	nvault_set(g_hVault, g_szAuthID, g_szBuffer);
#else
	TrieSetCell(g_tTrie, g_szAuthID, g_iAnnouncer[iPlayer]);
#endif

	formatex(g_szBuffer, charsmax(g_szBuffer), "AK_STATUS_%d", g_iAnnouncer[iPlayer]);

	client_print_color( iPlayer, print_team_red, "^1[^4AK^1] %L %L", iPlayer, "AK_COMMAND",
		iPlayer, g_szBuffer );

	return PLUGIN_HANDLED_MAIN;
}

public msg_SendAudio()
{
	get_msg_arg_string(2, g_szBuffer, charsmax(g_szBuffer));

	if(contain(g_szBuffer[7], "terwin") != -1 || contain(g_szBuffer[7], "ctwin") != -1){ // %!MRAD_
	
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public CSGameRules_OnRoundFreezeEnd_Pre(){

	if(g_hMsg){
	
		unregister_message(g_iMsgId, g_hMsg);
		g_hMsg = 0;
	}
	arrayset(g_iKillStreak, 0, sizeof(g_iKillStreak));
	arrayset(g_iMultiKill, 0, sizeof(g_iMultiKill));
	g_bFirstBlood = false;
}

public CBasePlayer_Killed_Pre(iVictim, iKiller){

	if(iVictim == iKiller || !is_user_connected(iKiller) || 
	(!g_iFFA && rg_get_user_team(iVictim) == rg_get_user_team(iKiller))){
	
		g_iKillStreak[iVictim] = g_iMultiKill[iVictim] = 0;
		return;
	}

	g_iMultiKill[iVictim] = 0;

	g_iKiller = iKiller;
	g_iKillStreak[iKiller]++;
	g_iMultiKill[iKiller]++;

	static Float:fCurrKillTime[MAX_PLAYERS +1];

	new Float:fLastKillTime = fCurrKillTime[iKiller];
	fCurrKillTime[iKiller] = get_gametime();

	/* --- */

	if(g_iKillStreak[iVictim] > 4){

		g_iKiller = iVictim;
		g_iKillStreak[iVictim] = 0;
		Announcer(SHUTDOWN);
		return;
	}

	g_iKillStreak[iVictim] = 0;

	if(!g_bFirstBlood){

		g_bFirstBlood = true;
		Announcer(FIRST_BLOOD);
		return;
	}

	new TeamName: iVictimTeam = rg_get_user_team(iVictim);

	if(TEAM_SPECTATOR > iVictimTeam > TEAM_UNASSIGNED){

		get_players(g_iPlayers, g_iPlayerCount, "ae", iVictimTeam == TEAM_TERRORIST ? "TERRORIST" : "CT");

		if(!g_iPlayerCount){

			if(!g_hMsg){
			
				g_hMsg = register_message(g_iMsgId, "msg_SendAudio");
			}
			Announcer(DEICIDE);
			return;
		}
	}

	/* --- */

	if(g_iKillStreak[iKiller] == 1){
	
		return;
	}

	if(fCurrKillTime[iKiller] - fLastKillTime < MULTIKILL_TIME && g_iMultiKill[iKiller] < 6){

		Announcer(g_iMultiKill[iKiller] - 2);
		return;
	}

	g_iMultiKill[iKiller] = 1;

	if(g_iKillStreak[iKiller] % 2 == 0){
	
		return;
	}

	if(g_iKillStreak[iKiller] > 11){
	
		Announcer(GODLIKE);
		return;
	}

	switch(g_iKillStreak[iKiller]){
	
		case 3: Announcer(KILLING_SPREE);
		case 5: Announcer(RAMPAGE);
		case 7: Announcer(UNSTOPPABLE);
		case 9: Announcer(DIVINE);
		case 11: Announcer(IMMORTAL);
	}
}

stock Announcer(iPos){

	new szNameKiller[MAX_NAME_LENGTH];
	get_user_name(g_iKiller, szNameKiller, charsmax(szNameKiller));

	get_players(g_iPlayers, g_iPlayerCount, "c");

#if COLOR_MODE == 1
	set_hudmessage(HUD_R, HUD_G, HUD_B, HUD_X, HUD_Y, 0, 0.0, HUD_TIME);
#elseif COLOR_MODE == 2
	set_hudmessage(g_iColor[iPos][R], g_iColor[iPos][G], g_iColor[iPos][B], HUD_X, HUD_Y, 0, 0.0, HUD_TIME);
#else
	set_hudmessage(	random_num(MIN_VALUE, MAX_VALUE), random_num(MIN_VALUE, MAX_VALUE),
		random_num(MIN_VALUE, MAX_VALUE), HUD_X, HUD_Y, 0, 0.0, HUD_TIME );
#endif

	for(new i, iPlayer; i < g_iPlayerCount; i++){

		iPlayer = g_iPlayers[i];

		if(g_iAnnouncer[iPlayer] == AS__ALL || (g_iAnnouncer[iPlayer] == AS__PERSONAL && iPlayer == g_iKiller)){

			rg_send_audio(iPlayer, g_szSound[iPos]);
			ShowSyncHudMsg(iPlayer, g_iMsgHudSync, "%L", iPlayer, g_szLangMsg[iPos], szNameKiller);
		}
	}
}

stock TeamName:rg_get_user_team(id){

	return get_member(id, m_iTeam);
}