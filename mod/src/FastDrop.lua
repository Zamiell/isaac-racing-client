local FastDrop = {}

-- Includes
local g = require("src/globals")

--
-- Fast drop functions
--

-- Check for fast-drop inputs
function FastDrop:CheckDropInput()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- If they do not have a hotkey bound, do nothing
  if g.race.hotkeyDrop == 0 or g.race.hotkeyDrop == nil then
    return
  end

  -- Check for the input
  -- (we check all inputs instead of "player.ControllerIndex" because
  -- a controller player might be using the keyboard to reset)
  -- (we use "IsActionPressed()" instead of "IsActionTriggered()" because
  -- it is faster to drop on press than on release)
  local pressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsButtonPressed(g.race.hotkeyDrop, i) then
      pressed = true
      break
    end
  end
  if not pressed then
    return
  end

  -- Trinkets (this does handle the Tick properly)
  local pos3 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropTrinket(pos3, false)
  local pos4 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropTrinket(pos4, false)

  -- Pocket items (cards, pills, runes, etc.)
  local pos1 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropPoketItem(0, pos1) -- Spider misspelled this
  local pos2 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropPoketItem(1, pos2)
end

-- Check for fast-drop inputs (trinket-only)
function FastDrop:CheckDropInputTrinket()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- If they do not have a hotkey bound, do nothing
  if g.race.hotkeyDropTrinket == 0 or g.race.hotkeyDropTrinket == nil then
    return
  end

  -- Check for the input
  -- (we check all inputs instead of "player.ControllerIndex" because
  -- a controller player might be using the keyboard to reset)
  -- (we use "IsActionPressed()" instead of "IsActionTriggered()" because
  -- it is faster to drop on press than on release)
  local pressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsButtonPressed(g.race.hotkeyDropTrinket, i) then
      pressed = true
      break
    end
  end
  if not pressed then
    return
  end

  -- Trinkets (this does handle the Tick properly)
  local pos1 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropTrinket(pos1, false)
  local pos2 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropTrinket(pos2, false)
end

-- Check for fast-drop inputs (pocket-item-only)
function FastDrop:CheckDropInputPocket()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- If they do not have a hotkey bound, do nothing
  if g.race.hotkeyDropPocket == 0 or g.race.hotkeyDropPocket == nil then
    return
  end

  -- Check for the input
  -- (we check all inputs instead of "player.ControllerIndex" because
  -- a controller player might be using the keyboard to reset)
  -- (we use "IsActionPressed()" instead of "IsActionTriggered()" because
  -- it is faster to drop on press than on release)
  local pressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsButtonPressed(g.race.hotkeyDropPocket, i) then
      pressed = true
      break
    end
  end
  if not pressed then
    return
  end

  -- Pocket items (cards, pills, runes, etc.)
  local pos1 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropPoketItem(0, pos1) -- Spider misspelled this
  local pos2 = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  player:DropPoketItem(1, pos2)
end

return FastDrop
