local RPSpeedrun = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Variables
--

RPSpeedrun.charNum = 1
RPSpeedrun.sprites = {}
RPSpeedrun.startTime = 0
RPSpeedrun.finished = false
RPSpeedrun.finishTime = 0
RPSpeedrun.chooseOrder = {}

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

  -- Reset the order
  RPSpeedrun.chooseOrder = {}

  -- Spawn two buttons
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, RPGlobals:GridToPos(4, 5), true) -- 20
  Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, RPGlobals:GridToPos(8, 5), true) -- 20

  -- Spawn the graphics over the buttons
  -- TODO
end

-- Called from the PostUpdate callback
function RPSpeedrun:CheckButtonPressed(gridEntity, i)
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

    -- The "R+9" button was pressed, so remove both of the buttons
    local num = room:GetGridSize()
    for j = 1, num do
      local gridEntity2 = room:GetGridEntity(j)
      if gridEntity2 ~= nil and gridEntity:ToPressurePlate() ~= nil then
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end
    end

    -- Spawn the character selection graphics next to the buttons
    RPSpeedrun.sprites.character = {}
    for playerType = 0, 13 do
      if playerType ~= PlayerType.PLAYER_ISAAC and -- 0
         playerType ~= PlayerType.PLAYER_MAGDALENA and -- 1
         playerType ~= PlayerType.PLAYER_EDEN and -- 9
         playerType ~= PlayerType.PLAYER_LAZARUS2 and -- 11
         playerType ~= PlayerType.PLAYER_BLACKJUDAS and -- 12
         playerType ~= PlayerType.PLAYER_LILITH and -- 13
         playerType ~= PlayerType.PLAYER_APOLLYON then -- 15

        RPSpeedrun.sprites.character[i] = Sprite()
        RPSpeedrun.sprites.character[i]:Load("gfx/custom/characters/" .. tostring(i) .. ".anm2", true)
        RPSpeedrun.sprites.character[i]:SetFrame("Death", 5) -- The 5th frame is rather interesting
        RPSpeedrun.sprites.character[i].Color = Color(1, 1, 1, 0.35, 0, 0, 0)
        -- Fade the character so it looks like a ghost
      end
    end

  elseif gridEntity:GetSaveState().State == 3 and
         gridEntity.Position.X == RPGlobals:GridToPos(8, 5).X and
         gridEntity.Position.Y == RPGlobals:GridToPos(8, 5).Y then

    -- The "R+14" button was pressed, so remove both of the buttons
    local num = room:GetGridSize()
    for j = 1, num do
      local gridEntity2 = room:GetGridEntity(j)
      if gridEntity2 ~= nil and gridEntity:ToPressurePlate() ~= nil then
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end
    end

    -- Spawn the character selection graphics next to the buttons
    RPSpeedrun.sprites.character = {}
    for playerType = 0, 13 do
      if playerType ~= PlayerType.PLAYER_LAZARUS2 and -- 11
         playerType ~= PlayerType.PLAYER_BLACKJUDAS then -- 12

        RPSpeedrun.sprites.character[i] = Sprite()
        RPSpeedrun.sprites.character[i]:Load("gfx/custom/characters/" .. tostring(i) .. ".anm2", true)
        RPSpeedrun.sprites.character[i]:SetFrame("Death", 5) -- The 5th frame is rather interesting
        RPSpeedrun.sprites.character[i].Color = Color(1, 1, 1, 0.35, 0, 0, 0)
        -- Fade the character so it looks like a ghost
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

return RPSpeedrun
