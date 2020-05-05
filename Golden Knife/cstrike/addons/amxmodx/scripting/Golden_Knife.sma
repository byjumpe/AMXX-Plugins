#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#define VIP ADMIN_LEVEL_H

enum _:MODEL_NUM {
    V_MODEL,
    P_MODEL
};

new const g_szModels[MODEL_NUM][] = {
    "models/GoldenKhife/v_golden_knife.mdl", 
    "models/GoldenKhife/p_golden_knife.mdl" 
};

public plugin_init() {
    register_plugin("[ReAPI] Gold Knife", "0.0.1", "Jumper");
    RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham_Item_Deploy_Post", true);
}

public plugin_precache() {
    for(new i; i < MODEL_NUM; i++){
        precache_model(g_szModels[i]);
    }
}

public Ham_Item_Deploy_Post(weapon) {
    new id = get_member(weapon, m_pPlayer);
    if(!is_user_connected(id)) {
        return HAM_IGNORED;
    }
    if(!(get_user_flags(id) & VIP)) {
        return HAM_IGNORED;
    }

    set_entvar(id, var_viewmodel, g_szModels[V_MODEL]);
    set_entvar(id, var_weaponmodel, g_szModels[P_MODEL]);

    return HAM_IGNORED;
}
