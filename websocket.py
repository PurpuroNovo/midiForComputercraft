import asyncio
import pygame.midi
import websockets

WS_PORT = 8765

pygame.midi.init()

for i in range(pygame.midi.get_count()):
    info = pygame.midi.get_device_info(i)
    interface, name, isInput, isOutput, opened = info
    print(i, name.decode(), "Input" if isInput else "Output")

DEVICE_ID = int(input("Enter MIDI device ID: "))

midiInfo = pygame.midi.get_device_info(DEVICE_ID)

midiInput = None
midiOutput = None
if midiInfo[2]:
    midiInput = pygame.midi.Input(DEVICE_ID)
else:
    midiOutput = pygame.midi.Output(DEVICE_ID)

def midiLength(status):
    high = status & 0xF0

    if high in (0xC0, 0xD0): # Program Change and Channel Pressure are the quirky ones
        return 2
    elif high in (0x80, 0x90, 0xA0, 0xB0, 0xE0):
        return 3
    else:
        return 0  # Unsupported

connectedClients = set() # TODO: use 1 braincell for this
async def midiInputServer(websocket):
    print(f"Client connected: {websocket.remote_address[0]}:{websocket.remote_address[1]}")
    connectedClients.add(websocket)
    try:
        while True:
            await asyncio.sleep(0.001)
            if midiInput.poll():
                events = midiInput.read(10)
                for event in events:
                    data, timestamp = event
                    length = midiLength(data[0])
                    # They have to be limited to size otherwise the extra zeros break things
                    await websocket.send(bytes(data[:length]))
    except websockets.ConnectionClosed:
        print("Client disconnected")
        connectedClients.remove(websocket)

async def midiOutputServer(websocket):
    print(f"Client connected: {websocket.remote_address[0]}:{websocket.remote_address[1]}")
    connectedClients.add(websocket)
    buffer = bytearray()

    try:
        async for message in websocket:
            if not isinstance(message, bytes):
                continue

            buffer.extend(message)

            while buffer:
                status = buffer[0]
                length = midiLength(status)
                if length == 0:
                    buffer.pop(0)
                    continue

                if len(buffer) < length:
                    break

                midiMessage = buffer[:length]
                del buffer[:length]

                try:
                    if length == 2:
                        midiOutput.write_short(midiMessage[0], midiMessage[1], 0)
                    else:
                        midiOutput.write_short(midiMessage[0], midiMessage[1], midiMessage[2])
                except Exception as e:
                    print(f"MIDI error: {e}, data: {list(midiMessage)}")
    except websockets.ConnectionClosed:
        print("Client disconnected")
    finally:
        connectedClients.remove(websocket)

async def main():
    print("-"*25)
    if midiInput:
        async with websockets.serve(midiInputServer, "0.0.0.0", WS_PORT):
            print(f"MIDI input running on ws://0.0.0.0:{WS_PORT}")
            print("Run the following command in Computercraft to connect:")
            print(f"wsmidi input ws://0.0.0.0:{WS_PORT}")
            await asyncio.Future()
    elif midiOutput:
        async with websockets.serve(midiOutputServer, "0.0.0.0", WS_PORT):
            print(f"MIDI output running on ws://0.0.0.0:{WS_PORT}")
            print("Run the following command in Computercraft to connect:")
            print(f"wsmidi output ws://0.0.0.0:{WS_PORT}")
            await asyncio.Future()

try:
    asyncio.run(main())
except KeyboardInterrupt:
    print("Shutting down...")
finally:
    if midiInput:
        midiInput.close()
    if midiOutput:
        midiOutput.close()
    pygame.midi.quit()
