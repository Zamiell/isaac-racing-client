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

RPSpeedrun.charPosition9 = { -- The format is character number, X, Y
  {2, 2, 1}, -- Cain
  {3, 4, 1}, -- Judas
  {4, 6, 1}, -- Blue Baby
  {5, 8, 1}, -- Eve
  {6, 10, 1}, -- Samson
  {7, 2, 3}, -- Azazel
  {8, 4, 3}, -- Lazarus
  {10, 8, 3}, -- The Lost
  {14, 10, 3}, -- Keeper
}
RPSpeedrun.charPosition14 = { -- The format is character number, X, Y
  {0, 1, 1}, -- Isaac
  {1, 3, 1}, -- Magdalene
  {2, 5, 1}, -- Cain
  {3, 7, 1}, -- Judas
  {4, 9, 1}, -- Blue Baby
  {5, 11, 1}, -- Eve
  {6, 1, 3}, -- Samson
  {7, 3, 3}, -- Azazel
  {8, 5, 3}, -- Lazarus
  {9, 7, 3}, -- Eden
  {10, 9, 3}, -- The Lost
  {13, 11, 3}, -- Lilith
  {14, 1, 5}, -- Keeper
  {15, 11, 5}, -- Apollyon
}

--
-- Variables
--

RPSpeedrun.charNum = 1 -- Reset expliticly from a long-reset
RPSpeedrun.sprites = {} -- Reset in the PostGameStarted callback
RPSpeedrun.startedTime = 0 -- Reset expliticly if we are on the first character
RPSpeedrun.finished = false -- Reset expliticly if we reset when already finished
RPSpeedrun.finishedTime = 0 -- Reset expliticly if we reset when already finished
RPSpeedrun.chooseType = 0 -- Reset when we enter the "Choose Char Order" room
RPSpeedrun.chooseOrder = {} -- Reset when we enter the "Choose Char Order" room
RPSpeedrun.fastReset = false -- Reset expliticly when we detect a fast reset
RPSpeedrun.spawnedCheckpoint = false -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.resetFrame = 0 -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.finishedChar = false -- Reset at the beginning of a run

--
-- Speedrun functions
--

-- Called from the PostGameStarted callback
function RPSpeedrun:Init()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local isaacFrameCount = Isaac.GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge == Isaac.GetChallengeIdByName("Change Char Order") then
    -- Make sure that some speedrun related variables are reset
    RPSpeedrun.finished = false
    RPSpeedrun.finishedTime = 0
    RPSpeedrun.charNum = 1
    RPSpeedrun.fastReset = false

    -- Go to the "Change Char Order" room
    Isaac.ExecuteCommand("stage 1a") -- The Cellar is the cleanest floor
    Isaac.ExecuteCommand("goto s.boss.9999")
    -- We can't use an existing boss room because after the boss is removed, a pedestal will spawn
    Isaac.DebugString("Going to the \"Change Char Order\" room.")
    -- We do more things in the "PostNewRoom" callback
    return
  end

  if challenge ~= Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then

    return
  end

  -- Reset some per-run variables
  RPSpeedrun.spawnedCheckpoint = false
  RPSpeedrun.resetFrame = 0

  -- Do actions based on the specific challenge
  if challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") then
    Isaac.DebugString("In R+9 challenge.")

  elseif challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then
    Isaac.DebugString("In R+14 challenge.")

    -- Give extra items to characters for the R+14 speedrun category
    if character == PlayerType.PLAYER_ISAAC then -- 0
      -- Add the Battery
      player:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63

      -- Giving the player the item does not actually remove it from any of the pools,
      -- so we have to expliticly add it to the ban list
      RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
      -- Add the Soul Jar
      player:AddCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR, 0, false)

      -- (the Soul Jar does not appear in any pools so we don't have to add it to the ban list)

    elseif character == PlayerType.PLAYER_LILITH then -- 13
      -- Lilith starts with the Schoolbag by default
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS -- 357
      Isaac.DebugString("Adding collectible 357") -- Box of Friends

      -- Giving the player the item does not actually remove it from any of the pools,
      -- so we have to expliticly add it to the ban list
      RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) -- 357

      -- Reorganize the items on the item tracker
      Isaac.DebugString("Removing collectible 412") -- Cambion Conception
      Isaac.DebugString("Adding collectible 412") -- Cambion Conception

    elseif character == PlayerType.PLAYER_APOLLYON then -- 15
      -- Apollyon starts with the Schoolbag by default
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_VOID -- 477
      Isaac.DebugString("Adding collectible 477") -- Void

      -- Giving the player the item does not actually remove it from any of the pools,
      -- so we have to expliticly add it to the ban list
      RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_VOID) -- 477
    end

    if RPGlobals.run.schoolbag.item ~= 0 then
      -- Make sure that the Schoolbag item is fully charged
      RPGlobals.run.schoolbag.charges = RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.run.schoolbag.item)
      RPSchoolbag.sprites.item = nil
    end
  end

  -- Move to the next character if we grabbed the checkpoint
  if RPSpeedrun.finishedChar then
    RPSpeedrun.finishedChar = false
    RPSpeedrun.fastReset = true -- Set this so that we don't go back to the beginning again
    RPSpeedrun.charNum = RPSpeedrun.charNum + 1
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting to switch to the new character.")
    return
  end

  -- Move to the first character if we finished
  if RPSpeedrun.finished then
    RPSpeedrun.finished = false
    RPSpeedrun.finishedTime = 0
    RPSpeedrun.charNum = 1
    RPSpeedrun.fastReset = false
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting to go back to the first character (since we finished the speedrun).")
    return
  end

  if challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     character ~= RPGlobals.race.order9[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+9 speedrun.")
    return

  elseif challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
         character ~= RPGlobals.race.order14[RPSpeedrun.charNum] then

    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we are on the wrong character for a R+14 speedrun.")
    return
  end

  if RPSpeedrun.fastReset then
    RPSpeedrun.fastReset = false

  elseif RPSpeedrun.fastReset == false and
         ((challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
           character ~= RPGlobals.race.order9[1]) or
          (challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
           character ~= RPGlobals.race.order14[1])) then

    -- They held R, and they are not on the first character, so they want to restart from the first character
    RPSpeedrun.charNum = 1
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because we want to start from the first character again.")
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
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then

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

  RPSpeedrun.spawnedCheckpoint = false

  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)

  -- Freeze the player
  player.ControlsEnabled = false

  -- Mark to restart the run after the "Checkpoint" text has displayed on the screen for a little bit
  RPSpeedrun.resetFrame = isaacFrameCount + 30
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

  -- We grabbed the checkpoint, so move us to the next character for the speedrun
  if RPSpeedrun.resetFrame ~= 0 and isaacFrameCount >= RPSpeedrun.resetFrame then
    RPSpeedrun.resetFrame = 0
    RPSpeedrun.finishedChar = true
    game:Fadeout(0.0275, RPGlobals.FadeoutTarget.FADEOUT_RESTART_RUN) -- 3
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
  sfx:Play(SoundEffect.SOUND_SPEEDRUN_FINISH, 1.5, 0, false, 1)

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
  RPSpeedrun.chooseType = 0
  RPSpeedrun.chooseOrder = {}
  RPSpeedrun.sprites = {}

  -- Spawn two buttons for the R+9 and R+14 selection
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, RPGlobals:GridToPos(4, 5), true) -- 20
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, RPGlobals:GridToPos(8, 5), true) -- 20

  -- Spawn the graphics over the buttons
  RPSpeedrun.sprites.button1 = Sprite()
  RPSpeedrun.sprites.button1:Load("gfx/speedrun/button1.anm2", true)
  RPSpeedrun.sprites.button1:SetFrame("Default", 0)
  RPSpeedrun.sprites.button2 = Sprite()
  RPSpeedrun.sprites.button2:Load("gfx/speedrun/button2.anm2", true)
  RPSpeedrun.sprites.button2:SetFrame("Default", 0)
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
  local room = game:GetRoom()

  if gridEntity:GetSaveState().State == 3 and
     gridEntity.Position.X == RPGlobals:GridToPos(4, 5).X and
     gridEntity.Position.Y == RPGlobals:GridToPos(4, 5).Y then

    RPSpeedrun.chooseType = 9
    Isaac.DebugString("The R+9 button was pressed.")

    -- Remove both of the buttons
    local num = room:GetGridSize()
    for i = 1, num do
      local gridEntity2 = room:GetGridEntity(i)
      if gridEntity2 ~= nil then
        local test = gridEntity2:ToPressurePlate()
        if test ~= nil then
          room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
        end
      end
    end
    RPSpeedrun.sprites.button1 = nil
    RPSpeedrun.sprites.button2 = nil

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
         gridEntity.Position.X == RPGlobals:GridToPos(8, 5).X and
         gridEntity.Position.Y == RPGlobals:GridToPos(8, 5).Y then

    RPSpeedrun.chooseType = 14
    Isaac.DebugString("The R+14 button was pressed.")

    -- Remove both of the buttons
    local num = room:GetGridSize()
    for i = 1, num do
      local gridEntity2 = room:GetGridEntity(i)
      if gridEntity2 ~= nil then
        local test = gridEntity2:ToPressurePlate()
        if test ~= nil then
          room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
        end
      end
    end
    RPSpeedrun.sprites.button1 = nil
    RPSpeedrun.sprites.button2 = nil

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
  end

  if RPSpeedrun.chooseType == 9 then
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
  elseif RPSpeedrun.chooseType == 14 then
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
    local posButton1 = RPGlobals:GridToPos(4, 4)
    local posRender = Isaac.WorldToRenderPosition(posButton1, false)
    RPSpeedrun.sprites.button1:RenderLayer(0, posRender)
  end
  if RPSpeedrun.sprites.button2 ~= nil then
    local posButton2 = RPGlobals:GridToPos(8, 4)
    local posRender = Isaac.WorldToRenderPosition(posButton2, false)
    RPSpeedrun.sprites.button2:RenderLayer(0, posRender)
  end
  if RPSpeedrun.sprites.characters ~= nil then
    local posNull = Vector(0, 0)
    if #RPSpeedrun.sprites.characters == 9 then
      for i = 1, #RPSpeedrun.sprites.characters do
        local posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition9[i][2], RPSpeedrun.charPosition9[i][3] - 1)
        local posRender = Isaac.WorldToRenderPosition(posGame, false)
        posRender.Y = posRender.Y + 10
        RPSpeedrun.sprites.characters[i]:Render(posRender, posNull, posNull)
      end
    elseif #RPSpeedrun.sprites.characters == 14 then
      for i = 1, #RPSpeedrun.sprites.characters do
        local posGame = RPGlobals:GridToPos(RPSpeedrun.charPosition14[i][2], RPSpeedrun.charPosition14[i][3] - 1)
        local posRender = Isaac.WorldToRenderPosition(posGame, false)
        posRender.Y = posRender.Y + 10
        RPSpeedrun.sprites.characters[i]:Render(posRender, posNull, posNull)
      end
    end
  end
end

-- Called from the PostRender callback
function RPSpeedrun:DisplayCharProgress()
  -- Don't show the progress if we are not in the custom challenge
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then

    return
  end

  -- Check to see if they have a set order
  if (challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and #RPGlobals.race.order9 == 1) or
     (challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and #RPGlobals.race.order14 == 1) then

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

return RPSpeedrun
