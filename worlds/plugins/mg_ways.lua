require "json"
require "sqlite3"
require "utils"

local mg_rooms_id = "13292fe3403d8b28f77bf5ac"
local db_name = "mg_ways.db"
local MODE_RECORD_ALL = "all"
local MODE_RECORD_WARNING = "warn"
local MODE_RECORD_EDIT_BOX = "edit"
local routeRecordMode = nil
local lastStart = nil
local roomsOnRoute = {}
local lastRoom = nil
local currentSteps = {}
local route = {}
local default_directions = {}
default_directions["w"] = "w"
default_directions["westen"] = "w"
default_directions["westoben"] = "wob"
default_directions["wob"] = "wob"
default_directions["wu"] = "wu"
default_directions["westunten"] = "wu"
default_directions["sw"] = "sw"
default_directions["suedwesten"] = "sw"
default_directions["swob"] = "swob"
default_directions["suedwestoben"] = "swob"
default_directions["swu"] = "swu"
default_directions["suedwestunten"] = "swu"
default_directions["s"] = "s"
default_directions["sob"] = "sob"
default_directions["suedoben"] = "sob"
default_directions["su"] = "su"
default_directions["suedunten"] = "su"
default_directions["so"] = "so"
default_directions["suedosten"] = "so"
default_directions["soob"] = "soob"
default_directions["suedostoben"] = "soob"
default_directions["sou"] = "sou"
default_directions["suedostunten"] = "sou"
default_directions["o"] = "o"
default_directions["osten"] = "o"
default_directions["oob"] = "oob"
default_directions["ostoben"] = "oob"
default_directions["ou"] = "ou"
default_directions["ostunten"] = "ou"
default_directions["no"] = "no"
default_directions["nordosten"] = "no"
default_directions["noob"] = "noob"
default_directions["nordostoben"] = "noob"
default_directions["nou"] = "nou"
default_directions["nordostunten"] = "nou"
default_directions["n"] = "n"
default_directions["norden"] = "n"
default_directions["nob"] = "nob"
default_directions["nordoben"] = "nob"
default_directions["nu"] = "nu"
default_directions["nordunten"] = "nu"
default_directions["nw"] = "nw"
default_directions["nordwesten"] = "nw"
default_directions["nwob"] = "nwob"
default_directions["nordwestoben"] = "nwob"
default_directions["nwu"] = "nwu"
default_directions["nordwestunten"] = "nwu"
default_directions["ob"] = "ob"
default_directions["oben"] = "ob"
default_directions["u"] = "u"
default_directions["unten"] = "u"
default_directions["raus"] = "raus"

function OnPluginInstall()
      local db = sqlite3.open(db_name)
      db:exec([[
CREATE TABLE IF NOT EXISTS Routes(
   id,
   start_id,
   end_id
   );
   CREATE TABLE IF NOT EXISTS Ways(
      route_id,
      from_id,
      to_id,
      steps
      );
      CREATE TABLE IF NOT EXISTS Migrations(
id,
date
      );
      CREATE TABLE IF NOT EXISTS Rooms(
id,
short,
domain,
visibleExits
      );
]])
      Migrate(db)
      db:close()
end -- OnPluginInstall

function OnPluginConnect()
      routeRecordMode = GetVariable("mode")
end -- OnPluginConnect

function MMode()
      routeRecordMode = utils.listbox("Wie sollen Wege beim erfassen von Routen aufgezeichnet werden?",
            "Erfassungsmodus auswählen",
            {
                  MODE_RECORD_WARNING =
                  "Nur Himmelsrichtungen zur Route hinzufügen, Warnung bei Raumübergang ohne erkannten Befehl.",
                  MODE_RECORD_EDIT_BOX =
                  "Nur Himmelsrichtungen zur Route hinzufügen, wenn das wechseln von Räumen mit anderen Befehlen erfolgte wird ein Eingabefeld zur Eingabe der Befehle beöffnet.",
                  MODE_RECORD_ALL =
                  "Alle Befehle, die während des Erfassens von Routen eingegeben werden werden zur Route hinzugefügt."
            }, MODE_RECORD_EDIT_BOX
      )
      if routeRecordMode ~= nil then
            SetVariable("mode", routeRecordMode)
      end
      return routeRecordMode
end -- MMode

function Migrate(db)
end -- function migrate

function IsStartingRoom(roomId)
      local db = sqlite3.open(db_name)
      local stm = db:prepare("SELECT count(*) FROM Routes WHERE start_id=:room_id")
      stm:bind_names({ room_id = roomId })
      local result = stm:step()
      assert(result == sqlite3.ROW, "Fehler beim Abrufen der Tabelle routes")
      local count = stm:get_value(0)
      stm:finalize()
      db:close();

      return count > 0
end --

function GetRoutesWithRoom(room_id)
      local db = sqlite3.open(db_name)
      local stm = db:prepare([[
SELECT rstart.short as start_short, rstart.id as start_id,
rend.short as end_short,  rend.id as end_id
FROM Ways w
INNER JOIN Routes
ON w.route_id=routes.id
INNER JOIN rooms rend
on rend.id=routes.end_id
INNER JOIN rooms rstart
ON rstart.id=routes.start_id
WHERE w.from_id=:room_id
]])
      stm:bind_names({ room_id = room_id })
      local result = stm:step()
      local destinationRooms = {}
      while result == sqlite3.ROW do
            local row = stm:get_named_values()
            table.insert(destinationRooms, {
                  destination = { id = row.end_id, short = row.end_short },
                  start = { id = row.start_id, short = row.start_short }
            })
            stm:step()
      end -- while
      stm:finalize()
      db:close()
      return destinationRooms
end -- getRoutesWithRoom

function MStart(name, line, wildcards)
      if routeRecordMode == nil then
            local selectedMode = MMode()
            if (selectedMode == nil) then
                  utils.msgbox(
                        "Es wurde kein Modus ausgewählt, das Erfassen von Wegen benötigt aber die Angabe eines Erfassungsmodus. Geben Sie mmode ein, um den Modus zu setzen bzw. später zu ändern.",
                        "Kein Modus ausgewählt", "ok", "!")
                  return nil
            end
      end
      if lastStart ~= nil then
            local replaceMsgResult = utils.msgbox(
                  "Es wird bereits eine Route aufgezeichnet. Soll trotzdem eine neue Route begonnen werden?", nil,
                  "yesno")
            if replaceMsgResult == "no" then
                  return
            end -- if
      end       -- if
      local currentRoom = GetRoomInfo()
      if (currentRoom == nil) then
            return nil
      end -- if

      if IsStartingRoom(currentRoom.id) then
            StartRoute(currentRoom)
      else
            local possibleStarts = GetRoutesWithRoom(currentRoom.id)
            local lBoxEntries = { new = "Diesen Raum als Startpunkt nutzen." }
            if #possibleStarts > 0 then
                  lBoxEntries["go_start"] = "Zu angebundenem Raum gehen und Route dort beginnen."
                  lBoxEntries["additional_route"] =
                  "Eine neue Route erstellen, welche die vorhandene Route über diesen Raum nutzt."
            end -- if
            local lBoxResult = utils.listbox(
                  "Dieser Raum ist noch nicht als Startraum angebunden. Wählen sie die passende Aktion aus.", nil,
                  lBoxEntries, "new")
            if lBoxResult == "new" then
                  StartRoute(currentRoom)
            elseif lBoxResult == "go_start" then
                  ShowPossibleGotosForMstart(possibleStarts)
            elseif lBoxResult == "additional_route" then
            end -- if
      end       -- if
end             -- function mstart

function ShowPossibleGotosForMstart(routes)
      local lbxDestinationSelectTable = {}
      for i, route in ipairs(routes) do
            local newEntry = {}
            newEntry[route.destination.id] = route.destination.short
            table.insert(lbxDestinationSelectTable, newEntry)
      end -- for
      local lbxResult = utils.listbox("Wählen Sie den Raum aus, in dem die Route begonnen werden soll.", nil,
            lbxDestinationSelectTable)
end -- function

function GetRoomInfo(warnOnRoomWithoutId)
      warnOnRoomWithoutId = warnOnRoomWithoutId or true
      local roomJSON = GetPluginVariable(mg_rooms_id, "roomJSON")
      if roomJSON == nil then
            utils.msgbox(
                  "Der aktuelle Raum konnte nicht ermittelt werden. Evtl. wurde seit dem installieren von mg_rooms noch kein Raum gewechselt?",
                  "Fehler beim ermitteln des aktuellen Raums")
            return nil
      end -- if for nil check
      local room = json.decode(roomJSON)
      if room.id == "" then
            if warnOnRoomWithoutId == true then
                  utils.msgbox("Dieser Raum kann nicht für Wege genutzt werden.")
            end
            return nil
      end -- if
      return room
end       -- getRoomInfo

function StartRoute(room)
      lastStart = room
      lastRoom = nil
      currentSteps = {}
      route = {}
end

function OnPluginCommand(sText)
      if lastStart ~= nil then
            local direction = default_directions[sText]
            if direction ~= nil then
                  table.insert(currentSteps, direction)
            elseif routeRecordMode == MODE_RECORD_ALL then
                  table.insert(currentSteps, sText)
            end -- if default direction or mode record all
      end -- if recording route
      return true
end

function OnPluginBroadcast(msg, id, name, text)
      if id == mg_rooms_id and msg == 1 and lastStart then
            local room = GetRoomInfo(false)
            if (room == nil) then
                  return nil
            end -- room is nil
            table.insert(roomsOnRoute, room)
            table.insert(route, { startroom = lastRoom, endRoom = room, Path = currentSteps })
            lastRoom = room
            currentSteps = {}
      end -- is new room
end       -- OnPluginBroadcast
