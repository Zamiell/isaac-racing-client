local RPPostUpdate = {}

-- Includes
local RPGlobals            = require("src/rpglobals")
local RPPills              = require("src/rppills")
local RPCheckEntities      = require("src/rpcheckentities")
local RPFastClear          = require("src/rpfastclear")
local RPFastDrop           = require("src/rpfastdrop")
local RPSchoolbag          = require("src/rpschoolbag")
local RPSoulJar            = require("src/rpsouljar")
local RPFastTravel         = require("src/rpfasttravel")
local RPRace               = require("src/rprace")
local RPSpeedrun           = require("src/rpspeedrun")
local RPSpeedrunPostUpdate = require("src/rpspeedrunpostupdate")
local RPChangeCharOrder    = require("src/rpchangecharorder")

-- Check various things once per game frame (30 times a second)
-- (this will not fire while the floor/room is loading)
-- ModCallbacks.MC_POST_UPDATE (1)
function RPPostUpdate:Main()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local activeCharge = player:GetActiveCharge()
  local sfx = SFXManager()

  -- Keep track of the total amount of rooms cleared on this run thus far
  RPPostUpdate:CheckRoomCleared()

  -- Keep track of our max hearts if we are Keeper
  -- (to fix the Greed's Gullet bug and the double coin / nickel healing bug)
  RPPostUpdate:CheckKeeperHearts()

  -- Check on every frame to see if we need to open the doors
  -- (we can't just add this as a new MC_POST_UPDATE callback because
  -- it causes a bug where the Womb 2 trapdoor appears for a frame)
  RPFastClear:PostUpdate()

  -- Fix The Battery + 9 Volt synergy (2/2)
  if RPGlobals.run.giveExtraCharge then
    RPGlobals.run.giveExtraCharge = false
    player:SetActiveCharge(activeCharge + 1)
  end

  -- Check the player's health for the Soul Jar mechanic
  RPSoulJar:CheckHealth()

  -- Check to see if we are leaving a crawlspace (and if we are softlocked in a Boss Rush)
  RPFastTravel:CheckCrawlspaceExit()
  RPFastTravel:CheckCrawlspaceSoftlock()

  -- Ban Basement 1 Treasure Rooms (2/2)
  RPPostUpdate:CheckBanB1TreasureRoom()

  -- Check all the grid entities in the room
  RPCheckEntities:Grid()

  -- Check all the non-grid entities in the room
  RPCheckEntities:NonGrid()

  -- Check for a Haunt fight speedup
  -- (we want to detach the first Lil' Haunt from a Haunt early because the vanilla game takes too long)
  RPPostUpdate:CheckHauntSpeedup()

  -- Check to see if an item that messes with item pedestals got canceled
  -- (this has to be done a frame later or else it won't work)
  if RPGlobals.run.rechargeItemFrame == gameFrameCount then
    RPGlobals.run.rechargeItemFrame = 0
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
  RPFastDrop:CheckDropInput()

  -- Check for Schoolbag switch inputs
  -- (and other miscellaneous Schoolbag activities)
  RPSchoolbag:CheckActiveCharges()
  RPSchoolbag:CheckEmptyActive()
  RPSchoolbag:CheckBossRush()
  RPSchoolbag:CheckInput()

  -- Check for the vanilla Schoolbag and convert it to the Racing+ Schoolbag if necessary
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then -- 534
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) -- 534
    if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false then
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    end
  end

  RPPills:CheckPHD()

  RPRace:PostUpdate()
  RPSpeedrunPostUpdate:Main()
end

-- Keep track of the when the room is cleared
function RPPostUpdate:CheckRoomCleared()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomClear = room:IsClear()

  -- Check the clear status of the room and compare it to what it was a frame ago
  if roomClear == RPGlobals.run.currentRoomClearState then
    return
  end

  RPGlobals.run.currentRoomClearState = roomClear

  if roomClear == false then
    return
  end

  if RPGlobals.run.fastCleared == false then
    Isaac.DebugString("Vanilla room clear detected!")
  end

  -- If the room just got changed to a cleared state, increment the variables for the bag familiars
  RPFastClear:IncrementBagFamiliars()

  -- Give a charge to the player's Schoolbag item
  RPSchoolbag:AddCharge()
end

-- Keep track of our hearts if we are Keeper
-- (to fix the Greed's Gullet bug and the double coin / nickel healing bug)
function RPPostUpdate:CheckKeeperHearts()
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

  if baseHearts ~= RPGlobals.run.keeper.baseHearts then
    -- Our health changed; we took a devil deal, took a health down pill, or went from 1 heart to 2 hearts
    local heartsDiff = baseHearts - RPGlobals.run.keeper.baseHearts
    RPGlobals.run.keeper.baseHearts = RPGlobals.run.keeper.baseHearts + heartsDiff
    Isaac.DebugString("Set new Keeper baseHearts to: " .. tostring(RPGlobals.run.keeper.baseHearts) ..
                      " (from detection, change was " .. tostring(heartsDiff) .. ")")
  end

  -- Check Keeper coin count
  if coins ~= RPGlobals.run.keeper.coins then
    local coinDifference = coins - RPGlobals.run.keeper.coins
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
    RPGlobals.run.keeper.coins = player:GetNumCoins()
  end
end

-- Speed up the first Lil' Haunt attached to a Haunt (3/3)
function RPPostUpdate:CheckHauntSpeedup()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local blackChampionHaunt = RPGlobals.run.speedLilHauntsBlack
  if gameFrameCount ~= RPGlobals.run.speedLilHauntsFrame then
    return
  end
  RPGlobals.run.speedLilHauntsFrame = 0
  RPGlobals.run.speedLilHauntsBlack = false

  -- Detach the first Lil' Haunt for each Haunt in the room
  for i = 1, #RPGlobals.run.currentHaunts do
    -- Get the index of all the Lil' Haunts attached to this particular haunt and sort them
    local indexes = {}
    for j, lilHaunt in pairs(RPGlobals.run.currentLilHaunts) do
      if lilHaunt.parentIndex ~= nil and
         lilHaunt.parentIndex == RPGlobals.run.currentHaunts[i] then

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
          Isaac.DebugString("Error: Lil Haunt at index " .. tostring(entity.Index) ..
                            " was not able to be converted to an NPC.")
          for k, entity2 in pairs(Isaac.GetRoomEntities()) do
            if entity2.Type == EntityType.ENTITY_THE_HAUNT then
              local string = "DEBUG: "
              if entity2.Variant == 10 then
                string = string .. "Lil' "
              end
              string = string .. "Haunt found at index " .. tostring(entity2.Index)
              if entity2.Parent == nil then
                string = string .. " with no parent."
              else
                string = string .. " with parent index " .. tostring(entity2.Parent.Index)
              end
              Isaac.DebugString(string)
            end
          end
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
        if RPGlobals.run.currentLilHaunts[index] == nil then
          Isaac.DebugString("Error: Lil Haunt at index " .. tostring(entity.Index) ..
                            " was not already in the \"currentLilHaunts\" table.")
        end

        Isaac.DebugString("Manually detached a Lil' Haunt with index " .. tostring(entity.Index) ..
                          " on frame: " .. tostring(gameFrameCount))
      end
    end
  end
end

function RPPostUpdate:RaceChecks()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  -- Check to see if the player just picked up the a Crown of Light from a Basement 1 Treasure Room fart-reroll
  if RPGlobals.run.removedCrownHearts == false and
     player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     RPGlobals.run.roomsEntered == 1 then -- They are still in the starting room

    -- The player started with Crown of Light, so we don't need to even go into the below code block
    RPGlobals.run.removedCrownHearts = true
  end
  if RPGlobals.run.removedCrownHearts == false and
     stage == LevelStage.STAGE1_1 and -- 1
     player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     (((RPGlobals.race.rFormat == "unseeded" or
        RPGlobals.race.rFormat == "diversity") and
       RPGlobals.race.status == "in progress" and
       (RPGlobals.race.ranked and RPGlobals.race.solo) == false) or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)")) then

     -- Remove the two soul hearts that the Crown of Light gives
     RPGlobals.run.removedCrownHearts = true
     player:AddSoulHearts(-4)
  end

  -- Handle things for the "Change Char Order" custom challenge
  RPChangeCharOrder:PostUpdate()
end

-- Ban Basement 1 Treasure Rooms
-- (this has to be in both MC_POST_RENDER and MC_POST_UPDATE because
-- we want it to already be barred when the seed is fading in and
-- having it only in MC_POST_RENDER makes the door not solid)
function RPPostUpdate:CheckBanB1TreasureRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local challenge = Isaac.GetChallenge()

  if stage == 1 and
     roomType ~= RoomType.ROOM_SECRET and -- 7
     (RPGlobals.race.rFormat == "seeded" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
      (challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") and
       RPSpeedrun.charNum >= 2)) then

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

return RPPostUpdate
