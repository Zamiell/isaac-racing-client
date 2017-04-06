local RPSpeedrun = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")
local RPSaveDat = require("src/rpsavedat")

--
-- Variables
--

RPSpeedrun.charNum = 1
RPSpeedrun.sprites = {}
RPSpeedrun.startedTime = 0
RPSpeedrun.finished = false
RPSpeedrun.finishedTime = 0
RPSpeedrun.choosetype = 0
RPSpeedrun.chooseOrder = {}
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
-- Speedrun functions
--

-- Called from the PostNewRoom callback
function RPSpeedrun:PostNewRoomChangeOrder()
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
  -- TODO
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
      RPSpeedrun.sprites.characters[newIndex].Color = Color(1, 1, 1, 0.35, 0, 0, 0)
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
      RPSpeedrun.sprites.characters[newIndex].Color = Color(1, 1, 1, 0.35, 0, 0, 0)
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

-- Called from the PostRender callback
function RPSpeedrun:DisplayCharProgress()
  -- Don't show the progress if we are not in the custom challenge
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then

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

function RPSpeedrun:DisplayCharSelectRoom()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  if RPSpeedrun.sprites.button1 ~= nil then
    local posButton1 = RPGlobals:GridToPos(4, 4)
    RPSpeedrun.sprites.button1:RenderLayer(0, posButton1)
  end
  if RPSpeedrun.sprites.button2 ~= nil then
    local posButton2 = RPGlobals:GridToPos(8, 4)
    RPSpeedrun.sprites.button2:RenderLayer(0, posButton2)
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
function RPSpeedrun:CheckChallenge()
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

return RPSpeedrun
