#pragma semicolon 1

#include <amxmodx>
#include <reapi>

public plugin_init() {
    register_plugin("[ReAPI] Info Killer", "0.0.6", "Jumper");

    RegisterHookChain(RG_CSGameRules_DeathNotice, "CSGameRules_DeathNotice", true);
}

public CSGameRules_DeathNotice(const iVictim, const iKiller, pevInflictor) {
    if(iVictim == iKiller || !is_user_connected(iKiller) || !rg_is_player_can_takedamage(iVictim, iKiller)) {
        return HC_CONTINUE;
    }

    client_print_color(iVictim, iKiller, "^4* ^1Вас убил ^3%n^1, у него осталось ^4%.0f ^1HP", iKiller, Float:get_entvar(iKiller, var_health));

    return HC_CONTINUE;
}
