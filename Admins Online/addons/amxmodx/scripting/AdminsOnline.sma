#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

#define MAX_HUD_LENGTH 512

//Флаг учета админа
#define ADMIN_FLAG ADMIN_BAN 

enum {
    HUD_DISABLED,
    HUD_ENABLED
};

new g_iSyncAdminHud, g_iAdminNum, g_iShowAdminHud[MAX_PLAYERS +1];

public plugin_init() {
    register_plugin("Admins Online HUD", "0.0.10", "Jumper");

    register_dictionary("AdminOnline.txt");

    g_iSyncAdminHud = CreateHudSyncObj();

    new const adminhud_cmd[][] = { "say /adminhud", "say_team /adminhud" };
    for(new i; i < sizeof adminhud_cmd; i++) {
        register_clcmd(adminhud_cmd[i], "AdminHudToggle");
    }

    set_task_ex(5.0, "AdminOnlineHUD", .flags = SetTask_Repeat);
}

public client_putinserver(id) {
    g_iShowAdminHud[id] = HUD_ENABLED;
    updateAdminNum(id);
}

public client_disconnected(id) {
    updateAdminNum(id);
}

public AdminOnlineHUD() {
    new players[MAX_PLAYERS], count;
    get_players_ex(players, count, GetPlayers_ExcludeBots|GetPlayers_ExcludeHLTV);

    for(new i, id; i < count; i++) {
        id = players[i];
        if(g_iShowAdminHud[id] == HUD_ENABLED){
            ShowAdminHud(id);
        }
    }
}

public AdminHudToggle(id) {
    if(g_iShowAdminHud[id] == HUD_ENABLED) {
        g_iShowAdminHud[id] = HUD_DISABLED;
        ClearSyncHud(id, g_iSyncAdminHud);
        client_print_color(0, print_team_red, "%L", LANG_PLAYER, "ADM_HUD_OFF");
    } else {
        g_iShowAdminHud[id] = HUD_ENABLED;
        ShowAdminHud(id);
        client_print_color(0, print_team_default, "%L", LANG_PLAYER, "ADM_HUD_ON");
    }
}

getAdminNum() {
    new players[MAX_PLAYERS], count, num;
    get_players_ex(players, count, GetPlayers_ExcludeBots|GetPlayers_ExcludeHLTV);

    for(new i, id; i < count; i++) {
        id = players[i];
        if(get_user_flags(id) & ADMIN_FLAG) {
            num++;
        }
    }
    return num;
}

updateAdminNum(const id) {
    if(is_user_bot(id) || is_user_hltv(id) || !(get_user_flags(id) & ADMIN_FLAG)) {
        return;
    }
    g_iAdminNum = getAdminNum();
}

ShowAdminHud(id) {
    new szMsg[MAX_HUD_LENGTH];
    if(g_iAdminNum > 0) {
        set_hudmessage(51, 251, 51, 0.15, 0.0, 0, 0.0, 5.1, 0.1, 0.1);
        formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "ADM_HUD_ONLINE", g_iAdminNum);
    } else {
        set_hudmessage(255, 0, 0, 0.15, 0.0, 0, 0.0, 5.1, 0.1, 0.1);
        formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "ADM_HUD_OFFLINE");
    }
    ShowSyncHudMsg(id, g_iSyncAdminHud, szMsg);
}
