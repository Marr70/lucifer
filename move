--SC MOVE
id = 102 -- Target ID For Take ItemId 
worldTake = {"tesmoving", "tesmoving2"} -- Name World For Take Item 
doorTake = "alamak" -- ID DOOR World Take 
worldDestination = "tessaving" --name world for put to vend
doorDestination = "anjay" -- ID DOOR world Destination
warpDelay = 5000
mode = "wtw" --wtv/wtw/vtw/vtv

--DO NOT EDIT
bot = getBot()
stock_value = 0
bl_vend = {}

function reconnect(world,id,x,y)
    if bot.status ~= BotStatus.online then
        sleep(100)
        konek = 0
        while true do
            bot:connect()
            sleep(20000)
            if bot.status == BotStatus.account_banned then
                sleep(100)
                while true do
                    sleep(10000)
                end
            end
            while bot.status == BotStatus.online and bot:getWorld().name:upper() ~= world:upper() do
                bot:sendPacket(3, "action|join_request\nname|"..world:upper().."\ninvitedWorld|0")
                sleep(5000)
            end
            if bot.status == BotStatus.online and bot:getWorld().name:upper() == world:upper() then
                if id then
                    while bot:getWorld():getTile(math.floor(getLocal().posx/32), math.floor(getLocal().posy/32)).fg == 6 do
                        bot:sendPacket(3,"action|join_request\nname|"..world:upper().."|"..id:upper().."\ninvitedWorld|0")
                        sleep(3000)
                    end
                end
                if x and y and bot.status == BotStatus.online and bot:getWorld().name:upper() == world:upper() then
                    while math.floor(getLocal().posx/32) ~= x or math.floor(getLocal().posy/32) ~= y do
                        if bot:findPath(x,y) then
                            sleep(1500)
                        end
                    end
                end
                if bot.status == BotStatus.online and bot:getWorld().name:upper() == world:upper() then
                    if x and y then
                        if bot.status == BotStatus.online and math.floor(getLocal().posx/32) == x and math.floor(getLocal().posy/32) == y then
                            break
                        end
                    elseif bot.status == BotStatus.online then
                        break
                    end
                end
            end
            if konek < 20 then
                konek = konek + 1
            else
                sleep(10*60000)
                konek = 0
                sleep(100)
            end
        end
        sleep(100)
    end
end

function warp(to, id)
    while bot:getWorld().name:upper() ~= to:upper() do
        bot:sendPacket(3,"action|join_request\nname|"..to:upper().."\ninvitedWorld|0")
        sleep(warpDelay)
    end
    if id == "" or id == nil then
        return
    end
    while bot:getWorld():getTile(math.floor(getLocal().posx/32), math.floor(getLocal().posy/32)).fg == 6 do
        bot:sendPacket(3,"action|join_request\nname|"..to:upper().."|"..id:upper().."\ninvitedWorld|0")
        sleep(warpDelay)
    end
end

function round(n)
    return n % 1 > 0.5 and math.ceil(n) or math.floor(n)
end

function getpos()
    local pos = {
        x = math.floor(getLocal().posx/32),
        y = math.floor(getLocal().posy/32)
    }
    return pos
end

function tileDrop(x,y,ids,value)
    local stack = 0
    local count = 0
    local store = {}
    for _,obj in pairs(bot:getWorld():getObjects()) do
        if math.floor(obj.x/32) == x and math.floor(obj.y/32) == y then
            stack = stack + 1
            count = count + obj.count
            if store[obj.id] then
                store[obj.id] = store[obj.id] + obj.count
            else
                store[obj.id] = obj.count
            end
        end
    end

    if count <= (4000-value) then
        if stack < 19 then
            return true
        end
        for objId, itm in pairs(store) do
            if objId == ids then
                if math.ceil(itm%200) ~= 0 and math.ceil(itm%200) <= (200-value) then
                    return true
                else
                    return false
                end
            end
        end
    end
    return false
end

function hook(var, netid)
    if var:get(0):getString() == "OnDialogRequest" then
        if var:get(1):getString():find("contains") then
            stock_value = var:get(1):getString():match("a total of (%d+)")
        end
    end
end

function take()
    local currentworld = bot:getWorld().name
    for _,obj in pairs(bot:getWorld():getObjects()) do
        if obj.id == id then
            ex = round(obj.x/32)-1
            ye = math.floor(obj.y/32)
            bot:findPath(round(obj.x/32)-1,math.floor(obj.y/32))
            reconnect(currentworld, doorTake, ex, ye)
            sleep(1500)
            bot:collect(2)
            reconnect(currentworld, doorTake, ex, ye)
            sleep(3000)
        end
        if bot:getInventory():findItem(id) > 0 then
            break
        end
    end
end

function empty()
    local currentworld = bot:getWorld().name
    for _,tile in pairs(bot:getWorld():getTiles()) do
        if tile.fg == 2978 or tile.fg == 9268 then
            if tile:getExtra().id == id then
                ex = tile.x
                ye = tile.y
                bot:findPath(tile.x,tile.y)
                reconnect(currentworld, doorTake, ex, ye)
                sleep(1500)
                bot:wrench(getpos().x, getpos().y)
                sleep(1000)
                bot:sendPacket(2,"action|dialog_return\ndialog_name|vending\ntilex|"..tile.x.."|\ntiley|"..tile.y.."|\nbuttonClicked|pullstock\n\nsetprice|0\nchk_peritem|0\nchk_perlock|1")
                reconnect(currentworld, doorTake, ex, ye)
                sleep(500)
            end
            if bot:getInventory():findItem(id) > 0 then
                break
            end
        end
    end
end

function droprata()
    warp(worldDestination,doorDestination)
    sleep(500)
    reconnect(worldDestination,doorDestination)

    for y = 53,0,-1 do
        for x = 1,99 do
            if y <= getpos().y and x > getpos().x then
                if tileDrop(x,y,id, bot:getInventory():findItem(id)) then
                    ex = x + 1
                    ye = y
                    bot:findPath(x+1,y)
                    reconnect(worldDestination,doorDestination, ex, ye)
                    sleep(1000)
                    bot:setDirection(true)
                    sleep(1000)
                    while bot:getInventory():findItem(id) > 0 and tileDrop(x,y,id, bot:getInventory():findItem(id)) do
                        bot:drop(id, bot:getInventory():findItem(id))
                        reconnect(worldDestination,doorDestination, ex, ye)
                        sleep(3000)
                    end
                end
                if bot:getInventory():findItem(id) == 0 then
                    return
                end
            end
        end  
    end
end

function put()
    warp(worldDestination,doorDestination)
    sleep(500)
    reconnect(worldDestination,doorDestination)

    for _,tile in pairs(bot:getWorld():getTiles()) do
        if tile.fg == 2978 or tile.fg == 9268 then
            if not bl_vend[tile.x..","..tile.y] then
                if tile:getExtra().id == 0 then
                    ex = tile.x
                    ye = tile.y
                    bot:findPath(tile.x,tile.y)
                    reconnect(worldDestination,doorDestination, ex, ye)
                    sleep(1500)
                    bot:wrench(getpos().x, getpos().y)
                    sleep(1000)
                    bot:sendPacket(2,"action|dialog_return\ndialog_name|vending\ntilex|"..tile.x.."|\ntiley|"..tile.y.."|\nstockitem|"..id)
                    reconnect(worldDestination,doorDestination, ex, ye)
                    stock_value = 0
                    break
                elseif tile:getExtra().id == id then
                    ex = tile.x
                    ye = tile.y
                    bot:findPath(tile.x,tile.y)
                    reconnect(worldDestination,doorDestination, ex, ye)
                    sleep(1000)
                    bot:wrench(bot.x,bot.y)
                    listenEvents(2)
                    while stock_value == 0 do
                        sleep(500)
                    end
                    if tonumber(stock_value) <= (5000 - bot:getInventory():findItem(id)) then
                        bot:sendPacket(2,"action|dialog_return\ndialog_name|vending\ntilex|"..tile.x.."|\ntiley|"..tile.y.."|\nbuttonClicked|addstock\n\nsetprice|0\nchk_peritem|0\nchk_perlock|1")
                        reconnect(worldDestination,doorDestination, ex, ye)
                        stock_value = 0
                        break
                    else
                        bl_vend[tile.x..","..tile.y] = true
                        stock_value = 0
                    end
                end
            end
        end
    end
end

function checkfloating()
    for _,obj in pairs(bot:getWorld():getObjects()) do
        if obj.id == id then
            return true
        end
    end
    return false
end

function checkvends()
    for _,tile in pairs(bot:getWorld():getTiles()) do
        if tile.fg == 2978 or tile.fg == 9268 then
            if tile:getExtra().id == id then
                return true
            end
        end
    end
    return false
end

bot.auto_collect = false
bot.auto_reconnect = true
addEvent(Event.variantlist, hook)

if mode == "wtv" then
    while true do
        while bot:getInventory():findItem(id) == 0 do
            if #worldTake == 0 then
                sleep(1000)
                bot:warp("EXIT")
                sleep(3000)
                bot:stopScript()
            end
            for indexWorld,world in pairs(worldTake) do
                warp(world, doorTake)
                sleep(500)
                reconnect(world,doorTake)
                if not checkfloating() then
                    table.remove(worldTake, indexWorld)
                    break
                end
                take()
                if bot:getInventory():findItem(id) > 0 then
                    break
                end
            end
        end
        sleep(1500)
        while bot:getInventory():findItem(id) > 0 do
            put()
        end
        sleep(1500)
    end
elseif mode == "wtw" then
    while true do
        while bot:getInventory():findItem(id) == 0 do
            if #worldTake == 0 then
                sleep(1000)
                bot:warp("EXIT")
                sleep(3000)
                bot:stopScript()
            end
            for indexWorld,world in pairs(worldTake) do
                warp(world, doorTake)
                sleep(500)
                reconnect(world,doorTake)
                if not checkfloating() then
                    table.remove(worldTake, indexWorld)
                    break
                end
                take()
                if bot:getInventory():findItem(id) > 0 then
                    break
                end
            end
        end
        sleep(1500)
        while bot:getInventory():findItem(id) > 0 do
            droprata()
        end
        sleep(1500)
    end
elseif mode == "vtw" then
    while true do
        while bot:getInventory():findItem(id) == 0 do
            if #worldTake == 0 then
                sleep(1000)
                bot:warp("EXIT")
                sleep(3000)
                bot:stopScript()
            end
            for indexWorld,world in pairs(worldTake) do
                warp(world,doorTake)
                sleep(500)
                reconnect(world,doorTake)
                if not checkvends() then
                    table.remove(worldTake, indexWorld)
                    break
                end
                empty()
                if bot:getInventory():findItem(id) > 0 then
                    break
                end
            end
        end
        sleep(1500)
        while bot:getInventory():findItem(id) > 0 do
            droprata()
        end
        sleep(1500)
    end
elseif mode == "vtv" then
    while true do
        while bot:getInventory():findItem(id) == 0 do
            if #worldTake == 0 then
                sleep(1000)
                bot:warp("EXIT")
                sleep(3000)
                bot:stopScript()
            end
            for indexWorld,world in pairs(worldTake) do
                warp(world,doorTake)
                sleep(500)
                reconnect(world,doorTake)
                if not checkvends() then
                    table.remove(worldTake, indexWorld)
                    break
                end
                empty()
                if bot:getInventory():findItem(id) > 0 then
                    break
                end
            end
        end
        sleep(1500)
        while bot:getInventory():findItem(id) > 0 do
            put()
        end
        sleep(1500)
    end
end
