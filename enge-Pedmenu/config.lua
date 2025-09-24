Config = Config or {}

-- QBCore metadata klíč (perzistence)
Config.PersistMetaKey = 'warden_selected_ped'

-- Fallback model
Config.FallbackModel = 'mp_m_freemode_01' -- nebo 'mp_f_freemode_01'

-- Auto-aplikace po připojení
Config.ApplyOnPlayerLoaded = true

-- ox_lib menu – položek na stránku
Config.ItemsPerPage = 15

-- Název příkazu pro otevření menu (změň, pokud /pedmenu už používá jiný resource)
Config.MenuCommand = 'wpedmenu'   -- např. 'modelmenu', 'vipmenu', ...

-- okokNotify nastavení
Config.NotifyTitle = 'PedWhitelist'
Config.NotifyDuration = 5000 -- ms

-- Whitelist čistě přes Discord ID:
-- ['discord:ID'] = { '__all__' } nebo konkrétní seznam pedů
Config.AllowedByDiscord = {
    -- ['discord:111111111111111111'] = { '__all__' },
    -- ['discord:222222222222222222'] = { 'ig_lestercrest', 'ig_billionaire' },
}

-- Když je true, náš skript nikdy neaplikuje freemode modely
-- (mp_m_freemode_01 / mp_f_freemode_01) a nechá to čistě na IA persistenci.
Config.RespectFreemodePersistence = true
