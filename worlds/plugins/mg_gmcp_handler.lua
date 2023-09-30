local IAC, SB, SE, DO = 0xFF, 0xFA, 0xF0, 0xFD
GMCP                  = 201
GMCPDebug             = tonumber(GetVariable("GMCPDebug")) or 0

function GmcpDebug(name, line, wildcards)
   local newval = tonumber(wildcards[1])
   if not newval or newval > 2 or newval < 0 then
      ColourNote("darkorange", "", "GMCPDebug valid values are: 0 - off, 1 - simple, 2 - verbose")
      return
   end
   GMCPDebug = newval
   local msg = "off"
   if GMCPDebug == 1 then
      msg = "simple"
   elseif GMCPDebug == 2 then
      msg = "verbose"
   end
   ColourNote("darkorange", "", "GMCPDebug: " .. msg)
end

---------------------------------------------------------------------------------------------------
-- Mushclient callback function when telnet SB data received.
---------------------------------------------------------------------------------------------------
function OnPluginTelnetSubnegotiation(msg_type, data)
   if msg_type ~= GMCP then
      return
   end -- if not GMCP

   -- debugging
   if GMCPDebug > 0 then
      ColourNote("darkorange", "", data)
   end

   local message, params = string.match(data, "([%a.]+)%s+(.*)")

   -- if valid format, broadcast to all interested plugins
   if message then
      BroadcastPlugin(1, data)
   end -- if
end    -- function OnPluginTelnetSubnegotiation

function OnPluginSaveState()
   SetVariable("GMCPDebug", tostring(GMCPDebug))
end

function OnPluginTelnetRequest(msg_type, data)
   if msg_type == GMCP and data == "WILL" then
      return true
   end -- if

   if msg_type == GMCP and data == "SENT_DO" then
      Note("Enabling GMCP.")
      -- This hard-coded block may need to be made into a config table as we add more message types.
      Send_GMCP_Packet(string.format('Core.Hello { "client": "MUSHclient", "version": "%s" }', Version()))
      Send_GMCP_Packet('Core.Supports.Set [ ]')
      Send_GMCP_Packet("Core.Debug 1")


      BroadcastPlugin(2, "initialized")
      return true
   end -- if GMCP login needed (just sent DO)

   return false
end -- function OnPluginTelnetRequest

function OnPluginDisable()
   EnablePlugin(GetPluginID(), true)
   ColourNote("white", "blue", "You are not allowed to disable the " ..
      GetPluginInfo(GetPluginID(), 1) .. " plugin. It is necessary for other plugins.")
end

function AddGMCPPackage(name)
   Send_GMCP_Packet("Core.Supports.Add [\"" .. name .. "\"]")
end -- function

---------------------------------------------------------------------------------------------------
-- Helper function to send GMCP data.
---------------------------------------------------------------------------------------------------
function Send_GMCP_Packet(what)
   assert(what, "Send_GMCP_Packet passed a nil message.")

   SendPkt(string.char(IAC, SB, GMCP) ..
      (string.gsub(what, "\255", "\255\255")) ..       -- IAC becomes IAC IAC
      string.char(IAC, SE))
end                                                    -- Send_GMCP_Packet
