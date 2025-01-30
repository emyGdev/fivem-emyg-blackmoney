local QBCore = exports['qb-core']:GetCoreObject()

-- NPC Oluşturma ve qb-target Entegrasyonu
CreateThread(function()
    for _, npc in pairs(Config.NPCs) do
        RequestModel(npc.model)
        while not HasModelLoaded(npc.model) do Wait(1) end

        local ped = CreatePed(4, npc.model, npc.coords.x, npc.coords.y, npc.coords.z - 1.0, npc.heading, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    icon = 'fas fa-money-bill-wave',
                    label = npc.label,
                    action = function()
                        TriggerEvent('emyg:client:launderMoney')
                    end
                }
            },
            distance = 2.5
        })
    end
end)

-- Kara Para Aklama İşlemi
RegisterNetEvent('emyg:client:launderMoney', function()
    QBCore.Functions.TriggerCallback('emyg:server:checkBlackMoney', function(hasBlackMoney)
        if hasBlackMoney then
            QBCore.Functions.Progressbar('launder_money', 'Kara Para Aklanıyor...', Config.ProgressTime, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = Config.Animation.dict,
                anim = Config.Animation.anim,
                flags = 49,
            }, {}, {}, function() -- İşlem tamamlandı
                TriggerServerEvent('emyg:server:launderMoney')
                ClearPedTasks(PlayerPedId())
            end, function() -- İptal edildi
                ClearPedTasks(PlayerPedId())
                QBCore.Functions.Notify('İşlem iptal edildi!', 'error')
            end)
        else
            QBCore.Functions.Notify('Yeterli kara paran yok!', 'error')
        end
    end)
end)
