if not midi then require("midi") end

local speaker = peripheral.find("speaker")
local device = midi.create("Noteblock MIDI Synth")

-- Idea: best of both worlds
-- Since noteblocks cant reach all notes due to computercraft limiting us, i can choose in other ranges
-- Some instruments overlap in range, if they overlap, you could choose a bias, example: for Xylophones, if you find yourself in bell range, always pick bell, if not, pick something else

-- the noteblock pitches span from 0 to 24
-- also, the pitches arent integers, they support half steps

local instrumentRoots = {
    bass           = 18, -- F#1
    bell           = 66, -- F#5
    flute          = 54, -- F#4
    chime          = 66, -- F#5
    guitar         = 30, -- F#2
    xylophone      = 66, -- F#5
    iron_xylophone = 42, -- F#3
    cow_bell       = 54, -- F#4
    didgeridoo     = 18, -- F#1
    bit            = 42, -- F#3
    banjo          = 42, -- F#3
    pling          = 42, -- F#3
    harp           = 42, -- F#3
}

local pitches = {}

-- using only these for now to not mix things
for i = 1, 25 do
    local pitch = i-1
    pitches[18 + pitch] = {"bass", pitch}
    pitches[66 + pitch] = {"bell", pitch}
    pitches[42 + pitch] = {"harp", pitch}
end

local drumList = {
    [35] = "basedrum",
    [36] = "basedrum",
    [38] = "snare",
    [40] = "snare",
    [42] = "hat",
    [44] = "hat",
    [46] = "hat"
}

device:listen(function (data)
    local status = bit.band(data[1], 0xF0)
    local channel = bit.band(data[1], 0x0F) + 1
    local note = data[2]
    local velocity = data[3]

    if status == midi.NOTE_ON then
        if channel == 10 then
            local instrument = drumList[note]
            if instrument then
                speaker.playNote(instrument, velocity/127)
            end
        else
            local pitch = pitches[note]
            if pitch then
                speaker.playNote(pitch[1], velocity/127, pitch[2])
            end
        end
    end
end)

local server = "ws://localhost:8765"
local ws = assert(http.websocket(SERVER))
print("Listening to MIDI server " .. server)
local connected = true
while connected do
    local data = ws.receive()
    device:send(data)
end