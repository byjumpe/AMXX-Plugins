#pragma semicolon 1

#include <amxmodx>
#include <reapi>

new const VERSION[] = "1.1.0";
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

new g_iDamage[MAX_PLAYERS +1][MAX_PLAYERS +1], g_iHits[MAX_PLAYERS +1][MAX_PLAYERS +1], g_Cvar[CVAR_LIST];

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
    for (new i = 1; i <= MaxClients; i++) {
        g_iDamage[id][i] = 0;
        g_iHits[id][i] = 0;
    }
}

public client_disconnected(id) {
    for (new i = 1; i <= MaxClients; i++) {
        g_iDamage[i][id] = 0;
        g_iHits[i][id] = 0;
    }
}

public CBasePlayer_TakeDamage(const victim, pevInflictor, attacker, Float:flDamage) {
    if(victim == attacker || !is_user_connected(attacker) || !rg_is_player_can_takedamage(victim, attacker)) {
        return HC_CONTINUE;
    }
    g_iDamage[attacker][victim] += floatround(flDamage);
    g_iHits[attacker][victim]++;

    if(!is_user_alive(victim)){
        new WeaponIdType:wID;

        if (get_member(victim, m_bKilledByBomb)) {
            wID = WEAPON_C4;
        } else if(get_member(victim, m_bKilledByGrenade)) {
            wID = WEAPON_HEGRENADE;
        } else {
            new ActiveItem = get_member(attacker, m_pActiveItem);

            if(!is_nullent(ActiveItem)) {
                wID = get_member(ActiveItem, m_iId);          
            }
        }

        new wName[24];
        rg_get_weapon_info(wID, WI_NAME, wName, charsmax(wName));

        if(g_Cvar[ANNOUNCE] == 0) {
                if(g_iDamage[victim][attacker] > 0) {
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT1",
                        attacker,
                        Float:get_entvar(attacker, var_health),
                        wName[7]
                    );            
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT2",
                        g_iDamage[attacker][victim],
                        g_iHits[attacker][victim],
                        attacker
                    );
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT3",
                        g_iDamage[victim][attacker],
                        g_iHits[victim][attacker],
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
                        wName[7]
                    );            
                    client_print_color(
                        victim,
                        attacker,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_CHAT2",
                        g_iDamage[attacker][victim],
                        g_iHits[attacker][victim],
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

                if(g_iDamage[victim][attacker] > 0) {
                    show_hudmessage(
                        victim,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_HUD",
                        attacker,
                        Float:get_entvar(attacker, var_health), 
                        wName[7],
                        g_iDamage[attacker][victim],
                        g_iHits[attacker][victim],
                        g_iDamage[victim][attacker],
                        g_iHits[victim][attacker]
                    );
                } else {
                    show_hudmessage(
                        victim,
                        "%L",
                        LANG_PLAYER,
                        "INFO_KILLER_HUD_NO_DMG",
                        attacker,
                        Float:get_entvar(attacker, var_health),
                        wName[7],
                        g_iDamage[attacker][victim],
                        g_iHits[attacker][victim]
                    );
                }
            }

        g_iDamage[attacker][victim] = 0;
        g_iHits[attacker][victim] = 0;
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
    register_cvar("re_info_killer", VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);
}
