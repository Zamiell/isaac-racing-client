local RPSpeedrun = {}

--
-- Includes
--

local RPGlobals   = require("src/rpglobals")
local RPSaveDat   = require("src/rpsavedat")
local RPSprites   = require("src/rpsprites")
local RPSchoolbag = require("src/rpschoolbag")

--
-- Constants
--

RPSpeedrun.buttons = {
  R9S1  = {X = 2, Y = 3},
  R14S1 = {X = 6, Y = 3},
  R7S2  = {X = 10, Y = 3},
  R7S3  = {X = 4, Y = 5},
  R7S4  = {X = 8, Y = 5},
}
RPSpeedrun.charPosition9 = { -- The format is character number, X, Y
  {2, 2, 1},  -- Cain
  {3, 4, 1},  -- Judas
  {4, 6, 1},  -- Blue Baby
  {5, 8, 1},  -- Eve
  {6, 10, 1}, -- Samson
  {7, 3, 3},  -- Azazel
  {8, 5, 3},  -- Lazarus
  {10, 7, 3}, -- The Lost
  {14, 9, 3}, -- Keeper
}
RPSpeedrun.charPosition14 = { -- The format is character number, X, Y
  {0, 1, 1},   -- Isaac
  {1, 3, 1},   -- Magdalene
  {2, 5, 1},   -- Cain
  {3, 7, 1},   -- Judas
  {4, 9, 1},   -- Blue Baby
  {5, 11, 1},  -- Eve
  {6, 1, 3},   -- Samson
  {7, 3, 3},   -- Azazel
  {8, 5, 3},   -- Lazarus
  {9, 7, 3},   -- Eden
  {10, 9, 3},  -- The Lost
  {13, 11, 3}, -- Lilith
  {14, 2, 5},  -- Keeper
  {15, 10, 5}, -- Apollyon
}
RPSpeedrun.charPosition7_2 = { -- The format is character number, X, Y
  {0, 2, 1},  -- Isaac
  {2, 4, 1},  -- Cain
  {3, 6, 1},  -- Judas
  {7, 8, 1},  -- Azazel
  {9, 10, 1}, -- Eden
  {15, 5, 3}, -- Apollyon
  {Isaac.GetPlayerTypeByName("Samael"), 7, 3}, -- Samael
}
RPSpeedrun.charPosition7_3 = { -- The format is character number, X, Y
  {0, 2, 1},  -- Isaac
  {1, 4, 1},  -- Magdalene
  {3, 6, 1},  -- Judas
  {5, 8, 1},  -- Eve
  {6, 10, 1}, -- Samson
  {8, 5, 3},  -- Lazarus
  {10, 7, 3}, -- The Lost
}
RPSpeedrun.charPosition7_4 = { -- The format is character number, X, Y
  {2, 2, 1},  -- Cain
  {3, 4, 1},  -- Judas
  {4, 6, 1},  -- Blue Baby
  {7, 8, 1},  -- Azazel
  {8, 10, 1}, -- Lazarus
  {13, 5, 3}, -- Lilith
  {15, 7, 3}, -- Apollyon
}
RPSpeedrun.itemPosition7_4 = { -- The format is item number, X, Y
  {172, 1, 1},  -- Sacrificial Dagger
  {224, 3, 1},  -- Cricket's Body
  {373, 5, 1},  -- Dead Eye
  {52, 7, 1},   -- Dr. Fetus
  {229, 9, 1},  -- Monstro's Lung
  {311, 11, 1}, -- Judas' Shadow
  {1006, 1, 3},   -- Chocolate Milk + Steven
  {1005, 11, 3},  -- Jacob's Ladder + There's Options

  {1001, 9, 5},  -- Mutant Spider + The Inner Eye
  {1002, 10, 5},  -- Technology + A Lump of Coal
  {1003, 11, 5}, -- Fire Mind + Mysterious Liquid + 13 luck
  {1004, 12, 5},  -- Kamikaze! + Host Hat

  {114, 0, 5}, -- Mom's Knife
  {395, 1, 5}, -- Tech X
  {168, 2, 5}, -- Epic Fetus
  {149, 3, 5}, -- Ipecac
}
RPSpeedrun.season4classSNum = 4

--
-- Variables
--

RPSpeedrun.charNum = 1 -- Reset expliticly from a long-reset and on the first reset after a finish
RPSpeedrun.sprites = {} -- Reset in the PostGameStarted callback
RPSpeedrun.startedTime = 0 -- Reset expliticly if we are on the first character
RPSpeedrun.finished = false -- Reset at the beginning of every run
RPSpeedrun.finishedTime = 0 -- Reset at the beginning of every run
RPSpeedrun.chooseType = nil -- Reset when we enter the "Choose Char Order" room
RPSpeedrun.chooseOrder = {} -- Reset when we enter the "Choose Char Order" room
RPSpeedrun.chooseOrder2 = {} -- Reset when we enter the "Choose Char Order" room
RPSpeedrun.fastReset = false -- Reset expliticly when we detect a fast reset
RPSpeedrun.spawnedCheckpoint = false -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.fadeFrame = 0 -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.resetFrame = 0 -- Reset after we execute the "restart" command and at the beginning of a new run
RPSpeedrun.liveSplitReset = false

--
-- Speedrun functions
--

-- Called from the PostGameStarted callback
function RPSpeedrun:Init()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local isaacFrameCount = Isaac.GetFrameCount()
  local challenge = Isaac.GetChallenge()
  local itemConfig = Isaac.GetItemConfig()
  local sfx = SFXManager()

  -- Reset some per-run variables
  RPSpeedrun.spawnedCheckpoint = false
  RPSpeedrun.fadeFrame = 0
  RPSpeedrun.resetFrame = 0

  if RPSpeedrun.liveSplitReset then
    RPSpeedrun.liveSplitReset = false
    player:AddCollectible(CollectibleType.COLLECTIBLE_OFF_LIMITS, 0, false)
    Isaac.DebugString("Reset the LiveSplit AutoSplitter by giving \"Off Limits\", item ID " ..
                      tostring(CollectibleType.COLLECTIBLE_OFF_LIMITS) .. ".")
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_OFF_LIMITS) .. " (Off Limits)")
  end

  -- Move to the first character if we finished
  -- (this has to be above the challenge name check so that the fireworks won't carry over to another run)
  if RPSpeedrun.finished then
    RPSpeedrun.charNum = 1
    RPSpeedrun.finished = false
    RPSpeedrun.finishedTime = 0
    RPSpeedrun.fastReset = false
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting to go back to the first character (since we finished the speedrun).")
    return
  end

  if challenge == Isaac.GetChallengeIdByName("Change Char Order") then
    -- Make sure that some speedrun related variables are reset
    RPSpeedrun.charNum = 1
    RPSpeedrun.fastReset = false

    -- Remove the D6
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 106

    -- Give Isaac's some speed
    player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
    Isaac.DebugString("Removing collectible 28 (The Belt)")
    player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
    Isaac.DebugString("Removing collectible 28 (The Belt)")
    player:RemoveCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_BELT)) -- 28

    -- Go to the "Change Char Order" room
    Isaac.ExecuteCommand("stage 1a") -- The Cellar is the cleanest floor
    Isaac.ExecuteCommand("goto s.boss.9999")
    -- We can't use an existing boss room because after the boss is removed, a pedestal will spawn
    Isaac.DebugString("Going to the \"Change Char Order\" room.")
    -- We do more things in the "PostNewRoom" callback
    return
  end

  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  -- Do actions based on the specific challenge
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    Isaac.DebugString("In the R+9 (Season 1) challenge.")

    -- Give extra items to characters for the R+9 speedrun category (Season 1)
    if character == PlayerType.PLAYER_KEEPER then -- 14
      -- Add the items
      player:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
      player:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498

      -- Remove them from all the pools
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

      -- Grant an extra coin/heart container
      player:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
      player:AddCoins(1) -- This fills in the new heart container
      player:AddCoins(25) -- Add a 2nd container
      player:AddCoins(1) -- This fills in the new heart container
    end

  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    Isaac.DebugString("In the R+14 (Season 1) challenge.")

    -- Give extra items to characters for the R+14 speedrun category (Season 1)
    if character == PlayerType.PLAYER_ISAAC then -- 0
      -- Add the Battery
      player:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

      -- Make Isaac start with a double charge instead of a single charge
      player:SetActiveCharge(12)
      sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

    elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
      -- Add the Soul Jar
      player:AddCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR, 0, false)
      -- (the Soul Jar does not appear in any pools so we don't have to add it to the ban list)

    elseif character == PlayerType.PLAYER_LILITH then -- 13
      -- Lilith starts with the Schoolbag by default
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS -- 357
      RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
      RPSchoolbag.sprites.item = nil
      Isaac.DebugString("Adding collectible 357 (Box of Friends)")
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) -- 357

      -- Reorganize the items on the item tracker
      Isaac.DebugString("Removing collectible 412 (Cambion Conception)")
      Isaac.DebugString("Adding collectible 412 (Cambion Conception)")

    elseif character == PlayerType.PLAYER_KEEPER then -- 14
      -- Add the items
      player:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
      player:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498

      -- Remove them from all the pools
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

      -- Grant an extra coin/heart container
      player:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
      player:AddCoins(1) -- This fills in the new heart container
      player:AddCoins(25) -- Add a 2nd container
      player:AddCoins(1) -- This fills in the new heart container

    elseif character == PlayerType.PLAYER_APOLLYON then -- 15
      -- Apollyon starts with the Schoolbag by default
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_VOID -- 477
      RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
      RPSchoolbag.sprites.item = nil
      Isaac.DebugString("Adding collectible 477 (Void)")
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VOID) -- 477
    end

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    Isaac.DebugString("In the R+7 (Season 2) challenge.")

    -- Give extra items to characters for the R+7 speedrun category (Season 2)
    if character == PlayerType.PLAYER_ISAAC then -- 0
      -- Add the Battery
      player:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

      -- Make Isaac start with a double charge instead of a single charge
      player:SetActiveCharge(12)
      sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

    elseif character == PlayerType.PLAYER_APOLLYON then -- 15
      -- Apollyon starts with the Schoolbag by default
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_VOID -- 477
      RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
      RPSchoolbag.sprites.item = nil
      Isaac.DebugString("Adding collectible 477 (Void)")
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VOID) -- 477
    end

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    Isaac.DebugString("In the R+7 (Season 3) challenge.")

    -- Everyone starts with the Schoolbag in this season
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    RPSchoolbag.sprites.item = nil

    -- Give extra items to characters for the R+7 speedrun category (Season 3)
    if character == PlayerType.PLAYER_ISAAC then -- 0
      -- Isaac starts with Moving Box
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_MOVING_BOX -- 523
      Isaac.DebugString("Adding collectible 523 (Moving Box)")

    elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
      -- Magdalene starts with the How to Jump
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_HOW_TO_JUMP -- 282
      Isaac.DebugString("Adding collectible 282 (How to Jump)")

    elseif character == PlayerType.PLAYER_JUDAS then -- 3
      -- Judas starts with the Book of Belial
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL -- 34
      Isaac.DebugString("Adding collectible 34 (Book of Belial)")

    elseif character == PlayerType.PLAYER_EVE then -- 5
      -- Eve starts with The Candle
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_CANDLE -- 164
      Isaac.DebugString("Adding collectible 164 (The Candle)")

    elseif character == PlayerType.PLAYER_SAMSON then -- 6
      -- Samsom starts with Mr. ME!
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_MR_ME -- 527
      Isaac.DebugString("Adding collectible 527 (Mr. ME!)")

    elseif character == PlayerType.PLAYER_LAZARUS then -- 8
      -- Lazarus starts with Ventricle Razor
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_VENTRICLE_RAZOR -- 396
      Isaac.DebugString("Adding collectible 396 (Ventricle Razor)")

    elseif character == PlayerType.PLAYER_THELOST then -- 10
      -- The Lost starts with Glass Cannon
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_GLASS_CANNON -- 352
      Isaac.DebugString("Adding collectible 352 (Glass Cannon)")
    end

    -- Set the Schoolbag item charges
    RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)

    -- Remove the Schoolbag item from all pools
    itemPool:RemoveCollectible(RPGlobals.run.schoolbag.item)

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    Isaac.DebugString("In the R+7 (Season 4) challenge.")

    -- Everyone starts with the Schoolbag in this season
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    RPSchoolbag.sprites.item = nil

    -- Give extra items to characters for the R+7 speedrun category (Season 4)
    if character == PlayerType.PLAYER_LAZARUS then -- 8
      -- Lazarus does not start with a pill to prevent players resetting for a good pill
      player:SetPill(0, 0)

    elseif character == PlayerType.PLAYER_LILITH then -- 13
      player:AddCollectible(CollectibleType.COLLECTIBLE_INCUBUS, 0, false) -- 360
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360

      -- Don't show it on the item tracker
      Isaac.DebugString("Removing collectible 360 (Incubus)")

      -- If we switch characters, we want to remove the extra Incubus
      RPGlobals.run.extraIncubus = true
    end

    -- Give the additional (chosen) starting item/build
    -- (the item choice is stored in the "order9" variable)
    local itemID = RPGlobals.race.order9[RPSpeedrun.charNum]
    if itemID < 1000 then
      -- This is a single item build
      player:AddCollectible(itemID, 0, false)
      itemPool:RemoveCollectible(itemID)
    else
      -- This is a build with two items
      if itemID == 1001 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER, 0, false) -- 153
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
        player:AddCollectible(CollectibleType.COLLECTIBLE_INNER_EYE, 0, false) -- 2
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2

      elseif itemID == 1002 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY, 0, false) -- 68
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) -- 68
        player:AddCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL, 0, false) -- 132
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) -- 132

      elseif itemID == 1003 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND, 0, false) -- 257
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND) -- 257
        player:AddCollectible(CollectibleType.COLLECTIBLE_13_LUCK, 0, false)
        player:AddCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID, 0, false) -- 317
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID) -- 317

      elseif itemID == 1004 then
        -- Start with the Kamikaze in the active slot for quality of life purposes
        player:AddCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE, 0, false) -- 40
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE) -- 40
        RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_D6 -- 105
        RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
        player:AddCollectible(CollectibleType.COLLECTIBLE_HOST_HAT, 0, false) -- 375
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_HOST_HAT) -- 375

      elseif itemID == 1005 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER, 0, false) -- 494
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) -- 494
        player:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 249
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 249

      elseif itemID == 1006 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, 0, false) -- 69
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) -- 69
        player:AddCollectible(CollectibleType.COLLECTIBLE_STEVEN, 0, false) -- 50
        itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_STEVEN) -- 50
      end
    end

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") then
    Isaac.DebugString("In the R+7 (Season 5) challenge.")

    -- Everyone starts with the Schoolbag in this season
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    RPSchoolbag.sprites.item = nil

    -- Give extra items to characters for the R+7 speedrun category (Season 5)
    -- TODO
  end

  -- The first character of the speedrun always gets More Options to speed up the process of getting a run going
  -- (but not on Season 4, since there is no resetting involved)
  if RPSpeedrun.charNum == 1 and
     challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") then

    player:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
    Isaac.DebugString("Removing collectible 414 (More Options)")
    -- We don't need to show this on the item tracker to reduce clutter
    RPGlobals.run.removeMoreOptions = true
    -- More Options will be removed upon entering the first Treasure Room
  end

  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") and
     character ~= RPGlobals.race.order9[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+9 (Season 1) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") and
         character ~= RPGlobals.race.order14[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+14 (Season 1) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") and
         character ~= RPGlobals.race.order7[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+7 (Season 2) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") and
         character ~= RPGlobals.race.order7[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+7 (Season 3) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") and
         character ~= RPGlobals.race.order7[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+7 (Season 4) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") and
         character ~= 0 then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+7 (Season 5) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return
  end

  if RPSpeedrun.fastReset then
    RPSpeedrun.fastReset = false

  elseif RPSpeedrun.fastReset == false and
         RPSpeedrun.charNum ~= 1 then

    -- They held R, and they are not on the first character, so they want to restart from the first character
    RPSpeedrun.charNum = 1
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we want to start from the first character again.")

    -- Tell the LiveSplit AutoSplitter to reset
    RPSpeedrun.liveSplitReset = true
    return
  end

  if RPSpeedrun.charNum == 1 then
    RPSpeedrun.startedTime = 0
  end
end

-- Called from the the PostUpdate callback
function RPSpeedrun:StartTimer()
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  if RPSpeedrun.startedTime == 0 then
    RPSpeedrun.startedTime = Isaac.GetTime()
  end
end

-- Called from the PostUpdate callback (RPCheckEntities:NonGrid)
function RPSpeedrun:CheckpointTouched()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local isaacFrameCount = Isaac.GetFrameCount()

  if RPSpeedrun.spawnedCheckpoint then
    RPSpeedrun.spawnedCheckpoint = false
  else
    return
  end

  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)
  Isaac.DebugString("Checkpoint custom item given (" .. tostring(CollectibleType.COLLECTIBLE_CHECKPOINT) .. ").")

  -- Freeze the player
  player.ControlsEnabled = false

  -- Mark to fade out after the "Checkpoint" text has displayed on the screen for a little bit
  RPSpeedrun.fadeFrame = isaacFrameCount + 30
end

-- Called from the PostUpdate callback
function RPSpeedrun:CheckRemoveIncubus()
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- We want to remove the extra Incubus if they attempt to switch characters
  if RPGlobals.run.extraIncubus and
     character ~= PlayerType.PLAYER_LILITH then -- 13

    RPGlobals.run.extraIncubus = false
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360
    Isaac.DebugString("Removed the extra Incubus (for R+7 Season 4).")
  end
end

-- Called from the PostRender callback
function RPSpeedrun:CheckRestart()
  -- Local variables
  local game = Game()
  local isaacFrameCount = Isaac.GetFrameCount()

  -- We grabbed the checkpoint, so fade out the screen before we reset
  if RPSpeedrun.fadeFrame ~= 0 and isaacFrameCount >= RPSpeedrun.fadeFrame then
    RPSpeedrun.fadeFrame = 0
    game:Fadeout(0.0275, RPGlobals.FadeoutTarget.FADEOUT_RESTART_RUN) -- 3
    RPSpeedrun.resetFrame = isaacFrameCount + 70 -- 72 restarts as the current character, and we want a frame of leeway
    -- (this is necessary because we don't want the player to be able to reset to skip having to watch the fade out)
  end

  -- The screen is now black, so move us to the next character for the speedrun
  if RPSpeedrun.resetFrame ~= 0 and isaacFrameCount >= RPSpeedrun.resetFrame then
    RPSpeedrun.resetFrame = 0
    RPSpeedrun.fastReset = true -- Set this so that we don't go back to the beginning again
    RPSpeedrun.charNum = RPSpeedrun.charNum + 1
    RPGlobals.run.restartFrame = isaacFrameCount + 1

    Isaac.DebugString("Switching to the next character for the speedrun.")
    return
  end
end

-- Called from the PostUpdate callback (RPCheckEntities:NonGrid)
function RPSpeedrun:Finish()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local sfx = SFXManager()

  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)

  -- Finish the speedrun
  RPSpeedrun.finished = true
  RPSpeedrun.finishedTime = Isaac.GetTime() - RPSpeedrun.startedTime
  RPGlobals.run.endOfRunText = true -- Show the run summary

  -- Play a sound effect
  sfx:Play(SoundEffect.SOUND_SPEEDRUN_FINISH, 1.5, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch

  -- Fireworks will play on the next frame (from the PostUpdate callback)
end

--
-- Functions for the "Change Char Order" custom challenge
--

-- Called from the PostNewRoom callback
function RPSpeedrun:PostNewRoomChangeCharOrder()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndexUnsafe = level:GetCurrentRoomIndex()
  local room = game:GetRoom()
  local sfx = SFXManager()
  local challenge = Isaac.GetChallenge()
  local player = game:GetPlayer(0)

  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") or
     roomIndexUnsafe ~= GridRooms.ROOM_DEBUG_IDX then -- -3

    return
  end

  -- Stop the boss room sound effect
  sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

  -- We want to trap the player in the room, so delete all 4 doors
  for i = 0, 3 do
    room:RemoveDoor(i)
  end

  -- Put the player next to the bottom door
  player.Position = Vector(320, 400)

  -- Reset the graphics and the order
  RPSpeedrun.chooseType = nil
  RPSpeedrun.chooseOrder = {}
  RPSpeedrun.chooseOrder2 = {}
  RPSpeedrun.sprites = {}

  -- Spawn buttons for each type of speedrun
  local pos
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R9S1.X, RPSpeedrun.buttons.R9S1.Y)
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R14S1.X, RPSpeedrun.buttons.R14S1.Y)
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S2.X, RPSpeedrun.buttons.R7S2.Y)
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S3.X, RPSpeedrun.buttons.R7S3.Y)
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S4.X, RPSpeedrun.buttons.R7S4.Y)
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20

  -- Spawn the graphics over the buttons
  RPSpeedrun.sprites.button1 = Sprite()
  RPSpeedrun.sprites.button1:Load("gfx/speedrun/button1.anm2", true)
  RPSpeedrun.sprites.button1:SetFrame("Default", 0)
  RPSpeedrun.sprites.button2 = Sprite()
  RPSpeedrun.sprites.button2:Load("gfx/speedrun/button2.anm2", true)
  RPSpeedrun.sprites.button2:SetFrame("Default", 0)
  RPSpeedrun.sprites.button3 = Sprite()
  RPSpeedrun.sprites.button3:Load("gfx/speedrun/button3.anm2", true)
  RPSpeedrun.sprites.button3:SetFrame("Default", 0)
  RPSpeedrun.sprites.button4 = Sprite()
  RPSpeedrun.sprites.button4:Load("gfx/speedrun/button4.anm2", true)
  RPSpeedrun.sprites.button4:SetFrame("Default", 0)
  RPSpeedrun.sprites.button5 = Sprite()
  RPSpeedrun.sprites.button5:Load("gfx/speedrun/button5.anm2", true)
  RPSpeedrun.sprites.button5:SetFrame("Default", 0)
end

-- Called from the PostRender callback
function RPSpeedrun:CheckChangeCharOrder()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)

  -- Disable the controls or else the player will be able to move around while the screen is still black
  if gameFrameCount < 1 then
    player.ControlsEnabled = false
  else
    player.ControlsEnabled = true
  end
end

-- Called from the PostUpdate callback
function RPSpeedrun:CheckButtonPressed(gridEntity)
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  -- Local variables
  local game = Game()

  local buttonPos1 = RPGlobals:GridToPos(RPSpeedrun.buttons.R9S1.X, RPSpeedrun.buttons.R9S1.Y)
  local buttonPos2 = RPGlobals:GridToPos(RPSpeedrun.buttons.R14S1.X, RPSpeedrun.buttons.R14S1.Y)
  local buttonPos3 = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S2.X, RPSpeedrun.buttons.R7S2.Y)
  local buttonPos4 = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S3.X, RPSpeedrun.buttons.R7S3.Y)
  local buttonPos5 = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S4.X, RPSpeedrun.buttons.R7S4.Y)
  if gridEntity:GetSaveState().State == 3 and
     gridEntity.Position.X == buttonPos1.X and
     gridEntity.Position.Y == buttonPos1.Y then

    RPSpeedrun.chooseType = "R+9"
    Isaac.DebugString("The R+9 (Season 1) button was pressed.")

    RPSpeedrun:RemoveAllRoomButtons()

    RPSpeedrun.sprites.characters = {}
    for i = 1, #RPSpeedrun.charPosition9 do
      -- Spawn 9 buttons for the 9 characters
      Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, -- 20
                      RPGlobals:GridToPos(RPSpeedrun.charPosition9[i][2], RPSpeedrun.charPosition9[i][3]), true)

      -- Spawn the character selection graphics next to the buttons
      local newIndex = #RPSpeedrun.sprites.characters + 1
      RPSpeedrun.sprites.characters[newIndex] = Sprite()
      local charNum = RPSpeedrun.charPosition9[i][1]
      RPSpeedrun.sprites.characters[newIndex]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
      RPSpeedrun.sprites.characters[newIndex]:SetFrame("Death", 5) -- The 5th frame is rather interesting
      RPSpeedrun.sprites.characters[newIndex].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      -- Fade the character so it looks like a ghost
    end

  elseif gridEntity:GetSaveState().State == 3 and
         gridEntity.Position.X == buttonPos2.X and
         gridEntity.Position.Y == buttonPos2.Y then

    RPSpeedrun.chooseType = "R+14"
    Isaac.DebugString("The R+14 (Season 1) button was pressed.")

    RPSpeedrun:RemoveAllRoomButtons()

    RPSpeedrun.sprites.characters = {}
    for i = 1, #RPSpeedrun.charPosition14 do
      -- Spawn 14 buttons for the 14 characters
      Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, -- 20
                      RPGlobals:GridToPos(RPSpeedrun.charPosition14[i][2], RPSpeedrun.charPosition14[i][3]), true)

      -- Spawn the character selection graphics next to the buttons
      local newIndex = #RPSpeedrun.sprites.characters + 1
      RPSpeedrun.sprites.characters[newIndex] = Sprite()
      local charNum = RPSpeedrun.charPosition14[i][1]
      RPSpeedrun.sprites.characters[newIndex]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
      RPSpeedrun.sprites.characters[newIndex]:SetFrame("Death", 5) -- The 5th frame is rather interesting
      RPSpeedrun.sprites.characters[newIndex].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      -- Fade the character so it looks like a ghost
    end

  elseif gridEntity:GetSaveState().State == 3 and
         gridEntity.Position.X == buttonPos3.X and
         gridEntity.Position.Y == buttonPos3.Y then

    RPSpeedrun.chooseType = "R+7 (S2)"
    Isaac.DebugString("The R+7 (Season 2) button was pressed.")

    RPSpeedrun:RemoveAllRoomButtons()

    RPSpeedrun.sprites.characters = {}
    for i = 1, #RPSpeedrun.charPosition7_2 do
      -- Spawn 7 buttons for the 7 characters
      Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, -- 20
                      RPGlobals:GridToPos(RPSpeedrun.charPosition7_2[i][2], RPSpeedrun.charPosition7_2[i][3]), true)

      -- Spawn the character selection graphics next to the buttons
      local newIndex = #RPSpeedrun.sprites.characters + 1
      RPSpeedrun.sprites.characters[newIndex] = Sprite()
      local charNum = RPSpeedrun.charPosition7_2[i][1]
      RPSpeedrun.sprites.characters[newIndex]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
      RPSpeedrun.sprites.characters[newIndex]:SetFrame("Death", 5) -- The 5th frame is rather interesting
      RPSpeedrun.sprites.characters[newIndex].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      -- Fade the character so it looks like a ghost
    end

  elseif gridEntity:GetSaveState().State == 3 and
         gridEntity.Position.X == buttonPos4.X and
         gridEntity.Position.Y == buttonPos4.Y then

    RPSpeedrun.chooseType = "R+7 (S3)"
    Isaac.DebugString("The R+7 (Season 3) button was pressed.")

    RPSpeedrun:RemoveAllRoomButtons()

    RPSpeedrun.sprites.characters = {}
    for i = 1, #RPSpeedrun.charPosition7_3 do
      -- Spawn 7 buttons for the 7 characters
      Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, -- 20
                      RPGlobals:GridToPos(RPSpeedrun.charPosition7_3[i][2], RPSpeedrun.charPosition7_3[i][3]), true)

      -- Spawn the character selection graphics next to the buttons
      local newIndex = #RPSpeedrun.sprites.characters + 1
      RPSpeedrun.sprites.characters[newIndex] = Sprite()
      local charNum = RPSpeedrun.charPosition7_3[i][1]
      RPSpeedrun.sprites.characters[newIndex]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
      RPSpeedrun.sprites.characters[newIndex]:SetFrame("Death", 5) -- The 5th frame is rather interesting
      RPSpeedrun.sprites.characters[newIndex].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      -- Fade the character so it looks like a ghost
    end

  elseif gridEntity:GetSaveState().State == 3 and
         gridEntity.Position.X == buttonPos5.X and
         gridEntity.Position.Y == buttonPos5.Y then

    RPSpeedrun.chooseType = "R+7 (S4)"
    Isaac.DebugString("The R+7 (Season 4) button was pressed.")

    RPSpeedrun:RemoveAllRoomButtons()

    RPSpeedrun.sprites.characters = {}
    for i = 1, #RPSpeedrun.charPosition7_4 do
      -- Spawn 7 buttons for the 7 characters
      Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, -- 20
                      RPGlobals:GridToPos(RPSpeedrun.charPosition7_4[i][2], RPSpeedrun.charPosition7_4[i][3]), true)

      -- Spawn the character selection graphics next to the buttons
      local newIndex = #RPSpeedrun.sprites.characters + 1
      RPSpeedrun.sprites.characters[newIndex] = Sprite()
      local charNum = RPSpeedrun.charPosition7_4[i][1]
      RPSpeedrun.sprites.characters[newIndex]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
      RPSpeedrun.sprites.characters[newIndex]:SetFrame("Death", 5) -- The 5th frame is rather interesting
      RPSpeedrun.sprites.characters[newIndex].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      -- Fade the character so it looks like a ghost
    end
  end

  if RPSpeedrun.chooseType == "R+9" then
    for i = 1, #RPSpeedrun.charPosition9 do
      local posButton = RPGlobals:GridToPos(RPSpeedrun.charPosition9[i][2], RPSpeedrun.charPosition9[i][3])
      if gridEntity:GetSaveState().State == 3 and
         gridEntity.VarData == 0 and
         gridEntity.Position.X == posButton.X and
         gridEntity.Position.Y == posButton.Y then

        -- We have pressed one of the buttons corresponding to the characters
        gridEntity.VarData = 1 -- Mark that we have pressed this button already
        RPSpeedrun.chooseOrder[#RPSpeedrun.chooseOrder + 1] = RPSpeedrun.charPosition9[i][1]
        if #RPSpeedrun.chooseOrder == 9 then
          -- We have finished choosing our 9 characters
          RPGlobals.race.order9 = RPSpeedrun.chooseOrder
          RPSaveDat:Save()
          Isaac.DebugString("New order: " .. RPGlobals:TableToString(RPSpeedrun.chooseOrder))
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
      end
    end

  elseif RPSpeedrun.chooseType == "R+14" then
    for i = 1, #RPSpeedrun.charPosition14 do
      local posButton = RPGlobals:GridToPos(RPSpeedrun.charPosition14[i][2], RPSpeedrun.charPosition14[i][3])
      if gridEntity:GetSaveState().State == 3 and
         gridEntity.VarData == 0 and
         gridEntity.Position.X == posButton.X and
         gridEntity.Position.Y == posButton.Y then

        -- We have pressed one of the buttons corresponding to the characters
        gridEntity.VarData = 1 -- Mark that we have pressed this button already
        RPSpeedrun.chooseOrder[#RPSpeedrun.chooseOrder + 1] = RPSpeedrun.charPosition14[i][1]
        if #RPSpeedrun.chooseOrder == 14 then
          -- We have finished choosing our 14 characters
          RPGlobals.race.order14 = RPSpeedrun.chooseOrder
          RPSaveDat:Save()
          Isaac.DebugString("New order: " .. RPGlobals:TableToString(RPSpeedrun.chooseOrder))
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
      end
    end

  elseif RPSpeedrun.chooseType == "R+7 (S2)" then
    for i = 1, #RPSpeedrun.charPosition7_2 do
      local posButton = RPGlobals:GridToPos(RPSpeedrun.charPosition7_2[i][2], RPSpeedrun.charPosition7_2[i][3])
      if gridEntity:GetSaveState().State == 3 and
         gridEntity.VarData == 0 and
         gridEntity.Position.X == posButton.X and
         gridEntity.Position.Y == posButton.Y then

        -- We have pressed one of the buttons corresponding to the characters
        gridEntity.VarData = 1 -- Mark that we have pressed this button already
        RPSpeedrun.chooseOrder[#RPSpeedrun.chooseOrder + 1] = RPSpeedrun.charPosition7_2[i][1]
        if #RPSpeedrun.chooseOrder == 7 then
          -- We have finished choosing our 7 characters
          RPGlobals.race.order7 = RPSpeedrun.chooseOrder
          RPSaveDat:Save()
          Isaac.DebugString("New order: " .. RPGlobals:TableToString(RPSpeedrun.chooseOrder))
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
      end
    end

  elseif RPSpeedrun.chooseType == "R+7 (S3)" then
    for i = 1, #RPSpeedrun.charPosition7_3 do
      local posButton = RPGlobals:GridToPos(RPSpeedrun.charPosition7_3[i][2], RPSpeedrun.charPosition7_3[i][3])
      if gridEntity:GetSaveState().State == 3 and
         gridEntity.VarData == 0 and
         gridEntity.Position.X == posButton.X and
         gridEntity.Position.Y == posButton.Y then

        -- We have pressed one of the buttons corresponding to the characters
        gridEntity.VarData = 1 -- Mark that we have pressed this button already
        RPSpeedrun.chooseOrder[#RPSpeedrun.chooseOrder + 1] = RPSpeedrun.charPosition7_3[i][1]
        if #RPSpeedrun.chooseOrder == 7 then
          -- We have finished choosing our 7 characters
          RPGlobals.race.order7 = RPSpeedrun.chooseOrder
          RPSaveDat:Save()
          Isaac.DebugString("New order: " .. RPGlobals:TableToString(RPSpeedrun.chooseOrder))
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
      end
    end

  elseif RPSpeedrun.chooseType == "R+7 (S4)" then
    for i = 1, #RPSpeedrun.charPosition7_4 do
      local posButton = RPGlobals:GridToPos(RPSpeedrun.charPosition7_4[i][2], RPSpeedrun.charPosition7_4[i][3])
      if gridEntity:GetSaveState().State == 3 and
         gridEntity.VarData == 0 and
         gridEntity.Position.X == posButton.X and
         gridEntity.Position.Y == posButton.Y then

        -- We have pressed one of the buttons corresponding to the characters
        gridEntity.VarData = 1 -- Mark that we have pressed this button already
        RPSpeedrun.chooseOrder[#RPSpeedrun.chooseOrder + 1] = RPSpeedrun.charPosition7_4[i][1]
        if #RPSpeedrun.chooseOrder == 7 then
          -- We have finished choosing our 7 characters
          RPGlobals.race.order7 = RPSpeedrun.chooseOrder
          RPSaveDat:Save()
          Isaac.DebugString("New order: " .. RPGlobals:TableToString(RPSpeedrun.chooseOrder))
          RPSpeedrun:RemoveAllRoomButtons2()
          return
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
      end
    end
    for i = 1, #RPSpeedrun.itemPosition7_4 do
      local posButton = RPGlobals:GridToPos(RPSpeedrun.itemPosition7_4[i][2], RPSpeedrun.itemPosition7_4[i][3])
      if gridEntity:GetSaveState().State == 3 and
         gridEntity.VarData == 0 and
         gridEntity.Position.X == posButton.X and
         gridEntity.Position.Y == posButton.Y then

        -- We have pressed one of the buttons corresponding to the items
        gridEntity.VarData = 1 -- Mark that we have pressed this button already
        RPSpeedrun.chooseOrder2[#RPSpeedrun.chooseOrder2 + 1] = RPSpeedrun.itemPosition7_4[i][1]
        if #RPSpeedrun.chooseOrder2 == 7 then
          -- We have finished choosing our 7 items
          RPGlobals.race.order9 = RPSpeedrun.chooseOrder2
          RPSaveDat:Save()
          Isaac.DebugString("New order2: " .. RPGlobals:TableToString(RPSpeedrun.chooseOrder2))
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.items[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.items[i]:SetFrame("Default", #RPSpeedrun.chooseOrder2)

        -- Change the player sprite
        local charNum = RPSpeedrun.chooseOrder[#RPSpeedrun.chooseOrder2 + 1]
        RPSpeedrun.sprites.characters[1]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
        RPSpeedrun.sprites.characters[1]:SetFrame("Death", 5) -- The 5th frame is rather interesting
        RPSpeedrun.sprites.characters[1].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
        -- Fade the character so it looks like a ghost

        if i > #RPSpeedrun.itemPosition7_4 - RPSpeedrun.season4classSNum then -- Big 4
          -- They touched an S class item, and are only allowed to choose one of those
          RPSpeedrun:RemoveAllRoomButtons3(i)
        end
      end
    end
  end
end

function RPSpeedrun:RemoveAllRoomButtons()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  -- Remove all of the buttons in the room
  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end
    end
  end
  RPSpeedrun.sprites.button1 = nil
  RPSpeedrun.sprites.button2 = nil
  RPSpeedrun.sprites.button3 = nil
  RPSpeedrun.sprites.button4 = nil
  RPSpeedrun.sprites.button5 = nil
end

-- Used in the "Char Char Order" room for season 4 (to remove all the character buttons)
function RPSpeedrun:RemoveAllRoomButtons2()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- Remove all of the buttons in the room
  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end
    end
  end

  -- Make the sprite that shows what character we are choosing for
  RPSpeedrun.sprites.characters = {}
  RPSpeedrun.sprites.characters[1] = Sprite()
  local charNum = RPSpeedrun.chooseOrder[1]
  RPSpeedrun.sprites.characters[1]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
  RPSpeedrun.sprites.characters[1]:SetFrame("Death", 5) -- The 5th frame is rather interesting
  RPSpeedrun.sprites.characters[1].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
  -- Fade the character so it looks like a ghost

  RPSpeedrun.sprites.items = {}
  for i = 1, #RPSpeedrun.itemPosition7_4 do
    -- Spawn buttons for the all the items
    local buttonPos = RPGlobals:GridToPos(RPSpeedrun.itemPosition7_4[i][2], RPSpeedrun.itemPosition7_4[i][3])
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, buttonPos, true) -- 20
    if i > #RPSpeedrun.itemPosition7_4 - RPSpeedrun.season4classSNum then -- Big 4
      -- Spawn creep for the S-Class items
      room:SetClear(false) -- Or else the creep will instantly dissipate
      for j = 1, 10 do
        local creep = game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED,
                                 buttonPos, Vector(0, 0), nil, 0, 0)
        creep:ToEffect().Timeout = 1000000
      end
    end

    -- Spawn the item selection graphics next to the buttons
    local newIndex = #RPSpeedrun.sprites.items + 1
    RPSpeedrun.sprites.items[newIndex] = Sprite()
    local itemNum = RPSpeedrun.itemPosition7_4[i][1]
    if itemNum < 1000 then
      RPSpeedrun.sprites.items[newIndex]:Load("gfx/items2/collectibles/" .. tostring(itemNum) .. ".anm2", true)
    else
      RPSpeedrun.sprites.items[newIndex]:Load("gfx/items2/combos/" .. tostring(itemNum) .. ".anm2", true)
    end
    RPSpeedrun.sprites.items[newIndex]:SetFrame("Default", 1)
  end

  -- Move Isaac to the center of the room
  player.Position = room:GetCenterPos()
end

-- Used in the "Char Char Order" room for season 4 (to remove all the S class item buttons)
function RPSpeedrun:RemoveAllRoomButtons3(itemNum)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  -- Remove all of the buttons in the room
  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        for j = #RPSpeedrun.itemPosition7_4 - RPSpeedrun.season4classSNum + 1, #RPSpeedrun.itemPosition7_4 do -- Big 4
          local itemPos = RPGlobals:GridToPos(RPSpeedrun.itemPosition7_4[j][2], RPSpeedrun.itemPosition7_4[j][3])
          if gridEntity.Position.X == itemPos.X and
             gridEntity.Position.Y == itemPos.Y then

            room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
          end
        end
      end
    end
  end

  -- Remove the sprites for the last 4 items
  -- (but leave the one we just chose so that it stays as a number)
  for i = #RPSpeedrun.itemPosition7_4 - RPSpeedrun.season4classSNum + 1, #RPSpeedrun.itemPosition7_4 do -- Big 4
    if i ~= itemNum then
      RPSpeedrun.sprites.items[i] = Sprite()
    end
  end
end

--
-- Display functions
--

-- Called from the PostRender callback
function RPSpeedrun:DisplayCharSelectRoom()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  if RPSpeedrun.sprites.button1 ~= nil then
    local posButton1 = RPGlobals:GridToPos(RPSpeedrun.buttons.R9S1.X, RPSpeedrun.buttons.R9S1.Y - 1)
    local posRender = Isaac.WorldToRenderPosition(posButton1, false)
    RPSpeedrun.sprites.button1:RenderLayer(0, posRender)
  end
  if RPSpeedrun.sprites.button2 ~= nil then
    local posButton2 = RPGlobals:GridToPos(RPSpeedrun.buttons.R14S1.X, RPSpeedrun.buttons.R14S1.Y - 1)
    local posRender = Isaac.WorldToRenderPosition(posButton2, false)
    RPSpeedrun.sprites.button2:RenderLayer(0, posRender)
  end
  if RPSpeedrun.sprites.button3 ~= nil then
    local posButton3 = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S2.X, RPSpeedrun.buttons.R7S2.Y - 1)
    local posRender = Isaac.WorldToRenderPosition(posButton3, false)
    RPSpeedrun.sprites.button3:RenderLayer(0, posRender)
  end
  if RPSpeedrun.sprites.button4 ~= nil then
    local posButton4 = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S3.X, RPSpeedrun.buttons.R7S3.Y - 1)
    local posRender = Isaac.WorldToRenderPosition(posButton4, false)
    RPSpeedrun.sprites.button4:RenderLayer(0, posRender)
  end
  if RPSpeedrun.sprites.button5 ~= nil then
    local posButton5 = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S4.X, RPSpeedrun.buttons.R7S4.Y - 1)
    local posRender = Isaac.WorldToRenderPosition(posButton5, false)
    RPSpeedrun.sprites.button5:RenderLayer(0, posRender)
  end
  if RPSpeedrun.sprites.characters ~= nil then
    for i = 1, #RPSpeedrun.sprites.characters do
      local posGame
      if #RPSpeedrun.sprites.characters == 9 then
        posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition9[i][2], RPSpeedrun.charPosition9[i][3] - 1)
      elseif #RPSpeedrun.sprites.characters == 14 then
        posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition14[i][2], RPSpeedrun.charPosition14[i][3] - 1)
      elseif #RPSpeedrun.sprites.characters == 7 then
        posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition7_2[i][2], RPSpeedrun.charPosition7_2[i][3] - 1)
        -- The positions are the same for season 3 and so on
      elseif #RPSpeedrun.sprites.characters == 1 then
        -- The bottom-center of the room
        posGame = RPGlobals:GridToPos(6, 5)
      end
      local posRender = Isaac.WorldToRenderPosition(posGame, false)
      posRender.Y = posRender.Y + 10
      RPSpeedrun.sprites.characters[i]:Render(posRender, Vector(0, 0), Vector(0, 0))
    end
  end
  if RPSpeedrun.sprites.items ~= nil then
    for i = 1, #RPSpeedrun.sprites.items do
      local posGame = RPGlobals:GridToPos(RPSpeedrun.itemPosition7_4[i][2], RPSpeedrun.itemPosition7_4[i][3] - 1)
      local posRender = Isaac.WorldToRenderPosition(posGame, false)
      posRender.Y = posRender.Y
      RPSpeedrun.sprites.items[i]:Render(posRender, Vector(0, 0), Vector(0, 0))
    end
  end
end

-- Called from the PostRender callback
function RPSpeedrun:DisplayCharProgress()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- Don't show the progress if we are not in the custom challenge
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  -- Check to see if they have a set order
  if (challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") and
      (RPGlobals.race.order9 == nil or
       #RPGlobals.race.order9 == 0 or
       #RPGlobals.race.order9 == 1)) or
     (challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") and
      (RPGlobals.race.order14 == nil or
       #RPGlobals.race.order14 == 0 or
       #RPGlobals.race.order14 == 1)) or
     ((challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
       challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
       challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
       challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)")) and
      (RPGlobals.race.order7 == nil or
       #RPGlobals.race.order7 == 0 or
       #RPGlobals.race.order7 == 1)) then

    -- Load the sprites
    if RPSpeedrun.sprites.needToSet1 == nil then
      RPSpeedrun.sprites.needToSet1 = Sprite()
      RPSpeedrun.sprites.needToSet1:Load("gfx/speedrun/need-to-set1.anm2", true)
      RPSpeedrun.sprites.needToSet1:SetFrame("Default", 0)
      RPSpeedrun.sprites.needToSet2 = Sprite()
      RPSpeedrun.sprites.needToSet2:Load("gfx/speedrun/need-to-set2.anm2", true)
      RPSpeedrun.sprites.needToSet2:SetFrame("Default", 0)
      RPSpeedrun.sprites.needToSet3 = Sprite()
      RPSpeedrun.sprites.needToSet3:Load("gfx/speedrun/need-to-set3.anm2", true)
      RPSpeedrun.sprites.needToSet3:SetFrame("Default", 0)
    end

    -- Display the sprites
    local pos = RPSprites:GetScreenCenterPosition()
    pos.Y = pos.Y - 80
    RPSpeedrun.sprites.needToSet1:RenderLayer(0, pos)
    pos.Y = pos.Y + 30
    RPSpeedrun.sprites.needToSet2:RenderLayer(0, pos)
    pos.Y = pos.Y + 40
    RPSpeedrun.sprites.needToSet3:RenderLayer(0, pos)
    return
  end

  -- Load the sprites
  if RPSpeedrun.sprites.slash == nil then
    RPSpeedrun.sprites.digit = {}
    for i = 1, 4 do
      RPSpeedrun.sprites.digit[i] = Sprite()
      RPSpeedrun.sprites.digit[i]:Load("gfx/timer/timer.anm2", true)
      RPSpeedrun.sprites.digit[i].Scale = Vector(0.9, 0.9)
      -- Make the numbers a bit smaller than the ones used for the timer
      RPSpeedrun.sprites.digit[i]:SetFrame("Default", 0)
    end
    RPSpeedrun.sprites.slash = Sprite()
    RPSpeedrun.sprites.slash:Load("gfx/timer/slash.anm2", true)
    RPSpeedrun.sprites.slash:SetFrame("Default", 0)
  end

  -- Local variables
  local digitLength = 7.25
  local startingX = 23
  local startingY = 79
  local adjustment1 = 0
  local adjustment2 = 0
  if RPSpeedrun.charNum > 9 then
    adjustment1 = digitLength - 2
    adjustment2 = adjustment1 - 1
  end

  -- Display the sprites
  local digit1 = RPSpeedrun.charNum
  local digit2 = -1
  if RPSpeedrun.charNum > 9 then
    digit1 = 1
    digit2 = RPSpeedrun.charNum - 10
  end
  local digit3 = 7 -- Assume a 7 character speedrun by default
  local digit4 = -1
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    digit3 = 9
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    digit3 = 1
    digit4 = 4
  end

  local posDigit1 = Vector(startingX, startingY)
  RPSpeedrun.sprites.digit[1]:SetFrame("Default", digit1)
  RPSpeedrun.sprites.digit[1]:RenderLayer(0, posDigit1)

  if digit2 ~= -1 then
    local posDigit2 = Vector(startingX + digitLength - 1, startingY)
    RPSpeedrun.sprites.digit[2]:SetFrame("Default", digit2)
    RPSpeedrun.sprites.digit[2]:RenderLayer(0, posDigit2)
  end

  local posSlash = Vector(startingX + digitLength -1 + adjustment1, startingY)
  RPSpeedrun.sprites.slash:RenderLayer(0, posSlash)

  local posDigit3 = Vector(startingX + digitLength + adjustment2 + 5 , startingY)
  RPSpeedrun.sprites.digit[3]:SetFrame("Default", digit3)
  RPSpeedrun.sprites.digit[3]:RenderLayer(0, posDigit3)

  if digit4 ~= -1 then
    local posDigit4 = Vector(startingX + digitLength + adjustment2 + 3 + digitLength, startingY)
    RPSpeedrun.sprites.digit[3]:SetFrame("Default", digit4)
    RPSpeedrun.sprites.digit[3]:RenderLayer(0, posDigit4)
  end
end

--
-- Other
--

function RPSpeedrun:PostNewRoom()
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  RPSpeedrun:PostNewRoomWomb2Error()
  RPSpeedrun:PostNewRoomReplaceBosses()
  RPSpeedrun:PostNewRoomCheckCurseRoom()
  RPSpeedrun:PostNewRoomCheckSacrificeRoom()
  RPSpeedrun:PostNewRoomCheckLibrary()
end

-- Fix the bug where the "correct" exit always appears in the I AM ERROR room in custom challenges (1/2)
function RPSpeedrun:PostNewRoomWomb2Error()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local gridSize = room:GetGridSize()

  if stage ~= LevelStage.STAGE4_2 then -- 8
    return
  end

  if roomType ~= RoomType.ROOM_ERROR then -- 3
    return
  end

  -- Find out whether we should spawn a passage up or down, depending on the room seed
  math.randomseed(roomSeed)
  local direction = math.random(1, 2)
  if direction == 1 then
    Isaac.DebugString("Randomly decided that the I AM ERROR room direction should be up.")
  elseif direction == 2 then
    Isaac.DebugString("Randomly decided that the I AM ERROR room direction should be down.")
  end

  -- Find any existing trapdoors
  local pos
  for i = 1, gridSize do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_TRAPDOOR then -- 17
        if direction == 1 then
          -- We need to remove it since we are going up
          pos = gridEntity.Position
          room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

          -- Spawn a Heaven Door (1000.39) (it will get replaced with the fast-travel version on this frame)
          game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, pos, Vector(0, 0), nil, 0, 0)
          Isaac.DebugString("Replaced a trapdoor with a beam of light.")
          return
        elseif direction == 2 then
          -- If we are going down and there is already a trapdoor, we don't need to do anything
          return
        end
      end
    end
  end

  -- Find any existing beams of light
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_EFFECT and -- 1000
       entity.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then -- 39

      if direction == 1 then
        -- If we are going up and there is already a beam of light, we don't need to do anything
        return
      elseif direction == 2 then
        -- We need to remove it since we are going down
        pos = entity.Position
        entity:Remove()

        -- Spawn a trapdoor (it will get replaced with the fast-travel version on this frame)
        Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, pos, true) -- 17
        Isaac.DebugString("Replaced a beam of light with a trapdoor.")
        return
      end
    end
  end
end

-- Replace the two final bosses in season 3
function RPSpeedrun:PostNewRoomReplaceBosses()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomClear = room:IsClear()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    return
  end

  -- ESA (European Speedrunner Assembly)
  if RPGlobals.debug then
    return
  end

  if stage ~= 10 and
     stage ~= 11 then

    return
  end

  if roomType ~= RoomType.ROOM_BOSS then -- 5
    return
  end

  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    return
  end

  if roomClear then
    return
  end

  -- Don't do anything if we have somehow gone the wrong direction
  -- (via We Need to Go Deeper!, Undefined, etc.)
  local direction = RPSpeedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end
  if stageType == 1 and -- Cathedral or The Chest
     direction == 2 then

    return
  end
  if stageType == 0 and -- Sheol or Dark Room
     direction == 1 then

    return
  end

  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if stageType == 1 and -- Cathedral
       entity.Type == EntityType.ENTITY_ISAAC then -- 273

      entity:Remove()

    elseif stageType == 0 and -- Sheol
           entity.Type == EntityType.ENTITY_SATAN then -- 84

        entity:Remove()

    elseif stageType == 1 and -- The Chest
           entity.Type == EntityType.ENTITY_ISAAC then -- 102

        entity:Remove()

      elseif stageType == 0 and -- Dark Room
             entity.Type == EntityType.ENTITY_THE_LAMB  then -- 273

        entity:Remove()
      end
    end

    -- Spawn the replacement boss
    if stage == 10 then
      Isaac.Spawn(838, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
      Isaac.DebugString("Spawned Jr. Fetus (for season 3).")
    elseif stage == 11 then
      Isaac.Spawn(777, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
      Isaac.DebugString("Spawned Mahalath (for season 3).")
    end
end

-- Prevent people from resetting for a Curse Room in R+7 Season 4
function RPSpeedrun:PostNewRoomCheckCurseRoom()
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local challenge = Isaac.GetChallenge()
  local player = game:GetPlayer(0)

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_CURSE or -- 10
     RPGlobals.run.deletedCurseRoom then

    return
  end

  -- Check to see if there are any pickups in the room
  local pickups = false
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_PICKUP or -- 5
       entity.Type == EntityType.ENTITY_SLOT then -- 6

      pickups = true
      break
    end
  end
  if pickups == false then
    return
  end

  RPGlobals.run.deletedCurseRoom = true
  player:AnimateSad()
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_PICKUP or -- 5
       entity.Type == EntityType.ENTITY_SLOT then -- 6

      entity:Remove()
    end
  end
  Isaac.DebugString("Deleted all of the pickups in a Curse Room (during a R+7 Season 4 run).")
end

-- Prevent people from resetting for a Sacrifice Room in R+7 Season 4
function RPSpeedrun:PostNewRoomCheckSacrificeRoom()
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local gridSize = room:GetGridSize()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local challenge = Isaac.GetChallenge()
  local player = game:GetPlayer(0)

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_SACRIFICE then -- 13

    return
  end

  player:AnimateSad()
  for i = 1, gridSize do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 8
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end

    end
  end
  Isaac.DebugString("Deleted the spikes in a Sacrifice Room (during a R+7 Season 4 run).")
end

-- Prevent people from resetting for a Library in R+7 Season 4
function RPSpeedrun:PostNewRoomCheckLibrary()
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local challenge = Isaac.GetChallenge()
  local player = game:GetPlayer(0)

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_LIBRARY then -- 12

    return
  end

  player:AnimateSad()
  for i = 1, 20 do
    game:Spawn(EntityType.ENTITY_MONSTRO, 0, room:GetCenterPos(), Vector(0, 0), nil, 0, roomSeed)
  end
  Isaac.DebugString("Spawned Monstros in a Library (during a R+7 Season 4 run).")
end

-- Don't move to the first character of the speedrun if we die
function RPSpeedrun:PostGameEnd(gameOver)
  if gameOver == false then
    return
  end

  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  RPSpeedrun.fastReset = true
  Isaac.DebugString("Game over detected.")
end

function RPSpeedrun:InSpeedrun()
  local challenge = Isaac.GetChallenge()

  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") then

    return true
  else
    return false
  end
end

return RPSpeedrun
