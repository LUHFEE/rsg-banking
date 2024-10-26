local spawnedPeds = {}
lib.locale()

local function NearNPC(npcmodel, npccoords, heading)
    local spawnedPed = CreatePed(npcmodel, npccoords.x, npccoords.y, npccoords.z - 1.0, heading, false, false, 0, 0)
    SetEntityAlpha(spawnedPed, 0, false)
    SetRandomOutfitVariation(spawnedPed, true)
    SetEntityCanBeDamaged(spawnedPed, false)
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    -- set relationship group between npc and player
    SetPedRelationshipGroupHash(spawnedPed, GetPedRelationshipGroupHash(spawnedPed))
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedPed), `PLAYER`)

    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedPed, i, false)
        end
    end

    return spawnedPed
end

CreateThread(function()
    for k,v in pairs(Config.BankLocations) do
        local coords = v.npccoords
        local newpoint = lib.points.new({
            coords = coords,
            heading = coords.w,
            distance = Config.DistanceSpawn,
            model = v.npcmodel,
            name = v.name,
            ped = nil,
            bankid = v.bankid
        })

        newpoint.onEnter = function(self)
            if not self.ped then
                lib.requestModel(self.model, 10000)
                self.ped = NearNPC(self.model, self.coords, self.heading)

                pcall(function ()
                    if Config.UseTarget then
                        exports['rsg-target']:AddTargetEntity(self.ped, {
                            options = {
                                {
                                    icon = 'fa-solid fa-eye',
                                    label = locale('cl_lang_1') ,
                                    targeticon = 'fa-solid fa-eye',
                                    action = function()
                                        TriggerEvent('rsg-banking:client:OpenBanking', self.bankid)
                                    end
                                },
                            },
                            distance = 4.0,
                        })

                    end
                end)
            end
        end

        newpoint.onExit = function(self)
            exports['rsg-target']:RemoveTargetEntity(self.ped, locale('cl_lang_1') )
            if self.ped and DoesEntityExist(self.ped) then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(self.ped, i, false)
                    end
                end
                DeleteEntity(self.ped)
                self.ped = nil
            end
        end

        spawnedPeds[k] = newpoint
    end
end)

-- cleanup
local resource = GetCurrentResourceName()
AddEventHandler("onResourceStop", function(resourceName)
    if resource ~= resourceName then return end
    for k, v in pairs(spawnedPeds) do
        exports['rsg-target']:RemoveTargetEntity(v.ped, locale('cl_lang_1'))
        if v.ped and DoesEntityExist(v.ped) then
            DeleteEntity(v.ped)
        end

        spawnedPeds[k] = nil
    end
end)