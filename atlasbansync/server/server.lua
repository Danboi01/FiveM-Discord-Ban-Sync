local function GetDiscordID(player)
    for i = 0, GetNumPlayerIdentifiers(player) - 1 do
        local identifier = GetPlayerIdentifier(player, i)
        if identifier and string.find(identifier, "discord:") then
            return identifier:match("discord:(%d+)")
        end
    end
    return nil
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    deferrals.defer()
    local src = source
    local discordId = GetDiscordID(src)

    if not Config.Token or not Config.GuildID then
        print("ERROR: Missing Discord Bot Token or Guild ID in Config!")
        deferrals.done("Server configuration error. Contact an administrator.")
        return
    end

    deferrals.update("Checking your ban status with the linked Discord...")

    if not discordId then
        if Config.RequireDiscordToJoin then
            deferrals.done("You must have a linked Discord account to join this server!")
        else
            deferrals.done() 
        end
        return
    end

    local banCheckUrl = string.format("https://discord.com/api/v10/guilds/%s/bans/%s", Config.GuildID, discordId)

    PerformHttpRequest(banCheckUrl, function(statusCode, resultData, resultHeaders)
        if statusCode == 200 then
            print("Player " .. name .. " (" .. discordId .. ") is banned from the Discord server.")
            deferrals.done(Config.BanMessage or "You are banned from this server.")
        elseif statusCode == 404 then
            print("Player " .. name .. " is not banned. Allowing connection.")
            deferrals.done() 
        elseif statusCode == 401 or statusCode == 403 then
            deferrals.done("Server configuration error. Contact an administrator.")
        else
            deferrals.done("Unable to verify ban status. Try again later.")
        end
    end, "GET", "", {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. Config.Token
    })
end)
