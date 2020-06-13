local Sprites = {}

-- Includes
local g = require("racing_plus/globals")

-- Variables
Sprites.sprites = {}

-- This is called once to load the PNG from the anm2 file
function Sprites:Init(spriteType, spriteName)
  -- If this is a new sprite type, initialize it in the sprite table
  if Sprites.sprites[spriteType] == nil then
    Sprites.sprites[spriteType] = {}
  end

  -- Do nothing if this sprite type is already set to this name
  if Sprites.sprites[spriteType].spriteName == spriteName then
    return
  end

  -- Check to see if we are clearing this sprite
  if spriteName == 0 then
    Sprites.sprites[spriteType].sprite = nil
    Sprites.sprites[spriteType].spriteName = 0
    return
  end

  -- Otherwise, initialize the sprite
  Sprites.sprites[spriteType].spriteName = spriteName
  Sprites.sprites[spriteType].sprite = Sprite()
  local animationName = "Default"

  if spriteType == "seeded-item1" or
     spriteType == "seeded-item2" or
     spriteType == "seeded-item3" or
     spriteType == "seeded-item4" or
     spriteType == "seeded-item5" or
     spriteType == "diversity-item1" or
     spriteType == "diversity-item2" or
     spriteType == "diversity-item3" or
     spriteType == "diversity-item4" or
     spriteType == "eden-item1" or
     spriteType == "eden-item2" then

    Sprites.sprites[spriteType].sprite:Load("gfx/items2/collectibles/" .. spriteName .. ".anm2", true)

  elseif spriteType == "diversity-item5" then
    Sprites.sprites[spriteType].sprite:Load("gfx/items2/trinkets/" .. spriteName .. ".anm2", true)

  elseif spriteType == "ready" or
         spriteType == "readyTotal" then

    if tonumber(spriteName) > 50 then
      Sprites.sprites[spriteType].sprite:Load("gfx/race/ready/unknown.anm2", true)
    else
      Sprites.sprites[spriteType].sprite:Load("gfx/race/ready/" .. spriteName .. ".anm2", true)
    end

  elseif spriteType == "place" then -- On the middle-left-hand side of the screen
    Sprites.sprites[spriteType].sprite:Load("gfx/race/place/" .. spriteName .. ".anm2", true)

  elseif spriteType == "place2" then -- Displayed when the race is finished
    Sprites.sprites[spriteType].sprite:Load("gfx/race/place2/" .. spriteName .. ".anm2", true)

  elseif spriteType == "corrupt1" or
         spriteType == "corrupt2" then

    Sprites.sprites[spriteType].sprite:Load("gfx/misc/" .. spriteName .. ".anm2", true)

  elseif spriteType == "black" then
    Sprites.sprites[spriteType].sprite:Load("gfx/misc/black.anm2", true)

  elseif spriteType == "dps-button" then
    local filename = "gfx/potato/PotatoDummy.anm2"
    Sprites.sprites[spriteType].sprite:Load(filename, true)
    Sprites.sprites[spriteType].sprite.Scale = Vector(0.75, 0.75)
    animationName = "Idle"

  elseif spriteType == "victory-lap-button" then
    local filename = "gfx/items2/collectibles/" .. CollectibleType.COLLECTIBLE_FORGET_ME_NOW .. ".anm2" -- 127
    Sprites.sprites[spriteType].sprite:Load(filename, true)

  else
    Sprites.sprites[spriteType].sprite:Load("gfx/race/" .. spriteName .. ".anm2", true)
  end

  -- Everything is a non-animation, so we just want to set frame 0
  Sprites.sprites[spriteType].sprite:SetFrame(animationName, 0)
end

-- This is called on every frame in MC_POST_RENDER
function Sprites:Display()
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local challenge = Isaac.GetChallenge()

  -- Loop through all the sprites and render them
  for k, v in pairs(Sprites.sprites) do
    -- Position it
    local pos = Sprites:GetScreenCenterPosition() -- Start in the center of the screen by default

    -- Type stuff
    local typeFormatX = 110
    local typeFormatY = 10

    -- Position all the sprites
    if k == "top" then -- Pre-race messages and the countdown
      pos.Y = pos.Y - 80
    elseif k == "myStatus" then
      pos.Y = pos.Y - 40
    elseif k == "raceRanked" then
      pos.X = pos.X - typeFormatX
      pos.Y = pos.Y + typeFormatY
    elseif k == "raceRankedIcon" then
      pos.X = pos.X - typeFormatX
      pos.Y = pos.Y + typeFormatY + 23
    elseif k == "raceFormat" then
      pos.X = pos.X + typeFormatX
      pos.Y = pos.Y + typeFormatY
    elseif k == "raceFormatIcon" then
      pos.X = pos.X + typeFormatX
      pos.Y = pos.Y + typeFormatY + 23
    elseif k == "ready" then
      pos.X = pos.X - 20
      pos.Y = pos.Y - 15
    elseif k == "slash" then
      pos.Y = pos.Y - 15
    elseif k == "readyTotal" then
      pos.X = pos.X + 20
      pos.Y = pos.Y - 15
    elseif k == "goal" then
      pos.X = pos.X - 25
      pos.Y = pos.Y + 95
    elseif k == "raceGoal" then
      pos.X = pos.X + 25
      pos.Y = pos.Y + 95
    elseif k == "seeded-starting-item" then
      pos.Y = pos.Y - 40
    elseif k == "seeded-starting-build" then
      pos.Y = pos.Y - 40
    elseif k == "seeded-item1" then
      pos.Y = pos.Y - 10
    elseif k == "seeded-item2" then
      pos.X = pos.X - 15
      pos.Y = pos.Y - 10
    elseif k == "seeded-item3" then
      pos.X = pos.X + 15
      pos.Y = pos.Y - 10
    elseif k == "seeded-item4" then
      pos.X = pos.X - 45
      pos.Y = pos.Y - 10
    elseif k == "seeded-item5" then
      pos.X = pos.X + 45
      pos.Y = pos.Y - 10
    elseif k == "diversity-active" then
      pos.X = pos.X - 90
      pos.Y = pos.Y - 70
    elseif k == "diversity-passives" then
      pos.X = pos.X + 90
      pos.Y = pos.Y - 40
    elseif k == "diversity-trinket" then
      pos.X = pos.X - 90
      pos.Y = pos.Y + 30
    elseif k == "diversity-item1" then -- The active item
      pos.X = pos.X - 90
      pos.Y = pos.Y - 40
    elseif k == "diversity-item2" then -- The 1st passive item
      pos.X = pos.X + 60
      pos.Y = pos.Y - 10
    elseif k == "diversity-item3" then -- The 2nd passive item
      pos.X = pos.X + 90
      pos.Y = pos.Y - 10
    elseif k == "diversity-item4" then -- The 3rd passive item
      pos.X = pos.X + 120
      pos.Y = pos.Y - 10
    elseif k == "diversity-item5" then -- The trinket
      pos.X = pos.X - 90
      pos.Y = pos.Y + 60
    elseif k == "eden-item1" then
      pos.X = 123
      pos.Y = 17
    elseif k == "eden-item2" then
      pos.X = 153
      pos.Y = 17
    elseif k == "place" then -- "1st", "2nd", etc.
      -- Move it next to the "R+" icon
      pos.X = 24
      if g.g.Difficulty ~= Difficulty.DIFFICULTY_NORMAL then -- 0
        -- The hard mode symbol will interfere, so it needs to be moved to the right
        pos.X = 34
      end
      if challenge ~= 0 then
        pos.X = 67
      end
      pos.Y = 79
    elseif k == "place2" then -- The final place graphic
      pos.Y = pos.Y - 80
    elseif k == "corrupt1" then -- The final place graphic
      pos.Y = pos.Y - 80
    elseif k == "corrupt2" then -- The final place graphic
      pos.Y = pos.Y - 50
    elseif k == "dps-button" then
      for _, button in ipairs(g.run.buttons) do
        if button.type == "dps" and
           button.roomIndex == roomIndex then

          local newPos = Isaac.WorldToScreen(button.pos)
          pos.X = newPos.X
          pos.Y = newPos.Y - 15
        end
      end
    elseif k == "victory-lap-button" then
      for _, button in ipairs(g.run.buttons) do
        if button.type == "victory-lap" and
           button.roomIndex == roomIndex then

          local newPos = Isaac.WorldToScreen(button.pos)
          pos.X = newPos.X + 1
          pos.Y = newPos.Y - 25
        end
      end
    end

    -- Draw it
    if v.sprite ~= nil then
      -- For non-animations, we want to just render frame 0
      Sprites.sprites[k].sprite:RenderLayer(0, pos)
    end
  end
end

-- Taken from Alphabirth: https://steamcommunity.com/sharedfiles/filedetails/?id=848056541
function Sprites:GetScreenCenterPosition()
  -- Local variables
  local shape = g.r:GetRoomShape()
  local centerPos = g.r:GetCenterPos()
  local centerOffset = centerPos - g.r:GetTopLeftPos()

  if centerOffset.X > 260 then
    centerPos.X = centerPos.X - 260
  end
  if shape == RoomShape.ROOMSHAPE_LTL or -- 9
     shape == RoomShape.ROOMSHAPE_LBL then -- 11

    centerPos.X = centerPos.X - 260
  end
  if centerOffset.Y > 140 then
    centerPos.Y = centerPos.Y - 140
  end
  if shape == RoomShape.ROOMSHAPE_LTL or -- 9
     shape == RoomShape.ROOMSHAPE_LTR then -- 10

    centerPos.Y = centerPos.Y - 140
  end

  return Isaac.WorldToRenderPosition(centerPos, false)
end

-- This clears the graphics that should only appear in the starting room
function Sprites:ClearStartingRoomGraphicsTop()
  Sprites:Init("myStatus", 0)
  Sprites:Init("ready", 0)
  Sprites:Init("slash", 0)
  Sprites:Init("readyTotal", 0)
end

function Sprites:ClearStartingRoomGraphicsBottom()
  Sprites:Init("raceRanked", 0)
  Sprites:Init("raceRankedIcon", 0)
  Sprites:Init("raceFormat", 0)
  Sprites:Init("raceFormatIcon", 0)
  Sprites:Init("goal", 0)
  Sprites:Init("raceGoal", 0)
end

-- This clears the graphics that appear in the starting room after the race has started
function Sprites:ClearPostRaceStartGraphics()
  Sprites:Init("seeded-starting-item", 0)
  Sprites:Init("seeded-starting-build", 0)
  Sprites:Init("seeded-item1", 0)
  Sprites:Init("seeded-item2", 0)
  Sprites:Init("seeded-item3", 0)
  Sprites:Init("seeded-item4", 0)
  Sprites:Init("seeded-item5", 0)
  Sprites:Init("diversity-active", 0)
  Sprites:Init("diversity-passives", 0)
  Sprites:Init("diversity-trinket", 0)
  Sprites:Init("diversity-item1", 0)
  Sprites:Init("diversity-item2", 0)
  Sprites:Init("diversity-item3", 0)
  Sprites:Init("diversity-item4", 0)
  Sprites:Init("diversity-item5", 0)
end

return Sprites
