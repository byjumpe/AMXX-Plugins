#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

new const VERSION[] = "0.0.12";
new const CONFIG_NAME[] = "MusicConnection.ini";

#define IsMp3Format(%1)    bool:(equali(%1[strlen(%1) - 4], ".mp3"))
#define IsWavFormat(%1)    bool:(equali(%1[strlen(%1) - 4], ".wav"))

enum (+=1) {
    SectionNone = -1,
    MusicConnection,
    Setting
};

new Array:g_MusicConnection;
new Trie:g_Setting;
new g_MusicConnectionNum, g_Section, g_Sound[MAX_RESOURCE_PATH_LENGTH]; 

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
    if(is_user_bot(id) || is_user_hltv(id)) {
        return;
    }

    ArrayGetString(g_MusicConnection, random(g_MusicConnectionNum), g_Sound, charsmax(g_Sound));

    if(IsMp3Format(g_Sound)) {
        client_cmd(id, "stopsound; mp3 play %s", g_Sound);
    } else {
        client_cmd(id, "stopsound; spk %s", g_Sound);
    }
}

public client_putinserver(id) {
    if(is_user_bot(id) || is_user_hltv(id)) {
        return;
    }

    new Float:fTime;
    TrieGetCell(g_Setting, "time_stop_sound", fTime);
    set_task_ex(fTime, "StopSound", id);
}

public StopSound(id) {
    if(!is_user_connected(id)) {
        return;
    }

    client_cmd(id, "stopsound");
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
    switch(g_Section) {
        case SectionNone: {
             return false;
        }
        case Setting: {
             if(!key[0] || !value[0]) {
                 log_amx("Emty key or value!");
                 return false;
             }
             new Float:fvalue = str_to_float(value);
             TrieSetCell(g_Setting, key, fvalue);
        }
        case MusicConnection: {
             if((key[0] && !IsWavFormat(key)) && (key[0] && !IsMp3Format(key))) {
                 log_amx("Invalid sound file! Parse string '%s'. Only sound files in wav or mp3 format should be used!", key);
                 return false;
             }
             new Sound[MAX_RESOURCE_PATH_LENGTH];
             format(Sound, charsmax(Sound), "sound/%s", key);
             if(file_exists(fmt("%s", Sound))) {
                 precache_sound(key);
             }
             ArrayPushString(g_MusicConnection, Sound);
        }
    }

    return true;
}
