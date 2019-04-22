local PostUpdate = {}

-- Includes
local g                  = require("src/globals")
local Pills              = require("src/pills")
local CheckEntities      = require("src/checkentities")
local FastClear          = require("src/fastclear")
local FastDrop           = require("src/fastdrop")
local Schoolbag          = require("src/schoolbag")
local SoulJar            = require("src/souljar")
local FastTravel         = require("src/fasttravel")
local Race               = require("src/race")
local Speedrun           = require("src/speedrun")
local SpeedrunPostUpdate = require("src/speedrunpostupdate")
local ChangeCharOrder    = require("src/changecharorder")

-- Check various things once per game frame (30 times a second)
-- (this will not fire while the floor/room is loading)
-- ModCallbacks.MC_POST_UPDATE (1)
function PostUpdate:Main()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local activeCharge = player:GetActiveCharge()
  local sfx = SFXManager()

  -- Keep track of the total amount of rooms cleared on this run thus far
  PostUpdate:CheckRoomCleared()

  -- Keep track of our max hearts if we are Keeper
  -- (to fix the Greed's Gullet bug and the double coin / nickel healing bug)
  PostUpdate:CheckKeeperHearts()

  PostUpdate:CheckItemPickup()
  PostUpdate:CheckTransformations()

  -- Check on every frame to see if we need to open the doors
  -- (we can't just add this as a new MC_POST_UPDATE callback because
  -- it causes a bug where the Womb 2 trapdoor appears for a frame)
  FastClear:PostUpdate()

  -- Check to see if we are leaving a crawlspace (and if we are softlocked in a Boss Rush)
  FastTravel:CheckCrawlspaceExit()
  FastTravel:CheckCrawlspaceSoftlock()

  -- Ban Basement 1 Treasure Rooms (2/2)
  PostUpdate:CheckBanB1TreasureRoom()

  -- Check all the grid entities in the room
  CheckEntities:Grid()

  -- Check all the non-grid entities in the room
  CheckEntities:NonGrid()

  -- Check for a Haunt fight speedup
  -- (we want to detach the first Lil' Haunt from a Haunt early because the vanilla game takes too long)
  PostUpdate:CheckHauntSpeedup()

  -- Check to see if an item that messes with item pedestals got canceled
  -- (this has to be done a frame later or else it won't work)
  if g.run.rechargeItemFrame == gameFrameCount then
    g.run.rechargeItemFrame = 0
    player:FullCharge()
    sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  end

  -- Check for Mutant Spider's Inner Eye (a custom item)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE) then
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE)
    -- This custom item is set to not be shown on the item tracker
    player:AddCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER, 0, false) -- 153
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
    player:AddCollectible(CollectibleType.COLLECTIBLE_INNER_EYE, 0, false) -- 2
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2
  end

  -- Check for item drop inputs (fast-drop)
  FastDrop:CheckDropInput()

  -- Check for Schoolbag switch inputs
  -- (and other miscellaneous Schoolbag activities)
  Schoolbag:CheckActiveCharges()
  Schoolbag:CheckEmptyActive()
  Schoolbag:CheckBossRush()
  Schoolbag:CheckInput()

  -- Check for the vanilla Schoolbag and convert it to the Racing+ Schoolbag if necessary
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then -- 534
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) -- 534
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_SCHOOLBAG) .. " (Schoolbag)")
    if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false then
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    end
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end

  -- Check to see if the player just picked up the a Crown of Light from a Basement 1 Treasure Room fart-reroll
  PostUpdate:CrownOfLight()

  -- Check the player's health for the Soul Jar mechanic
  SoulJar:PostUpdate()

  -- Fix The Battery + 9 Volt synergy (2/2)
  if g.run.giveExtraCharge then
    g.run.giveExtraCharge = false
    player:SetActiveCharge(activeCharge + 1)
  end

  Pills:CheckPHD()

  -- Handle things for races
  Race:PostUpdate()

  -- Handle things for multi-character speedruns
  SpeedrunPostUpdate:Main()

  -- Handle things for the "Change Char Order" custom challenge
  ChangeCharOrder:PostUpdate()
end

-- Keep track of the when the room is cleared
function PostUpdate:CheckRoomCleared()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomClear = room:IsClear()

  -- Check the clear status of the room and compare it to what it was a frame ago
  if roomClear == g.run.currentRoomClearState then
    return
  end

  g.run.currentRoomClearState = roomClear

  if roomClear == false then
    return
  end

  if g.run.fastCleared == false then
    Isaac.DebugString("Vanilla room clear detected!")
  end

  -- If the room just got changed to a cleared state, increment the variables for the bag familiars
  FastClear:IncrementBagFamiliars()

  -- Give a charge to the player's Schoolbag item
  Schoolbag:AddCharge()
end

-- Keep track of our hearts if we are Keeper
-- (to fix the Greed's Gullet bug and the double coin / nickel healing bug)
function PostUpdate:CheckKeeperHearts()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local maxHearts = player:GetMaxHearts()
  local coins = player:GetNumCoins()

  if character ~= PlayerType.PLAYER_KEEPER then -- 14
    return
  end

  -- Find out how many coin containers we should have
  -- (2 is equal to 1 actual heart container)
  local coinContainers = 0
  if coins >= 99 then
    coinContainers = 8
  elseif coins >= 75 then
    coinContainers = 6
  elseif coins >= 50 then
    coinContainers = 4
  elseif coins >= 25 then
    coinContainers = 2
  end
  local baseHearts = maxHearts - coinContainers

  if baseHearts ~= g.run.keeper.baseHearts then
    -- Our health changed; we took a devil deal, took a health down pill, or went from 1 heart to 2 hearts
    local heartsDiff = baseHearts - g.run.keeper.baseHearts
    g.run.keeper.baseHearts = g.run.keeper.baseHearts + heartsDiff
    Isaac.DebugString("Set new Keeper baseHearts to: " .. tostring(g.run.keeper.baseHearts) ..
                      " (from detection, change was " .. tostring(heartsDiff) .. ")")
  end

  -- Check Keeper coin count
  if coins ~= g.run.keeper.coins then
    local coinDifference = coins - g.run.keeper.coins
    if coinDifference > 0 then
      for i = 1, coinDifference do
        local newCoins = player:GetNumCoins()
        if player:GetHearts() < player:GetMaxHearts() and
           newCoins ~= 25 and
           newCoins ~= 50 and
           newCoins ~= 75 and
           newCoins ~= 99 then

          player:AddHearts(2)
          player:AddCoins(-1)
        end
      end
    end

    -- Set the new coin count (we re-get it since it may have changed)
    g.run.keeper.coins = player:GetNumCoins()
  end
end

function PostUpdate:CheckItemPickup()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Only run the below code once per item
  if player:IsItemQueueEmpty() then
    if g.run.pickingUpItem then
      g.run.pickingUpItem = false
    end
    return
  elseif g.run.pickingUpItem then
    return
  end
  g.run.pickingUpItem = true

  -- Mark to draw the streak text for this item
  g.run.streakText = player.QueuedItem.Item.Name
  g.run.streakFrame = Isaac.GetFrameCount()

  -- Keep track of our passive items over the course of the run
  if player.QueuedItem.Item.Type ~= ItemType.ITEM_ACTIVE then -- 3
    g.run.passiveItems[#g.run.passiveItems + 1] = player.QueuedItem.Item.ID
    if player.QueuedItem.Item.ID == CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE then
      Isaac.DebugString("Adding collectible 3001 (Mutant Spider's Inner Eye)")
    end
    SpeedrunPostUpdate:CheckFirstCharacterStartingItem()
  end
end

function PostUpdate:CheckTransformations()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  for i = 0, PlayerForm.NUM_PLAYER_FORMS - 1 do
    local hasForm = player:HasPlayerForm(i)
    if hasForm ~= g.run.transformations[i] then
      g.run.transformations[i] = hasForm
      g.run.streakText = g.Transformations[i + 1]
      g.run.streakFrame = Isaac.GetFrameCount()
    end
  end

  -- In order to detect the Stompy transformation, we can't use the "player:HasPlayerForm()" function
  local stompyIndex = PlayerForm.NUM_PLAYER_FORMS -- It will always be the final index
  if player.SpriteScale.X > 1.95 and g.run.transformations[stompyIndex] == false then
    g.run.transformations[stompyIndex] = true
    g.run.streakText = g.Transformations[stompyIndex + 1]
    g.run.streakFrame = Isaac.GetFrameCount()
  end
end

-- Speed up the first Lil' Haunt attached to a Haunt (3/3)
function PostUpdate:CheckHauntSpeedup()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local blackChampionHaunt = g.run.speedLilHauntsBlack
  if g.run.speedLilHauntsFrame == 0 or
     gameFrameCount < g.run.speedLilHauntsFrame then

    return
  end

  -- Detach the first Lil' Haunt for each Haunt in the room
  for i = 1, #g.run.currentHaunts do
    -- Get the index of all the Lil' Haunts attached to this particular haunt and sort them
    local indexes = {}
    for j, lilHaunt in pairs(g.run.currentLilHaunts) do
      if lilHaunt.parentIndex ~= nil and
         lilHaunt.parentIndex == g.run.currentHaunts[i] then

        indexes[#indexes + 1] = lilHaunt.index
      end
    end
    table.sort(indexes)

    -- Manually detach the first Lil' Haunt
    -- (or the first and the second Lil' Haunt, if this is a black champion Haunt)
    for j, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Index == indexes[1] or
         (entity.Index == indexes[2] and blackChampionHaunt) then

        if entity.Index == indexes[1] then
          Isaac.DebugString("Found the first Lil' Haunt to detach at index: " .. tostring(entity.Index))
        elseif entity.Index == indexes[2] and blackChampionHaunt then
          Isaac.DebugString("Found the second Lil' Haunt to detach at index: " .. tostring(entity.Index))
        end
        local npc = entity:ToNPC()
        if npc == nil then
          Isaac.DebugString("Failed to convert Lil Haunt at index " .. tostring(entity.Index) ..
                            " to an NPC. Trying again on the next frame...")
          return
        end
        npc.State = NpcState.STATE_MOVE -- 4
        -- (doing this will detach them)

        -- We need to manually set them to visible (or else they will be invisible for some reason)
        npc.Visible = true

        -- We need to manually set the color, or else the Lil' Haunt will remain faded
        npc:SetColor(Color(1, 1, 1, 1, 0, 0, 0), 0, 0, false, false)

        -- We need to manually set their collision or else tears will pass through them
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4

        -- Add a check to make sure they are in the tracking table
        -- (this might be unnecessary; included for debugging purposes)
        local index = GetPtrHash(npc)
        if g.run.currentLilHaunts[index] == nil then
          Isaac.DebugString("Error: Lil Haunt at index " .. tostring(entity.Index) ..
                            " was not already in the \"currentLilHaunts\" table.")
          return
        end

        Isaac.DebugString("Manually detached a Lil' Haunt with index " .. tostring(entity.Index) ..
                          " on frame: " .. tostring(gameFrameCount))
      end
    end
  end

  -- Only reset the variables at the end of the function in case we hit an error above
  g.run.speedLilHauntsFrame = 0
  g.run.speedLilHauntsBlack = false
end

-- Ban Basement 1 Treasure Rooms
-- (this has to be in both MC_POST_RENDER and MC_POST_UPDATE because
-- we want it to already be barred when the seed is fading in and
-- having it only in MC_POST_RENDER makes the door not solid)
function PostUpdate:CheckBanB1TreasureRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local challenge = Isaac.GetChallenge()

  if stage == 1 and
     roomType ~= RoomType.ROOM_SECRET and -- 7
     (g.race.rFormat == "seeded" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
      (challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") and
       Speedrun.charNum >= 2) or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)")) then

    local door
    for i = 0, 7 do
      door = room:GetDoor(i)
      if door ~= nil and
         door:IsRoomType(RoomType.ROOM_TREASURE) and -- 4
         roomType ~= RoomType.ROOM_TREASURE then -- 4
         -- "door:IsOpen()" will always be true because
         -- the game tries to reopen the door in a cleared room on every frame

        door:Bar()

        -- The bars are buggy and will only appear for the first few frames, so just disable them altogether
        door.ExtraVisible = false
      end
    end
  end
end

-- Check to see if the player just picked up the a Crown of Light from a Basement 1 Treasure Room fart-reroll
function PostUpdate:CrownOfLight()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  if g.run.removedCrownHearts == false and
     player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     g.run.roomsEntered == 1 then -- They are still in the starting room

    -- The player started with Crown of Light, so we don't need to even go into the below code block
    g.run.removedCrownHearts = true
  end
  if g.run.removedCrownHearts == false and
     stage == LevelStage.STAGE1_1 and -- 1
     player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     (((g.race.rFormat == "unseeded" or
        g.race.rFormat == "diversity") and
       g.race.status == "in progress" and
       (g.race.ranked and g.race.solo) == false) or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)")) then

     -- Remove the two soul hearts that the Crown of Light gives
     g.run.removedCrownHearts = true
     player:AddSoulHearts(-4)
  end
end

return PostUpdate
