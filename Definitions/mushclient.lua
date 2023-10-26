---@diagnostic disable: lowercase-global
--mmmeta
---@import ReturnCodes
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
---@return ReturnCodes.eInvalidObjectLabel|ReturnCodes.eOK
function SetVariable(VariableName, Contents)
    return ReturnCodes
end

---@param message integer
---@param text string
---@return integer
function BroadcastPlugin(message, text)
    return 1
end

---@return ReturnCodes
---@param PluginID string
---@param Routine string
---@param Argument string
function CallPlugin(PluginID, Routine, Argument)
    return ReturnCodes.eOK
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

---@return (ReturnCodes.eNoSuchPlugin|ReturnCodes.eOK)|integer
---@param PluginID string
---@param Enabled boolean
function EnablePlugin(PluginID, Enabled)
    return ReturnCodes.eOK
end

---@return string
function GetPluginID()
    return "plugin_id"
end

---@return string|table|boolean|number
---@param PluginID string
---@param InfoType integer
function GetPluginInfo(PluginID, InfoType)
    return "Some example"
end

---@param Packet string
---@return ReturnCodes
function SendPkt(Packet)
    return ReturnCodes.eOK
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
---@return ReturnCodes
function PlaySound(Buffer, FileName, Loop, Volume, Pan)
    FileName = FileName or ""
    loop = loop or false
    Volume = Volume or 0
    pan = pan or 0
    return ReturnCodes.eOK
end

---@return nil
---@param Message string
function SetStatus(Message)
end

---@return ReturnCodes
function SaveState  ();
    return ReturnCodes.eOK
end

---@return string
function CreateGUID()
    return "some guid"
end

---@return ReturnCodes.eOK
---@param ... string
function Send(...)
    return ReturnCodes
end