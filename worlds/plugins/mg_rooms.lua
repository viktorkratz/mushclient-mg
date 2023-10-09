require "json"
local gmcp_handler_id = "ee38f102d1e8014f681df982"
function OnPluginBroadcast(msg, id, name, data)
    if (id == gmcp_handler_id and msg == 2) then
        AddRoomPackage()
    end -- if new GMCP data
    if (id == gmcp_handler_id and msg == 1) then
        local startNr, endNr, subpackage, gmcpJson = string.find(data, [[^%s*MG.room.(info)%s*({.*})%s*$]])
        if subpackage == "info" then
            ---@type Room
            local decoded = json.decode(gmcpJson)
            SetVariable("id", decoded.id)
            SetVariable("short", decoded.short)
            SetVariable("domain", decoded.domain)
            SetVariable("roomJSON", gmcpJson)
            BroadcastPlugin(1, gmcpJson)
        end -- if info subpackage
    end     -- if GMCP data
end         -- End of OnPluginBroadcast

function OnPluginInstall()
    AddRoomPackage()
end -- OnPluginInstall

function AddRoomPackage()
    CallPlugin(gmcp_handler_id, "AddGMCPPackage", "MG.room 1")
end -- function addRoomPackage
