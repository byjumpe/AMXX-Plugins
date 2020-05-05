#include <amxmodx>
#tryinclude <authemu>
#tryinclude <reapi>

new const g_szFileName[] = "user_connect.ini";

enum _:FLAG_LANG{
	
	a_Flag,
	a_Lang[32]
};

enum _:TrieTypes{

	Trie:AUTHID,
	Trie:NAME,
	Trie:IP,
	Trie:OTHER
}

new Trie: g_tData[TrieTypes];
new Array: g_aFlagLang, g_iArraySize;

public plugin_init(){

	register_plugin("User Connect", "0.1.1", "Jumper");
	register_dictionary("user_connect.txt");

	read_cfg();
}

read_cfg(){

	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	format(szPath, charsmax(szPath), "%s/%s", szPath, g_szFileName);

	new iFile = fopen(szPath, "rt");

	if(!iFile){

		set_fail_state("File ^"%s^" is not found", szPath);
	}
 
	for(new i; i < TrieTypes; i++){

		g_tData[i] = TrieCreate();
	}
	
	g_aFlagLang = ArrayCreate(FLAG_LANG);

	new szBuffer[128], szAuthType[6], szAccess[MAX_AUTHID_LENGTH], szLang[32], szFlagLang[FLAG_LANG];

	while(!feof(iFile)){

		fgets(iFile, szBuffer, charsmax(szBuffer));
		parse(szBuffer, szAuthType, charsmax(szAuthType), szAccess, charsmax(szAccess), szLang, charsmax(szLang));

		if(!szBuffer[0] || szBuffer[0] == ';' || !szAuthType[0] || !szAccess[0] || !szLang[0])
			continue;

		if(!strcmp(szAuthType, "steam")){

			TrieSetString(g_tData[AUTHID], szAccess, szLang);
		}
		else if(!strcmp(szAuthType, "name")){

			TrieSetString(g_tData[NAME], szAccess, szLang);
		}
		else if(!strcmp(szAuthType, "ip")){

			TrieSetString(g_tData[IP], szAccess, szLang);
		}
		else if(!strcmp(szAuthType, "flags")){

			szFlagLang[a_Flag] = read_flags(szAccess);
			copy(szFlagLang[a_Lang], charsmax(szFlagLang[a_Lang]), szLang);
			ArrayPushArray(g_aFlagLang, szFlagLang);
			g_iArraySize++;
		}
		else if(!strcmp(szAuthType, "*")){

			TrieSetString(g_tData[OTHER], szAccess, szLang);
		}
	}
	
	fclose(iFile);
}

public client_putinserver(id){

	if(is_user_bot(id) || is_user_hltv(id)){

		return;
	}
 
	new szNick[MAX_NAME_LENGTH], szIP[MAX_IP_LENGTH],  szAuthID[MAX_AUTHID_LENGTH], szLang[32];

	get_user_name(id, szNick, charsmax(szNick));
	get_user_authid(id,  szAuthID, charsmax( szAuthID));
	get_user_ip(id, szIP, charsmax(szIP), 1);
	new iFlags = get_user_flags(id);

	if(TrieKeyExists(g_tData[NAME], szNick)){

		TrieGetString(g_tData[NAME], szNick, szLang, charsmax(szLang));
	}
	else if(TrieKeyExists(g_tData[AUTHID], szAuthID)){

		TrieGetString(g_tData[AUTHID], szAuthID, szLang, charsmax(szLang));
	}
	else if(TrieKeyExists(g_tData[IP], szIP)){

		TrieGetString(g_tData[IP], szIP, szLang, charsmax(szLang));
	}
	else if(g_iArraySize){

		for(new i, szFlagLang[FLAG_LANG]; i < g_iArraySize; i++){

			ArrayGetArray(g_aFlagLang, i, szFlagLang);

			if(iFlags & szFlagLang[a_Flag]){

				copy(szLang, charsmax(szLang), szFlagLang[a_Lang]);
				break;
			}
		}
	}
	#if defined _authemu_included
	else if(is_user_authemu(id) && TrieKeyExists(g_tData[OTHER], "GSClient")){

		TrieGetString(g_tData[OTHER], "GSClient", szLang, charsmax(szLang));
	}
	#endif
	else if(is_user_steam(id) && TrieKeyExists(g_tData[OTHER], "STEAM")){

		TrieGetString(g_tData[OTHER], "STEAM", szLang, charsmax(szLang));
	}
	else if(TrieKeyExists(g_tData[OTHER], "ALL")){

		TrieGetString(g_tData[OTHER], "ALL", szLang, charsmax(szLang));
	}
	if(szLang[0]){
 
		client_print_color(0, print_team_default, "%L", LANG_PLAYER, szLang, id);
		log_amx("Client %n lang %s", id, szLang);
	}
}
#if !defined _reapi_included 
stock bool:is_user_steam(id){
// Author Sh0oter
		static dp_pointer;
	 
		if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider"))){
		 
			server_cmd("dp_clientinfo %d", id);
			server_exec();
			return (get_pcvar_num(dp_pointer) == 2) ? true : false;
		}
		return false;
}
#endif