---@meta

---@class sqlite3Statement
sqlite3Statement = {}
---@return integer
---@param nametable table<string,any>
function sqlite3Statement:bind_names(nametable)
    return sqlite3.OK
end

---@return integer
function sqlite3Statement:finalize()
    return sqlite3.OK
end

---@return integer
function sqlite3Statement:step()
    return sqlite3.OK
end

---@return any
---@param number integer
function sqlite3Statement:get_value(number)
    return 7
end

---@return table<integer,any>
function sqlite3Statement:get_values()
    return {}
end

---@return table<string,any>
function sqlite3Statement:get_named_values()
    return {}
end

function sqlite3Statement:reset()
end


---@class sqlite3Db
sqlite3Db = {}

---@param sql string
---@param func fun(udata:any, columnNumber:integer,tableValues:table<integer,any>, tableNames:table<integer,string>)?
---@param udata any
---@return integer
function sqlite3Db:exec(sql, func, udata)
    return 0
end

---@param sql string
---@return sqlite3Statement
function sqlite3Db:prepare(sql)
    return sqlite3Statement
end

---@return integer
function sqlite3Db:close()
    return 0
end

---@class sqlite3
sqlite3 = {
    OK = 0,
    ERROR = 1,
    INTERNAL = 2,
    PERM = 3,
    ABORT = 4,
    BUSY = 5,
    LOCKED = 6,
    NOMEM = 7,
    READONLY = 8,
    INTERRUPT = 9,
    IOERR = 10,
    CORRUPT = 11,
    NOTFOUND = 12,
    FULL = 13,
    CANTOPEN = 14,
    PROTOCOL = 15,
    EMPTY = 16,
    SCHEMA = 17,
    TOOBIG = 18,
    CONSTRAINT = 19,
    MISMATCH = 20,
    MISUSE = 21,
    NOLFS = 22,
    FORMAT = 24,
    RANGE = 25,
    NOTADB = 26,
    ROW = 100,
    DONE = 101
}

---@param filename string
---@return sqlite3Db
function sqlite3.open(filename)
    return sqlite3Db
end