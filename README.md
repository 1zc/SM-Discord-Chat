# Infra's Simple Discord Chat Relay for SourceMod

Simple SourceMod plugin that logs chats to Discord via webhooks. Not everything needs to be complicated! Tested on CS:GO and TF2.

## Webhook Styles:

The plugin features two webhook styles, one super simple style suited for logging and the other looking slighly prettier. Styles can be configured in `cfg/sourcemod/Infra-DiscordChat.cfg` using the `infra_dcr_simple` variable.

Pretty Style (`infra_dcr_simple "0"`):

![Pretty Style](https://infra.s-ul.eu/prjXi6Df)

Simple Style (`infra_dcr_simple "1"`):

![Simple Style](https://infra.s-ul.eu/75UIvxUK)

If you are looking to use this plugin purely to log chats, I recommend using the simple style. While it may not be as pretty as the other option, it makes searching SteamIDs in Discord possible. 

## How to Install:

- Clone the repository by hitting the big green download code button at the top.
- Extract the ZIP file to your game-directory folder (Eg: csgo/) on your server.

## How to Configure:

All configuration is done in `cfg/sourcemod/Infra-DiscordChat.cfg`. 

### Setting up `infra_dcr_webhook_url`:
The plugin needs a WebHook URL from Discord to be able to send chat messages to. Follow the steps below if you are unsure how this can be done:

* ***Step 1:*** Edit a channel > enter the Webhooks section inside the Integrations sub-menu > Make a new webhook.
* ***Step 2:*** Customize your new webhook! I recommend naming it according to the server you're going to use the webhook for, and adding an avatar related to your servers. (Making separate webhooks, accordingly named, for each server you host is a great way to identify what server a chat message was sent in!)
* ***Step 3:*** Copy your webhook URL, go back to `Infra-DiscordChat.cfg`, and send `infra_dcr_webhook_url` to your webhook URL.

![Webhook Setup](https://infra.s-ul.eu/PGIRZY4W)

### Setting up `infra_dcr_steamAPI_key`:
The plugin uses a SteamAPI key to access the Steam Web API to get player's profile pictures. This is an optional ConVar, disabling it will default the plugin to the simple webhook style since it can't pull profile pictures.

You can get your SteamAPI key here: https://steamcommunity.com/dev/apikey (**DO NOT SHARE THIS KEY WITH ANYONE.**)
