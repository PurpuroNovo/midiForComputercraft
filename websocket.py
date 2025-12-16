import asyncio
import pygame.midi
import websockets

pygame.midi.init()

for i in range(pygame.midi.get_count()):
    info = pygame.midi.get_device_info(i)
    interface, name, is_input, is_output, opened = info
    print(i, name.decode(), "Input" if is_input else "Output")

INPUT_DEVICE_ID = int(input("Enter MIDI input device ID: "))

midi_input = pygame.midi.Input(INPUT_DEVICE_ID)
connected_clients = set()

async def midi_server(websocket):
    print("Client connected:", websocket.remote_address)
    connected_clients.add(websocket)
    try:
        while True:
            await asyncio.sleep(0.001)
            if midi_input.poll():
                events = midi_input.read(10)
                for event in events:
                    data, timestamp = event
                    status = data[0] & 0xF0
                    if status == 0xC0 or status == 0xD0:
                        # I have to do this because I get two extra zeros, i get this is to compensate but it breaks program changes if i stream the midi messages again
                        await websocket.send(bytes(data[:2]))
                    else:
                        await websocket.send(bytes(data))
    except websockets.ConnectionClosed:
        print("Client disconnected")
    finally:
        connected_clients.remove(websocket)

async def main():
    async with websockets.serve(midi_server, "0.0.0.0", 8765):
        print("MIDI server running on ws://0.0.0.0:8765")
        await asyncio.Future()

try:
    asyncio.run(main())
except KeyboardInterrupt:
    print("Shutting down...")
finally:
    midi_input.close()
    pygame.midi.quit()
