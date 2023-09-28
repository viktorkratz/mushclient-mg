local mg_char_id = "267745b27b2f0e42200da929"
local lastHp = tonumber(0)
local hp_announcement_treshold = 9
function OnPluginBroadcast(msg, id, name, data)
    if (id == mg_char_id and msg == 1) then
        local currentHp = tonumber(GetPluginVariable(mg_char_id, "hp"))
        if (currentHp <= (lastHp - hp_announcement_treshold)) or (currentHp >= (lastHp + hp_announcement_treshold)) then
            local modHp = currentHp % 10
            local hpSound = ((currentHp - modHp) / 10)
            PlaySound(0, "healthtones\\health" .. hpSound .. ".wav", 0, 0, 0)
            lastHp = currentHp
        end -- compare if
    end     -- if
end         -- function
