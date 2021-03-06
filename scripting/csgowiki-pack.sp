// 
#include "global_define.inc"

#include "csgowiki/utils.sp"
#include "csgowiki/menus.sp"

#include "csgowiki/steam_bind.sp"
#include "csgowiki/server_monitor.sp"
#include "csgowiki/utility_submit.sp"
#include "csgowiki/utility_wiki.sp"
#include "csgowiki/utility_modify.sp"
#include "csgowiki/kicker.sp"
#include "csgowiki/qqchat.sp"

public Plugin:myinfo = {
    name = "[CSGO Wiki] Plugin-Pack",
    author = "CarOL",
    description = "Provide interactive method between www.csgowiki.top and game server",
    version = "v1.2.0",
    url = "https://github.com/hx-w/CSGOWiki-Plugins"
};

public OnPluginStart() {
    // event
    HookEvent("hegrenade_detonate", Event_HegrenadeDetonate);
    HookEvent("flashbang_detonate", Event_FlashbangDetonate);
    HookEvent("smokegrenade_detonate", Event_SmokegrenadeDetonate);
    HookEvent("molotov_detonate", Event_MolotovDetonate);

    // command define
    RegConsoleCmd("sm_bsteam", Command_BindSteam);
    RegConsoleCmd("sm_submit", Command_Submit);
    RegConsoleCmd("sm_wiki", Command_Wiki);
    RegConsoleCmd("sm_modify", Command_Modify);
    RegConsoleCmd("sm_abort", Command_SubmitAbort);

    RegConsoleCmd("sm_proround", Command_ProRound);

    RegConsoleCmd("sm_qq", Command_QQchat);

    RegAdminCmd("sm_vel", Command_Velocity, ADMFLAG_GENERIC);

    // global timer
    CreateTimer(10.0, ServerMonitorTimerCallback, _, TIMER_REPEAT);

    // post fix
    g_iServerTickrate = GetServerTickrate();

    HintColorMessageFixStart();

    // convar
    g_hWikiAutoThrow = FindOrCreateConvar("sm_wiki_auto_throw", "1", "Set whether auto throw grenade when `!wiki` triggered");
    g_hWikiAutoKicker = FindOrCreateConvar("sm_wiki_auto_kick", "0", "Set how long(min) can the player stay in server without binding csgowiki account. Set 0 to disable this kicker", 0.0, 10.0);
    g_hCSGOWikiEnable = FindOrCreateConvar("sm_csgowiki_enable", "0", "Set wether enable csgowiki plugins or not. Set 0 will disable all modules belong to CSGOWiki.");
    g_hOnUtilitySubmit = FindOrCreateConvar("sm_utility_submit_on", "1", "Set module: <utility_submit> on/off.");
    g_hOnUtilityWiki = FindOrCreateConvar("sm_utility_wiki_on", "1", "Set module: <utility_wiki> on/off.");
    g_hOnServerMonitor = FindOrCreateConvar("sm_server_monitor_on", "0", "Set module: <server_monitor> on/off");
    g_hCSGOWikiToken = FindOrCreateConvar("sm_csgowiki_token", "", "Make sure csgowiki token valid. Some modules will be disabled if csgowiki token invalid");
    g_hWikiReqLimit = FindOrCreateConvar("sm_wiki_request_limit", "1", "Limit cooling time(second) for each player's `!wiki` request. Set 0 to unlimit", 0.0, 10.0);
    g_hChannelEnable = FindOrCreateConvar("sm_qqchat_enable", "0", "Set wether enable qqchat or not, use `!qq <msg>` trigger qqchat when convar set 1");
    g_hChannelServerRemark = FindOrCreateConvar("sm_qqchat_remark", "", "Set server name shown in qqchat");
    g_hChannelQQgroup = FindOrCreateConvar("sm_qqchat_qqgroup", "", "Bind qqgroup id to this server. ONE qqgroup only");

    AutoExecConfig(true, "csgowiki-pack");
}

public OnMapStart() {
    g_iServerTickrate = GetServerTickrate();
    GetCurrentMap(g_sCurrentMap, LENGTH_MAPNAME);

    // reset for map start
    ResetUtilitySubmitState();
    ResetUtilityWikiState();
    ResetReqLock();

    // init collection
    GetAllCollection();

    // channel chat timer
    if (GetConVarBool(g_hChannelEnable)) {
        CreateTimer(1.0, ChannelPullTimerCallback, _, TIMER_REPEAT);
    }
}

public OnClientPutInServer(client) {

    // timer define
    if (IsPlayer(client) && GetConVarBool(g_hCSGOWikiEnable)) {
        CreateTimer(3.0, QuerySteamTimerCallback, client);
    }
    ResetSingleClientWikiState(client);
    ResetSingleClientSubmitState(client);
    ClearPlayerToken(client);
    ResetReqLock(client);
    updateServerMonitor();
}

public OnClientDisconnect(client) {

    ResetSingleClientSubmitState(client);
    updateServerMonitor(-1);
    ClearPlayerToken(client);
    ResetReqLock(client);
    // reset bind_flag
    ResetSteamBindFlag(client);
}

public OnPluginEnd() {
    updateServerMonitor(-1);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[DATA_DIM], Float:angles[DATA_DIM], &weapon) {
    // for utility submit
    if (!buttons) return;
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        OnPlayerRunCmdForUtilitySubmit(client, buttons);
    }
}

public Action:Event_HegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_HegrenadeDetonateForUtilitySubmit(event);
    }
}



public Action:Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_FlashbangDetonateForUtilitySubmit(event);
    }
}


public Action:Event_SmokegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_SmokegrenadeDetonateForUtilitySubmit(event);
    }
}



public Action:Event_MolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast) { 
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_MolotovDetonateForUtilitySubmit(event);
    }
}