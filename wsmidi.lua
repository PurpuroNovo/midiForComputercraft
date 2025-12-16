require("synth")

local device = midi.find("Noteblock MIDI Synth")
local server = arg[1] or "ws://localhost:8765"
local ws = assert(http.websocket(server))
print("Listening to MIDI server " .. server)
local connected = true
while connected do
    local data = ws.receive()
    device:send(data)
end