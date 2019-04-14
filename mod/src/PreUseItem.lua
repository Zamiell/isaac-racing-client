local PreUseItem = {}

-- Includes
local g         = require("src/globals")
local Schoolbag = require("src/schoolbag")

--
-- Pre-use collectible item functions
-- ModCallbacks.MC_PRE_USE_ITEM (23)
--

-- CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER (84)
-- This callback is used naturally by Ehwaz (Passage) runes
function PreUseItem:Item84()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)

  -- Prevent the racers from "cheating" by using the shovel on Womb 2 in the "Everything" race goal
  if g.race.goal == "Everything" and
     stage == 8 then

    -- Signal that what they did was illegal
    player:AnimateSad()

    -- By returning true, it will cancel the original effect
    return true
  end
end

-- CollectibleType.COLLECTIBLE_BOOK_OF_SIN (97)
function PreUseItem:Item97()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- The Book of Sin has an equal chance to spawn a heart, coin, bomb, key, battery, pill, or card/rune
  g.RNGCounter.BookOfSin = g:IncrementRNG(g.RNGCounter.BookOfSin)
  math.randomseed(g.RNGCounter.BookOfSin)
  local bookPickupType = math.random(1, 7)
  g.RNGCounter.BookOfSin = g:IncrementRNG(g.RNGCounter.BookOfSin)

  local pos = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  local vel = Vector(0, 0)

  if bookPickupType == 1 then
    -- Random Heart - 5.10.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel,
               player, 0, g.RNGCounter.BookOfSin)

  elseif bookPickupType == 2 then
    -- Random Coin - 5.20.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, player, 0, g.RNGCounter.BookOfSin)

  elseif bookPickupType == 3 then
    -- Random Bomb - 5.40.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, g.RNGCounter.BookOfSin)

  elseif bookPickupType == 4 then
    -- Random Key - 5.30.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel, player, 0, g.RNGCounter.BookOfSin)

  elseif bookPickupType == 5 then
    -- Lil' Battery - 5.90.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, pos, vel,
               player, 0, g.RNGCounter.BookOfSin)

  elseif bookPickupType == 6 then
    -- Random Pill - 5.70.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pos, vel, player, 0, g.RNGCounter.BookOfSin)

  elseif bookPickupType == 7 then
    -- Random Card/Rune - 5.300.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, vel,
               player, 0, g.RNGCounter.BookOfSin)
  end

  -- When we return from the function below, no animation will play, so we have to explitily perform one
  player:AnimateCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SIN, "UseItem", "PlayerPickup") -- 97

  -- By returning true, it will cancel the original effect
  return true
end

-- CollectibleType.COLLECTIBLE_DEAD_SEA_SCROLLS (124)
function PreUseItem:Item124()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  g.RNGCounter.DeadSeaScrolls = g:IncrementRNG(g.RNGCounter.DeadSeaScrolls)
  math.randomseed(g.RNGCounter.DeadSeaScrolls)
  local effectType = math.random(1, 28)

  local effects = { -- 26 total item effects
    -- https://bindingofisaacrebirth.gamepedia.com/Dead_Sea_Scrolls
    -- Listed in alphabetical order
    CollectibleType.COLLECTIBLE_ANARCHIST_COOKBOOK, -- 65 (1)
    CollectibleType.COLLECTIBLE_BOBS_ROTTEN_HEAD, -- 42 (2)
    CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, -- 34 (3)
    CollectibleType.COLLECTIBLE_BOOK_REVELATIONS, -- 78 (4)
    CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, -- 58 (5)
    CollectibleType.COLLECTIBLE_BOOK_OF_SIN, -- 97 (6)
    CollectibleType.COLLECTIBLE_CRACK_THE_SKY, -- 160 (7)
    CollectibleType.COLLECTIBLE_DECK_OF_CARDS, -- 85 (8)
    CollectibleType.COLLECTIBLE_GAMEKID, -- 93 (9)
    CollectibleType.COLLECTIBLE_HOURGLASS, -- 66 (10)
    CollectibleType.COLLECTIBLE_KAMIKAZE, -- 40 (11)
    CollectibleType.COLLECTIBLE_LEMON_MISHAP, -- 56 (12)
    CollectibleType.COLLECTIBLE_MOMS_BOTTLE_PILLS, -- 102 (13)
    CollectibleType.COLLECTIBLE_MOMS_BRA, -- 39 (14)
    CollectibleType.COLLECTIBLE_MONSTROS_TOOTH, -- 86 (15)
    CollectibleType.COLLECTIBLE_MR_BOOM, -- 37 (16)
    CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN, -- 77 (17)
    CollectibleType.COLLECTIBLE_THE_NAIL, -- 83 (18)
    CollectibleType.COLLECTIBLE_PINKING_SHEARS, -- 107 (19)
    CollectibleType.COLLECTIBLE_SATANIC_BIBLE, -- 292 (20)
    CollectibleType.COLLECTIBLE_SHOOP_DA_WHOOP, -- 49 (21)
    CollectibleType.COLLECTIBLE_TAMMYS_HEAD, -- 38 (22)
    CollectibleType.COLLECTIBLE_TELEPORT, -- 44 (23)
    CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER, -- 84 (24)
    CollectibleType.COLLECTIBLE_YUM_HEART, -- 45 (25)
    CollectibleType.COLLECTIBLE_WOODEN_NICKEL, -- 349 (26)
  }

  if effectType == 27 then
    player:UsePill(PillEffect.PILLEFFECT_EXPLOSIVE_DIARRHEA, PillColor.PILL_NULL) -- 4, 0
  elseif effectType == 28 then
    player:UsePill(PillEffect.PILLEFFECT_LEMON_PARTY, PillColor.PILL_NULL) -- 26, 0
  else
    player:UseActiveItem(effects[effectType], false, false, false, false)
  end
  Isaac.DebugString("Used Dead Sea Scrolls effect: " .. tostring(effectType))

  -- Cancel the original effect
  return true
end

-- CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS (422)
function PreUseItem:Item422()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomVariant = roomDesc.Data.Variant
  local player = game:GetPlayer(0)

  -- Prevent the usage of the Glowing Hour Glass in the pre-race room
  if roomVariant == 9999 then -- Only the pre-race room has this specific ID
    -- We want to signify to the player that using the Glowing Hour Glass here is forbidden
    player:AnimateSad()
    return true
  end

  -- Reset the Schoolbag
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) and
     player:HasTrinket(TrinketType.TRINKET_BROKEN_REMOTE) == false then
     -- Broken Remote cancels the Glowing Hour Glass effect

    Isaac.DebugString("Rewinding the Schoolbag item.")
    g.run.schoolbag.item = g.run.schoolbag.lastRoomItem
    g.run.schoolbag.nextRoomCharge = true
    -- If we don't wait until the next room is entered, the slot 1 charge will just apply to the Glowing Hour Glass
    -- and not the item that was in the Schoolbag
    g.run.schoolbag.charge = g.run.schoolbag.lastRoomSlot2Charges
    if g.run.schoolbag.item == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then
       g.run.schoolbag.charge = 0 -- Prevent using the Glowing Hour Glass over and over
    end
    Schoolbag.sprites.item = nil
  end
end

-- CollectibleType.COLLECTIBLE_SMELTER (479)
-- This callback is used naturally by Gulp! pills
function PreUseItem:Item479()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  local trinket1 = player:GetTrinket(0) -- This will be 0 if there is no trinket
  local trinket2 = player:GetTrinket(1) -- This will be 0 if there is no trinket

  if trinket1 ~= 0 then
    -- Send a message to the item tracker to add this trinket
    Isaac.DebugString("Gulping trinket " .. trinket1)
  end

  if trinket2 ~= 0 then
    -- Send a message to the item tracker to add this trinket
    Isaac.DebugString("Gulping trinket " .. trinket2)
  end

  -- By returning nothing, it will go on to do the Smelter effect
end

function PreUseItem:PreventItemPedestalEffects(itemID)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)

  -- Car Battery will mess up the D6 and D100 (and possibly others) because
  -- this function will be entered twice on the same frame (and there will be no time to replace the pedestal)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then -- 356
    return
  end

  if PreUseItem:UnreplacedItemsExist() then
    Isaac.DebugString("Canceling item " .. tostring(itemID) .. " due to unreplaced items in the room.")
    g.run.rechargeItemFrame = gameFrameCount + 1
    return true
  end
end

function PreUseItem:UnreplacedItemsExist()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  -- Look for pedestals that have not been replaced yet
  local entities = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                    -1, false, false)
  for i, entity in pairs(entities) do
    local alreadyReplaced = false
    for j = 1, #g.run.replacedPedestals do
      if g.run.replacedPedestals[j].room == roomIndex and
         g.run.replacedPedestals[j].seed == entity.InitSeed then

        alreadyReplaced = true
        break
      end
    end

    if alreadyReplaced == false then
      return true
    end
  end

  return false
end

return PreUseItem
