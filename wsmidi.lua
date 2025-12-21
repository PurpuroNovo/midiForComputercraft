if not midi then require("midi") end

function showUsage()
    print("Usage: wsmidi input <url>")
    print("Usage: wsmidi output <url>")
    print("Usage: wsmidi listen <url>")
    print("\nUse input if you want to plug a keyboard or a controller")
    print("Use output if you want to plug a synth")
    print("Use listen if you want to listen to an input (keyboard, controller) device using the default output device, note that it doesn't create any new input device.")
end

if (#arg < 2) or (not (arg[1] == "input" or arg[1] == "output" or arg[1] == "listen")) then
    showUsage()
    return
end

local persistent = settings.get("midi.persistent", false)

if not persistent and arg[1] == "output" then
    print("ERROR: Cannot create output devices without midi.persistent")
    print("If you want to create output devices, \"set midi.persistent true\"")
    return
end

-- Input (keyboard)
-- If persistent and multishell: Launch the daemon
-- Fallback mode: Just sends the input data to Noteblock MIDI Synth

-- Output (synth)
-- For it to work, it needs multishell and persistent

local server = arg[2]

function listen(fallback)
    local ws = assert(http.websocket(server))
    print("Listening to MIDI server " .. server)
    local device = midi.devices[midi.defaultOutputID]
    assert(device, "No MIDI output device found")

    if fallback then
        term.setTextColour(colors.yellow)
        print("Falling back to listening mode\n")

        if not persistent then
            print("midi.persistent is set to false")
            print("If you want inputs to become a device used by other programs, run \"set midi.persistent true\"")
        end
        if multishell == nil then
            print("You don't have multishell support because you are using a basic computer")
            print("If you want to make input websocket MIDI devices, craft an advanced computer")
        end

        term.setTextColour(colors.white)
    end

    while device.id ~= nil do
        local event = { os.pullEventRaw() }

        if event[1] == "terminate" or (event[1] == "websocket_close" and event[2] == server) then
            pcall(function () ws.close() end)
            break
        elseif (event[1] == "websocket_message" and event[2] == server) then
            local data = event[3]
            device:send(data)
        end
    end
end

if arg[1] == "input" then
    if (persistent and multishell) or daemon then
        if daemon then
            multishell.setTitle(multishell.getCurrent(), "daemon")
            local ws = assert(http.websocket(server))
            print("Listening to MIDI server " .. server)
            print("This tab is handling the websocket MIDI")
            print("Close it if you wish to close the connection")
            local device = midi.create("Websocket MIDI", "input")
            while device.id ~= nil do
                local event = { os.pullEventRaw() }

                if event[1] == "terminate" or (event[1] == "websocket_close" and event[2] == server) then
                    pcall(function () ws.close() end)
                    device:pop()
                    break
                elseif (event[1] == "websocket_message" and event[2] == server) then
                    local data = event[3]
                    device:send(data)
                    midi.find("Noteblock MIDI Synth"):send(data) -- for debug
                end
            end
            pcall(function () ws.close() end)
            device:pop()
        else
            multishell.launch({
                arg = { arg[1], arg[2] },
                daemon = true,
                http = http,
                midi = midi,
                os = os,
                multishell = multishell
            }, shell.getRunningProgram())
        end
    else
        listen(true)
    end
elseif arg[1] == "listen" then
    listen(false)
else
    print("ERROR: TODO")
end