# Don't Drop the Sun

A small Roblox multiplayer prototype in which everyone cooperates to keep a physics-based sun airborne. The server creates the arena, sun, remotes, rounds, randomized challenges, and modifiers at runtime.

## Run in Roblox Studio

1. Install [Rojo](https://rojo.space/) and its Roblox Studio plugin.
2. From this directory, run `rojo serve`.
3. Open a new Baseplate in Studio, open the Rojo plugin, and connect.
4. Start a play test. The generated arena supports solo testing and multiplayer server tests.

## Controls

- **Keyboard:** `E` or left mouse button
- **Gamepad:** right trigger
- **Mobile:** **HIT SUN** touch button

Move within 18 studs of the sun, aim the camera, and activate the control to launch it. All hits are distance-checked and rate-limited by the server.

## Project layout

- `src/shared/Config.lua` contains tuning values.
- `src/server/GameServer.server.lua` owns gameplay and validates player actions.
- `src/client/SunController.client.lua` creates the HUD and cross-platform controls.

This is an MVP foundation. Persistent rewards, additional challenge modules, sound, and custom art can be added after play-testing the core hit mechanic.
