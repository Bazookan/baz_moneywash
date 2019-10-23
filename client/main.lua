ESX = nil

local policeCount = 2 -- Counts of police to be able to wash
local openedFirst = false
local openedSecond = false
local inFirstZone = false
local inSecondZone = false
local Locations = {
    ["Zones"] = { 
        ["first"] = {["x"] = -60.95, ["y"] = -2517.52, ["z"] = 7.4, ["Info"] = "Pengatvätt"},
        ["second"] = {["x"] = -58.6, ["y"] = -2519.17, ["z"] = 7.4, ["Info"] = "Pengatvätt"}
    }
}

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(50)
        ESX = exports["es_extended"]:getSharedObject()
    end

    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for place, v in pairs(Locations["Zones"]) do
            local dstCheck = GetDistanceBetweenCoords(coords, v["x"], v["y"], v["z"], true)
            local text = v["Info"]

            if dstCheck <= 2.75 then
                sleep = 5

                if dstCheck <= 0.75 then
                    text = '[~r~E~s~] ' .. v["Info"]

                    if place == "first" then
                        inFirstZone = true
                    elseif place == "second" then
                        inSecondZone = true
                    end

                    if IsControlJustPressed(0, 38) then
                        ESX.TriggerServerCallback("baz_moneywash:fetchCops", function(IsEnough)
                            if IsEnough then
                                ESX.TriggerServerCallback('baz_moneywash:getCooldown', function(cooldown, id)
                                    if cooldown == 0 then
                                        openMenu(place)
                                    elseif cooldown == 1 then 
                                        ESX.TriggerServerCallback('baz_moneywash:getAmount', function(money, id)
                                            retrieveMoney(place, money)
                                        end, place)
                                    else
                                        if cooldown > 60 then
                                            sendNotification('Någon tvättar redan, tvättningen är klar om ' .. math.ceil(round(cooldown/60)) .. ' minut(er).', 'error', 1500)
                                        else
                                            sendNotification('Någon tvättar redan, tvättningen är klar om ' .. cooldown .. ' sekunder.', 'error', 1500)
                                        end
                                    end
                                end, place)
                            else
                                sendNotification('Inte tillräckligt med poliser vakna.', 'error', 1500)
                            end
                        end, policeCount)
                    end
                else
                    if place == "first" then
                        inFirstZone = false
                    elseif place == "second" then
                        inSecondZone = false
                    end
                end
                
                drawM(text, v["x"], v["y"], v["z"] - 0.98)
            end
        end

        if openedFirst and not inFirstZone then
            openedFirst = false
            ESX.UI.Menu.CloseAll()
        end

        if openedSecond and not inSecondZone then
            openedSecond = false
            ESX.UI.Menu.CloseAll()
        end

        Citizen.Wait(sleep)
    end
end)

openMenu = function(machine)
    ESX.UI.Menu.CloseAll()

    if machine == "first" then
        openedFirst = true
    elseif machine == "second" then
        openedSecond = true
    else
        openedFirst = false
        openedSecond = false
    end

    if openedFirst or openedSecond then
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'moneywash',
            {
                title = 'Pengatvätt',
                align = 'center',
                elements = {
                    {label = 'Egen summa', value = 'wash'},
                    {label = 'Snabb summa', value = 'fast'}
                }
            }, function(data, menu)
                if data.current.value == 'wash' then
                    menu.close()
				    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'wash_amount', {
					    title = 'Hur mycket vill du tvätta?'
                    }, function(data2, menu2)
                        local washAmount = tonumber(data2.value)

                        if washAmount == nil then
                            sendNotification('Ogiltig mängd.', 'error', 1500)
                        elseif washAmount < 1000 then
                            sendNotification('Du måste tvätta minst 1000 kr åt gången.', 'error', 2000)
                        else
                            ESX.TriggerServerCallback('baz_moneywash:checkMoney', function(hasMoney, id, amount)
                                if hasMoney then
                                    local time = (washAmount/10)
                                    ESX.UI.Menu.CloseAll()
                                    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'accept',
                                        {
                                            title = 'Detta kommer ta ' .. math.ceil(round(time/60)) .. ' minut(er), vill du fortsätta?',
                                            align = 'center',
                                            elements = {
                                                {label = 'Ja', value = 'yes'},
                                                {label = 'Nej', value = 'no'}
                                            }
                                        }, function(data3, menu3)
                                            if data3.current.value == 'yes' then
                                                ESX.TriggerServerCallback('baz_moneywash:setCooldown', function(id, seconds)
                                                    sendNotification('Du påbörjade en tvättning av ' .. washAmount .. ' kr.', 'success', 2000)
                                                    ESX.UI.Menu.CloseAll()
                                                    openedFirst = false
                                                    openedSecond = false
                                                end, machine, time)
                                            end
                                    
                                            if data3.current.value == 'no' then
                                                ESX.UI.Menu.CloseAll()
                                                openedFirst = false
                                                openedSecond = false
                                            end
                                        end, function(data3, menu3)
                                            menu3.close()
                                            openedFirst = false
                                            openedSecond = false
                                        end
                                    )
                                else
                                    sendNotification('Du har inte tillräckligt med svarta pengar!', 'error', 1500)
                                end
                            end, machine, washAmount)
					    end
				    end, function(data2, menu2)
                        menu2.close()
                        openMenu(machine)
				    end)
                end

                if data.current.value == 'fast' then
                    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fastwash',
                        {
                            title = 'Pengatvätt',
                            align = 'center',
                            elements = {
                                {label = '<span style="color: red;">5000</span> kr [<span style="color: green;">8 min</span>]',	 value = '5000'},
                                {label = '<span style="color: red;">10000</span> kr [<span style="color: green;">17 min</span>]', value = '10000'},
                                {label = '<span style="color: red;">15000</span> kr [<span style="color: green;">25 min</span>]', value = '15000'},
                                {label = '<span style="color: red;">20000</span> kr [<span style="color: green;">33 min</span>]', value = '20000'}
                            }

                        }, function(data, menu)
                            if data.current.value == '5000' then
                                local washAmount = 5000
                                local time = (washAmount/10)
                                ESX.TriggerServerCallback('baz_moneywash:checkMoney', function(hasMoney, id, amount)
                                    if hasMoney then
                                        ESX.TriggerServerCallback('baz_moneywash:setCooldown', function(id, seconds)
                                            sendNotification('Du påbörjade en tvättning av 5000 kr.', 'success', 2000)
                                            ESX.UI.Menu.CloseAll()
                                            openedFirst = false
                                            openedSecond = false
                                        end, machine, time)
                                    else
                                        sendNotification('Du har inte tillräckligt med svarta pengar!', 'error', 1500)
                                    end
                                end, machine, washAmount)
                            end

                            if data.current.value == '10000' then
                                local washAmount = 10000
                                local time = (washAmount/10)
                                ESX.TriggerServerCallback('baz_moneywash:checkMoney', function(hasMoney, id, amount)
                                    if hasMoney then
                                        ESX.TriggerServerCallback('baz_moneywash:setCooldown', function(id, seconds)
                                            sendNotification('Du påbörjade en tvättning av 10000 kr.', 'success', 2000)
                                            ESX.UI.Menu.CloseAll()
                                            openedFirst = false
                                            openedSecond = false
                                        end, machine, time)
                                    else
                                        sendNotification('Du har inte tillräckligt med svarta pengar!', 'error', 1500)
                                    end
                                end, machine, washAmount)
                            end
                
                            if data.current.value == '15000' then
                                local washAmount = 15000
                                local time = (washAmount/10)
                                ESX.TriggerServerCallback('baz_moneywash:checkMoney', function(hasMoney, id, amount)
                                    if hasMoney then
                                        ESX.TriggerServerCallback('baz_moneywash:setCooldown', function(id, seconds)
                                            sendNotification('Du påbörjade en tvättning av 15000 kr.', 'success', 2000)
                                            ESX.UI.Menu.CloseAll()
                                            openedFirst = false
                                            openedSecond = false
                                        end, machine, time)
                                    else
                                        sendNotification('Du har inte tillräckligt med svarta pengar!', 'error', 1500)
                                    end
                                end, machine, washAmount)
                            end
                
                            if data.current.value == '20000' then
                                local washAmount = 20000
                                local time = (washAmount/10)
                                ESX.TriggerServerCallback('baz_moneywash:checkMoney', function(hasMoney, id, amount)
                                    if hasMoney then
                                        ESX.TriggerServerCallback('baz_moneywash:setCooldown', function(id, seconds)
                                            sendNotification('Du påbörjade en tvättning av 20000 kr.', 'success', 2000)
                                            ESX.UI.Menu.CloseAll()
                                            openedFirst = false
                                            openedSecond = false
                                        end, machine, time)
                                    else
                                        sendNotification('Du har inte tillräckligt med svarta pengar!', 'error', 1500)
                                    end
                                end, machine, washAmount)
                            end
                        end, function(data, menu)
                            openMenu(machine)
                        end
                    )
                end
            end, function(data, menu)
                menu.close()
                openedFirst = false
                openedSecond = false
            end
        )
    else
        sendNotification('Försök igen!', 'error', 1500)
    end
end

retrieveMoney = function(id, amount)
    ESX.UI.Menu.CloseAll()

    if id == "first" then
        openedFirst = true
    elseif id == "second" then
        openedSecond = true
    else
        openedFirst = false
        openedSecond = false
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'takeout',
        {
            title = 'Tillgängligt',
            align = 'center',
            elements = {
                {label = 'Ta ut: <span style="color: red;">' .. amount .. '</span> kr', value = 'takeoutmoney'}
            }
        },
        function(data, menu)

            if data.current.value == 'takeoutmoney' then
                TriggerServerEvent('baz_moneywash:retrieveMoney', id, amount)
                menu.close()
                openedFirst = false
                openedSecond = false
            end

        end, function(data, menu)
            menu.close()
            openedFirst = false
            openedSecond = false
        end
    )
end

drawText = function(x, y, z, text)
    local onScreen,x,y = World3dToScreen2d(x, y, z)
    local factor = #text / 370

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x,y)
        DrawRect(x,y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 120)
    end
end

drawM = function(hint, x, y, z)
    drawText(x, y, z + 1.0, hint)
	DrawMarker(25, x, y, z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 2.0, 255, 255, 255, 100, false, true, 2, false, false, false, false)
end

round = function(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

sendNotification = function(message, messageType, messageTimeout)
	TriggerEvent("pNotify:SendNotification", {
		text = message,
		type = messageType,
		queue = 'bazookan',
		timeout = messageTimeout,
		layout = 'bottomCenter'
	})
end
