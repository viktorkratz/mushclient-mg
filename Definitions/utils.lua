---@meta

---@class utils
utils = {}

---@param msg string
---@param title string?
---@param t table<any,string>
---@param default any
---@return any
function utils.choose(msg, title, t, default)
    title = title or "MUSHclient"
    return ""
end

---@param msg string
---@param title string?
---@param type "ok"|"abortretryignore"|"okcancel"|"retrycancel"|"yesno"|"yesnocancel"|nil
---@param icon "!" | "?" | "i" | "." | nil
---@param default 1|2|3|nil
function utils.msgbox(msg, title, type, icon, default)
    title = title or "MUSHclient"
    default = default or 1
    icon = icon or "!"
    type = type or "ok"
    return "yes"
end

---@param msg string
---@param title string?
---@param tbl table<any,string>?
---@param default any?
---@return any?
function utils.listbox(msg, title, tbl, default)
    title = title or "MUSHclient"
end
