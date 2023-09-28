require "json"
local gmcp_handler_id = "ee38f102d1e8014f681df982"
function OnPluginBroadcast(msg, id, name, data)
    if (id == gmcp_handler_id and msg == 2) then
        AddCharPackage()
    end -- Add package if
    if (id == gmcp_handler_id and msg == 1) then
        local startNr, endNr, subpackage, gmcpJson = string.find(data, [[^%s*MG.char.(vitals)%s*({.*})%s*$]])
        if subpackage == "vitals" then
            local decoded = json.decode(gmcpJson)

            SetVariable("hp", decoded.hp)
            SetVariable("sp", decoded.sp)
            SetVariable("poison", decoded.poison)
            BroadcastPlugin(1, gmcpJson)
        end -- nil check if
    end     -- GMCP message If
end         -- function

function OnPluginInstall()
    AddCharPackage()
end -- Function

function AddCharPackage()
    CallPlugin(gmcp_handler_id, "AddGMCPPackage", "MG.char 1")
end
