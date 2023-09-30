--mmmeta

---@return integer
---@param variableName string
---@param contents string
function SetVariable(variableName, contents)
    return 1
end

---@param VariableName string
---@return any
function GetVariable(VariableName)
    return ""
end

---@param VariableName string
---@param Contents string
---@return eInvalidObjectLabel|eOK
function SetVariable(VariableName, Contents)
end

---@param message integer
---@param text string
---@return integer
function BroadcastPlugin(message, text)
    return 1
end

---@return eNoSuchPlugin |ePluginDisabled|eNoSuchRoutine|eErrorCallingPluginRoutine|eBadParameter|eOK
---@param PluginID string
---@param Routine string
---@param Argument string
function CallPlugin(PluginID, Routine, Argument)
    return 1
end

---@param TextColour string
---@param BackgroundColour string
---@param Text string
---@return nil
function ColourNote(TextColour, BackgroundColour, Text)
end

---@param Message string
---@return nil
function Note(Message)
end

---@return string
function Version()
    return "1.2.3"
end

---@return eNoSuchPlugin|eOK
---@param PluginID string
---@param Enabled boolean
function EnablePlugin(PluginID, Enabled)
end

---@return string
function GetPluginID()
end

---@return string|date|boolean|number
---@param PluginID string
---@param InfoType integer
function GetPluginInfo(PluginID, InfoType)
end

---@param Packet string
---@return eOK|eWorldClosed
function SendPkt(Packet)
end

---@param PluginID string
---@param VariableName string
---@return string?
function GetPluginVariable(PluginID, VariableName)
end

---@param Buffer integer
---@param FileName string?
---@param Loop boolean?
---@param Volume number?
---@param Pan number?
---@return eCannotPlaySound|eBadParameter|eFileNotFound|eOK
function PlaySound(Buffer, FileName, Loop, Volume, Pan)
    FileName = FileName or ""
    loop = loop or false
    Volume = Volume or 0
    pan = pan or 0
end

---@return nil
---@param Message string
function SetStatus(Message)
end
