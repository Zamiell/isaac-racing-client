local RPSprites = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Sprite functions
--

-- Call this once to load the PNG from the anm2 file
function RPSprites:Init(spriteType, spriteName)
  -- If this is a new sprite type, initialize it in the sprite table
  if RPGlobals.spriteTable[spriteType] == nil then
    RPGlobals.spriteTable[spriteType] = {}
  end

  -- Do nothing if this sprite type is already set to this name
  if RPGlobals.spriteTable[spriteType].spriteName == spriteName then
    return
  end

  -- Check to see if we are clearing this sprite
  if spriteName == 0 then
    RPGlobals.spriteTable[spriteType].sprite = nil
    RPGlobals.spriteTable[spriteType].spriteName = 0
    return
  end

  -- Otherwise, initialize the sprite
  RPGlobals.spriteTable[spriteType].sprite = Sprite()
  if spriteType == "seeded-item1" or
     spriteType == "seeded-item2" or
     spriteType == "seeded-item3" or
     spriteType == "seeded-item4" or
     spriteType == "seeded-item5" or
     spriteType == "diversity-item1" or
     spriteType == "diversity-item2" or
     spriteType == "diversity-item3" or
     spriteType == "diversity-item4" then

    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/items3/collectibles/" .. spriteName .. ".anm2", true)

  elseif spriteType == "diversity-item5" then
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/items3/trinkets/" .. spriteName .. ".anm2", true)

  elseif spriteType == "place" then
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/place/" .. spriteName .. ".anm2", true)

  else
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/" .. spriteName .. ".anm2", true)
  end

  RPGlobals.spriteTable[spriteType].spriteName = spriteName
end

-- Call this every frame in MC_POST_RENDER
function RPSprites:Display()
  if RPGlobals.race.status == "none" and RPGlobals.raceVars.finished == false then
    return
  end

  -- Loop through all the sprites and render them
  for k, v in pairs(RPGlobals.spriteTable) do
    -- Position it
    local vec = RPSprites:GetScreenCenterPosition() -- Start the vector off in the center of the screen by default
    local animationName = "Default"
    if k == "top" then -- Pre-race messages and the countdown
      vec.Y = vec.Y - 80
    elseif k == "myStatus" then
      vec.Y = vec.Y - 40
    elseif k == "raceType" then
      vec.X = vec.X - 110
      vec.Y = vec.Y + 45
    elseif k == "raceFormat" then
      vec.X = vec.X + 110
      vec.Y = vec.Y + 45
    elseif k == "seeded-starting-item" then
      vec.Y = vec.Y - 40
    elseif k == "seeded-starting-build" then
      vec.Y = vec.Y - 40
    elseif k == "seeded-item1" then
      vec.Y = vec.Y - 10
    elseif k == "seeded-item2" then
      vec.X = vec.X - 15
      vec.Y = vec.Y - 10
    elseif k == "seeded-item3" then
      vec.X = vec.X + 15
      vec.Y = vec.Y - 10
    elseif k == "seeded-item4" then
      vec.X = vec.X - 45
      vec.Y = vec.Y - 10
    elseif k == "seeded-item5" then
      vec.X = vec.X + 45
      vec.Y = vec.Y - 10
    elseif k == "diversity-active" then
      vec.X = vec.X - 80
      vec.Y = vec.Y - 40
    elseif k == "diversity-passives" then
      vec.Y = vec.Y - 40
    elseif k == "diversity-trinket" then
      vec.X = vec.X + 80
      vec.Y = vec.Y - 40
    elseif k == "diversity-item1" then -- The active item
      vec.X = vec.X - 80
      vec.Y = vec.Y - 10
    elseif k == "diversity-item2" then -- The 1st passive item
      vec.X = vec.X - 30
      vec.Y = vec.Y - 10
    elseif k == "diversity-item3" then -- The 2nd passive item
      vec.Y = vec.Y - 10
    elseif k == "diversity-item4" then -- The 3rd passive item
      vec.X = vec.X + 30
      vec.Y = vec.Y - 10
    elseif k == "diversity-item5" then -- The trinket
      vec.X = vec.X + 80
      vec.Y = vec.Y - 10
    elseif k == "clock" then
      vec.X = 7.5 -- Move it below the Angel chance
      vec.Y = 217
    end

    -- Draw it
    if v.sprite ~= nil then
      RPGlobals.spriteTable[k].sprite:SetFrame(animationName, 0)
      RPGlobals.spriteTable[k].sprite:RenderLayer(0, vec)
    end
  end
end

function RPSprites:TimerUpdate()
  if RPGlobals.raceVars.startedTime == 0 then
    return
  end

  -- Find out how much time has passed since the race started
  -- (or what the race finish time was)
  local elapsedTime
  if RPGlobals.raceVars.finished then
    elapsedTime = RPGlobals.raceVars.finishedTime - RPGlobals.raceVars.startedTime
  else
    elapsedTime = Isaac:GetTime() - RPGlobals.raceVars.startedTime
    -- "Isaac:GetTime()" is analogous to Lua's "os.clock()"
  end
  elapsedTime = elapsedTime / 1000 -- This will be in milliseconds, so we divide by 1000

  local minutes = math.floor(elapsedTime / 60)
  if minutes < 10 then
    minutes = "0" .. tostring(minutes)
  else
    minutes = tostring(minutes)
  end

  local seconds = elapsedTime % 60
  seconds = RPGlobals:Round(seconds, 1)
  if seconds < 10 then
    seconds = "0" .. tostring(seconds)
  else
    seconds = tostring(seconds)
  end

  local timerString = minutes .. ':' .. seconds
  Isaac.RenderText(timerString, 17, 211, 0.7, 1, 0.2, 1.0) -- X, Y, R, G, B, A
end

-- Taken from Alphabirth: https://steamcommunity.com/sharedfiles/filedetails/?id=848056541
function RPSprites:GetScreenCenterPosition()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
  local pos = room:GetCenterPos()

  if centerOffset.X > 260 then
    pos.X = pos.X - 260
  end
  if centerOffset.Y > 140 then
    pos.Y = pos.Y - 140
  end

  return Isaac.WorldToRenderPosition(pos, false)
end

-- This should only clear the graphics that appear after the race has started
function RPSprites:ClearStartingRoomGraphics()
  RPSprites:Init("seeded-starting-item", 0)
  RPSprites:Init("seeded-starting-build", 0)
  RPSprites:Init("seeded-item1", 0)
  RPSprites:Init("seeded-item2", 0)
  RPSprites:Init("seeded-item3", 0)
  RPSprites:Init("seeded-item4", 0)
  RPSprites:Init("seeded-item5", 0)
  RPSprites:Init("diversity-active", 0)
  RPSprites:Init("diversity-passives", 0)
  RPSprites:Init("diversity-trinket", 0)
  RPSprites:Init("diversity-item1", 0)
  RPSprites:Init("diversity-item2", 0)
  RPSprites:Init("diversity-item3", 0)
  RPSprites:Init("diversity-item4", 0)
  RPSprites:Init("diversity-item5", 0)
end

return RPSprites
