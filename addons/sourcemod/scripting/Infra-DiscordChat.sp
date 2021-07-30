#include <sourcemod>
#include <discord>
#include <basecomm>
#include <ripext>

#include "dcr/utils.sp"

ConVar g_cvWebhook;
ConVar g_cvChatHook;
ConVar g_cvSimpleMode;
ConVar g_cvSteamAPIKey;
ConVar g_cvDebug;
HTTPClient httpClient;
char g_szSteamAvatar[MAXPLAYERS + 1][256];

public Plugin myinfo = 
{
	name = "Infra's Simple Discord Chat Relay",
	author = "Infra",
	description = "Simple plugin to relay in-game text chat to a webhook!", 
	version = "1.0.0", 
	url = "https://github.com/1zc"
};

public void OnPluginStart()
{   
    g_cvChatHook = CreateConVar("infra_dcr_enable", "0", "Toggle whether the plugin is enabled. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);
    g_cvSimpleMode = CreateConVar("infra_dcr_simple", "0", "Toggle simple chat webook mode. 1 = Simple, 0 = Modern.", _, true, 0.0, true, 1.0);
    g_cvDebug = CreateConVar("infra_dcr_debug", "0", "Toggle debug mode. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);
    g_cvWebhook = CreateConVar("infra_dcr_webhook_url", "", "Webhook URL to relay chats to.", FCVAR_PROTECTED);
    g_cvSteamAPIKey = CreateConVar("infra_dcr_steamAPI_key", "", "Steam Web API key.", FCVAR_PROTECTED);

    AutoExecConfig(true, "Infra-DiscordChat");
}

public void OnConfigsExecuted()
{
    if (httpClient != null)
    	delete httpClient;
    
    httpClient = new HTTPClient("https://api.steampowered.com");
}

public void OnClientPostAdminCheck(int client)
{
    GetProfilePic(client);
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] argText)
{
    if (!g_cvChatHook.BoolValue)
    {
        if (g_cvDebug.BoolValue)
        {
            PrintToConsole(0, "[Infra-DCR] DEBUG: Plugin not enabled in config, aborting. (infra_dcr_enable = 0)");
        }
        return;
    }

    if (client > 0) // Check if client is NOT console.
    {
        if (BaseComm_IsClientGagged(client) || IsChatTrigger()) // Check if client is gagged. || Check if text was a recognized command/trigger.
        {
            if (g_cvDebug.BoolValue)
            {
                PrintToConsole(0, "[Infra-DCR] DEBUG: Client %i is gagged or used a chat trigger, aborting.", client);
            }
            return;
        }
    }
    
    // Prep the message before processing.
    char messageTxt[256];
    Format(messageTxt, sizeof(messageTxt), argText);
    StripQuotes(messageTxt);
    TrimString(messageTxt);
    // Time to sanitise.
    SanitiseText(messageTxt);

    // Is the resultant string blank?
    if (StrEqual(messageTxt, "") || StrEqual(messageTxt, " "))
    {
        if (g_cvDebug.BoolValue)
        {
            PrintToConsole(0, "[Infra-DCR] DEBUG: Client %i sent a blank message, aborting.", client);
        }
        return;
    }

    // Away it goes!
    if (g_cvSimpleMode.BoolValue)
        sendSimpleWebhook(client, messageTxt);
    else
        sendWebhook(client, messageTxt);
}

void sendWebhook(int client, char[] text)
{
    char webhook[1024], finalText[512], clientName[128], steamID[64];
    GetConVarString(g_cvWebhook, webhook, sizeof(webhook));
    if (StrEqual(webhook, ""))
	{
        LogError("[Infra-DCR] WebhookURL was not configured, aborting.");
        return;
	}

    if (client == 0)
    {
        Format(clientName, sizeof(clientName), "CONSOLE")
        Format(steamID, sizeof(steamID), "-");
    }

    else
    {
        GetClientName(client, clientName, sizeof(clientName));
        GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID), true);
        Format(clientName, sizeof(clientName), "%s (%s)", clientName, steamID);
    }

    ReplaceString(clientName, 32, "@", "", false);
    ReplaceString(clientName, 32, "\\", "", false);
    ReplaceString(clientName, 32, "`", "", false);

    Format(finalText, sizeof(finalText), "`%s`", text);

    DiscordWebHook hook = new DiscordWebHook(webhook);
    hook.SlackMode = true;
    hook.SetContent(finalText);
    hook.SetUsername(clientName);
    if (!StrEqual(g_szSteamAvatar[client], "NULL", false)) //&& !StrEqual(g_szSteamAvatar[client], "", false))
    {
        if (g_cvDebug.BoolValue)
        {
            PrintToConsole(0, "[Infra-DCR] DEBUG: Client %i has an avatar, using it! URL: %s", client, g_szSteamAvatar[client]);
        }
        hook.SetAvatar(g_szSteamAvatar[client]);
    }
    hook.Send();
    delete hook;
}

void sendSimpleWebhook(int client, char[] text)
{
    char webhook[1024], finalText[512], clientName[32], steamID[64];
    GetConVarString(g_cvWebhook, webhook, sizeof(webhook));
    if (StrEqual(webhook, ""))
	{
        LogError("[Infra-DCR] WebhookURL was not configured. Aborting.");
        return;
	}

    if (client == 0)
    {
        Format(clientName, sizeof(clientName), "CONSOLE")
        Format(steamID, sizeof(steamID), "-");
    }

    else
    {
        GetClientName(client, clientName, sizeof(clientName));
        GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID), true);
    }

    ReplaceString(clientName, 32, "@", "", false);
    ReplaceString(clientName, 32, "\\", "", false);
    ReplaceString(clientName, 32, "`", "", false);

    Format(finalText, sizeof(finalText), "%s (`%s`): `%s`", clientName, steamID, text);

    DiscordWebHook hook = new DiscordWebHook(webhook);
    hook.SlackMode = true;
    hook.SetContent(finalText);
    hook.Send();
    delete hook;
}

void GetProfilePic(int client)
{
    char szRequestBuffer[1024], szSteamID[64], szAPIKey[256];

    GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof(szSteamID), true);
    GetConVarString(g_cvSteamAPIKey, szAPIKey, sizeof(szAPIKey));
    if (StrEqual(szAPIKey, "", false))
    {
        PrintToConsole(0, "[Infra-DCR] ERROR: Steam API Key not configured. Falling back to DCR Simple Mode.");
        g_cvSimpleMode.BoolValue = true;
        return;
    }

    Format(szRequestBuffer, sizeof szRequestBuffer, "ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=json", szAPIKey, szSteamID);
    httpClient.Get(szRequestBuffer, GetProfilePicCallback, client);
}

public void GetProfilePicCallback(HTTPResponse response, any client)
{
    if (response.Status != HTTPStatus_OK) 
    {
        FormatEx(g_szSteamAvatar[client], sizeof(g_szSteamAvatar[]), "NULL");
        PrintToConsole(0, "[Infra-DCR] ERROR: Failed to reach SteamAPI. Status: %i", response.Status);
        return;
    }

    JSONObject objects = view_as<JSONObject>(response.Data);
    JSONObject Response = view_as<JSONObject>(objects.Get("response"));
    JSONArray players = view_as<JSONArray>(Response.Get("players"));
    int playerlen = players.Length;
    if (g_cvDebug.BoolValue)
    {
        PrintToConsole(0, "[Infra-DCR] DEBUG: Client %i SteamAPI Response Length: %i", client, playerlen);
    }

    JSONObject player;
    for (int i = 0; i < playerlen; i++)
    {
        player = view_as<JSONObject>(players.Get(i));
        player.GetString("avatarfull", g_szSteamAvatar[client], sizeof(g_szSteamAvatar[]));
        if (g_cvDebug.BoolValue)
        {
            PrintToConsole(0, "[Infra-DCR] DEBUG: Client %i has Avatar URL: %s", client, g_szSteamAvatar[client]);
        }
        delete player;
    }
}