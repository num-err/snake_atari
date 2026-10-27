# Snake Remake — TIC-80 (in progress)

A remake of the classic *Snake* arcade game for the [TIC-80](https://tic80.com) fantasy console, written in Lua for CS 86: Game Systems at Swarthmore College.

> **Status: in progress.** Gameplay — growing body, food spawning, wall and self-collision, scoring — is being built now.

## Planned gameplay

- Snake moves continuously on a grid; arrow keys change direction
- Eating food grows the snake and increases the score
- Hitting a wall or the snake's own body ends the game
- Speed increases as the snake grows

## Running it

```
cd game
tic80 --fs .
load game.lua
run
```

If the game uses `middleclass` or `std.strict`, bundle it first:

```
luarocks install --local std.strict
luarocks install --local amalg
~/.luarocks/bin/amalg.lua -o exported_game.lua middleclass std.strict -s game.lua
```

Then `load exported_game.lua` in TIC-80 and `export html remake.zip` to build a browser version.
