#include <sourcemod>
#include <csutils>
#include <sdktools>
#include <cstrike>
#include <system2>
#include <json>

#define PREFIX "\x01[\x05CSGO Wiki\x01]"

#define LENGTH_TOKEN 33
#define LENGTH_STEAMID64 20 // 17 for usuall
#define LENGTH_STATUS 7
#define LENGTH_NAME 33
#define LENGTH_IP 17
#define LENGTH_SERVER_MONITOR 512
#define LENGTH_MAPNAME 12
#define LENGTH_UTILITY_FULL 13
#define LENGTH_UTILITY_TINY 8
#define LENGTH_UTILITY_ZH 24
#define LENGTH_UTILITY_ID 7
#define LENGTH_UTILITY_BRIEF 41
#define LENGTH_MESSAGE 128
#define DATA_DIM 3

#define CSGO_ACTION_NUM 9
#define CSGOWIKI_ACTION_NUM 7

// 功能开关  steambind 不能关闭
Handle g_hCSGOWikiEnable = INVALID_HANDLE;
Handle g_hOnUtilitySubmit = INVALID_HANDLE;
Handle g_hOnUtilityWiki = INVALID_HANDLE;
Handle g_hOnServerMonitor = INVALID_HANDLE;
Handle g_hWikiReqLimit = INVALID_HANDLE;
Handle g_hWikiAutoKicker = INVALID_HANDLE;
Handle g_hChannelEnable = INVALID_HANDLE;
Handle g_hChannelServerRemark = INVALID_HANDLE;
Handle g_hChannelQQgroup = INVALID_HANDLE;
Handle g_hWikiAutoThrow = INVALID_HANDLE;
// wiki token
new Handle: g_hCSGOWikiToken;

// 地图 tick信息
char g_sCurrentMap[LENGTH_MAPNAME];
int g_iServerTickrate;

// --------- steam_bind.sp define -----------
enum StateBind {
    e_bUnknown = 0,
    e_bUnbind = 1,
    e_bBinded = 2
};

StateBind g_aPlayerStateBind[MAXPLAYERS + 1];

// --------- utility_submit.sp define -----------
enum StateClient {
    e_cDefault = 0,
    e_cThrowReady = 1,
    e_cThrowEnd = 2,
    e_cAlreadyThrown = 3,
    e_cM_ThrowReady = 4,
    e_cM_ThrowEnd = 5,
    e_cM_AlreadyThrown = 6,
    e_cV_ThrowReady = 7
}


enum WikiAction {
    e_wJump = 0,
    e_wDuck = 1,
    e_wRun = 2,
    e_wWalk = 3,
    e_wStand = 4,
    e_wLeftclick = 5,
    e_wRightclick = 6
}


new g_aCsgoActionMap[CSGO_ACTION_NUM] = {
    IN_JUMP, IN_DUCK, IN_ATTACK, IN_ATTACK2, 
    IN_MOVELEFT, IN_MOVERIGHT, IN_FORWARD, IN_BACK, IN_SPEED
};

StateClient g_aPlayerStatus[MAXPLAYERS + 1];
// data for utility record
GrenadeType g_aUtilityType[MAXPLAYERS + 1];
float g_aStartPositions[MAXPLAYERS + 1][DATA_DIM];
float g_aStartAngles[MAXPLAYERS + 1][DATA_DIM];
float g_aThrowPositions[MAXPLAYERS + 1][DATA_DIM];
float g_aEndspotPositions[MAXPLAYERS + 1][DATA_DIM];
float g_aUtilityVelocity[MAXPLAYERS + 1][DATA_DIM];

float g_aUtilityAirtime[MAXPLAYERS + 1];
int g_aActionRecord[MAXPLAYERS + 1];    // encoded


// ------------- utility_wiki.sp define -----------
JSON_Array g_jaUtilityCollection;
JSON_Object g_joProMatchInfo;
JSON_Array g_jaProUtilityInfo;
char g_aLastUtilityId[MAXPLAYERS + 1][LENGTH_UTILITY_ID];
JSON_Array g_aUtFilterCollection[MAXPLAYERS + 1];
bool g_aReqLock[MAXPLAYERS + 1];

// ------------- utility_modify.sp define ------------
char g_aPlayerToken[MAXPLAYERS + 1][LENGTH_TOKEN];
