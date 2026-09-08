# Remake Project

**WIP September 24th by class; DUE October 2nd by 11:59PM**

You and your partner will study a classic atari game by remaking it in
TIC-80. You do not have to recreate every aspect of the original game,
but your remake should capture the essence of the original game. Be
mindful of taking advantage (or rebeling against) of TIC-80's
affordances, in other words, what aspects of the original game does
TIC-80 make it easy to recreate.


## Learning Objectives

- understand what makes a classic game special by distilling it to its essence;
- create a **working** reimaginiation of the game on TIC-80 in Lua;
- think and write critically about your remake.

## Deliverable

Submit your write-up on GitHub as a
[`writeup/README.md`](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).
Your writeup should be about 1024 words, it should read clearly and
look nice. You will present your work during the lab period using a
few slides, a play-test session, and a demonstration.  You should also
include your TIC-80 game as a lua file and a collection of HTML files.

```console
unix:~$ cd game
unix:~$ tic80 --fs .
tic-80:~$ load game.lua
tic-80:~$ export html remake.zip
unix:~$ unzip remake.zip
unix:~$ chmod a+r cart.tic
```

If you use [`middleclass`](https://github.com/kikito/middleclass) or
[`strict`](https://github.com/lua-stdlib/strict), exporting the game is a little more involved. First, just once, install the two packages.

```console
$ luarocks install --local std.strict
$ luarocks install --local amalg
```

Then anytime you change the game and want to export it:
```console
unix:~$ cd game
unix:~$ ~/.luarocks/bin/amalg.lua -o exported_game.lua middleclass std.strict -s game.lua
unix:~$ tic80 --fs .
tic-80:~$ load exported_game.lua
tic-80:~$ export html remake.zip
unix:~$ unzip remake.zip
unix:~$ chmod a+r cart.tic

```

**Sometimes the game data gets stale in the browser's cache. Try
resetting your browser cache (or run in a private tab) if you make a
change that isn't updated when you refresh the github pages.**
