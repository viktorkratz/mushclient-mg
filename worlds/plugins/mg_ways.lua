require "json"
require "sqlite3"
require "utils"

local mg_rooms_id = "13292fe3403d8b28f77bf5ac"
local db_name = "mg_ways.db"
local lastStart = nil
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
            destinationRooms.insert({
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
            lastStart = currentRoom
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
                  lastStart = currentRoom
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
            lbxDestinationSelectTable.insert(newEntry)
      end -- for
      local lbxResult = utils.listbox("Wählen Sie den Raum aus, in dem die Route begonnen werden soll.", nil,
            lbxDestinationSelectTable)
end -- function

function GetRoomInfo()
      local roomJSON = GetPluginVariable(mg_rooms_id, "roomJSON")
      if roomJSON == nil then
            utils.msgbox(
                  "Der aktuelle Raum konnte nicht ermittelt werden. Evtl. wurde seit dem installieren von mg_rooms noch kein Raum gewechselt?",
                  "Fehler beim ermitteln des aktuellen Raums")
            return nil
      end -- if for nil check
      local room = json.decode(roomJSON)
      if room.id == "" then
            utils.msgbox("Dieser Raum kann nicht für Wege genutzt werden.")
            return nil
      end -- if
      return room
end       -- getRoomInfo
