local ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('baz_moneywash:retrieveMoney')
AddEventHandler('baz_moneywash:retrieveMoney', function(id, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer ~= nil then
        xPlayer.addMoney(amount)
        sendNotification(source, 'Du tog ut ' .. amount .. ' kr från tvätten!', 'success', 3500)
        MySQL.Async.execute('DELETE FROM moneywash WHERE id=@id', 
            {
                ["@id"] = id
            }
        )
    end
end)

ESX.RegisterServerCallback("baz_moneywash:fetchCops", function(source, callback, minCops)
    local copsOnDuty = 0

    local Players = ESX.GetPlayers()

    for i = 1, #Players do
        local xPlayer = ESX.GetPlayerFromId(Players[i])

        if xPlayer["job"]["name"] == "police" then
            copsOnDuty = copsOnDuty + 1
        end
    end

    if copsOnDuty >= minCops then
        callback(true)
    else
        callback(false)
    end
end)

ESX.RegisterServerCallback('baz_moneywash:checkMoney', function(source, callback, id, amount)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer ~= nil then
		local account = xPlayer.getAccount('black_money')

		if account.money >= amount then
            callback(true)
            xPlayer.removeAccountMoney('black_money', amount)
            MySQL.Async.execute('INSERT INTO moneywash (id, amount) VALUES (@id, @amount)', 
                {
                    ["@id"] = id,
                    ["@amount"] = amount
                }
            )
		else
			callback(false)
		end
	end
end)

ESX.RegisterServerCallback('baz_moneywash:getCooldown', function(source, callback, id)
    MySQL.Async.fetchAll('SELECT * FROM moneywash', {}, function(fetched)
        local found = false

        for i=1, #fetched, 1 do
            local row = fetched[i]

            if row ~= nil then
                if row.id == id then
                    if ((row.timestamp + row.cooldown) - os.time()) < 0 then
                        callback(1)
                    else
                        callback((row.timestamp + row.cooldown) - os.time())
                    end

                    found = true
                end
            end
        end

        if found == false then  
            callback(0)
        end
    end)
end)

ESX.RegisterServerCallback('baz_moneywash:getAmount', function(source, callback, id)
    local fetch = [[
        SELECT
            amount
        FROM
            moneywash
        WHERE
            id = @id
    ]]

    MySQL.Async.fetchScalar(fetch, {
        ["@id"] = id

    }, function(money)
        
        if money ~= nil then
            callback(json.decode(money))
        else
            callback(nil)
            print('baz_moneywash: Getting value didnt go as expected...')
        end 
    end)
end)

ESX.RegisterServerCallback('baz_moneywash:setCooldown', function(source, callback, id, seconds)
    MySQL.Async.fetchAll('SELECT * FROM moneywash', {}, function(fetched)
        local found = false

        for i=1, #fetched, 1 do
            local row = fetched[i]

            if row ~= nil then
                if row.id == id then
                    found = true
                end
            end
        end

        if found == true then
            MySQL.Async.execute('UPDATE moneywash SET cooldown=@cooldown, timestamp=@timestamp WHERE id=@id', 
                {
                    ["@id"] = id,
                    ["@cooldown"] = seconds,
                    ["@timestamp"] = os.time()
                }
            )
        else
            MySQL.Async.execute('INSERT INTO moneywash (id, cooldown, timestamp) VALUES (@id, @cooldown, @timestamp)', 
                {
                    ["@id"] = id,
                    ["@cooldown"] = seconds,
                    ["@timestamp"] = os.time()
                }
            )
        end
    end)

    callback()
end)

sendNotification = function(xSource, message, messageType, messageTimeout)
    TriggerClientEvent('pNotify:SendNotification', xSource, {
        text = message,
        type = messageType,
        queue = 'bazookan',
        timeout = messageTimeout,
        layout = 'bottomCenter'
    })
end