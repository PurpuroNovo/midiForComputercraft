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

local normalBias = {
    "harp",
    "bass",
    "didgeridoo",
    "guitar",
    "pling",
    "banjo",
    "bell",
    "flute",
    "chime",
    "bit",
    "xylophone",
    "iron_xylophone",
    "cow_bell",
}

local normalWeights = {}

for i = 1, #normalBias do
    normalWeights[normalBias[i]] = #normalBias - i
end

local instrumentBias = {
    -- Piano
    [1]  = {"harp", "pling"},  -- Acoustic Grand Piano
    [2]  = {"harp", "pling"},  -- Bright Acoustic Piano
    [3]  = {"pling", "harp"},  -- Electric Grand Piano
    [4]  = {"harp", "pling"},  -- Honky-tonk Piano
    [5]  = {"harp", "pling"},  -- Electric Piano 1
    [6]  = {"pling", "harp"},  -- Electric Piano 2
    [7]  = {"harp"},           -- Harpsichord
    [8]  = {"harp"},           -- Clavinet

    -- Chromatic Percussion
    [9]  = {"bell", "chime"},                                -- Celesta
    [10] = {"bell", "chime"},                                -- Glockenspiel
    [11] = {"bell", "chime"},                                -- Music Box
    [12] = {"bell", "chime"},                                -- Vibraphone
    [13] = {"xylophone", "bell"},                            -- Marimba
    [14] = {"xylophone", "iron_xylophone", "bell", "chime"}, -- Xylophone
    [15] = {"bell", "chime"},                                -- Tubular Bells
    [16] = {"pling", "bell"},                                -- Dulcimer

    -- Organ
    [17] = {"harp", "bit"}, -- Drawbar Organ
    [18] = {"harp", "bit"}, -- Percussive Organ
    [19] = {"harp", "bit"}, -- Rock Organ
    [20] = {"harp", "bit"}, -- Church Organ
    [21] = {"harp", "bit"}, -- Reed Organ
    [22] = {"harp", "bit"}, -- Accordion
    [23] = {"harp", "bit"}, -- Harmonica
    [24] = {"harp", "bit"}, -- Tango Accordion

    -- Guitar
    [25] = {"guitar", "banjo"}, -- Acoustic Guitar (nylon)
    [26] = {"guitar", "banjo"}, -- Acoustic Guitar (steel)
    [27] = {"guitar", "banjo"}, -- Electric Guitar (jazz)
    [28] = {"guitar", "banjo"}, -- Electric Guitar (clean)
    [29] = {"guitar", "banjo"}, -- Electric Guitar (muted)
    [30] = {"guitar", "banjo"}, -- Overdriven Guitar
    [31] = {"guitar", "banjo"}, -- Distortion Guitar
    [32] = {"guitar", "banjo"}, -- Guitar harmonics

    -- Bass
    [33] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Acoustic Bass
    [34] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Electric Bass (finger)
    [35] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Electric Bass (pick)
    [36] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Fretless Bass
    [37] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Slap Bass 1
    [38] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Slap Bass 2
    [39] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Synth Bass 1
    [40] = {"bass", "didgeridoo", "guitar", "banjo"}, -- Synth Bass 2

    -- Strings
    [41] = {"harp", "pling"}, -- Violin
    [42] = {"harp", "pling"}, -- Viola
    [43] = {"harp", "pling"}, -- Cello
    [44] = {"harp", "pling"}, -- Contrabass
    [45] = {"harp", "pling"}, -- Tremolo Strings
    [46] = {"harp", "pling"}, -- Pizzicato Strings
    [47] = {"harp"},          -- Orchestral Harp
    [48] = {"harp"},          -- Timpani
    [49] = {"harp", "pling"}, -- String Ensemble 1
    [50] = {"harp", "pling"}, -- String Ensemble 2
    [51] = {"harp", "pling"}, -- Synth Strings 1
    [52] = {"harp", "pling"}, -- Synth Strings 2
    [53] = {"harp", "pling"}, -- Choir Aahs
    [54] = {"harp", "pling"}, -- Voice Oohs
    [55] = {"harp", "pling"}, -- Synth Voice
    [56] = {"harp", "pling"}, -- Orchestra Hit

    -- Brass
    [57] = {"bit", "harp"}, -- Trumpet
    [58] = {"bit", "harp"}, -- Trombone
    [59] = {"bit", "harp"}, -- Tuba
    [60] = {"bit", "harp"}, -- Muted Trumpet
    [61] = {"bit", "harp"}, -- French Horn
    [62] = {"bit", "harp"}, -- Brass Section
    [63] = {"bit", "harp"}, -- Synth Brass 1
    [64] = {"bit", "harp"}, -- Synth Brass 2

    -- Reed
    [65] = {"flute", "bit"}, -- Soprano Sax
    [66] = {"flute", "bit"}, -- Alto Sax
    [67] = {"flute", "bit"}, -- Tenor Sax
    [68] = {"flute", "bit"}, -- Baritone Sax
    [69] = {"flute"},        -- Oboe
    [70] = {"flute"},        -- English Horn
    [71] = {"flute"},        -- Bassoon
    [72] = {"flute"},        -- Clarinet

    -- Pipe
    [73] = {"flute"}, -- Piccolo
    [74] = {"flute"}, -- Flute
    [75] = {"flute"}, -- Recorder
    [76] = {"flute"}, -- Pan Flute
    [77] = {"flute"}, -- Blown Bottle
    [78] = {"flute"}, -- Shakuhachi
    [79] = {"flute"}, -- Whistle
    [80] = {"flute"}, -- Ocarina

    -- Synth Lead
    [81] = {"bit", "pling"}, -- Lead 1 (square)
    [82] = {"bit", "pling"}, -- Lead 2 (sawtooth)
    [83] = {"bit", "pling"}, -- Lead 3 (calliope)
    [84] = {"bit", "pling"}, -- Lead 4 (chiff)
    [85] = {"bit", "pling"}, -- Lead 5 (charang)
    [86] = {"bit", "pling"}, -- Lead 6 (voice)
    [87] = {"bit", "pling"}, -- Lead 7 (fifths)
    [88] = {"bit", "pling"}, -- Lead 8 (bass + lead)

    -- Synth Pad
    [89] = {"chime", "pling"}, -- Pad 1 (new age)
    [90] = {"chime", "pling"}, -- Pad 2 (warm)
    [91] = {"chime", "pling"}, -- Pad 3 (polysynth)
    [92] = {"chime", "pling"}, -- Pad 4 (choir)
    [93] = {"chime", "pling"}, -- Pad 5 (bowed)
    [94] = {"chime", "pling"}, -- Pad 6 (metallic)
    [95] = {"chime", "pling"}, -- Pad 7 (halo)
    [96] = {"chime", "pling"}, -- Pad 8 (sweep)

    -- Synth Effects
    [97]  = {"chime", "pling"}, -- FX 1 (rain)
    [98]  = {"chime", "pling"}, -- FX 2 (soundtrack)
    [99]  = {"chime", "pling"}, -- FX 3 (crystal)
    [100] = {"chime", "pling"}, -- FX 4 (atmosphere)
    [101] = {"chime", "pling"}, -- FX 5 (brightness)
    [102] = {"chime", "pling"}, -- FX 6 (goblins)
    [103] = {"chime", "pling"}, -- FX 7 (echoes)
    [104] = {"chime", "pling"}, -- FX 8 (sci-fi)

    -- Ethnic
    [105] = {"banjo", "harp", "pling"}, -- Sitar
    [106] = {"banjo", "harp", "pling"}, -- Banjo
    [107] = {"banjo", "harp", "pling"}, -- Shamisen
    [108] = {"banjo", "harp", "pling"}, -- Koto
    [109] = {"banjo", "harp", "pling"}, -- Kalimba
    [110] = {"banjo", "harp", "pling"}, -- Bag pipe
    [111] = {"banjo", "harp", "pling"}, -- Fiddle
    [112] = {"banjo", "harp", "pling"}, -- Shanai

    -- Percussive
    [113] = {"bell", "xylophone", "iron_xylophone", "cow_bell"}, -- Tinkle Bell
    [114] = {"bell", "xylophone", "iron_xylophone", "cow_bell"}, -- Agogo
    [115] = {"bell", "xylophone", "iron_xylophone", "cow_bell"}, -- Steel Drums
    [116] = {"bell", "xylophone", "iron_xylophone", "cow_bell"}, -- Woodblock
    [117] = {"cow_bell", "snare"},                               -- Taiko Drum
    [118] = {"xylophone", "iron_xylophone", "bell"},             -- Melodic Tom
    [119] = {"xylophone", "iron_xylophone", "bell"},             -- Synth Drum
}

local soundEffects = {
    [120] = "minecraft:item.elytra.flying", -- Reverse Cymbal, TODO: Choose better sound
    [121] = "minecraft:item.crossbow.loading_end", -- Guitar Fret Noise
    [122] = "minecraft:entity.player.breath", -- Breath Noise
    [123] = "minecraft:ambient.underwater.enter", -- Seashore
    [124] = "minecraft:entity.parrot.ambient", -- Bird Tweet
    [125] = "minecraft:block.bell.use", -- Telephone Ring
    [126] = "minecraft:entity.phantom.fly", -- Helicopter
    [127] = "minecraft:entity.player.levelup", -- Applause
    [128] = "minecraft:entity.firework_rocket.blast", -- Gunshot
}

local drumList = {
    [35] = "basedrum",
    [36] = "basedrum",
    [38] = "snare",
    [40] = "snare",
    [42] = "hat",
    [44] = "hat",
    [46] = "hat"
}

local channelInstruments = {}

for i = 1, 16 do
    channelInstruments[i] = 1
end

device:listen(function (data)
    local status = bit.band(data[1], 0xF0)
    local channel = bit.band(data[1], 0x0F) + 1
    local note = data[2]
    local velocity = data[3]

    if status == midi.PROGRAM_CHANGE then
        local instrument = data[2] + 1
        channelInstruments[channel] = instrument
    end

    if status == midi.NOTE_ON then
        if channel == 10 then
            -- Drum channel, handle drums
            local instrument = drumList[note]
            if instrument then
                speaker.playNote(instrument, velocity/127)
            end
        else
            -- Instrument channels
            if soundEffects[channelInstruments[channel]] then
                speaker.playSound(soundEffects[channelInstruments[channel]], velocity/127)
            else
                local candidates = {}
                local bias = instrumentBias[channelInstruments[channel]]
                local weights = {}

                for i = 1, #bias do
                    weights[bias[i]] = (#bias - i) + #normalBias
                end

                for instrument, root in pairs(instrumentRoots) do
                    local offset = note - root
                    if offset >= 0 and offset <= 24 then
                        table.insert(candidates, {instrument, offset})
                    end
                end

                table.sort(candidates, function (a, b)
                    local weightA = weights[a[1]] or normalWeights[a[1]] or -1
                    local weightB = weights[b[1]] or normalWeights[b[1]] or -1
                    return weightA > weightB
                end)

                if candidates[1] then
                    speaker.playNote(candidates[1][1], velocity/127, candidates[1][2])
                end
            end
        end
    end
end)

local server = "ws://localhost:8765"
local ws = assert(http.websocket(server))
print("Listening to MIDI server " .. server)
local connected = true
while connected do
    local data = ws.receive()
    device:send(data)
end