shell.setPath(shell.path() .. ":/midi/cli")

local completion = require("cc.shell.completion")
local otherCompletion = require("cc.completion")

local function getMIDIids(text, mode)
    if settings.get("midi.persistent", false) == true and not midi then require("/midi") end
    if not midi then return end
    local ids = {}
    for id, device in pairs(midi.devices) do
        if device.mode == mode then
            table.insert(ids, tostring(id))
        end
    end
    return otherCompletion.choice(text, ids)
end

shell.setCompletionFunction("midi/cli/miditool.lua", completion.build(
    { completion.choice, {"list", "setoutput", "setinput", "play"} },
    function (shell, text, previous)
        if previous[2] == "setoutput" then
            return getMIDIids(text, "output")
        elseif previous[2] == "setinput" then
            return getMIDIids(text, "input")
        elseif previous[2] == "play" then
            return completion.file(shell, text)
        end
    end,
    completion.file
))

shell.setCompletionFunction("midi/cli/wsmidi.lua", completion.build(
    { completion.choice, {"input", "output", "listen"} }
))

shell.setAlias("midi", "miditool")