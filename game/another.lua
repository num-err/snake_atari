-- title:  3D Tic-Tac-Toe
-- author: CS86 Lab
-- desc:   remake of the Atari 2600 4x4x4 3D Tic-Tac-Toe
-- script: lua

--------------------------------------------------
-- Board representation
--------------------------------------------------
-- The cube is 4x4x4 (x,y,z each 0..3), stored as a flat
-- 64-entry table. 0 = empty, 1 = player 1 (X), 2 = player 2 (O).

local SIZE = 4

function idx(x, y, z)
  -- converts 0-based (x,y,z) into a 1-based flat table index
  return z * SIZE * SIZE + y * SIZE + x + 1
end

board = {}
for i = 1, SIZE * SIZE * SIZE do board[i] = 0 end

--------------------------------------------------
-- Generate all 76 winning lines
--------------------------------------------------
-- Rather than hand-typing every line, we generate them from
-- 13 direction vectors (every distinct 3D line direction,
-- with a vector and its negation counted only once).

local DIRECTIONS = {
  {1,0,0}, {0,1,0}, {0,0,1},
  {1,1,0}, {1,-1,0},
  {1,0,1}, {1,0,-1},
  {0,1,1}, {0,1,-1},
  {1,1,1}, {1,1,-1}, {1,-1,1}, {1,-1,-1},
}

winLines = {}

for x = 0, SIZE-1 do
  for y = 0, SIZE-1 do
    for z = 0, SIZE-1 do
      for _, d in ipairs(DIRECTIONS) do
        local dx, dy, dz = d[1], d[2], d[3]
        local ex, ey, ez = x + 3*dx, y + 3*dy, z + 3*dz
        -- only keep this line if all 4 cells stay inside the cube
        if ex >= 0 and ex < SIZE and ey >= 0 and ey < SIZE and ez >= 0 and ez < SIZE then
          local line = {}
          for i = 0, 3 do
            table.insert(line, idx(x + i*dx, y + i*dy, z + i*dz))
          end
          table.insert(winLines, line)
        end
      end
    end
  end
end
-- winLines now contains exactly 76 entries, each a list of 4 board indices.

--------------------------------------------------
-- Game state
--------------------------------------------------

cursor = { x = 0, y = 0, z = 0 }
turn = 1          -- 1 or 2, whose move it is
winner = nil      -- nil, 1, or 2
winningLine = nil -- set to the winning line's cell list when someone wins
isDraw = false

function resetGame()
  for i = 1, SIZE*SIZE*SIZE do board[i] = 0 end
  cursor = { x = 0, y = 0, z = 0 }
  turn = 1
  winner = nil
  winningLine = nil
  isDraw = false
end

-- Checks whether player p has completed any line. Returns the
-- winning line (a table of 4 indices) if so, otherwise nil.
function checkWin(p)
  for _, line in ipairs(winLines) do
    local allMatch = true
    for _, i in ipairs(line) do
      if board[i] ~= p then
        allMatch = false
        break
      end
    end
    if allMatch then return line end
  end
  return nil
end

function boardIsFull()
  for i = 1, SIZE*SIZE*SIZE do
    if board[i] == 0 then return false end
  end
  return true
end

--------------------------------------------------
-- Input handling
--------------------------------------------------

function handleInput()
  if btnp(0) then cursor.y = (cursor.y - 1) % SIZE end -- up
  if btnp(1) then cursor.y = (cursor.y + 1) % SIZE end -- down
  if btnp(2) then cursor.x = (cursor.x - 1) % SIZE end -- left
  if btnp(3) then cursor.x = (cursor.x + 1) % SIZE end -- right

  if btnp(4) then cursor.z = (cursor.z + 1) % SIZE end -- A: layer forward
  if btnp(5) then cursor.z = (cursor.z - 1) % SIZE end -- B: layer backward

  if btnp(6) then -- X: place a mark
    local i = idx(cursor.x, cursor.y, cursor.z)
    if board[i] == 0 then
      board[i] = turn

      local line = checkWin(turn)
      if line then
        winner = turn
        winningLine = line
      elseif boardIsFull() then
        isDraw = true
      else
        turn = (turn == 1) and 2 or 1
      end
    end
  end
end

--------------------------------------------------
-- Drawing
--------------------------------------------------

local CELL = 10
local GAP = 2
local PANEL_STRIDE = CELL + GAP
-- x-position of each of the 4 layer panels on screen
local PANEL_X = {6, 66, 126, 186}
local PANEL_Y = 24

function cellIsInWinningLine(i)
  if not winningLine then return false end
  for _, wi in ipairs(winningLine) do
    if wi == i then return true end
  end
  return false
end

function drawBoard()
  for z = 0, SIZE-1 do
    local px0 = PANEL_X[z+1]

    -- panel label
    print("LAYER "..(z+1), px0, PANEL_Y - 10, 15)

    for y = 0, SIZE-1 do
      for x = 0, SIZE-1 do
        local px = px0 + x * PANEL_STRIDE
        local py = PANEL_Y + y * PANEL_STRIDE
        local i = idx(x, y, z)

        local inWinLine = cellIsInWinningLine(i)
        local baseColor = inWinLine and 4 or 13 -- yellow highlight if part of the win

        rectb(px, py, CELL, CELL, baseColor)

        if board[i] == 1 then
          print("X", px + 2, py + 1, 12)
        elseif board[i] == 2 then
          print("O", px + 2, py + 1, 6)
        end

        -- highlight the cursor, but only on the layer you're currently on
        if not winner and not isDraw and z == cursor.z and x == cursor.x and y == cursor.y then
          rectb(px - 1, py - 1, CELL + 2, CELL + 2, 11)
        end
      end
    end
  end
end

function drawStatus()
  if winner then
    local label = (winner == 1) and "X" or "O"
    print("PLAYER "..label.." WINS!  PRESS ANY BUTTON", 8, 4, (winner == 1) and 12 or 6)
  elseif isDraw then
    print("DRAW GAME!  PRESS ANY BUTTON TO RESET", 8, 4, 15)
  else
    local label = (turn == 1) and "X" or "O"
    local col = (turn == 1) and 12 or 6
    print("PLAYER "..label.."'S TURN", 8, 4, col)
    print("ARROWS: MOVE   A/B: LAYER   X: PLACE", 8, 128, 13)
  end
end

--------------------------------------------------
-- Main loop
--------------------------------------------------

function TIC()
  if winner or isDraw then
    -- any button press resets the game
    if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) or btnp(6) or btnp(7) then
      resetGame()
    end
  else
    handleInput()
  end

  cls(0)
  drawBoard()
  drawStatus()
end


-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

