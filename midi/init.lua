midi = {}
---@type { [integer]: MIDIDevice }
midi.devices = {}
local _availableId = 1

require("midi.constants")

---@type number|nil
midi.defaultInputID = nil
---@type number|nil
midi.defaultOutputID = nil

---Find a MIDI device by name
---@param name string
---@return MIDIDevice|nil
---@param mode? MIDIDevice.mode
function midi.find(name, mode)
    for id, device in pairs(midi.devices) do
        if mode ~= nil then
            if device.mode == mode then
                if device.name == name then
                    return device
                end
            end
        else
            if device.name == name then
                return device
            end
        end
    end
end

---@alias MIDIDevice.mode 
---| "input" Input devices are devices which you receive input from, like keyboards or MIDI Controllers
---| "output" Output devices are devices that you send data to, like synthesizers

---Creates a new MIDI device
---
---If name is nil, it will not be added to the global device list
---
---Defaults to an output device if mode is not specified
---@param name string|nil
---@param mode? MIDIDevice.mode
function midi.create(name, mode)
    if mode == nil then mode = "output" end
    assert(mode == "input" or mode == "output", "mode must be input or output")

    ---@class MIDIDevice
    local device = {
        ---@type string|nil
        name = name,
        ---@type number|nil
        id = nil,
        ---@type MIDIDevice.mode
        mode = mode,
        isInput = (mode == "input"),
        isOutput = (mode == "output"),
        ---@type [ fun(data: number[]), function ][]
        listeners = {},
        lastListener = 1,

        ---Listen to valid MIDI messages in the device
        ---@param self MIDIDevice
        ---@param func fun(data: number[])
        ---@param onRemove? function
        ---@return integer
        listen = function (self, func, onRemove)
            self.listeners[self.lastListener] = {func, onRemove}
            self.lastListener = self.lastListener + 1
            return self.lastListener - 1
        end,

        ---Remove a listener from the device
        ---@param self MIDIDevice
        ---@param id integer
        removeListener = function (self, id)
            if self.listeners[id][2] then self.listeners[2]() end -- call the onRemove function if it is there
            self.listeners[id] = nil
        end,

        ---Remove this device from the device list, if this device is not on the list, it just removes the listeners
        ---
        ---Also removes all listeners
        ---
        ---@param self MIDIDevice
        pop = function (self)
            for key, _ in pairs(self.listeners) do
                self:removeListener(key)
            end

            if self.id then
                if midi.defaultInputID == self.id then midi.defaultInputID = nil end
                if midi.defaultOutputID == self.id then midi.defaultOutputID = nil end
                midi.devices[self.id] = nil
                self.id = nil
            end
        end,

        ---@private
        _fullStatus = nil,
        ---@private
        _status = nil,
        ---@private
        _buffer = {},
        ---@private
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
                if #self._buffer == midi.STATUS_SIZE[self._status] then
                    for _, pair in pairs(self.listeners) do
                        local data = {table.unpack(self._buffer)}
                        table.insert(data, 1, self._fullStatus)
                        pair[1](data)
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

    if type(name) == "string" then
        midi.devices[_availableId] = device
        device.id = _availableId
        if mode == "input" and midi.defaultInputID == nil then
            midi.defaultInputID = _availableId
        elseif mode == "output" and midi.defaultOutputID == nil then
            midi.defaultOutputID = _availableId
        end
        _availableId = _availableId + 1
    end
    return device
end

---Turns MIDI notes to human readable notes
---
---Example:
---
---48 -> C4
---@param note any
---@return unknown
function midi.noteToString(note)
    local modNote = note % 12
    local octave = math.floor(note / 12)

    return midi.NOTE_NAMES[modNote + 1] .. tostring(octave)
end

---Turns midi data to a human readable string
---
---Example:
---
--- "\x90\x30\x7f" -> Channel 1, Note On, C4, with velocity 127
---@param data string|number[]
function midi.toString(data)
    local arrayData = {}
    if type(data) == "table" then
        arrayData = data
    elseif type(data) == "string" then
        for i = 1, #data do
            arrayData[i] = data:byte(i)
        end
    end

    if arrayData[1] < 0x80 then -- if the first byte isn't a status byte we cant know anything
        local result = "Unknown data "

        for i = 1, #arrayData do result = result .. tostring(arrayData[i]) .. " " end
    end

    local status = bit.band(arrayData[1], 0xF0)
    local channel = bit.band(arrayData[1], 0x0F) + 1

    if status == midi.NOTE_OFF then
        local note = data[2]
        local velocity = data[3]
        return "Channel " .. channel .. ", Note Off, " .. midi.noteToString(note) .. ", with velocity " .. velocity
    elseif status == midi.NOTE_ON then
        local note = data[2]
        local velocity = data[3]
        return "Channel " .. channel .. ", Note On, " .. midi.noteToString(note) .. ", with velocity " .. velocity
    elseif status == midi.POLYPHONIC_KEY_PRESSURE then
        local note = data[2]
        local velocity = data[3]
        return "Channel " .. channel .. ", Polyphonic key pressure, " .. midi.noteToString(note) .. ", with velocity " .. velocity
    elseif status == midi.CONTROL_CHANGE then
        -- TODO: Understanding control changes is not as simple as this
        local control = data[2]
        local controlName = midi.CC_NAMES[control] or "Unknown"
        return "Channel " .. channel .. ", set CC " .. control .. " " .. controlName
    elseif status == midi.PROGRAM_CHANGE then
        local instrument = data[2] + 1
        return "Channel " .. channel .. ", Change instrument to " .. instrument .. " " .. (midi.INSTRUMENT_NAMES[instrument] or "Unknown")
    elseif status == midi.CHANNEL_PRESSURE then
        local pressure = data[2]
        return "Channel, " .. channel .. ", Change pressure to " .. pressure
    elseif status == midi.PITCH_BEND_CHANGE then
        local lsb = data[2]
        local msb = data[3]
        local value = msb * 128 + lsb 
        local pitch = (value - 8192) / 682
        return "Channel " .. channel .. ", Pitch bend " .. pitch .. " semitones"
    end

    return "Unknown Data"
end

require("midi.synth")