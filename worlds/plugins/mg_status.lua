local mg_char_id = "267745b27b2f0e42200da929"
function OnPluginBroadcast(msg, id, name, data)
    if id == mg_char_id and msg == 1 then
        local hp = GetPluginVariable(mg_char_id, "hp")
        local sp = GetPluginVariable(mg_char_id, "sp")
        SetStatus(hp .. " " .. sp)
    end -- if
end -- OnPluginBroadcast
