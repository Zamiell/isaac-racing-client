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
  R9S1  = {X = 6, Y = 3},
  R14S1 = {X = 4, Y = 5},
  R7S2  = {X = 8, Y = 5},
}
RPSpeedrun.charPosition9 = { -- The format is character number, X, Y
  {2, 2, 1},   -- Cain
  {3, 4, 1},   -- Judas
  {4, 6, 1},   -- Blue Baby
  {5, 8, 1},   -- Eve
  {6, 10, 1},  -- Samson
  {7, 2, 3},   -- Azazel
  {8, 4, 3},   -- Lazarus
  {10, 8, 3},  -- The Lost
  {14, 10, 3}, -- Keeper
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
  {14, 1, 5},  -- Keeper
  {15, 11, 5}, -- Apollyon
}
RPSpeedrun.charPosition7_1 = { -- The format is character number, X, Y
  {0, 2, 1},   -- Isaac
  {2, 4, 1},   -- Cain
  {3, 6, 1},   -- Judas
  {7, 8, 1},   -- Azazel
  {9, 10, 1},  -- Eden
  {15, 2, 3},  -- Apollyon
  {16, 10, 3}, -- Samael
}
RPSpeedrun.charPosition7_2 = { -- The format is character number, X, Y
  {0, 2, 1},   -- Isaac
  {1, 4, 1},   -- Magdalene
  {3, 6, 1},   -- Judas
  {5, 8, 1},   -- Eve
  {6, 10, 1},  -- Samson
  {8, 2, 3},   -- Lazarus
  {10, 10, 3}, -- The Lost
}

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
RPSpeedrun.fastReset = false -- Reset expliticly when we detect a fast reset
RPSpeedrun.spawnedCheckpoint = false -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.fadeFrame = 0 -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.resetFrame = 0 -- Reset after we execute the "restart" command and at the beginning of a new run
RPSpeedrun.s3direction = 1 -- 1 is up and 2 is down; reset at the beginning of a new run
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
    RPSpeedrun.s3direction = 1
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting to go back to the first character (since we finished the speedrun).")
    return
  end

  if challenge == Isaac.GetChallengeIdByName("Change Char Order") then
    -- Make sure that some speedrun related variables are reset
    RPSpeedrun.charNum = 1
    RPSpeedrun.fastReset = false

    -- Max out Isaac's speed
    player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
    player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
    player:RemoveCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_BELT)) -- 28

    -- Go to the "Change Char Order" room
    Isaac.ExecuteCommand("stage 1a") -- The Cellar is the cleanest floor
    Isaac.ExecuteCommand("goto s.boss.9999")
    -- We can't use an existing boss room because after the boss is removed, a pedestal will spawn
    Isaac.DebugString("Going to the \"Change Char Order\" room.")
    -- We do more things in the "PostNewRoom" callback
    return
  end

  if challenge ~= Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then

    return
  end

  -- Do actions based on the specific challenge
  if challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") then
    Isaac.DebugString("In the R+9 (S1) challenge.")

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

  elseif challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then
    Isaac.DebugString("In the R+14 (S1) challenge.")

    -- Give extra items to characters for the R+14 speedrun category (Season 1)
    if character == PlayerType.PLAYER_ISAAC then -- 0
      -- Add the Battery
      player:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63

      -- Remove it from all the pools
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
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS -- 357
      RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
      RPSchoolbag.sprites.item = nil
      Isaac.DebugString("Adding collectible 357 (Box of Friends)")

      -- Remove it from all the pools
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
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_VOID -- 477
      RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
      RPSchoolbag.sprites.item = nil
      Isaac.DebugString("Adding collectible 477 (Void)")

      -- Remove it from all the pools
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VOID) -- 477
    end

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") then
    Isaac.DebugString("In the R+7 (S2) challenge.")

    -- Give extra items to characters for the R+7 (S2) speedrun category (Season 2)
    if character == PlayerType.PLAYER_ISAAC then -- 0
      -- Add the Battery
      player:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63

      -- Make Isaac start with a double charge instead of a single charge
      player:SetActiveCharge(12)
      sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

      -- Remove it from all the pools
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    elseif character == PlayerType.PLAYER_APOLLYON then -- 15
      -- Apollyon starts with the Schoolbag by default
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_VOID -- 477
      RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
      RPSchoolbag.sprites.item = nil
      Isaac.DebugString("Adding collectible 477 (Void)")

      -- Remove it from all the pools
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VOID) -- 477
    end

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then
    Isaac.DebugString("In the R+7 (S3) challenge.")

    -- Everyone starts with the Schoolbag in this season
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
    RPSchoolbag.sprites.item = nil

    -- Give extra items to characters for the R+7 (S3) speedrun category (Season 3)
    if character == PlayerType.PLAYER_ISAAC then -- 0
      -- Isaac starts with Moving Box
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_MOVING_BOX -- 523
      Isaac.DebugString("Adding collectible 523 (Moving Box)")

    elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
      -- Magdalene starts with the How to Jump
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_HOW_TO_JUMP -- 282
      Isaac.DebugString("Adding collectible 282 (How to Jump)")

      -- Remove her speed up pill
      player:SetCard(0, 0)

    elseif character == PlayerType.PLAYER_JUDAS then -- 3
      -- Judas starts with the Book of Belial
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL -- 34
      Isaac.DebugString("Adding collectible 34 (Book of Belial)")

    elseif character == PlayerType.PLAYER_EVE then -- 5
      -- Eve starts with Delirious
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_DULL_RAZOR -- 486
      Isaac.DebugString("Adding collectible 486 (Dull Razor)")

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
  end

  if challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     character ~= RPGlobals.race.order9[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+9 (S1) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
         character ~= RPGlobals.race.order14[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+14 (S1) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and
         character ~= RPGlobals.race.order7[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+7 (S2) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") and
         character ~= RPGlobals.race.order7[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+7 (S3) speedrun." ..
                      " (" .. tostring(character) .. ")")
    return
  end

  if RPSpeedrun.fastReset then
    RPSpeedrun.fastReset = false

  elseif RPSpeedrun.fastReset == false and
         ((challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
           character ~= RPGlobals.race.order9[1]) or
          (challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
           character ~= RPGlobals.race.order14[1]) or
          (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and
           character ~= RPGlobals.race.order7[1]) or
          (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") and
           character ~= RPGlobals.race.order7[1])) then

    -- They held R, and they are not on the first character, so they want to restart from the first character
    RPSpeedrun.charNum = 1
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    RPSpeedrun.s3direction = 1
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
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then

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

  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)
  Isaac.DebugString("Checkpoint custom item given (" .. tostring(CollectibleType.COLLECTIBLE_CHECKPOINT) .. ").")

  -- Freeze the player
  player.ControlsEnabled = false

  -- Mark to fade out after the "Checkpoint" text has displayed on the screen for a little bit
  RPSpeedrun.fadeFrame = isaacFrameCount + 30
end

-- Called from the PostRender callback
function RPSpeedrun:CheckRestart()
  -- Local variables
  local game = Game()
  local isaacFrameCount = Isaac.GetFrameCount()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()

  -- Don't move to the first character of the speedrun if we die
  if (playerSprite:IsPlaying("Death") or
      playerSprite:IsPlaying("LostDeath")) and
      -- The Lost has a different death animation than all of the other characters
     player:GetExtraLives() == 0 then

    RPSpeedrun.fastReset = true
  end

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

    -- Make the next run go to the other path
    RPSpeedrun.s3direction = RPSpeedrun.s3direction + 1
    Isaac.DebugString("Set season 3 direction to: " .. tostring(RPSpeedrun.s3direction))
    if RPSpeedrun.s3direction == 3 then
      RPSpeedrun.s3direction = 1
      Isaac.DebugString("Set season 3 direction back to 1.")
    end

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

  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") or
     roomIndexUnsafe ~= GridRooms.ROOM_DEBUG_IDX then -- -3

    return
  end

  -- Stop the boss room sound effect
  sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

  -- We want to trap the player in the room,
  -- but we can't make a room with no doors because then the "goto" command would crash the game,
  -- so we have one door at the bottom
  room:RemoveDoor(3) -- The bottom door is always 3

  -- Reset the graphics and the order
  RPSpeedrun.chooseType = nil
  RPSpeedrun.chooseOrder = {}
  RPSpeedrun.sprites = {}

  -- Spawn buttons for each type of speedrun
  local pos
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R9S1.X, RPSpeedrun.buttons.R9S1.Y)
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R14S1.X, RPSpeedrun.buttons.R14S1.Y)
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  pos = RPGlobals:GridToPos(RPSpeedrun.buttons.R7S2.X, RPSpeedrun.buttons.R7S2.Y)
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
  if gridEntity:GetSaveState().State == 3 and
     gridEntity.Position.X == buttonPos1.X and
     gridEntity.Position.Y == buttonPos1.Y then

    RPSpeedrun.chooseType = "R+9"
    Isaac.DebugString("The R+9 (S1) button was pressed.")

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
    Isaac.DebugString("The R+14 (S1) button was pressed.")

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
    Isaac.DebugString("The R+7 (S2) button was pressed.")

    RPSpeedrun:RemoveAllRoomButtons()

    RPSpeedrun.sprites.characters = {}
    for i = 1, #RPSpeedrun.charPosition7_1 do
      -- Spawn 7 buttons for the 7 characters
      Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, -- 20
                      RPGlobals:GridToPos(RPSpeedrun.charPosition7_1[i][2], RPSpeedrun.charPosition7_1[i][3]), true)

      -- Spawn the character selection graphics next to the buttons
      local newIndex = #RPSpeedrun.sprites.characters + 1
      RPSpeedrun.sprites.characters[newIndex] = Sprite()
      local charNum = RPSpeedrun.charPosition7_1[i][1]
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
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
      end
    end

  elseif RPSpeedrun.chooseType == "R+7 (S2)" then
    for i = 1, #RPSpeedrun.charPosition7_1 do
      local posButton = RPGlobals:GridToPos(RPSpeedrun.charPosition7_1[i][2], RPSpeedrun.charPosition7_1[i][3])
      if gridEntity:GetSaveState().State == 3 and
         gridEntity.VarData == 0 and
         gridEntity.Position.X == posButton.X and
         gridEntity.Position.Y == posButton.Y then

        -- We have pressed one of the buttons corresponding to the characters
        gridEntity.VarData = 1 -- Mark that we have pressed this button already
        RPSpeedrun.chooseOrder[#RPSpeedrun.chooseOrder + 1] = RPSpeedrun.charPosition7_1[i][1]
        if #RPSpeedrun.chooseOrder == 7 then
          -- We have finished choosing our 7 characters
          RPGlobals.race.order7 = RPSpeedrun.chooseOrder
          RPSaveDat:Save()
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
      end
    end

  elseif RPSpeedrun.chooseType == "R+7 (S3)" then
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
          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end

        -- Change the graphic to that of a number
        RPSpeedrun.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
        RPSpeedrun.sprites.characters[i]:SetFrame("Default", #RPSpeedrun.chooseOrder)
        RPSpeedrun.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade
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
  if RPSpeedrun.sprites.characters ~= nil then
    for i = 1, #RPSpeedrun.sprites.characters do
      local posGame
      if #RPSpeedrun.sprites.characters == 9 then
        posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition9[i][2], RPSpeedrun.charPosition9[i][3] - 1)
      elseif #RPSpeedrun.sprites.characters == 14 then
        posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition14[i][2], RPSpeedrun.charPosition14[i][3] - 1)
      elseif #RPSpeedrun.sprites.characters == 7 then
        posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition7_1[i][2], RPSpeedrun.charPosition7_1[i][3] - 1)
      end
      local posRender = Isaac.WorldToRenderPosition(posGame, false)
      posRender.Y = posRender.Y + 10
      RPSpeedrun.sprites.characters[i]:Render(posRender, Vector(0, 0), Vector(0, 0))
    end
  end
end

-- Called from the PostRender callback
function RPSpeedrun:DisplayCharProgress()
  -- Don't show the progress if we are not in the custom challenge
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then

    return
  end

  -- Check to see if they have a set order
  if (challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
      (RPGlobals.race.order9 == nil or
       #RPGlobals.race.order9 == 0 or
       #RPGlobals.race.order9 == 1)) or
     (challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
      (RPGlobals.race.order14 == nil or
       #RPGlobals.race.order14 == 0 or
       #RPGlobals.race.order14 == 1)) or
     (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and
      (RPGlobals.race.order7 == nil or
       #RPGlobals.race.order7 == 0 or
       #RPGlobals.race.order7 == 1)) or
     (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") and
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
  local digit3 = 9 -- Assume a 9 character speedrun by default
  local digit4 = -1
  if challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then
    digit3 = 1
    digit4 = 4
  end
  if challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") or
     challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then

    digit3 = 7
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

-- Replace bosses in season 3
function RPSpeedrun:PostNewRoom()
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
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then
    return
  end

  if stage ~= 11 then
    return
  end

  if roomType ~= RoomType.ROOM_BOSS then -- 5
    return
  end

  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    return
  end

  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if stageType == 1 and -- The Chest
       entity.Type == EntityType.ENTITY_ISAAC then -- 102

      entity:Remove()
    elseif stageType == 0 and -- Dark Room
           entity.Type == EntityType.ENTITY_THE_LAMB  then -- 273

      entity:Remove()
    end
  end

  -- Spawn her
  Isaac.Spawn(777, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
  Isaac.DebugString("Spawned Mahalath (for season 3).")
end

return RPSpeedrun
