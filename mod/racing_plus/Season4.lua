local Season4 = {}

-- Includes
local g = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Schoolbag = require("racing_plus/schoolbag")

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season4:PostGameStarted()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 4) challenge.")

  -- Everyone starts with the Schoolbag in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Give extra items to some characters
  if character == PlayerType.PLAYER_LAZARUS then -- 8
    -- Lazarus does not start with a pill to prevent players resetting for a good pill
    g.p:SetPill(0, 0)
  elseif character == PlayerType.PLAYER_LILITH then -- 13
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_INCUBUS, 0, false) -- 360
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360

    -- Don't show it on the item tracker
    Isaac.DebugString("Removing collectible 360 (Incubus)")

    -- If we switch characters, we want to remove the extra Incubus
    g.run.extraIncubus = true
  end

  -- Give the additional (chosen) starting item/build
  -- (the item choice is stored in the second half of the "charOrder" variable)
  local itemID = RacingPlusData:Get("charOrder-R7S4")[Speedrun.charNum + 7]
  if itemID < 1000 then
    -- This is a single item build
    g.p:AddCollectible(itemID, 0, false)
    g.itemPool:RemoveCollectible(itemID)
  else
    -- This is a build with two items
    if itemID == 1001 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER, 0, false) -- 153
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_INNER_EYE, 0, false) -- 2
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2
    elseif itemID == 1002 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY, 0, false) -- 68
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) -- 68
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL, 0, false) -- 132
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) -- 132
    elseif itemID == 1003 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND, 0, false) -- 257
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND) -- 257
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_13_LUCK, 0, false)
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID, 0, false) -- 317
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID) -- 317
    elseif itemID == 1004 then
      -- Start with the Kamikaze in the active slot for quality of life purposes
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE, 0, false) -- 40
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE) -- 40
      Schoolbag:Put(CollectibleType.COLLECTIBLE_D6, 6) -- 105
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_HOST_HAT, 0, false) -- 375
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_HOST_HAT) -- 375
    elseif itemID == 1005 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER, 0, false) -- 494
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) -- 494
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 249
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 249
    elseif itemID == 1006 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, 0, false) -- 69
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) -- 69
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_STEVEN, 0, false) -- 50
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_STEVEN) -- 50
    end
  end
end

return Season4
