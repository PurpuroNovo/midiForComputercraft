# MIDI for Computercraft

Features:
* MIDI 1.0 Protocol support
* Noteblock MIDI Synth (analogous to GS Wavetable Synth Output) - Built-in synth that maps to noteblocks
* WebSocket MIDI devices (input, output)
* MIDI (Standard MIDI File) reader - Reads .mid/.midi files
* MIDI (Standard MIDI File) player - Plays .mid/.midi files or sequences

# Installation

To install MIDI to your Computercraft, run
```
wget run https://raw.githubusercontent.com/PurpuroNovo/midiForComputercraft/refs/heads/main/install.lua
```

# For users

To play a midi file, use `midi play <file>`
You don't have to use any outside program to play, the MIDI file is read inside Computercraft

## How to connect real MIDI devices (Keyboards/Synths)

NOTE: This only works with advanced computers

* Change your world to [allow local IPs](https://tweaked.cc/guide/local_ips.html)
* In your real computer, Install the latest version of [Python](https://www.python.org/), and run `python websocket.py`
* In your CC computer, make sure midi.persistent is enabled, if it isn't, use `set midi.persistent true`
* Run the command that `websocket.py` gave (should be `wsmidi output ws://0.0.0.0:8765` or `wsmidi input ws://0.0.0.0:8765`)
* Set the device as your default using `midi setoutput` or `midi setinput`

# For developers

Coming soon