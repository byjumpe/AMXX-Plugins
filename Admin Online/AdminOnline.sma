#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

#define MAX_HUD_LENGTH 512

//Флаг учета админа
#define ADMIN_FLAG ADMIN_BAN 
//Время обновления HUD'a в секундах
const Float:TIME_UPDATE = 1.0;

enum {
    HUD_DISABLED,
    HUD_ENABLED
};

new g_iSyncMsg, g_iAdminNum, g_iShowAdminHud[MAX_PLAYERS +1];

public plugin_init() {
    register_plugin("Admin Online HUD", "0.0.7", "Jumper");

    g_iSyncMsg = CreateHudSyncObj();

    register_clcmd("say /adminhud", "AdminHudToggle");

    set_task_ex(TIME_UPDATE, "AdminOnlineHUD", .flags = SetTask_Repeat);
}

public client_putinserver(id) {
    g_iShowAdminHud[id] = HUD_ENABLED;
    updateAdminNum(id);
}

public client_disconnected(id) {
    updateAdminNum(id);
}

public AdminOnlineHUD() {
    new players[MAX_PLAYERS], count, szMsg[MAX_HUD_LENGTH];
    get_players_ex(players, count, GetPlayers_ExcludeBots|GetPlayers_ExcludeHLTV);

    for(new i, id; i < count; i++) {
        id = players[i];
        if(g_iShowAdminHud[id] == HUD_ENABLED){
            if(g_iAdminNum > 0) {
                set_hudmessage(51, 251, 51, 0.15, 0.0, 0, 0.0, 1.0, 0.1, 0.1);
                formatex(szMsg, charsmax(szMsg), "Админов онлайн: %d", g_iAdminNum);
            } else {
                set_hudmessage(255, 0, 0, 0.15, 0.0, 0, 0.0, 1.0, 0.1, 0.1);
                formatex(szMsg, charsmax(szMsg), "Админов онлайн: НЕТ");
            }
            ShowSyncHudMsg(id, g_iSyncMsg, szMsg);
        }
    }
}

public AdminHudToggle(id) {
    if(++g_iShowAdminHud[id] > HUD_DISABLED) {
        g_iShowAdminHud[id] = HUD_ENABLED;
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
        return PLUGIN_HANDLED;
    }
    g_iAdminNum = getAdminNum();

    return PLUGIN_CONTINUE;
}
