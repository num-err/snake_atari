# Snake Remake — TIC-80

A reimagining of the classic Snake arcade game, built in Lua for the TIC-80 fantasy console.

## Overview

Rather than recreate the original feature for feature, this project distills Snake to its essential mechanics and rebuilds them within TIC-80's constraints. Throughout development, we examined which elements of the original translate naturally to TIC-80's built-in affordances (its fixed resolution, limited palette, sprite and map editors) and where we chose to work against those constraints to preserve the feel of the original.

## Goals

- **Distill the essence:** identify the core mechanics and design choices that make Snake compelling, and preserve them in the remake.
- **Build a working reimagining:** implement a complete, playable game in Lua on TIC-80.
- **Reflect critically:** document design decisions, trade-offs, and lessons learned in an accompanying write-up.

## Repository Structure

```
├── game.lua          # Game source code
├── remake/           # HTML export, playable in the browser
└── writeup/
    └── README.md     # Design write-up (~1,000 words)
```

## Running the Game

**In the browser:** open the HTML export via this repository's GitHub Pages site.

**In TIC-80:**

```
cd game
tic80 --fs .
load game.lua
```

## Building the HTML Export

```
cd game
tic80 --fs .
load game.lua
export html remake.zip
unzip remake.zip
chmod a+r cart.tic
```

If the project uses `middleclass` or `std.strict`, bundle the dependencies into a single file before exporting. Install the tooling once:

```
luarocks install --local std.strict
luarocks install --local amalg
```

Then rebuild after each change:

```
~/.luarocks/bin/amalg.lua -o exported_game.lua middleclass std.strict -s game.lua
tic80 --fs .
load exported_game.lua
export html remake.zip
unzip remake.zip
chmod a+r cart.tic
```

> **Note:** If changes don't appear on GitHub Pages after a refresh, clear your browser cache or open the page in a private window.

## Write-Up

A full discussion of our design process, the original game's defining qualities, and how TIC-80 shaped our approach is available in [`writeup/README.md`](writeup/README.md).
