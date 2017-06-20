local RPPostUpdate = {}

--
-- Includes
--

local RPGlobals       = require("src/rpglobals")
local RPSprites       = require("src/rpsprites")
local RPCheckEntities = require("src/rpcheckentities")
local RPFastClear     = require("src/rpfastclear")
local RPSchoolbag     = require("src/rpschoolbag")
local RPSoulJar       = require("src/rpsouljar")
local RPFastTravel    = require("src/rpfasttravel")
local RPSpeedrun      = require("src/rpspeedrun")

--
-- PostUpdate functions
--

-- Check various things once per game frame (30 times a second)
-- (this will not fire while the floor/room is loading)
-- ModCallbacks.MC_POST_UPDATE (1)
function RPPostUpdate:Main()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()

  -- Keep track of the total amount of rooms cleared on this run thus far
  RPPostUpdate:CheckRoomCleared()

  -- Keep track of our max hearts if we are Keeper
  -- (to fix the Greed's Gullet bug and the double coin / nickel healing bug)
  RPPostUpdate:CheckKeeperHearts()

  -- Check on every frame to see if we need to open the doors
  RPFastClear:PostUpdate()

  -- Check for The Book of Sin (for Bookworm)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SIN_SEEDED) and
     RPGlobals.run.touchedBookOfSin == false then

    -- We can't just put the real The Book of Sin in the pools and swap it out on pickup because
    -- the item pickup text would be wrong
    RPGlobals.run.touchedBookOfSin = true
    player:AddCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SIN, 0, false) -- 97
    Isaac.DebugString("Removing collectible 97")
    player:AddCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SIN_SEEDED, 4, false)

    -- Fix the bug where doing this swap will mess up their charges if they happen to have The Battery
    while player:GetBatteryCharge() < batteryCharge do
      player:SetActiveCharge(player:GetActiveCharge() + 1) -- This will add 1 charge to their battery
    end
  end

  -- Check for Eden's Soul (to fix the charge bug)
  if activeItem == CollectibleType.COLLECTIBLE_EDENS_SOUL then -- 490
    if RPGlobals.run.edensSoulSet and RPGlobals.run.edensSoulCharges ~= activeCharge then
      RPGlobals.run.edensSoulCharges = activeCharge
      Isaac.DebugString("Eden's Soul gained a charge, now at: " .. tostring(activeCharge))
    elseif RPGlobals.run.edensSoulSet == false then
      RPGlobals.run.edensSoulSet = true
      player:SetActiveCharge(RPGlobals.run.edensSoulCharges)
      Isaac.DebugString("Picked up Eden's Soul, setting charges to: " .. tostring(RPGlobals.run.edensSoulCharges))
    end
  else
    RPGlobals.run.edensSoulSet = false
  end

  -- Replace the bugged Scolex champion with the non-champion version (1/2)
  if RPGlobals.run.replaceBuggedScolex ~= 0 and
     RPGlobals.run.replaceBuggedScolex >= gameFrameCount then

    RPGlobals.run.replaceBuggedScolex = 0
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_PIN and entity.Variant == 1 and -- 62.1 (Scolex)
         entity:ToNPC():GetBossColorIdx() == 15 then -- The bugged black champion type

        entity:ToNPC():Morph(EntityType.ENTITY_PIN, 1, 0, -1) -- 62.1 (Scolex)
      end
    end
    Isaac.DebugString("Fixed the bugged Scolex champion.")
  end

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

  -- Check all the grid entities in the room
  RPCheckEntities:Grid()

  -- Check all the non-grid entities in the room
  RPCheckEntities:NonGrid()

  -- Check for item drop inputs (fast-drop)
  RPPostUpdate:CheckDropInput()

  -- Check for Schoolbag switch inputs
  -- (and other miscellaneous Schoolbag activities)
  RPSchoolbag:CheckActiveCharges()
  RPSchoolbag:CheckEmptyActive()
  RPSchoolbag:CheckBossRush()
  RPSchoolbag:CheckInput()

  -- Do race related checks
  RPPostUpdate:RaceChecks()
end

-- Keep track of the total amount of rooms cleared on this run thus far
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

  -- If the room just got changed to a cleared state, increment the variables for the bag familiars
  RPFastClear:IncrementBagFamiliars()

  -- Give a charge to the player's Schoolbag item
  RPSchoolbag.AddCharge()
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

-- Check for item drop inputs (fast-drop)
function RPPostUpdate:CheckDropInput()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local card1 = player:GetCard(0)
  local card2 = player:GetCard(1)
  local pill1 = player:GetPill(0)
  local pill2 = player:GetPill(1)
  local trinket1 = player:GetTrinket(0)
  local trinket2 = player:GetTrinket(1)

  -- We don't want to drop items if the player is intending to do a Schoolbag switch
  -- Furthermore, it isn't possible to drop/delete a player's 2nd card/pill slot
  -- (we are able to delete the first slot by adding a null card)
  -- So we have to disable the fast-drop feature if the player has an item that allows a 2nd card/pill slot
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_STARTER_DECK) or -- 251
     player:HasCollectible(CollectibleType.COLLECTIBLE_LITTLE_BAGGY) or -- 252
     player:HasCollectible(CollectibleType.COLLECTIBLE_DEEP_POCKETS) or -- 416
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLYDACTYLY) then -- 454

    return
  end

  -- Check for the input
  -- (use "IsActionPressed()" instead of "IsActionTriggered()" because
  -- new players might not know about the fast-drop feature and will just keep the button pressed down)
  if Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex) == false then -- 11
    return
  end

  local droppedCardPill = false
  if card1 ~= 0 and card2 == 0 and pill2 == 0 then
    -- Drop the card
    droppedCardPill = true
    player:AddCard(0)
    Isaac.DebugString("Dropped card " .. tostring(card1) .. ".")
  elseif pill1 ~= 0 and card2 == 0 and pill2 == 0 then
    -- Drop the pill
    droppedCardPill = true
    player:AddPill(0)
    Isaac.DebugString("Dropped pill " .. tostring(card1) .. ".")
  end

  -- Trinkets
  if trinket1 ~= 0 then
    -- Drop the first trinket
    player:DropTrinket(player.Position, false) -- The second argument is ReplaceTick

    -- If it is overlapping with a card or pill, we should find a new square to drop it on
    if droppedCardPill then
      -- Search for the dropped trinket
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        if entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_TRINKET and -- 350
           entity.SubType == trinket1 and
           entity.Position.X == player.Position.X and
           entity.Position.Y == player.Position.Y then

          -- We found the dropped trinket
          entity:Remove()

          -- Find a free location for the first trinket
          local newPos = room:FindFreePickupSpawnPosition(player.Position, 0, true)

          -- Respawn it
          game:Spawn(entity.Type, entity.Variant, newPos, entity.Velocity,
                     entity.Parent, entity.SubType, entity.InitSeed)
        end
      end
    end
  end
  if trinket2 ~= 0 then
    -- Drop the second trinket
    player:DropTrinket(player.Position, false) -- The second argument is ReplaceTick

    -- Search for the dropped trinket
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_PICKUP and -- 5
         entity.Variant == PickupVariant.PICKUP_TRINKET and -- 350
         entity.SubType == trinket2 and
         entity.Position.X == player.Position.X and
         entity.Position.Y == player.Position.Y then

        -- We found the dropped trinket
        entity:Remove()

        -- Find a free location for the first trinket
        local newPos = room:FindFreePickupSpawnPosition(player.Position, 0, true)

        -- Respawn it
        game:Spawn(entity.Type, entity.Variant, newPos, entity.Velocity,
                   entity.Parent, entity.SubType, entity.InitSeed)
      end
    end
  end
end

-- Do race related checks
-- (some race related checks are also in CheckGridEntities, CheckEntities, and CheckEntitiesNPC
-- so that we don't have to iterate through all of the entities in the room twice)
function RPPostUpdate:RaceChecks()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local gameFrameCount = game:GetFrameCount()
  local isaacFrameCount = Isaac.GetFrameCount()

  -- Ban Basement 1 Treasure Rooms (2/2)
  RPPostUpdate:CheckBanB1TreasureRoom()

  -- Check to see if we need to start the speedrun timer
  RPSpeedrun:StartTimer()

  -- Make race winners get sparklies and fireworks
  if (RPGlobals.raceVars.finished == true and
      RPGlobals.race.status == "none" and
      RPGlobals.race.place == 1 and
      RPGlobals.race.numEntrants >= 3) or
     RPSpeedrun.finished then

    -- Give Isaac sparkly feet (1000.103.0)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ULTRA_GREED_BLING, 0,
                player.Position + RandomVector():__mul(10), Vector(0, 0), nil)

    -- Spawn 30 fireworks (1000.104.0)
    -- (some can be duds randomly and not spawn any fireworks after the 20 frame countdown)
    if RPGlobals.raceVars.fireworks < 40 and gameFrameCount % 20 == 0 then
      for i = 1, 5 do
        RPGlobals.raceVars.fireworks = RPGlobals.raceVars.fireworks + 1
        local firework = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIREWORKS, 0,
                                     RPGlobals:GridToPos(math.random(1, 11), math.random(2, 8)),
                                     Vector(0, 0), nil) -- 0,12  0,8
        local fireworkEffect = firework:ToEffect()
        fireworkEffect:SetTimeout(20)
      end
    end
  end

  -- Check to see if the player just picked up the "Victory Lap" custom item
  if player:HasCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP) then
    -- Remove it so that we don't trigger this behavior again on the next frame
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP)

    -- Remove the final place graphic if it is showing
    RPSprites:Init("place2", 0)

    -- Make them float upwards
    -- (the code is loosely copied from the "RPFastTravel:CheckTrapdoorEnter()" function)
    RPGlobals.run.trapdoor.state = 1
    Isaac.DebugString("Trapdoor state: " .. RPGlobals.run.trapdoor.state .. " (from Victory Lap)")
    RPGlobals.run.trapdoor.upwards = true
    RPGlobals.run.trapdoor.frame = isaacFrameCount + 40
    player.ControlsEnabled = false
    player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0
    -- (this is necessary so that enemy attacks don't move the player while they are doing the jumping animation)
    player.Velocity = Vector(0, 0) -- Remove all of the player's momentum
    player:PlayExtraAnimation("LightTravel")
    RPGlobals.run.currentFloor = RPGlobals.run.currentFloor - 1
    -- This is needed or else state 5 will not correctly trigger
    -- (because the PostNewRoom callback will occur 3 times instead of 2)
    RPGlobals.raceVars.victoryLaps = RPGlobals.raceVars.victoryLaps + 1
  end

  -- Check to see if the player just picked up the "Finish" custom item
  if player:HasCollectible(CollectibleType.COLLECTIBLE_FINISHED) then
    -- Remove the final place graphic if it is showing
    RPSprites:Init("place2", 0)

    -- No animations will advance once the game is fading out,
    -- and the first frame of the item pickup animation looks very strange,
    -- so just make the player invisible to compensate
    player.Visible = false

    -- Go back to the title screen
    game:Fadeout(0.0275, RPGlobals.FadeoutTarget.FADEOUT_TITLE_SCREEN) -- 2
  end
end

-- Ban Basement 1 Treasure Rooms
-- (this has to be in both PostRender and PostUpdate because
-- we want it to already be barred when the seed is fading in and
-- having it only in PostRender makes the door not solid)
function RPPostUpdate:CheckBanB1TreasureRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()

  if stage == 1 and
     roomType ~= RoomType.ROOM_SECRET and -- 7
     RPGlobals.race.rFormat == "seeded" then

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
