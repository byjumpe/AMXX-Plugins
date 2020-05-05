/* 

    Благодарность: fantom (за код https://dev-cs.ru/threads/2672/post-30421)

*/
#pragma semicolon 1

#include <amxmodx>

#define RELOAD_TW    ADMIN_CFG    // Флаг доступа к команде перезагрузки конфига

new g_szAuthIDs[32][24], g_szAuthIDsNum, g_pcvEnabled;

public plugin_init() {
    register_plugin("Technical Works", "0.1.0", "Jumper");
    register_dictionary("technical_works.txt");

    register_concmd("tw_reloadcfg", "ReloadCfg", RELOAD_TW);
    g_pcvEnabled = register_cvar("tw_enable", "1");
}

public plugin_cfg() {
    if (!ReadGfg()) {
        set_fail_state("[TW]: Error load cfg technicalworks.ini");
    }
}

public client_authorized(id) {
    if (!get_pcvar_num(g_pcvEnabled)) {
        return PLUGIN_CONTINUE;
    }
    new szAuthID[24];
    get_user_authid(id, szAuthID, charsmax(szAuthID));
    if (!InArray(szAuthID)) {
        server_cmd("kick #%d  %L", get_user_userid(id), LANG_PLAYER, "REASON_WORKS");
    }
    return PLUGIN_CONTINUE;
}

public ReloadCfg(id, level, cid) {
    if(~get_user_flags(id) & level) {
        client_print(id, print_console, "[TW]: You have not access to this command");
    } else if (!ReadGfg()) {
        client_print(id, print_console, "[TW]: Error load cfg technicalworks.ini");
    } else {
        client_print(id, print_console, "[TW]: Reload cfg technicalworks.ini");
    }
}

bool:InArray(const szAuthID[]) {
    for(new i = 0; i < g_szAuthIDsNum; i++) {
        if(equal(g_szAuthIDs[i], szAuthID)) {
            return true;
        }
    }
    return false;
}

bool:ReadGfg() {
    new szFilePath[64];
    get_localinfo("amxx_configsdir", szFilePath, charsmax(szFilePath));
    add(szFilePath, charsmax(szFilePath), "/technicalworks.ini");

    new FileHandle = fopen(szFilePath, "rt");
    if(!FileHandle){
        return false;
    }

    g_szAuthIDsNum = 0;

    new szString[32];
    while(!feof(FileHandle)) {
        fgets(FileHandle, szString, charsmax(szString));
        trim(szString);
        if (szString[0] == EOS || szString[0] == ';') {
            continue;
        }

        remove_quotes(szString);

        copy(g_szAuthIDs[g_szAuthIDsNum], sizeof (g_szAuthIDs[]), szString);
        g_szAuthIDsNum++;

        if (g_szAuthIDsNum >= sizeof g_szAuthIDs) {
            break;
        }
    }
    fclose(FileHandle);
    return true;
}
