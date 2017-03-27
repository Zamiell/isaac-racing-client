local RPPostUpdate = {}

--
-- Includes
--

local RPGlobals         = require("src/rpglobals")
local RPCheckEntities   = require("src/rpcheckentities")
local RPFastClear       = require("src/rpfastclear")
local RPSchoolbag       = require("src/rpschoolbag")
local RPSoulJar         = require("src/rpsouljar")
local RPFastTravel      = require("src/rpfasttravel")

--
-- PostUpdate functions
--

-- Check various things once per game frame (30 times a second)
-- (this will not fire while the floor/room is loading)
-- ModCallbacks.MC_POST_UPDATE (1)
function RPPostUpdate:Main()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()

  -- Keep track of the total amount of rooms cleared on this run thus far
  RPPostUpdate:CheckRoomCleared()

  -- Keep track of our max hearts if we are Keeper
  -- (to fix the Greed's Gullet bug and the double coin / nickel healing bug)
  RPPostUpdate:CheckKeeperHearts()

  -- Fast-clear for puzzle rooms
  RPFastClear:CheckPuzzleRoom()

  -- Fix Globin softlocks
  for i, globin in pairs(RPGlobals.run.currentGlobins) do
    if globin ~= nil then
      if globin.npc.State ~= globin.lastState and globin.npc.State == 3 then
        -- A globin went down
        globin.regens = globin.regens + 1
        if (globin.regens >= 5) then
          globin.npc:Kill()
          RPGlobals.run.currentGlobins[i] = nil
          Isaac.DebugString("Killed Globin " .. tostring(i) .. " to prevent a soft-lock.")
        end
      end
      globin.lastState = globin.npc.State
    end
  end

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
    if RPGlobals.run.edensSoulSet then
      RPGlobals.run.edensSoulCharges = activeCharge
    else
      RPGlobals.run.edensSoulSet = true
      player:SetActiveCharge(RPGlobals.run.edensSoulCharges)
    end
  else
    RPGlobals.run.edensSoulSet = false
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

  -- Check for item drop inputs
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

  -- If the room just got changed to a cleared state, increment the total rooms cleared
  RPGlobals.run.roomsCleared = RPGlobals.run.roomsCleared + 1
  Isaac.DebugString("Rooms cleared: " .. tostring(RPGlobals.run.roomsCleared))

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
    if coinDifference >= 2 then
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

-- Check for item drop inputs
function RPPostUpdate:CheckDropInput()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- We don't want to drop items if the player is intending to do a Schoolbag switch
  -- Furthermore, adding a null card/pill won't work if there are 2 slots,
  -- so we have to disable the feature if the player has these items
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_STARTER_DECK) or -- 251
     player:HasCollectible(CollectibleType.COLLECTIBLE_LITTLE_BAGGY) or -- 252
     player:HasCollectible(CollectibleType.COLLECTIBLE_DEEP_POCKETS) or -- 416
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLYDACTYLY) then -- 454

    return
  end

  -- Check for the input
  local dropPressed = false
  for i = 0, 3 do -- There are 4 possible players from 0 to 3
    -- Use "IsActionPressed()" instead of "IsActionTriggered()" because
    -- new players might not know about the fast-drop feature and will just keep the button pressed down
    if Input.IsActionPressed(ButtonAction.ACTION_DROP, i) then -- 11
      dropPressed = true
    end
  end
  if dropPressed == false then
    return
  end

  -- Cards and pills
  local card1 = player:GetCard(0)
  local card2 = player:GetCard(1)
  local pill1 = player:GetPill(0)
  local pill2 = player:GetPill(1)
  if card1 ~= 0 and card2 == 0 and pill2 == 0 then
    -- Drop the card
    player:AddCard(0)
    Isaac.DebugString("Dropped card " .. tostring(card1) .. ".")
  elseif pill1 ~= 0 and card2 == 0 and pill2 == 0 then
    -- Drop the pill
    player:AddPill(0)
    Isaac.DebugString("Dropped pill " .. tostring(card1) .. ".")
  end

  -- Trinkets
  -- (if the player has 2 trinkets, this will drop both of them)
  player:DropTrinket(player.Position, false) -- The second argument is ReplaceTick
end

-- Do race related checks
-- (some race related checks are also in CheckGridEntities, CheckEntities, and CheckEntitiesNPC
-- so that we don't have to iterate through all of the entities in the room twice)
function RPPostUpdate:RaceChecks()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local trinket1 = player:GetTrinket(0) -- This will be 0 if there is no trinket
  local trinket2 = player:GetTrinket(1) -- This will be 0 if there is no trinket

  -- Ban trinkets (2/2)
  -- (it is possible to pick up a banned trinket if it is spawned in a doorway,
  -- so also check to see if the player has a banned trinket equipped)
  for j = 1, #RPGlobals.raceVars.trinketBanList do
    if trinket1 == RPGlobals.raceVars.trinketBanList[j] then
      player:TryRemoveTrinket(trinket1) -- This will even remove the Tick
    elseif trinket2 == RPGlobals.raceVars.trinketBanList[j] then
      player:TryRemoveTrinket(trinket2) -- This will even remove the Tick
    end
  end

  -- Ban Basement 1 Treasure Rooms (2/2)
  RPPostUpdate:CheckBanB1TreasureRoom()

  -- Make race winners get sparklies and fireworks
  --[[
  if raceVars.finished == true then
    -- Give Isaac sparkly feet (1000.103.0)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ULTRA_GREED_BLING, 0,
                player.Position + RandomVector():__mul(10), Vector(0, 0), nil)

    -- Spawn 30 fireworks (1000.104.0)
    -- (some can be duds randomly and not spawn any fireworks after the 20 frame countdown)
    if raceVars.fireworks < 40 and gameFrameCount % 20 == 0 then
      for i = 1, 5 do
        raceVars.fireworks = raceVars.fireworks + 1
        local firework = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIREWORKS, 0,
                                     RPGlobals:GridToPos(math.random(1, 11), math.random(2, 8)),
                                     Vector(0, 0), nil) -- 0,12  0,8
        local fireworkEffect = firework:ToEffect()
        fireworkEffect:SetTimeout(20)
      end
    end
  end
  --]]

  if RPGlobals.raceVars.finished and player:IsHoldingItem() == false then
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP) then
      -- Check to see if we have a Victory Lap (a custom item that emulates Forget Me Now)
      RPGlobals.raceVars.victoryLaps = RPGlobals.raceVars.victoryLaps + 1
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP)
      Isaac.DebugString("Removing collectible " .. CollectibleType.COLLECTIBLE_VICTORY_LAP .. " (Victory Lap)")
      player:UseActiveItem(CollectibleType.COLLECTIBLE_FORGET_ME_NOW, false, false, false, false)
      Isaac.DebugString("Using a Victory Lap.")

    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_FINISHED) then
      -- Check to see if we have a Finished (a custom item that sends us to the credits)
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_FINISHED)
      Isaac.DebugString("Removing collectible " .. CollectibleType.COLLECTIBLE_FINISHED .. " (Finished)")
      Isaac.DebugString("Going to the credits.")
      game:End(2) -- 0 does nothing, 1 is the death screen, 2 is the first ending (after killing Mom for the first time)
      -- All cutscenes are removed in the Racing+ mod, so this will skip the cutscene and go directly to the credits
    end
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
