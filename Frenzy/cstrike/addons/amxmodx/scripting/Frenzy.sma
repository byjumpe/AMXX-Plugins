#pragma semicolon 1

#include <amxmodx>
#include <reapi>

new g_iFrenzy, bool:g_bFrenzy[MAX_PLAYERS +1], Float:g_fEnableHP, Float:g_fSpeed, Float:g_fDamage;
new g_iMsgScreenFade;

new const SOUND_FRENZY[] = "frenzy.wav";

public plugin_init() {
    register_plugin("[ReAPI] Frenzy", "0.0.6", "Jumper");

    register_event("Health", "Event_Health", "be", "1>0");

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage_Pre");
    RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre");
    RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage_Post", .post = true);
    RegisterHookChain(RG_CSGameRules_DeathNotice, "CSGameRules_DeathNotice_Post", .post = true);
    RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "CBasePlayer_ResetMaxSpeed_Post", .post = true);

    g_iMsgScreenFade = get_user_msgid("ScreenFade");
}

public plugin_precache() {
    precache_sound(SOUND_FRENZY);
}

public plugin_cfg() {
    bind_pcvar_num(create_cvar("frenzy", "1", .description = "Вкл/Выкл Ярость"), g_iFrenzy);
    bind_pcvar_float(create_cvar("frenzy_hp", "15.0", .description = "Количество HP для активации Ярости"), g_fEnableHP);
    bind_pcvar_float(create_cvar("frenzy_speed", "320.0", .description = "Скорость передвижения игрока при активации Ярости"), g_fSpeed);
    bind_pcvar_float(create_cvar("frenzy_damage", "2.0", .description = "Во сколько раз увеличивать урон при активации Ярости"), g_fDamage);

    AutoExecConfig(true, "Frenzy");
}

public client_putinserver(id) {
    g_bFrenzy[id] = false;
    rg_reset_maxspeed(id);
}

public CBasePlayer_TakeDamage_Post(const iVictim, pevInflictor, iAttacker, Float:fDamage, bitsDamageType) {
    if(iVictim == iAttacker || !is_user_connected(iAttacker) || !rg_is_player_can_takedamage(iVictim, iAttacker)) {
        return HC_CONTINUE;
    }

    new Float:fVictimHP = get_entvar(iVictim, var_health);

    if(fVictimHP <= g_fEnableHP && fVictimHP > 0.0 && !g_bFrenzy[iVictim] && g_iFrenzy == 1) {
        set_entvar(iVictim, var_renderfx, kRenderFxGlowShell);
        set_entvar(iVictim, var_rendercolor, Float:{ 255.0, 0.0, 0.0 });
        set_entvar(iVictim, var_renderamt, 15.0); 
        set_entvar(iVictim, var_maxspeed, g_fSpeed);
        ScreenFade(iVictim);
        rh_emit_sound2(iVictim, 0, CHAN_AUTO, SOUND_FRENZY);

        g_bFrenzy[iVictim] = true;
    }

    return HC_CONTINUE;
}

public CBasePlayer_TakeDamage_Pre(const iVictim, pevInflictor, iAttacker, Float:fDamage, bitsDamageType) {
    if(pevInflictor == iAttacker || iVictim == iAttacker || !is_user_connected(iAttacker) || !rg_is_player_can_takedamage(iVictim, iAttacker)) {
        return HC_CONTINUE;
    }

    if(g_bFrenzy[iAttacker]) {
            SetHookChainArg(4, ATYPE_FLOAT, fDamage * g_fDamage);
    }

    return HC_CONTINUE;
}

public CSGameRules_RestartRound_Pre() {
    for(new id = 1; id <= MaxClients; id++) {
        if(g_bFrenzy[id] && g_iFrenzy == 1) {
            DisableFrenzy(id);
        }
    }
}

public Event_Health(id) {
    new iHealth = read_data(1);

    if(g_bFrenzy[id] && iHealth > floatround(g_fEnableHP) && g_iFrenzy == 1) {
        DisableFrenzy(id);
    }
}

public CSGameRules_DeathNotice_Post(const iVictim, const iKiller, pevInflictor) {
    if(g_bFrenzy[iVictim] && g_iFrenzy == 1) {
        DisableFrenzy(iVictim);
    }
}

public CBasePlayer_ResetMaxSpeed_Post(id) {
    if(g_bFrenzy[id] && g_iFrenzy == 1){
        set_entvar(id, var_maxspeed, g_fSpeed);
    }
}

ScreenFade(id) {
    message_begin(MSG_ONE, g_iMsgScreenFade, {0, 0, 0}, id);
    write_short(1<<10);
    write_short(1<<10);
    write_short(0x0000);
    write_byte(255);  // R
    write_byte(0);    // G       
    write_byte(0);    // B       
    write_byte(50);   // Alpha    
    message_end(); 
}

DisableFrenzy(id) {
    set_entvar(id, var_renderfx, kRenderFxNone);
    g_bFrenzy[id] = false;
    rg_reset_maxspeed(id);
}
