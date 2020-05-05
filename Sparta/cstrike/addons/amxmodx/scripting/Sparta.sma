#pragma semicolon 1

#include <amxmodx>
#include <reapi>

// Количество убийств подряд с ножа
stock const KILLS = 5;

// Цвет HUD'a
stock const HUD_R = 250;
stock const HUD_G = 250;
stock const HUD_B = 250;

// Позиция HUD'a
const Float: HUD_X = -1.0;
const Float: HUD_Y = 0.25;

// Длительность отображения HUD
const Float: HUD_TIME = 5.0;

// Звук
new const SPARTA_SOUND[] = "Sparta/this_is_sparta.wav";

new g_iKnifeKillStreak[MAX_PLAYERS +1], g_iMsgHudSync;

public plugin_init() {
    register_plugin("[ReAPI] This is Sparta", "0.0.1", "Jumper");

    RegisterHookChain(RG_CSGameRules_DeathNotice, "CSGameRules_DeathNotice", true);

    g_iMsgHudSync = CreateHudSyncObj();
}

public plugin_precache() {
    precache_sound(SPARTA_SOUND);
}

public client_disconnected(iPlayer) {
    g_iKnifeKillStreak[iPlayer] = 0;
}

public CSGameRules_OnRoundFreezeEnd_Pre() {
    arrayset(g_iKnifeKillStreak, 0, sizeof(g_iKnifeKillStreak));
}

public CSGameRules_DeathNotice(const iVictim, const iKiller, pevInflictor){
    if(iVictim == iKiller || !is_user_connected(iKiller) || !rg_is_player_can_takedamage(iVictim, iKiller)) {
        return HC_CONTINUE;
    }

    set_hudmessage(HUD_R, HUD_G, HUD_B, HUD_X, HUD_Y, 0, 0.0, HUD_TIME);

    if(iKiller == pevInflictor && WeaponIdType:get_member(get_member(iKiller, m_pActiveItem), m_iId) == WEAPON_KNIFE) {
        g_iKnifeKillStreak[iKiller]++;

        if(g_iKnifeKillStreak[iKiller] == KILLS) {
            rg_send_audio(0, SPARTA_SOUND, PITCH_NORM);
            ShowSyncHudMsg(0, g_iMsgHudSync, "%n: This is Spartaaaaaa!", iKiller);
            g_iKnifeKillStreak[iKiller] = 0;
        }
    }
    g_iKnifeKillStreak[iVictim] = 0;

    return HC_CONTINUE;
}