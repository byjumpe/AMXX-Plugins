#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

new const VERSION[] = "0.0.1";
new const CONFIG_NAME[] = "MusicConnection.ini";

#define IsMp3Format(%1)             equali(%1[strlen( %1 ) - 4 ], ".mp3")
#define CONTAIN_WAV_FILE(%1)        (containi(%1, ".wav") != -1)
#define CONTAIN_MP3_FILE(%1)        (containi(%1, ".mp3") != -1)

enum (+=1) {
    SectionNone = -1,
    MusicConnection,
    Setting
};

new Array:g_MusicConnection;
new Trie:g_Setting;
new g_MusicConnectionNum, g_Section, g_szSound[64]; 

public plugin_precache() {
    register_plugin("Music Connection", VERSION, "Jumper");

    g_MusicConnection = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);
    g_Setting = TrieCreate();

    new filedir[MAX_RESOURCE_PATH_LENGTH];
    get_localinfo("amxx_configsdir", filedir, charsmax(filedir));
    format(filedir, charsmax(filedir), "%s/%s", filedir, CONFIG_NAME);

    if(!file_exists(filedir)) {
        set_fail_state("File '%s' not found!", filedir);
    }

    if(!parseConfigINI(filedir)) {
        set_fail_state("Fatal parse error!");
    }

    if(g_MusicConnection) {
        g_MusicConnectionNum = ArraySize(g_MusicConnection);
    }
}

public client_connect(id) {
    ArrayGetString(g_MusicConnection, random(g_MusicConnectionNum), g_szSound, charsmax(g_szSound));

    if(IsMp3Format(g_szSound)) {
        client_cmd(id, "stopsound; mp3 play %s", g_szSound);
    } else {
        client_cmd(id, "stopsound; spk %s", g_szSound);
    }
}

public client_putinserver(id) {
    if(is_user_bot(id) || is_user_hltv(id)) {
        return PLUGIN_HANDLED;
    }

    new Float:fTime;
    TrieGetCell(g_Setting, "time_stop_sound", fTime);
    set_task_ex(fTime, "StopSound", id);

    return PLUGIN_CONTINUE;
}

public StopSound(id) {
    if(!is_user_connected(id)) {
        return PLUGIN_HANDLED;
    }

    client_cmd(id, "stopsound", g_szSound);

    return PLUGIN_CONTINUE;
}

bool:parseConfigINI(const configFile[]) {
    new INIParser:parser = INI_CreateParser();

    if(parser != Invalid_INIParser) {
        INI_SetReaders(parser, "ReadCFGKeyValue", "ReadCFGNewSection");
        INI_ParseFile(parser, configFile);
        INI_DestroyParser(parser);
        return true;
    }

    return false;
}

public bool:ReadCFGNewSection(INIParser:handle, const section[], bool:invalid_tokens, bool:close_bracket) {
    if(!close_bracket) {
        log_amx("Closing bracket was not detected! Current section name '%s'.", section);
        return false;
    }

    if(equal(section, "setting")) {
        g_Section = Setting;
        return true;
    }
    
    if(equal(section, "music_connection")) {
        g_Section = MusicConnection;
        return true;
    }

    return false;
}

public bool:ReadCFGKeyValue(INIParser:handle, const key[], const value[]) {
    if(g_Section == SectionNone) {
        return false;
    }

    switch(g_Section) {
        case Setting: {
             if(!key[0] || !value[0]) {
                 log_amx("Emty key or value!");
                 return false;
             }
             new Float:fvalue = str_to_float(value);
             TrieSetCell(g_Setting, key, fvalue);
        }
        case MusicConnection: {
             if((key[0] && !CONTAIN_WAV_FILE(key)) && (key[0] && !CONTAIN_MP3_FILE(key))) {
                 log_amx("Invalid sound file! Parse string '%s'. Only sound files in wav or mp3 format should be used!", key);
                 return false;
             }
             new szSound[64];
             format(szSound, charsmax(szSound), "sound/%s", key);
             if(file_exists(fmt("%s", szSound))) {
                 precache_sound(key);
             }
             ArrayPushString(g_MusicConnection, szSound);
        }
    }
    return true;
}
