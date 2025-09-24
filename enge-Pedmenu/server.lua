local QBCore = exports['qb-core']:GetCoreObject()

local function getDiscordIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('discord:') then
            return id:lower()
        end
    end
    return nil
end

local function isIn(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

local function resolveAllowedListForDiscord(discordId)
    if not discordId or not Config.AllowedByDiscord then return {} end
    local list = Config.AllowedByDiscord[discordId]
    if not list then return {} end

    -- '__all__' = všechny z Config.AllPeds
    for _, v in ipairs(list) do
        if v == '__all__' then
            return Config.AllPeds or {}
        end
    end
    return list
end

local function isPedInAllPeds(pedModel)
    local all = Config.AllPeds or {}
    if #all == 0 then
        -- Když není definovaný globální seznam, nevalidujeme podle něj
        return true
    end
    return isIn(all, pedModel)
end

local function isAllowedByDiscord(src, pedModel)
    pedModel = tostring(pedModel)
    local did = getDiscordIdentifier(src)
    if not did then return false end

    local allowedList = resolveAllowedListForDiscord(did)
    if #allowedList == 0 then return false end

    return isIn(allowedList, pedModel)
end

local function isPedAllowedForPlayer(src, pedModel)
    if not isPedInAllPeds(pedModel) then
        return false
    end
    if not isAllowedByDiscord(src, pedModel) then
        return false
    end
    return true
end

-- Vrátí klientovi jeho povolené pedy (průnik AllowedByDiscord a AllPeds)
QBCore.Functions.CreateCallback('warden-pedwhitelist:getAllowedPeds', function(source, cb)
    local did = getDiscordIdentifier(source)
    local allowed = resolveAllowedListForDiscord(did)
    local out = {}

    local all = Config.AllPeds or {}
    if #all == 0 then
        table.sort(allowed)
        cb(allowed)
        return
    end

    for _, ped in ipairs(allowed) do
        if isIn(all, ped) then
            out[#out+1] = ped
        end
    end

    table.sort(out)
    cb(out)
end)

-- Nastavení pedu (server gate) + perzistence
RegisterNetEvent('warden-pedwhitelist:server:setPed', function(pedModel)
    local src = source
    pedModel = tostring(pedModel or '')

    if pedModel == '' then
        TriggerClientEvent('warden-pedwhitelist:client:notify', src, 'Chybí model.', 'error')
        return
    end

    if isPedAllowedForPlayer(src, pedModel) then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.SetMetaData(Config.PersistMetaKey or 'warden_selected_ped', pedModel)
        end
        TriggerClientEvent('warden-pedwhitelist:client:applyPed', src, pedModel)
        TriggerClientEvent('warden-pedwhitelist:client:notify', src, ('Nastaven ped: %s'):format(pedModel), 'success')
    else
        TriggerClientEvent('warden-pedwhitelist:client:denyPed', src, pedModel, Config.FallbackModel or 'mp_m_freemode_01')
        TriggerClientEvent('warden-pedwhitelist:client:notify', src, 'Na tento ped nemáš oprávnění.', 'error')
    end
end)

-- Auto-aplikace pedu po připojení
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not (Config.ApplyOnPlayerLoaded) then return end
    local src = Player.PlayerData.source
    local key = Config.PersistMetaKey or 'warden_selected_ped'
    local savedPed = Player.PlayerData.metadata and Player.PlayerData.metadata[key]
    if not savedPed or savedPed == '' then return end

    -- pokud respektujeme freemode persistenci IA, freemode neaplikujeme vůbec
    if Config.RespectFreemodePersistence then
        if savedPed == 'mp_m_freemode_01' or savedPed == 'mp_f_freemode_01' then
            return
        end
    end

    TriggerClientEvent('warden-pedwhitelist:client:applyPed', src, savedPed)
end)
