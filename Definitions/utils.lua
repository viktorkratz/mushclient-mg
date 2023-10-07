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

---@class extrasTable
extrasTable = {
    box_width = nil,
    box_height = nil,
    prompt_width = nil,
    prompt_height = nil,
    reply_width = nil,
    reply_height = nil,
    max_length = nil,
    validate = nil,
    ok_button = nil,
    cancel_button_width = nil,
    read_only = nil,
    no_default = nil
}

---@param msg string
---@param title string?
---@param default string?
---@param font string?
---@param fontsize integer?
---@param extras extrasTable?
---@return string?
function utils.inputbox(msg, title, default, font, fontsize, extras)
    title = title or "MUSHclient"
    return nil
end

---@return string?
---@param msg string
---@param title string?
---@param default string?
---@param font string?
---@param fontsize integer?
---@param extras extrasTable?
function utils.editbox(msg, title, default, font, fontsize, extras)
    title = title or "MUSHclient"
    return nil
end
