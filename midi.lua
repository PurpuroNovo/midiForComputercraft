midi = {}
midi.devices = {}

-------- CONSTANTS --------

midi.NOTE_OFF                = 0x80
midi.NOTE_ON                 = 0x90
midi.POLYPHONIC_KEY_PRESSURE = 0xA0
midi.CONTROL_CHANGE          = 0xB0
midi.PROGRAM_CHANGE          = 0xC0
midi.CHANNEL_PRESSURE        = 0xD0
midi.PITCH_BEND_CHANGE       = 0xE0

midi.DATA_BYTES = {
    [midi.NOTE_OFF]                = 2,
    [midi.NOTE_ON]                 = 2,
    [midi.POLYPHONIC_KEY_PRESSURE] = 2,
    [midi.CONTROL_CHANGE]          = 2,
    [midi.PROGRAM_CHANGE]          = 1,
    [midi.CHANNEL_PRESSURE]        = 1,
    [midi.PITCH_BEND_CHANGE]       = 2
}

midi.NAMES = {
    [midi.NOTE_OFF]                = "Note Off",
    [midi.NOTE_ON]                 = "Note On",
    [midi.POLYPHONIC_KEY_PRESSURE] = "Polyphonic Key Pressure",
    [midi.CONTROL_CHANGE]          = "Control Change",
    [midi.PROGRAM_CHANGE]          = "Program Change",
    [midi.CHANNEL_PRESSURE]        = "Channel Pressure",
    [midi.PITCH_BEND_CHANGE]       = "Pitch Bend Change"
}

midi.INSTRUMENT_NAMES = {
    [1] = "Acoustic Grand Piano",
    [2] = "Bright Acoustic Piano",
    [3] = "Electric Grand Piano",
    [4] = "Honky-tonk Piano",
    [5] = "Electric Piano 1",
    [6] = "Electric Piano 2",
    [7] = "Harpsichord",
    [8] = "Clavinet",
    [9] = "Celesta",
    [10] = "Glockenspiel",
    [11] = "Music Box",
    [12] = "Vibraphone",
    [13] = "Marimba",
    [14] = "Xylophone",
    [15] = "Tubular Bells",
    [16] = "Dulcimer",
    [17] = "Drawbar Organ",
    [18] = "Percussive Organ",
    [19] = "Rock Organ",
    [20] = "Church Organ",
    [21] = "Reed Organ",
    [22] = "Accordion",
    [23] = "Harmonica",
    [24] = "Tango Accordion",
    [25] = "Acoustic Guitar (nylon)",
    [26] = "Acoustic Guitar (steel)",
    [27] = "Electric Guitar (jazz)",
    [28] = "Electric Guitar (clean)",
    [29] = "Electric Guitar (muted)",
    [30] = "Overdriven Guitar",
    [31] = "Distortion Guitar",
    [32] = "Guitar harmonics",
    [33] = "Acoustic Bass",
    [34] = "Electric Bass (finger)",
    [35] = "Electric Bass (pick)",
    [36] = "Fretless Bass",
    [37] = "Slap Bass 1",
    [38] = "Slap Bass 2",
    [39] = "Synth Bass 1",
    [40] = "Synth Bass 2",
    [41] = "Violin",
    [42] = "Viola",
    [43] = "Cello",
    [44] = "Contrabass",
    [45] = "Tremolo Strings",
    [46] = "Pizzicato Strings",
    [47] = "Orchestral Harp",
    [48] = "Timpani",
    [49] = "String Ensemble 1",
    [50] = "String Ensemble 2",
    [51] = "Synth Strings 1",
    [52] = "Synth Strings 2",
    [53] = "Choir Aahs",
    [54] = "Voice Oohs",
    [55] = "Synth Voice",
    [56] = "Orchestra Hit",
    [57] = "Trumpet",
    [58] = "Trombone",
    [59] = "Tuba",
    [60] = "Muted Trumpet",
    [61] = "French Horn",
    [62] = "Brass Section",
    [63] = "Synth Brass 1",
    [64] = "Synth Brass 2",
    [65] = "Soprano Sax",
    [66] = "Alto Sax",
    [67] = "Tenor Sax",
    [68] = "Baritone Sax",
    [69] = "Oboe",
    [70] = "English Horn",
    [71] = "Bassoon",
    [72] = "Clarinet",
    [73] = "Piccolo",
    [74] = "Flute",
    [75] = "Recorder",
    [76] = "Pan Flute",
    [77] = "Blown Bottle",
    [78] = "Shakuhachi",
    [79] = "Whistle",
    [80] = "Ocarina",
    [81] = "Lead 1 (square)",
    [82] = "Lead 2 (sawtooth)",
    [83] = "Lead 3 (calliope)",
    [84] = "Lead 4 (chiff)",
    [85] = "Lead 5 (charang)",
    [86] = "Lead 6 (voice)",
    [87] = "Lead 7 (fifths)",
    [88] = "Lead 8 (bass + lead)",
    [89] = "Pad 1 (new age)",
    [90] = "Pad 2 (warm)",
    [91] = "Pad 3 (polysynth)",
    [92] = "Pad 4 (choir)",
    [93] = "Pad 5 (bowed)",
    [94] = "Pad 6 (metallic)",
    [95] = "Pad 7 (halo)",
    [96] = "Pad 8 (sweep)",
    [97] = "FX 1 (rain)",
    [98] = "FX 2 (soundtrack)",
    [99] = "FX 3 (crystal)",
    [100] = "FX 4 (atmosphere)",
    [101] = "FX 5 (brightness)",
    [102] = "FX 6 (goblins)",
    [103] = "FX 7 (echoes)",
    [104] = "FX 8 (sci-fi)",
    [105] = "Sitar",
    [106] = "Banjo",
    [107] = "Shamisen",
    [108] = "Koto",
    [109] = "Kalimba",
    [110] = "Bag pipe",
    [111] = "Fiddle",
    [112] = "Shanai",
    [113] = "Tinkle Bell",
    [114] = "Agogo",
    [115] = "Steel Drums",
    [116] = "Woodblock",
    [117] = "Taiko Drum",
    [118] = "Melodic Tom",
    [119] = "Synth Drum",
    [120] = "Reverse Cymbal",
    [121] = "Guitar Fret Noise",
    [122] = "Breath Noise",
    [123] = "Seashore",
    [124] = "Bird Tweet",
    [125] = "Telephone Ring",
    [126] = "Helicopter",
    [127] = "Applause",
    [128] = "Gunshot",
}

---------------------------

function midi.find(name)
    return midi.devices[name]
end

---Creates a new MIDI stream
---
---If name is nil, it will not be added to the device list
---@param name string|nil
function midi.create(name)
    ---@class MIDIDevice
    local device = {
        ---If name is nil, the device isn't in the global device list
        ---@type string|nil
        name = name,
        listeners = {},

        listen = function (self, func)
            table.insert(self.listeners, func)
            return #self.listeners
        end,

        _fullStatus = nil,
        _status = nil,
        _buffer = {},
        handleByte = function (self, byte)
            if byte >= 0x80 then
                -- Status byte received
                self._fullStatus = byte
                self._status = bit.band(byte, 0xF0)
                self._buffer = {}
            else
                -- Data byte received
                if not self._status then return end
                table.insert(self._buffer, byte)
                if #self._buffer == midi.DATA_BYTES[self._status] then
                    for i = 1, #self.listeners do
                        local data = {table.unpack(self._buffer)}
                        table.insert(data, 1, self._fullStatus)
                        self.listeners[i](data)
                    end

                    self._buffer = {}
                end
            end
        end,

        ---Send MIDI data to the device
        ---@param self MIDIDevice
        ---@param data string|number[]|number
        send = function (self, data)
            if type(data) == "string" then
                for i = 1, #data do
                    self:handleByte(data:byte(i))
                end
            elseif type(data) == "table" then
                for i = 1, #data do
                    self:handleByte(data[i])
                end
            elseif type(data) == "number" then
                self:handleByte(data)
            end
        end
    }
    -- TODO: block the same device from being made
    if type(name) == "string" then midi.devices[name] = device end
    return device
end