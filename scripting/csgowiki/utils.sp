// check handle function on/off
bool check_function_on(Handle: ghandle, char[] errorMsg, client = -1) {
    bool benable = GetConVarBool(ghandle) && GetConVarBool(g_hCSGOWikiEnable);
    if (!benable && client != -1) {
        PrintToChat(client, "%s %s", PREFIX, errorMsg);
    }
    return benable;
}

// check player valid
stock bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

stock bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}


int GetServerTickrate() {
    return RoundToZero(1.0 / GetTickInterval());
}

// convar handle function
Handle FindOrCreateConvar(char[] cvName, char[] cvDefault, char[] cvDescription, float fMin=-1.0, float fMax=-1.0) {
    Handle cvHandle = FindConVar(cvName);
    if (cvHandle == INVALID_HANDLE) {
        if (fMin == -1.0 && fMax == -1.0)
            cvHandle = CreateConVar(cvName, cvDefault, cvDescription);
        else if (fMin != -1.0 && fMax != -1.0)
            cvHandle = CreateConVar(cvName, cvDefault, cvDescription, _, true, fMin, true, fMax);
        else return INVALID_HANDLE;
    }
    return cvHandle;
}

// utils for utility submit
void GrenadeType_2_Tinyname(GrenadeType utCode, char[] utTinyName) {
    switch (utCode) {
    case GrenadeType_HE:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "grenade");
    case GrenadeType_Flash:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "flash");
    case GrenadeType_Smoke:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "smoke");
    case GrenadeType_Molotov:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "molotov");
    case GrenadeType_Incendiary:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "molotov");
    }
}

void Action_Int2Array(client, bool[] wikiAction) {
    for (new idx = 0; idx < CSGO_ACTION_NUM; idx++) {
        if (g_aActionRecord[client] & (1 << idx)) {
            switch(g_aCsgoActionMap[idx]) {
            case IN_JUMP:   wikiAction[e_wJump] = true;
            case IN_DUCK:   wikiAction[e_wDuck] = true;
            case IN_ATTACK: wikiAction[e_wLeftclick] = true;
            case IN_ATTACK2:    wikiAction[e_wRightclick] = true;
            case IN_MOVELEFT:   wikiAction[e_wRun] = true;
            case IN_MOVERIGHT:  wikiAction[e_wRun] = true;
            case IN_BACK:       wikiAction[e_wRun] = true;   
            case IN_FORWARD:    wikiAction[e_wRun] = true;
            case IN_SPEED:  wikiAction[e_wWalk] = true;
            }
        }
    }
    // post fix
    if (!wikiAction[e_wRun] && wikiAction[e_wWalk]) {
        wikiAction[e_wWalk] = false; // 没有移动只按shift
    }
    if (wikiAction[e_wRun] && wikiAction[e_wWalk]) {
        wikiAction[e_wRun] = false; // just shift
    }
    if (wikiAction[e_wRun] && wikiAction[e_wDuck]) {
        wikiAction[e_wWalk] = true;
        wikiAction[e_wRun] = false;
    }
    if (!(wikiAction[e_wRun] || wikiAction[e_wWalk] 
        || wikiAction[e_wJump] || wikiAction[e_wDuck])) {
        wikiAction[e_wStand] = true;
    }
}

void Action_Int2Str(client, char[] strAction) {
    bool wikiAction[CSGOWIKI_ACTION_NUM] = {};
    Action_Int2Array(client, wikiAction);
    char StrTemp[CSGOWIKI_ACTION_NUM][6] = {
        "跳 ", "蹲 ", "跑 ", "走 ", "站 ", "左键 ", "右键 "
    };
    for (new idx = 0; idx < CSGOWIKI_ACTION_NUM; idx ++) {
        if (!wikiAction[idx]) continue;
        StrCat(strAction, LENGTH_MESSAGE, StrTemp[idx]);
    }
}

void TicktagGenerate(char[] tickTag, const bool[] wikiAction) {
    strcopy(tickTag, LENGTH_STATUS, "64/128");
    if (wikiAction[e_wJump]) {
        IntToString(g_iServerTickrate, tickTag, LENGTH_STATUS);
    }
}

void Utility_TinyName2Zh(char[] utTinyName, char[] format, char[] zh) {
    if (StrEqual(utTinyName, "smoke")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "烟雾弹");
    }
    else if (StrEqual(utTinyName, "grenade")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "手雷");
    }
    else if (StrEqual(utTinyName, "flash")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "闪光弹");
    }
    else if (StrEqual(utTinyName, "molotov")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "燃烧弹");
    }
}

void Utility_TinyName2Weapon(char[] utTinyName, char[] weaponName, client) {
    if (StrEqual(utTinyName, "smoke")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_smokegrenade");
    }
    else if (StrEqual(utTinyName, "grenade")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_hegrenade");
    }
    else if (StrEqual(utTinyName, "flash")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_flashbang");
    }
    else if (StrEqual(utTinyName, "molotov")) {
        new teamFlag = GetClientTeam(client);
        if (CS_TEAM_T == teamFlag) {
            strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_molotov");
        }
        else if (CS_TEAM_CT == teamFlag){  // [TODO]  spec
            strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_incgrenade");
        }
    }
}

GrenadeType TinyName_2_GrenadeType(char[] utTinyName, client) {
    if (StrEqual(utTinyName, "smoke")) {
        return GrenadeType_Smoke;
    }
    else if (StrEqual(utTinyName, "grenade")) {
        return GrenadeType_HE;
    }
    else if (StrEqual(utTinyName, "flash")) {
        return GrenadeType_Flash;
    }
    else if (StrEqual(utTinyName, "molotov")) {
        new teamFlag = GetClientTeam(client);
        if (CS_TEAM_T == teamFlag) {
            return GrenadeType_Molotov;
        }
        else if (CS_TEAM_CT == teamFlag){  // [TODO]  spec
            return GrenadeType_Incendiary;
        }
    }
    return GrenadeType_None;
}


void ResetReqLock(pclient = -1) {
    if (pclient != -1) {
        g_aReqLock[pclient] = false;
        return;
    }
    for (new client = 0; client <= MAXPLAYERS; client++) {
        g_aReqLock[client] = false;
    }
}

// ----------------- hint color message fix --------------
UserMsg g_TextMsg, g_HintText, g_KeyHintText;
static char g_sSpace[1024];

void HintColorMessageFixStart() {
    for(int i = 0; i < sizeof g_sSpace - 1; i++) {
        g_sSpace[i] = ' ';
    }

    g_TextMsg = GetUserMessageId("TextMsg");
    g_HintText = GetUserMessageId("HintText");
    g_KeyHintText = GetUserMessageId("KeyHintText");

    HookUserMessage(g_TextMsg, TextMsgHintTextHook, true);
    HookUserMessage(g_HintText, TextMsgHintTextHook, true);
    HookUserMessage(g_KeyHintText, TextMsgHintTextHook, true);
}

Action TextMsgHintTextHook(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init) {
    static char sBuf[sizeof g_sSpace];
    if(msg_id == g_HintText) {
        msg.ReadString("text", sBuf, sizeof sBuf);
  	}
    else if(msg_id == g_KeyHintText) {
        msg.ReadString("hints", sBuf, sizeof sBuf, 0);
    }
    else if(msg.ReadInt("msg_dst") == 4) {
        msg.ReadString("params", sBuf, sizeof sBuf, 0);
    }
    else {
        return Plugin_Continue;
    }

    if(StrContains(sBuf, "<font") != -1 || StrContains(sBuf, "<span") != -1) {
        DataPack hPack = new DataPack();
        hPack.WriteCell(playersNum);
        for(int i = 0; i < playersNum; i++) {
            hPack.WriteCell(players[i]);
        }
        hPack.WriteString(sBuf);
        hPack.Reset();
        RequestFrame(TextMsgFix, hPack);
        return Plugin_Handled;
    }	
    return Plugin_Continue;
}

void TextMsgFix(DataPack hPack) {
    int iCount = hPack.ReadCell();
    static int iPlayers[MAXPLAYERS + 1];

    for(int i = 0; i < iCount; i++) {
        iPlayers[i] = hPack.ReadCell();
    }

    int[] newClients = new int[MaxClients];
    int newTotal = 0;

    for (int i = 0; i < iCount; i++) {
        int client = iPlayers[i];
        if (IsClientInGame(client)) {
            newClients[newTotal] = client;
            newTotal++;
        }
    }
    if (newTotal == 0) {
        delete hPack;
        return;
    }
    static char sBuf[sizeof g_sSpace];
    hPack.ReadString(sBuf, sizeof sBuf);
    delete hPack;

    Protobuf hMessage = view_as<Protobuf>(StartMessageEx(g_TextMsg, newClients, newTotal, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));

    if(hMessage) {
        hMessage.SetInt("msg_dst", 4);
        hMessage.AddString("params", "#SFUI_ContractKillStart");

        Format(sBuf, sizeof sBuf, "</font>%s%s", sBuf, g_sSpace);
        hMessage.AddString("params", sBuf);

        hMessage.AddString("params", NULL_STRING);
        hMessage.AddString("params", NULL_STRING);
        hMessage.AddString("params", NULL_STRING);
        hMessage.AddString("params", NULL_STRING);

        EndMessage();
    }
}