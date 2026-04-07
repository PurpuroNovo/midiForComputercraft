if not midi then require("/midi") end

function showUsage()
    print("Usage: midi list")
    print("Usage: midi setoutput <id>")
    print("Usage: midi setinput <id>")
    print("Usage: midi play <file> | midi play <output id> <file>")
end

local persistent = settings.get("midi.persistent", false)
if not persistent then
    term.setTextColour(colors.yellow)
    print("midi.persistent is false, this means the midi api isn't permanent, therefore devices, and default inputs/outputs from other programs don't stick")
    print("if you want advanced use, \"set midi.persistent true\", if you just want to play MIDIs, keep as is")
    term.setTextColour(colors.white)
end

function logDevice(device)
    local id = device.id
    local isDefaultInput = midi.defaultInputID == id
    local isDefaultOutput = midi.defaultOutputID == id
    local isDefault = isDefaultInput or isDefaultOutput
    print(id .. " \"" .. device.name .. "\" " .. device.mode .. (isDefault and (isDefaultInput and " (Default input)" or " (Default output)") or ""))
end

if arg[1] == "list" then
    print("Avaliable MIDI devices")
    for id, device in pairs(midi.devices) do
        logDevice(device)
    end
elseif arg[1] == "setoutput" or arg[1] == "setinput" then
    if arg[2] then
        local id = tonumber(arg[2])
        assert(type(id) == "number", "Invalid ID")
        local device = midi.devices[id]
        assert(device, "Couldn't find device with id " .. id)
        if arg[1] == "setoutput" then assert(device.isOutput, "Cant set an input device as the default output") end
        if arg[1] == "setinput" then assert(device.isInput, "Can't set an output device as the default input") end
        if arg[1] == "setoutput" then midi.defaultOutputID = id end
        if arg[1] == "setinput" then midi.defaultInputID = id end
    else
        local device = nil
        if arg[1] == "setinput" then
            print("Showing default input device:")
            device = midi.devices[midi.defaultInputID]
        else
            print("Showing default output device:")
            device = midi.devices[midi.defaultOutputID]
        end
        if device then
            logDevice(device)
        else
            print("(No device found)")
        end
    end
elseif arg[1] == "play" then
    if type(tonumber(arg[2])) == "number" then
        if type(arg[3]) ~= "string" then return showUsage() end
        local device = midi.devices[tonumber(arg[2])]
        midisequencer.fromFile(shell.resolve(arg[3]), device):play()
    elseif type(arg[2]) == "string" then
        midisequencer.fromFile(shell.resolve(arg[2])):play()
    else
        showUsage()
    end
else
    showUsage()
end