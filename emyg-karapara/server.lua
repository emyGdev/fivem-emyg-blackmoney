local QBCore = exports['qb-core']:GetCoreObject()
local webhookURL = Config.WebhookURL
local webhookImage = Config.WebhookImage

-- Discord Webhook Gönderim Fonksiyonu
local function sendToDiscord(discordID, playerLicense, citizenID, blackMoney, cashAmount, saat)
    local embed = {
        {
            ["color"] = 3066993, -- Yeşil Renk
            ["title"] = "📊 EMY/SHOP Kara Para Log",
            ["description"] = string.format(
                "**👤 Kişi:** %s\n**🪪 CitizenID:** %s\n**🔑 FiveM Lisansı:** %s\n\n**💼 Kara Para Bilgileri:**\n💸 **Aklanan Kara Para:** %d\n💵 **Kazanılan Temiz Para:** %d\n\n🕒 **Saat:** %s",
                discordID and "<@" .. discordID .. ">" or "Bilinmeyen Oyuncu",
                citizenID, playerLicense, blackMoney, cashAmount, saat
            ),
            ["footer"] = {
                ["text"] = "EMY/SHOP Log Sistemi",
            },
            ["thumbnail"] = {
                ["url"] = webhookImage
            }
        }
    }

    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({
        embeds = embed,
        allowed_mentions = { parse = { "users" } }
    }), { ['Content-Type'] = 'application/json' })
end

-- Kara Para Kontrolü
QBCore.Functions.CreateCallback('emyg:server:checkBlackMoney', function(source, cb)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        local item = player.Functions.GetItemByName(Config.BlackMoneyItem)
        if item and item.amount > 0 then
            cb(true)
        else
            cb(false)
        end
    end
end)

-- Kara Para Aklama İşlemi
RegisterNetEvent('emyg:server:launderMoney')
AddEventHandler('emyg:server:launderMoney', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        local blackMoneyItem = player.Functions.GetItemByName(Config.BlackMoneyItem)
        if blackMoneyItem and blackMoneyItem.amount > 0 then
            local amount = blackMoneyItem.amount
            local cashAmount = math.floor(amount * Config.ConversionRate) -- Dönüşüm Oranı Uygulanıyor

            -- Kara Parayı Al
            player.Functions.RemoveItem(Config.BlackMoneyItem, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.BlackMoneyItem], "remove")

            -- Nakit Para Ver
            player.Functions.AddItem(Config.CashItem, cashAmount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.CashItem], "add")

            TriggerClientEvent('QBCore:Notify', src, string.format('%d adet kara para aklandı ve %d nakit para aldın!', amount, cashAmount), 'success')

            -- Discord Kullanıcı Bilgilerini Al
            local playerLicense = player.PlayerData.license
            local citizenID = player.PlayerData.citizenid
            local saat = os.date('%Y-%m-%d %H:%M:%S')

            -- Discord ID Alma
            local discordID = nil
            local identifiers = GetPlayerIdentifiers(src)
            for _, id in pairs(identifiers) do
                if string.find(id, "discord:") then
                    discordID = id:gsub("discord:", "")
                    break
                end
            end

            -- Discord Log Gönder
            sendToDiscord(discordID, playerLicense, citizenID, amount, cashAmount, saat)

        else
            TriggerClientEvent('QBCore:Notify', src, 'Yeterli kara paran yok!', 'error')
        end
    end
end)
