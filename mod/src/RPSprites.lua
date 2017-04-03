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
  RPGlobals.spriteTable[spriteType].spriteName = spriteName
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

  elseif spriteType == "ready" or spriteType == "readyTotal" then
    if tonumber(spriteName) > 50 then
      RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/ready/unknown.anm2", true)
    else
      RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/ready/" .. spriteName .. ".anm2", true)
    end

  elseif spriteType == "place" then
    if spriteName == "pre" or tonumber(spriteName) <= 16 then
      RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/place/" .. spriteName .. ".anm2", true)
    else
      Isaac.DebugString("Places beyond 16 are not supported.")
    end

  else
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/" .. spriteName .. ".anm2", true)
  end

  -- Everything is a non-animation, so we just want to set frame 0
  RPGlobals.spriteTable[spriteType].sprite:SetFrame("Default", 0)
end

-- Call this every frame in MC_POST_RENDER
function RPSprites:Display()
  -- Loop through all the sprites and render them
  for k, v in pairs(RPGlobals.spriteTable) do
    -- Position it
    local vec = RPSprites:GetScreenCenterPosition() -- Start the vector off in the center of the screen by default

    -- Type stuff
    local typeFormatX = 110
    local typeFormatY = 10

    -- Position all the sprites
    if k == "stage" then -- The name of the floor when we get to a new floor
      vec.Y = vec.Y - 85
    elseif k == "top" then -- Pre-race messages and the countdown
      vec.Y = vec.Y - 80
    elseif k == "myStatus" then
      vec.Y = vec.Y - 40
    elseif k == "raceType" then
      vec.X = vec.X - typeFormatX
      vec.Y = vec.Y + typeFormatY
    elseif k == "raceTypeIcon" then
      vec.X = vec.X - typeFormatX
      vec.Y = vec.Y + typeFormatY + 23
    elseif k == "raceFormat" then
      vec.X = vec.X + typeFormatX
      vec.Y = vec.Y + typeFormatY
    elseif k == "raceFormatIcon" then
      vec.X = vec.X + typeFormatX
      vec.Y = vec.Y + typeFormatY + 23
    elseif k == "ready" then
      vec.X = vec.X - 20
      vec.Y = vec.Y - 15
    elseif k == "slash" then
      vec.Y = vec.Y - 15
    elseif k == "readyTotal" then
      vec.X = vec.X + 20
      vec.Y = vec.Y - 15
    elseif k == "goal" then
      vec.X = vec.X - 25
      vec.Y = vec.Y + 95
    elseif k == "raceGoal" then
      vec.X = vec.X + 25
      vec.Y = vec.Y + 95
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
    elseif k == "place" then -- "1st", "2nd", etc.
      vec.X = 24 -- Move it next to the "R+" icon
      vec.Y = 79
    end

    -- Draw it
    if v.sprite ~= nil then
      if k == "stage" then
        -- For animations, we have to both "Render()" and "Update()"
        RPGlobals.spriteTable[k].sprite:Render(vec, Vector(0, 0), Vector(0, 0))
        RPGlobals.spriteTable[k].sprite:Update()
      else
        -- For non-animations, we want to just render frame 0
        RPGlobals.spriteTable[k].sprite:RenderLayer(0, vec)
      end
    end
  end
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

-- This clears the graphics that should only appear in the starting room
function RPSprites:ClearStartingRoomGraphicsTop()
  RPSprites:Init("myStatus", 0)
  RPSprites:Init("ready", 0)
  RPSprites:Init("slash", 0)
  RPSprites:Init("readyTotal", 0)
end

function RPSprites:ClearStartingRoomGraphicsBottom()
  RPSprites:Init("raceType", 0)
  RPSprites:Init("raceTypeIcon", 0)
  RPSprites:Init("raceFormat", 0)
  RPSprites:Init("raceFormatIcon", 0)
  RPSprites:Init("goal", 0)
  RPSprites:Init("raceGoal", 0)
end

-- This clears the graphics that appear in the starting room after the race has started
function RPSprites:ClearPostRaceStartGraphics()
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
