require "json"
require "os"
require "math"
require "sqlite3"
require "utils"
local mg_rooms_id = "13292fe3403d8b28f77bf5ac"
local db_name = "mg_ways.db"
local MODE_RECORD_ALL = "all"
local MODE_RECORD_WARNING = "warn"
local MODE_RECORD_EDIT_BOX = "edit"
local routeRecordMode = nil
---@type Room?
local lastStart = nil
---@type Room
local lastRoom = nil
---@type table<integer,string>
local commandsEntered = {}
local lastCommandWasDirection = false
local lastTime = os.clock()
local currentSteps = {}
---@class RoutePart
---@field startRoom RoomWithAlias
---@field endRoom RoomWithAlias
---@field path table<integer,string>
local routePart = {
      startRoom = { id = "start123", domain = "mountains", short = "", exits = {} },
      endRoom = { id = "end456", domain = "plains", short = "", exits = {} },
      path = {}
}
---@type table<integer,RoutePart>
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
default_directions["e"] = "o" -- For people used to play english muds :)
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
   startId,
   endId,
   length
   );
   CREATE TABLE IF NOT EXISTS Ways(
      routeId,
      fromId,
      toId,
      steps,
      partNumber
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
      CREATE TABLE IF NOT EXISTS RoomAliases(
roomId,
alias
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
                  [MODE_RECORD_WARNING] =
                  "Nur Himmelsrichtungen zur Route hinzufügen, Warnung bei Raumübergang ohne erkannten Befehl.",
                  [MODE_RECORD_EDIT_BOX] =
                  "Nur Himmelsrichtungen zur Route hinzufügen, wenn das wechseln von Räumen mit anderen Befehlen erfolgte wird ein Eingabefeld zur Eingabe der Befehle beöffnet.",
                  [MODE_RECORD_ALL] =
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
      local stm = db:prepare("SELECT count(*) FROM Routes WHERE startId=:roomId")
      stm:bind_names({ roomId = roomId })
      local result = stm:step()
      AssertDb(result == sqlite3.ROW, db)
      local count = stm:get_value(0)
      stm:finalize()
      db:close();

      return count > 0
end --

function GetRoutesWithRoom(roomId)
      local db = sqlite3.open(db_name)
      local stm = db:prepare([[
SELECT rstart.short as startShort, rstart.id as startId,
rend.short as endShort,  rend.id as endId
FROM Ways w
INNER JOIN Routes
ON w.routeId=routes.id
INNER JOIN rooms rend
on rend.id=routes.endId
INNER JOIN rooms rstart
ON rstart.id=routes.startId
WHERE w.fromId=:roomId
]])
      stm:bind_names({ roomId = roomId })
      local result = stm:step()
      local destinationRooms = {}
      while result == sqlite3.ROW do
            local row = stm:get_named_values()
            table.insert(destinationRooms, {
                  destination = { id = row.endId, short = row.endShort },
                  start = { id = row.startId, short = row.startShort }
            })
            stm:step()
      end -- while
      stm:finalize()
      db:close()
      return destinationRooms
end -- getRoutesWithRoom

---@param name string
---@param line string
---@param groups table<integer,string>
function MStart(name, line, groups)
      local alias = nil
      alias = groups[1]
      if alias == "" then
            alias = nil
      end
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
            StartRoute(currentRoom, alias)
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
                  StartRoute(currentRoom, alias)
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

function StartRoute(room, wildcards, alias)
      room.alias = alias
      lastStart = room
      lastRoom = room
      currentSteps = {}
      route = {}
end

function OnPluginCommand(sText)
      if lastStart ~= nil then
            lastTime = os.clock()
            local direction = default_directions[sText]
            lastCommandWasDirection = false
            if direction ~= nil then
                  lastCommandWasDirection = true
                  table.insert(currentSteps, direction)
            elseif routeRecordMode == MODE_RECORD_ALL then
                  table.insert(currentSteps, sText)
            end -- if default direction or mode record all
            table.insert(commandsEntered, sText)
      end       -- if recording route
      return true
end

function OnPluginBroadcast(msg, id, name, text)
      if id == mg_rooms_id and msg == 1 and lastStart then
            local room = GetRoomInfo(false)
            if (room == nil) then
                  return nil
            end -- room is nil

            if (os.clock() - 0.2) > lastTime then
                  local timeNumber = math.floor((os.clock() - lastTime) * 100)
                  local timeStr = "(" .. tostring(timeNumber) .. "ms)"
                  if lastCommandWasDirection == false then
                        table.insert(commandsEntered, timeStr)
                  else
                        table.insert(currentSteps, timeStr)
                  end
            end
            if routeRecordMode == MODE_RECORD_EDIT_BOX and #currentSteps == 0 and #commandsEntered ~= #currentSteps then
                  local suggestion = ConcatTableWithNewline(commandsEntered)
                  local inputResult = utils.editbox(
                        "Geben Sie den Weg vom letzten gültigen Raum in diesen Raum an. Im Textfeld sind bereits alle getätigten Befehle seit dem Betreten des letzten Raums enthalten.",
                        "Weg angeben", suggestion)
                  if inputResult == nil then
                        currentSteps = commandsEntered
                  else
                        local parts = SplitStringByNewline(inputResult)
                        currentSteps = parts
                  end
            end
            table.insert(route, { startRoom = lastRoom, endRoom = room, path = currentSteps })
            lastRoom = room
            currentSteps = {}
            commandsEntered = {}
      end -- is new room
end       -- OnPluginBroadcast

---@param name string
---@param commands string
---@param groupsTable table<integer,string>
function MEnd(name, commands, groupsTable)
      if lastStart == nil then
            utils.msgbox("Im Moment wird kein Weg aufgezeichnet der beendet werden könnte.")
            return
      end

      if groupsTable[1] ~= nil and groupsTable[1] ~= "" then
            route[#route].endRoom.alias = groupsTable[1]
      end

      CheckLoop()
      local lbxResult = nil
      lbxResult = 1
      while lbxResult ~= nil do
            local lbxRoute = {}
            local maximumDigitsCount = math.floor(math.log(#route, 10))
            local formatStr = "%0" .. maximumDigitsCount .. "d"
            for key, value in ipairs(route) do
                  lbxRoute[key] =
                      string.format(formatStr, key) ..
                      ": " ..
                      value.startRoom.short .. "-> " .. value.endRoom.short .. ":" .. table.concat(value.path, ";")
            end -- for loop
            lbxResult = tonumber(utils.listbox(
                  "Wählen Sie einen Abschnitt der Route aus und klicken Sie auf ok, um diesen Abschnitt zu bearbeiten. Klicken Sie auf abbrechen um dass Bearbeiten der Route abzuschließen.",
                  "Route bearbeiten", lbxRoute, lbxResult))
            if lbxResult ~= nil then
                  local routePart = route[lbxResult]
                  local editBoxResult = utils.editbox(
                        "Geben Sie den Weg zwischen den beiden Räumen an und trennen Sie jedes Kommando durch eine neue Zeile.\r\nVon: " ..
                        routePart.startRoom.short .. "\r\nNach:" .. routePart.endRoom.short, "Wegabschnitt bearbeiten",
                        ConcatTableWithNewline(routePart.path))
                  if editBoxResult ~= nil then
                        routePart.path = SplitStringByNewline(editBoxResult)
                  end
            end -- if user clicked on ok
      end       -- Show listbox loop
      SaveRoute()
      lastStart = nil
end -- function

function CheckLoop()
      local loops = {}
      local usedStartRooms = {}
      local loopCounter = 0
      for nr, routePart in ipairs(route) do
            local startRoomId = routePart.startRoom.id
            if usedStartRooms[startRoomId] ~= nil then
                  loops[usedStartRooms[startRoomId]] = nr - 1
                  loopCounter = loopCounter + 1
            end -- if start room already used
            usedStartRooms[startRoomId] = nr
      end       -- for each route part

      if loopCounter > 0 then
            local answer = utils.msgbox("Es wurden Schleifen im Weg entdeckt. Sollen diese entfernt werden?", nil,
                  "yesno")
            if answer == "yes" then
                  local currentIndex = 1
                  local increment = 0
                  local loopStart = nil
                  local loopEnd = nil
                  local maxCounter = #route
                  while currentIndex <= maxCounter
                  do
                        if loopStart == nil and loops[currentIndex] ~= nil then
                              loopStart = currentIndex
                              loopEnd = loops[currentIndex]
                              increment = increment + ((loopEnd + 1) - loopStart)
                        end -- if start of loop

                        if currentIndex == loopEnd then
                              loopStart = nil
                              loopEnd = nil
                        end -- if end of loop

                        route[currentIndex] = route
                            [currentIndex + increment] -- If currentCounter+increment is greater then maxCounter, nil is assigned so the array is finished
                        currentIndex = currentIndex + 1
                  end                                  -- loops
            end                                        -- if answer was yes
      end                                              -- if loops found
end                                                    -- function checkLoops

---@param roomId string
---@param alias string
---@param database sqlite3Db?
function AddAliasToDatabase(roomId, alias, database)
      local db = database or sqlite3.open(db_name)
      local stm = db:prepare([[INSERT INTO RoomAliases
      (roomId,alias)
      VALUES(:roomId,:alias)]])
      stm:bind_names({ roomId = roomId, alias = alias })
      stm:step()
      stm:finalize()
      if database == nil then
            db:close()
      end
end -- function addAlias

---@return string
---@param tableToConcat table<integer,string>
function ConcatTableWithNewline(tableToConcat)
      return table.concat(tableToConcat, "\r\n")
end -- function ConcatTableWithNewline

---@return table<integer,string>
---@param str string
function SplitStringByNewline(str)
      local counter = 1
      local returningTable = {}
      for line in string.gmatch(str, "[^\r^\n]+") do
            returningTable[counter] = line
            counter = counter + 1
      end -- for each line
      return returningTable
end       -- function SplitStringByNewline

function SaveRoute()
      ---@type table<integer,RoomWithAlias>
      local roomsInRoute = {}
      ---@type table<string, integer>
      local roomsMap = {}
      local insertCounter = 1
      ---@param map table<string,integer>
      ---@param roomsList table<integer,table>
      ---@param currentRoom table
      ---@param counter integer
      local function addEveryRoom(map, roomsList, currentRoom, counter)
            if map[currentRoom.id] == nil then
                  map[currentRoom.id] = counter
                  roomsList[counter] = currentRoom
                  return counter + 1
            else
                  local oldPosition = map[currentRoom.id]
                  roomsList[oldPosition].alias = roomsList[oldPosition].alias or currentRoom.alias
                  return counter
            end -- if room exists in map or else
      end       -- local function addEveryRoom

      for nr, routePart in pairs(route) do
            insertCounter = addEveryRoom(roomsMap, roomsInRoute, routePart.startRoom, insertCounter)
            insertCounter = addEveryRoom(roomsMap, roomsInRoute, routePart.endRoom, insertCounter)
            if roomsMap[routePart.endRoom.id] == nil then
                  roomsMap[routePart.endRoom.id] = insertCounter
                  roomsInRoute[insertCounter] = routePart.endRoom
                  insertCounter = insertCounter + 1
            end -- if end room already exists in map
      end       -- for each part in route

      -- Initialize db
      local db = sqlite3.open(db_name)
      db:exec("BEGIN TRANSACTION;")

      -- Add rooms
      local checkExistingRoomsCommand = [[SELECT id FROM Rooms WHERE id in(]]
      local roomsOnRouteCount = #roomsInRoute
      local checkExistingRoomsQueryParameters = {}
      for keyNr, room in pairs(roomsInRoute) do
            checkExistingRoomsCommand = checkExistingRoomsCommand .. ":room" .. keyNr
            checkExistingRoomsQueryParameters["room" .. keyNr] = room.id
            if keyNr ~= (roomsOnRouteCount) then
                  checkExistingRoomsCommand = checkExistingRoomsCommand .. ","
            end -- if not last element in array
      end       -- for each room in the route
      checkExistingRoomsCommand = checkExistingRoomsCommand .. ")"

      local existingRoomsStm = db:prepare(checkExistingRoomsCommand)
      existingRoomsStm:bind_names(checkExistingRoomsQueryParameters)
      local existingRoomsQueryResult = existingRoomsStm:step()

      while existingRoomsQueryResult == sqlite3.ROW do
            local values = existingRoomsStm:get_named_values()
            table.remove(roomsInRoute, roomsMap[values.id])
            existingRoomsQueryResult = existingRoomsStm:step()
      end -- for each row in the existing rooms query

      AssertDb(existingRoomsQueryResult == sqlite3.DONE, db)
      existingRoomsStm:finalize()

      -- Insert new rooms
      local insertCmdTable = {}
      local insertRoomsCmd = "INSERT INTO Rooms(id,short,domain, visibleExits) values(:id,:short,:domain, :exits)"
      local insertRoomsStmt = db:prepare(insertRoomsCmd)
      for keyNr, room in pairs(roomsInRoute) do
            insertRoomsStmt:bind_names({
                  id = room.id,
                  short = room.short,
                  domain = room.domain,
                  exits = json.encode(room.exits)
            })
            local result = insertRoomsStmt:step()
            AssertDb(result == sqlite3.DONE, db)
            insertRoomsStmt:reset()
            if room.alias ~= nil then
                  AddAliasToDatabase(room.id, room.alias, db)
            end
      end -- for each room in the route
      insertRoomsStmt:finalize()

      -- Add new route
      local insertRouteStmt = db:prepare([[INSERT INTO Routes
(id, startId,   endId,    length)
VALUES(:id, :startId, :endId, :length)]])
      local routeId = CreateGUID()
      insertRouteStmt:bind_names({ id = routeId, startId = route[1].startRoom.id, endId = route[#route].endRoom.id,
            length = #route })
      AssertDb(insertRouteStmt:step() == sqlite3.DONE, db)
      insertRouteStmt:finalize()

      -- Insert ways
      local insertWaysStmt = db:prepare([[INSERT INTO Ways
(routeId,fromId,toId,steps,partNumber)
VALUES
(:routeId,:fromId,:toId,:steps,:partNumber)]])

      for partNr, routePart in pairs(route) do
            insertWaysStmt:bind_names({ routeId = routeId, fromId = routePart.startRoom.id, toId = routePart.endRoom.id,
                  steps = json.encode(routePart.path), partNumber = partNr })
            AssertDb(insertWaysStmt:step() == sqlite3.DONE, db)
            insertWaysStmt:reset()
      end
      db:exec("END TRANSACTION")
      db:close()
end -- function SaveRoute

---@param check boolean
---@param db sqlite3Db
function AssertDb(check, db)
      if check == false then
            error(db:errmsg())
      end
end
