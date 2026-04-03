if not midi then require("/midi") end

midisequencer = {}

---@param device MIDIDevice
function midisequencer.clearDevice(device)
    for channel = 1, 16 do
        device:send({midi.PROGRAM_CHANGE + (channel - 1), 0x00}) -- Change to Acoustic Piano
        device:send({midi.CONTROL_CHANGE + (channel - 1), midi.CC_ALL_NOTES_OFF, 0})
        device:send({midi.CONTROL_CHANGE + (channel - 1), midi.CC_RESET_ALL_CONTROLLERS, 0})
    end
end

---@param events MIDIFile
---@param device? MIDIDevice|number
---@return MIDISequence
function midisequencer.fromEvents(events, device)
    ---@class MIDISequence
    local sequence = {}
    sequence.events = events
    if type(device) == "table" then
        sequence.device = device
    elseif type(device) == "number" then
        sequence.device = midi.devices[device]
    else
        sequence.device = midi.devices[midi.defaultOutputID]
    end
    assert(sequence.device, "MIDI device ID " .. tostring(device) .. " was not found")
    assert(sequence.device.isOutput, "Can't set an input device as the device for a sequencer!")

    sequence.microsecondsPerQuarter = 500000 -- 120 BPM as default
    sequence.secondsPerTick = (sequence.microsecondsPerQuarter / 1000000) / events.ticksPerQuarter

    ---@alias MIDISequence.TrackIndex number

    ---@type table<MIDISequence.TrackIndex, number>
    sequence.trackIndex = {}
    ---@type table<MIDISequence.TrackIndex, number>
    sequence.trackNextTick = {}

    function sequence:buildTrack()
        self.trackIndex = {}
        self.trackNextTick = {}
        for i = 1, #self.events.tracks do
            self.trackIndex[i] = 1
            if #self.events.tracks[i] > 0 then
                self.trackNextTick[i] = self.events.tracks[i][1].delta -- first delta
            else
                self.trackNextTick[i] = nil
            end
        end
    end
    sequence:buildTrack()

    sequence.globalSeconds = 0
    sequence.globalTick = 0

    ---Finds the track that will play next
    ---Returns { tick = absolute tick, tracks = (tracks that should play)}
    function sequence:getNextEvents()
        local result = {}
        result.tracks = {}
        result.tick = math.huge

        for track = 1, #self.events.tracks do
            if self.trackNextTick[track] ~= nil then
                if self.trackNextTick[track] == result.tick then
                    table.insert(result.tracks, track)
                elseif self.trackNextTick[track] < result.tick then
                    result.tick = self.trackNextTick[track]
                    result.tracks = { track }
                end
            end
        end

        return result
    end

    ---Advances the sequence by specific ticks, sending the data to the device
    ---@param ticks number
    function sequence:advance(ticks)
        local nextEvents = self:getNextEvents()
        if #nextEvents.tracks == 0 then return end

        self.globalTick = self.globalTick + ticks

        while self.globalTick >= nextEvents.tick do
            local nextTracks = nextEvents.tracks

            for i = 1, #nextTracks do
                local track = nextTracks[i]
                while true do -- this is so it advances all 0 delta events, so chords play in 1 advance call
                    local index = self.trackIndex[track]
                    local event = self.events.tracks[track][index]

                    if not event then break end

                    if event.type == "midi" then
                        self.device:send(event.expectedFullStatus)
                        self.device:send(event.data)
                    end

                    if event.type == "meta" and event.metaType == midifile.SET_TEMPO then
                        self.microsecondsPerQuarter = event.data[1] * 2^16 + event.data[2] * 2^8 + event.data[3]
                        self.secondsPerTick = (self.microsecondsPerQuarter / 1000000) / self.events.ticksPerQuarter
                    end

                    self.trackIndex[track] = index + 1

                    if self.trackIndex[track] > #self.events.tracks[track] then
                        self.trackNextTick[track] = nil
                        break
                    end

                    -- add next delta
                    local nextDelta = self.events.tracks[track][self.trackIndex[track] ].delta
                    self.trackNextTick[track] = self.trackNextTick[track] + nextDelta

                    if nextDelta ~= 0 then break end
                end
            end

            nextEvents = self:getNextEvents()
        end
    end

    function sequence:play()
        midisequencer.clearDevice(self.device)
        self:buildTrack()

        local lastAdvance = os.clock()
        local playing = true

        local function playLoop()
            while playing do
                local nextEvents = self:getNextEvents()

                if #nextEvents.tracks == 0 then
                    playing = false
                    break
                end

                -- this trickery is needed because sleep rounds to minecraft ticks
                -- currentTick is useful, because time could have passed since the end of the loop, which is when lastAdvance is set, and the
                local currentTick = self.globalTick + ((os.clock() - lastAdvance) / self.secondsPerTick)
                local ticksToWait = nextEvents.tick - currentTick
                local secondsToWait = ticksToWait * self.secondsPerTick
                local mcTicksToWait = math.floor(secondsToWait * 20) -- since this is .floor, it will always round down

                sleep(math.max(mcTicksToWait/20, 0))

                self:advance((os.clock() - lastAdvance) / self.secondsPerTick)
                lastAdvance = os.clock()
            end
        end

        local success, err = pcall(playLoop)

        midisequencer.clearDevice(self.device)

        if not success and err ~= "Terminated" then
            error(err)
        end
    end

    return sequence
end

---@param path string
---@param device? MIDIDevice|number
---@return MIDISequence
function midisequencer.fromFile(path, device)
    return midisequencer.fromEvents(midifile.read(path), device)
end