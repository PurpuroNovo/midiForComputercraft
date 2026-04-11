if fs.exists("/midi") then
    printError("MIDI is already installed!")
    return
end

-- yoinked from wget
local function get(sUrl)
    local ok, err = http.checkURL(sUrl)
    if not ok then
        printError(err or "Invalid URL.")
        return
    end

    local response = http.get(sUrl)
    if not response then return end

    local sResponse = response.readAll()
    response.close()
    return sResponse or ""
end

function download(url, path)
    print("Downloading " .. url .. " to " .. path .. "...")
    local content = get(url)
    if not content then
        printError("Failed!")
        return
    end
    local file, err = fs.open(path, "wb")
    if not file then
        printError("Cannot save file: " .. err)
        return
    end

    file.write(content)
    file.close()
end

local installDeflate = false
write("Do you want to install LibDeflate to support reading *.mid.zlib files? (optional) (yes/no) : ")
local input = read()
installDeflate = (input:lower() == "yes") or (input:lower() == "y")

local REPO = "https://raw.githubusercontent.com/PurpuroNovo/midiForComputercraft/refs/heads/main"
function downloadRepo(path)
    download(REPO .. path, path)
end

fs.makeDir("/midi")
downloadRepo("/midi/init.lua")
downloadRepo("/midi/constants.lua")
downloadRepo("/midi/synth.lua")
downloadRepo("/midi/midifile.lua")
downloadRepo("/midi/midisequencer.lua")
if installDeflate then
    download("https://gist.githubusercontent.com/MineRobber9000/bdc3ce6c73b32cb1e4a56817eb392222/raw/e28e657d4404145be3c506e9ae5a77da025be3ce/LibDeflate_min.lua", "/midi/LibDeflate.lua")
end

fs.makeDir("/midi/cli")
downloadRepo("/midi/cli/miditool.lua")
downloadRepo("/midi/cli/wsmidi.lua")

fs.makeDir("/startup")
downloadRepo("/startup/midi.lua")

settings.define("midi.persistent", {
    description = "If true, the midi and midifile API will put itself in the global table. Restart if you change this. False by default because it's experimental.",
    default = false,
    type = "boolean",
})

settings.define("midi.noteblock.usePitchbend", {
    description = "If true, midi.PITCH_BEND_CHANGE messages will be handled by the Noteblock MIDI Synth. This is false by default due to most pitch bends being slides, and noteblocks can't handle this.",
    default = false,
    type = "boolean",
})

settings.save()

term.setTextColor(colors.green)
print("Sucessfully Installed!")
print("Rebooting system...")
sleep(2)

os.reboot()