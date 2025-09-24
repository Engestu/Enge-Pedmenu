-- Klient: menu přes ox_lib + okokNotify
local QBCore = exports['qb-core']:GetCoreObject()

-- okokNotify wrapper
local function okok(msg, typ)
    typ = typ or 'info'
    local notifyType = 'info'
    if typ == 'success' then notifyType = 'success' end
    if typ == 'error' then notifyType = 'error' end
    exports['okokNotify']:Alert(Config.NotifyTitle or 'PedWhitelist', msg, Config.NotifyDuration or 5000, notifyType)
end

RegisterNetEvent('warden-pedwhitelist:client:notify', function(msg, type)
    okok(msg, type)
end)

-- Aplikace a odmítnutí
RegisterNetEvent('warden-pedwhitelist:client:applyPed', function(pedModel)
    local model = tostring(pedModel)

    if Config.RespectFreemodePersistence then
        if model == 'mp_m_freemode_01' or model == 'mp_f_freemode_01' then
            -- freemode necháváme na Illenium-appearance (kvůli outfitům)
            return
        end
    end

    exports['illenium-appearance']:setPlayerModel(model)
end)

RegisterNetEvent('warden-pedwhitelist:client:denyPed', function(requestedModel, fallbackModel)
    exports['okokNotify']:Alert("PedWhitelist", ('Model "%s" zamítnut.'):format(requestedModel), 5000, 'error')
end)



-- /setped (ponecháno)
RegisterCommand('setped', function(_, args)
    local model = args[1]
    if not model or model == '' then
        okok('Použití: /setped <ped_model>', 'error')
        return
    end
    TriggerServerEvent('warden-pedwhitelist:server:setPed', model)
end, false)

-- /<MenuCommand> – konfigurovatelné v config.lua
CreateThread(function()
    local cmd = (Config and Config.MenuCommand) or 'wpedmenu'
    RegisterCommand(cmd, function()
        if not lib or not lib.registerContext then
            okok('ox_lib není dostupná. Ujisti se, že je resource @ox_lib spuštěná před tímto.', 'error')
            return
        end

        -- Hlavní menu
        lib.registerContext({
            id = 'warden_ped_main',
            title = 'Ped výběr',
            options = {
                {
                    title = 'Seznam povolených pedů',
                    description = 'Procházej podle stránek',
                    onSelect = function() TriggerEvent('warden-pedwhitelist:client:openPagedList') end
                },
                {
                    title = 'Hledat',
                    description = 'Vyhledávat podle části názvu',
                    onSelect = function() TriggerEvent('warden-pedwhitelist:client:openSearch') end
                }
            }
        })
        lib.showContext('warden_ped_main')
    end, false)
end)

-- Paginace seznamu
local function buildPageContext(list, page, perPage)
    local id = ('warden_ped_page_%d'):format(page)
    local title = ('Peds (%d–%d / %d)'):format((page-1)*perPage + 1, math.min(page*perPage, #list), #list)

    local options = {}
    local startIdx = (page-1)*perPage + 1
    local endIdx = math.min(page*perPage, #list)

    for i = startIdx, endIdx do
        local ped = list[i]
        options[#options+1] = {
            title = ped,
            description = 'Nastavit tento model',
            onSelect = function()
                TriggerServerEvent('warden-pedwhitelist:server:setPed', ped)
            end
        }
    end

    if page > 1 then
        options[#options+1] = {
            title = '← Předchozí',
            onSelect = function() lib.showContext(('warden_ped_page_%d'):format(page-1)) end
        }
    end
    if endIdx < #list then
        options[#options+1] = {
            title = 'Další →',
            onSelect = function() lib.showContext(('warden_ped_page_%d'):format(page+1)) end
        }
    end

    return { id = id, title = title, options = options }
end

RegisterNetEvent('warden-pedwhitelist:client:openPagedList', function()
    QBCore.Functions.TriggerCallback('warden-pedwhitelist:getAllowedPeds', function(list)
        if type(list) ~= 'table' or #list == 0 then
            okok('Nemáš žádné povolené pedy.', 'error')
            return
        end

        local perPage = (Config and Config.ItemsPerPage) or 15
        local totalPages = math.ceil(#list / perPage)
        for p = 1, totalPages do
            local ctx = buildPageContext(list, p, perPage)
            lib.registerContext(ctx)
        end
        lib.showContext('warden_ped_page_1')
    end)
end)

-- Vyhledávání
RegisterNetEvent('warden-pedwhitelist:client:openSearch', function()
    local input = lib.inputDialog('Vyhledat ped', {
        { type = 'input', label = 'Název (část)', placeholder = 'např. vinewood', required = true }
    })
    if not input or not input[1] then return end
    local needle = string.lower(input[1])

    QBCore.Functions.TriggerCallback('warden-pedwhitelist:getAllowedPeds', function(list)
        local filtered = {}
        for _, ped in ipairs(list or {}) do
            if string.find(string.lower(ped), needle, 1, true) then
                filtered[#filtered+1] = ped
            end
        end
        if #filtered == 0 then
            okok('Nic nenalezeno.', 'error'); return
        end

        local opts = {}
        for _, ped in ipairs(filtered) do
            opts[#opts+1] = { title = ped, onSelect = function() TriggerServerEvent('warden-pedwhitelist:server:setPed', ped) end }
        end
        lib.registerContext({ id = 'warden_ped_search', title = ('Výsledky (%d)'):format(#filtered), options = opts })
        lib.showContext('warden_ped_search')
    end)
end)
