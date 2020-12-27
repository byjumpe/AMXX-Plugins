#pragma semicolon 1

#include <amxmodx>
#include <reapi>

new const VERSION[] = "1.0.0";
new const CONFIG_NAME[] = "InfoKiller.cfg";

enum any:CVAR_LIST {
    ANNOUNCE,
    HUD_RED,
    HUD_GREEN,
    HUD_BLUE,
    Float:HUD_X,
    Float:HUD_Y,
    Float:HUD_HOLD_TIME
};

enum WeaponId {
    NONE,
    P228,
    GLOCK,
    SCOUT,
    HEGRENADE,
    XM1014,
    C4,
    MAC10,
    AUG,
    ELITE = 10,
    FIVESEVEN,
    UMP45,
    SG550,
    GALIL,
    FAMAS,
    USP,
    GLOCK18,
    AWP,
    MP5,
    M249,
    M3,
    M4A1,
    TMP,
    G3SG1,
    DEAGLE = 26,
    SG552,
    AK47,
    KNIFE,
    P90
};

new const g_szLangMsg[WeaponId][] = {
    "INFO_KILLER_NONE",
    "INFO_KILLER_P228",
    "INFO_KILLER_GLOCK",
    "INFO_KILLER_SCOUT",
    "INFO_KILLER_HEGRENADE",
    "INFO_KILLER_XM1014",
    "INFO_KILLER_C4",
    "INFO_KILLER_MAC10",
    "INFO_KILLER_AUG",
	"",
    "INFO_KILLER_ELITE",
    "INFO_KILLER_FIVESEVEN",
    "INFO_KILLER_UMP45",
    "INFO_KILLER_SG550",
    "INFO_KILLER_GALIL",
    "INFO_KILLER_FAMAS",
    "INFO_KILLER_USP",
    "INFO_KILLER_GLOCK18",
    "INFO_KILLER_AWP",
    "INFO_KILLER_MP5",
    "INFO_KILLER_M249",
    "INFO_KILLER_M3",
    "INFO_KILLER_M4A1",
    "INFO_KILLER_TMP",
    "INFO_KILLER_G3SG1",
	"",
    "INFO_KILLER_DEAGLE",
    "INFO_KILLER_SG552",
    "INFO_KILLER_AK47",
    "INFO_KILLER_KNIFE",
    "INFO_KILLER_P90"
};

enum _:DAMAGE {
    DMG_TAKEN,
    DMG_GIVEN
}

enum _:HITS {
    HITS_TAKEN,
    HITS_GIVEN
}

new g_iDamage[MAX_PLAYERS +1][MAX_PLAYERS +1][DAMAGE], g_iHits[MAX_PLAYERS +1][MAX_PLAYERS +1][HITS], g_Cvar[CVAR_LIST];

public plugin_init() {
    register_plugin("[ReAPI] Info Killer", VERSION, "Jumper");

    RegisterCvars();

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage", true);
    RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true);

    register_dictionary("InfoKiller.txt");
}

public plugin_cfg() {
    new filedir[MAX_RESOURCE_PATH_LENGTH];
    get_localinfo("amxx_configsdir", filedir, charsmax(filedir));
    format(filedir, charsmax(filedir), "%s/%s", filedir, CONFIG_NAME);

    if(file_exists(filedir)) {
        server_cmd("exec %s", filedir);
    } else {
        set_fail_state("File '%s' not found!", filedir);
    }
}

public CBasePlayer_Spawn(id) {
    arrayset(g_iDamage[id][DAMAGE], 0, sizeof g_iDamage[]);
    arrayset(g_iHits[id][HITS], 0, sizeof g_iHits[]);
}

public client_disconnected(id) {
    arrayset(g_iDamage[id][DAMAGE], 0, sizeof g_iDamage[]);
    arrayset(g_iHits[id][HITS], 0, sizeof g_iHits[]);
}

public CBasePlayer_TakeDamage(const victim, pevInflictor, attacker, Float:flDamage) {
    if(victim == attacker || !is_user_connected(attacker) || !rg_is_player_can_takedamage(victim, attacker) || attacker != pevInflictor) {
        return HC_CONTINUE;
    }
    g_iDamage[attacker][victim][DMG_GIVEN] += floatround(flDamage);
    g_iHits[attacker][victim][HITS_GIVEN]++;
    g_iDamage[victim][attacker][DMG_TAKEN] += floatround(flDamage);
    g_iHits[victim][attacker][HITS_TAKEN]++;

    if(!is_user_alive(victim)){
        new ActiveItem = get_member(attacker, m_pActiveItem);

        if(is_nullent(ActiveItem)) {
            return HC_CONTINUE;
        }

        new WeaponId:wID = get_member(ActiveItem, m_iId);

        if(get_member(victim, m_bKilledByGrenade)) {
            wID = HEGRENADE;
        }

        if(g_Cvar[ANNOUNCE] == 0) {
                if(g_iDamage[victim][attacker][DMG_GIVEN] > 0) {
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT1",
                        attacker,
                        Float:get_entvar(attacker, var_health),
                        fmt("%L", LANG_PLAYER, g_szLangMsg[wID])
                    );            
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT2",
                        g_iDamage[attacker][victim][DMG_GIVEN],
                        g_iHits[attacker][victim][HITS_GIVEN],
                        attacker
                    );
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT3",
                        g_iDamage[victim][attacker][DMG_GIVEN],
                        g_iHits[victim][attacker][HITS_GIVEN],
                        attacker
                    );
                } else {
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER, 
                        "INFO_KILLER_CHAT1", 
                        attacker, 
                        Float:get_entvar(attacker, var_health),
                        fmt("%L", LANG_PLAYER, g_szLangMsg[wID])
                    );            
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT2",
                        g_iDamage[victim][attacker][DMG_TAKEN],
                        g_iHits[victim][attacker][HITS_TAKEN],
                        attacker
                    );
                }
        } else if(g_Cvar[ANNOUNCE] == 1) {
                set_hudmessage(
                    .red = g_Cvar[HUD_RED],
                    .green = g_Cvar[HUD_GREEN],
                    .blue = g_Cvar[HUD_BLUE],
                    .x = g_Cvar[HUD_X],
                    .y = g_Cvar[HUD_Y],
                    .holdtime = g_Cvar[HUD_HOLD_TIME]
                );

                if(g_iDamage[victim][attacker][DMG_GIVEN] > 0) {
                    show_hudmessage(
                        victim,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_HUD",
                        attacker,
                        Float:get_entvar(attacker, var_health), 
                        fmt("%L", LANG_PLAYER, g_szLangMsg[wID]),
                        g_iDamage[attacker][victim][DMG_GIVEN],
                        g_iHits[attacker][victim][HITS_GIVEN],
                        g_iDamage[victim][attacker][DMG_GIVEN],
                        g_iHits[victim][attacker][HITS_GIVEN]
                    );
                } else {
                    show_hudmessage(
                        victim,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_HUD_NO_DMG",
                        attacker,
                        Float:get_entvar(attacker, var_health),
                        fmt("%L", LANG_PLAYER, g_szLangMsg[wID]),
                        g_iDamage[victim][attacker][DMG_TAKEN],
                        g_iHits[victim][attacker][HITS_TAKEN]
                    );
                }
            }

        g_iDamage[attacker][victim][DMG_GIVEN] = 0;
        g_iHits[attacker][victim][HITS_GIVEN] = 0;
        g_iDamage[victim][attacker][DMG_TAKEN] = 0;
        g_iHits[victim][attacker][HITS_TAKEN] = 0;
    }

    return HC_CONTINUE;
}

RegisterCvars() {
    bind_pcvar_num(
        create_cvar(
            .name = "announce",
            .string = "1",
            .flags = FCVAR_NONE,
            .has_min = true,
            .min_val = 0.0,
            .has_max =true,
            .max_val = 1.0
        ), g_Cvar[ANNOUNCE]
    );
    bind_pcvar_num(
        create_cvar(
            .name = "hud_red",
            .string = "200",
            .flags = FCVAR_NONE
        ), g_Cvar[HUD_RED]
    );
    bind_pcvar_num(
        create_cvar(
            .name = "hud_green",
            .string = "205",
            .flags = FCVAR_NONE
        ), g_Cvar[HUD_GREEN]
    );
    bind_pcvar_num(
        create_cvar(
            .name = "hud_blue",
            .string = "255",
            .flags = FCVAR_NONE
        ), g_Cvar[HUD_BLUE]
    );
    bind_pcvar_float(
        create_cvar(
            .name = "hud_x",
            .string = "-1.0",
            .flags = FCVAR_NONE
        ), g_Cvar[HUD_X]
    );
    bind_pcvar_float(
        create_cvar(
            .name = "hud_y",
            .string = "0.65",
            .flags = FCVAR_NONE
        ), g_Cvar[HUD_Y]
    );
    bind_pcvar_float(
        create_cvar(
            .name = "hud_hold_time",
            .string = "7.0",
            .flags = FCVAR_NONE,
            .has_min = true,
            .min_val = 1.0
        ), g_Cvar[HUD_HOLD_TIME]
    );
}

public OnConfigsExecuted() {
    register_cvar("re_info_attacker", VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);
}
