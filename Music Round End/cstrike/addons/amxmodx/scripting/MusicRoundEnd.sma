#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <reapi>

new const VERSION[] = "1.0.1";
new const CONFIG_NAME[] = "MusicRoundEnd.ini";

#define IsMp3Format(%1)    bool:(equali(%1[strlen(%1) - 4], ".mp3"))
#define IsWavFormat(%1)    bool:(equali(%1[strlen(%1) - 4], ".wav"))

enum {
    MUSIC_DISABLED,
    MUSIC_ENABLED
};

enum (+=1) {
    SectionNone = -1,
    CTSWins,
    TerroristsWins
};

new Array:g_MusicForCT, Array:g_MusicForTerrorist;
new g_MusicForCTNum, g_MusicForTerroristNum, g_Section, 
    g_Sound[MAX_RESOURCE_PATH_LENGTH], g_iPlayMusic[MAX_PLAYERS +1]; 

public plugin_init() {
    register_plugin("Music Round End", VERSION, "Jumper");
    register_dictionary("MusicRoundEnd.txt");
    RegisterHookChain(RG_RoundEnd, "RoundEnd_Post", .post = true);

    new const music_cmd[][] = { "say /music", "say_team /music" };
    for(new i; i < sizeof music_cmd; i++) {
        register_clcmd(music_cmd[i], "PlayMusicToggle");
    }
}

public plugin_precache() {
    g_MusicForCT = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);
    g_MusicForTerrorist = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);

    new filedir[MAX_RESOURCE_PATH_LENGTH];
    get_localinfo("amxx_configsdir", filedir, charsmax(filedir));
    format(filedir, charsmax(filedir), "%s/%s", filedir, CONFIG_NAME);

    if(!file_exists(filedir)) {
        set_fail_state("File '%s' not found!", filedir);
    }

    if(!parseConfigINI(filedir)) {
        set_fail_state("Fatal parse error!");
    }

    if(g_MusicForCT) {
        g_MusicForCTNum = ArraySize(g_MusicForCT);
    }

    if(g_MusicForTerrorist) {
        g_MusicForTerroristNum = ArraySize(g_MusicForTerrorist);
    }
}

public client_putinserver(id) {
    g_iPlayMusic[id] = MUSIC_ENABLED;
}

public RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event){
    switch(status) {
        case WINSTATUS_CTS: {
            ArrayGetString(g_MusicForCT, random(g_MusicForCTNum), g_Sound, charsmax(g_Sound));
            PlayMusic(g_Sound);
        }
        case WINSTATUS_TERRORISTS: {
            ArrayGetString(g_MusicForTerrorist, random(g_MusicForTerroristNum), g_Sound, charsmax(g_Sound));
            PlayMusic(g_Sound);
        }
    }
}

public PlayMusicToggle(id) {
    if(g_iPlayMusic[id] == MUSIC_ENABLED) {
        g_iPlayMusic[id] = MUSIC_DISABLED;
        client_cmd(id, "stopsound");
        client_print_color(id, print_team_red, "%L", LANG_PLAYER, "ROUND_END_MUSIC_OFF");
    } else {
        g_iPlayMusic[id] = MUSIC_ENABLED;
        client_print_color(id, print_team_default, "%L", LANG_PLAYER, "ROUND_END_MUSIC_ON");
    }
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
    
    if(equal(section, "cts_wins")) {
        g_Section = CTSWins;
        return true;
    }
    
    if(equal(section, "terrorists_wins")) {
        g_Section = TerroristsWins;
        return true;
    }

    return false;
}

public bool:ReadCFGKeyValue(INIParser:handle, const key[], const value[]) {
    switch(g_Section) {
        case SectionNone: {
             return false;
        }
        case CTSWins: {
             PrecacheSoundEx(g_MusicForCT, key);
        }
        case TerroristsWins: {
             PrecacheSoundEx(g_MusicForTerrorist, key);
        }
    }

    return true;
}

bool:PrecacheSoundEx(Array:arr, const keys[]) {
    if((keys[0] && !IsWavFormat(keys)) && (keys[0] && !IsMp3Format(keys))) {
        log_amx("Invalid sound file! Parse string '%s'. Only sound files in wav or mp3 format should be used!", keys);
        return false;
    }
    static Sound[MAX_RESOURCE_PATH_LENGTH];
    formatex(Sound, charsmax(Sound), "sound/%s", keys);
    ArrayPushString(arr, Sound);
    if(!file_exists(Sound)) {
        log_amx("File missing '%s'.", Sound);
        return false;
    }
    if(IsMp3Format(keys)) {
        precache_generic(Sound);
    } else {
        precache_sound(keys);
    }

    return true;
}

PlayMusic(const sound[]) {
    new players[MAX_PLAYERS], count;
    get_players_ex(players, count, GetPlayers_ExcludeBots|GetPlayers_ExcludeHLTV);

    for(new i, id; i < count; i++) {
        id = players[i];
        if(g_iPlayMusic[id] == MUSIC_ENABLED){
            if(IsMp3Format(sound)) {
                client_cmd(id, "stopsound; mp3 play %s", sound);
            } else {
                rg_send_audio(id, sound);
            }
        }
    }
}
