if not midi then require("/midi") end

midifile = {}

-- I'm keeping these constants here because SMFs don't add that many extra data

midifile.SEQUENCE_NUMBER    = 0x00
midifile.TEXT               = 0x01
midifile.COPYRIGHT          = 0x02
midifile.TRACK_NAME         = 0x03
midifile.INSTRUMENT_NAME    = 0x04
midifile.LYRICS             = 0x05
midifile.MARKER             = 0x06
midifile.CUE_POINT          = 0x07
midifile.CHANNEL_PREFIX     = 0x20
midifile.PORT_NUMBER        = 0x21
midifile.END_OF_TRACK       = 0x2F
midifile.SET_TEMPO          = 0x51
midifile.SMPTE_OFFSET       = 0x54
midifile.TIME_SIGNATURE     = 0x58
midifile.KEY_SIGNATURE      = 0x59
midifile.SEQUENCER_SPECIFIC = 0x7F

midifile.META_NAMES = {
    [midifile.SEQUENCE_NUMBER]    = "Sequence Number",
    [midifile.TEXT]               = "Text",
    [midifile.COPYRIGHT]          = "Copyright",
    [midifile.TRACK_NAME]         = "Track Name",
    [midifile.INSTRUMENT_NAME]    = "Instrument Name",
    [midifile.LYRICS]             = "Lyrics",
    [midifile.MARKER]             = "Marker",
    [midifile.CUE_POINT]          = "Cue Point",
    [midifile.CHANNEL_PREFIX]     = "Channel Prefix",
    [midifile.PORT_NUMBER]        = "Port Number",
    [midifile.END_OF_TRACK]       = "End of Track",
    [midifile.SET_TEMPO]          = "Set Tempo",
    [midifile.SMPTE_OFFSET]       = "SMPTE Offset",
    [midifile.TIME_SIGNATURE]     = "Time Signature",
    [midifile.KEY_SIGNATURE]      = "Key Signature",
    [midifile.SEQUENCER_SPECIFIC] = "Sequencer Specific"
}

function midifile.read(path)
    ---@class MIDIFile
    local midiFile = {}
    local file= fs.open(path, "rb")
    assert(file ~= nil, "File not found")
    assert(file.read(4) == "MThd", "Not a valid MIDI file")

    ---@param size integer
    ---@return integer
    local function readInt(size)
        local result = 0
        for i = 0, size - 1 do
            local byte = file.read(1):byte(1)
            result = result * 256 + byte
        end
        return result
    end

    assert(readInt(4) == 6, "Invalid header")

    midiFile.format = readInt(2)
    assert(midiFile.format ~= 2, "This MIDI file contains multiple songs in one, I don't know how to handle this.")
    midiFile.numberOfTracks = readInt(2)
    midiFile.ticksPerQuarter = readInt(2)

    --print("This file has " .. midiFile.ticksPerQuarter .. " tracks.")

    ---@type (MIDIFile.event[])[]
    midiFile.tracks = {}
    for i = 1, midiFile.numberOfTracks do
        assert(file.read(4) == "MTrk", "Expected MTrk chunk, got something else")
        local trackLength = readInt(4)
        local track = {}
        local status = nil
        local channel = nil
        local index = 1

        ---Read variable length quantity
        ---@return integer
        local function readVLQ()
            local value = 0
            while true do
                local byte = file.read(1):byte(1)
                index = index + 1
                value = bit.bor(value * 2^7, bit.band(byte, 0x7F))
                if bit.band(byte, 0x80) == 0 then break end
            end
            return value
        end

        while index < trackLength do
            local deltaTime = readVLQ()

            ---@class MIDIFile.event
            local event = {}
            ---@type number
            event.delta = deltaTime
            ---@type number[]
            event.data = {}
            local messageByte = file.read(1):byte(1)
            index = index + 1

            if messageByte == 0xFF then -- Meta event
                status = nil
                event.type = "meta"
                event.metaType = file.read(1):byte(1)
                index = index + 1

                local length = readVLQ()
                event.length = length

                for _ = 1, length do
                    table.insert(event.data, file.read(1):byte(1))
                    index = index + 1
                end
            elseif messageByte == 0xF0 or messageByte == 0xF7 then -- SysEx 
                status = nil
                event.type = "sysex"
                local length = readVLQ()
                event.length = length

                for _ = 1, length do
                    table.insert(event.data, file.read(1):byte(1))
                    index = index + 1
                end
            else
                event.type = "midi"

                local length = nil
                if messageByte >= 0x80 then -- new status
                    status = bit.band(messageByte, 0xF0)
                    channel = bit.band(messageByte, 0x0F)
                    length = midi.STATUS_SIZE[status]
                    event.newStatus = true
                    table.insert(event.data, messageByte)
                else -- not a new status, this is a run of a previous status
                    assert(status, "Missing status")
                    assert(midi.STATUS_SIZE[status], "Unknown status length for status " .. status)
                    length = midi.STATUS_SIZE[status] - 1 -- -1 because the messageByte already counts
                    event.newStatus = false
                    table.insert(event.data, messageByte)
                end

                event.expectedFullStatus = status + channel

                for _ = 1, length do
                    table.insert(event.data, file.read(1):byte(1))
                    index = index + 1
                end
            end

            table.insert(track, event)
        end

        table.insert(midiFile.tracks, track)
    end

    file.close()

    return midiFile
end