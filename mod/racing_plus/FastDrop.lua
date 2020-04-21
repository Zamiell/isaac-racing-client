local FastDrop = {}

-- Includes
local g = require("racing_plus/globals")

function FastDrop:Main(target)
  -- Fast-drop is disabled during when the player is holding an item above their head
  if not g.p:IsItemQueueEmpty() then
    return
  end

  -- Trinkets (this does handle the Tick properly)
  if target == "both" or target == "trinket" then
    local pos3 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
    g.p:DropTrinket(pos3, false)
    local pos4 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
    g.p:DropTrinket(pos4, false)
  end

  -- Pocket items (cards, pills, runes, etc.)
  if target == "both" or target == "pocket" then
    local pos1 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
    g.p:DropPoketItem(0, pos1) -- Spider misspelled this
    local pos2 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
    g.p:DropPoketItem(1, pos2)
  end
end

return FastDrop
