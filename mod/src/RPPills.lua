local RPPills = {}

-- Includes
local RPGlobals = require("src/rpglobals")

-- Constants
RPPills.effects = {
  "Bad Trip",
  "Balls of Steel",
  "Bombs Are Key",
  "Explosive Diarrhea",
  "Full Health",
  "Health Down",
  "Health Up",
  "I Found Pills",
  "Puberty",
  "Pretty Fly",
  "Range Down",
  "Range Up",
  "Speed Down",
  "Speed Up",
  "Tears Down",
  "Tears Up",
  "Luck Down",
  "Luck Up",
  "Telepills",
  "48 Hour Energy",
  "Hematemesis",
  "Paralysis",
  "I can see forever!",
  "Pheromones",
  "Amnesia",
  "Lemon Party",
  "R U a Wizard?",
  "Percs!",
  "Addicted!",
  "Re-Lax",
  "???",
  "One makes you larger",
  "One makes you small",
  "Infested!",
  "Infested?",
  "Power Pill!",
  "Retro Vision",
  "Friends Till The End!",
  "X-Lax",
  "Something's wrong...",
  "I'm Drowsy...",
  "I'm Excited!!!",
  "Gulp!",
  "Horf!",
  "Feels like I'm walking on sunshine!",
  "Vurp!",
}
RPPills.effects[0] = "Bad Gas"

-- ModCallbacks.MC_USE_PILL (10)
function RPPills:Main(pillEffect)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Don't add any more pills after 7, since it won't display cleanly
  if #RPGlobals.run.pills >= 7 then
    return
  end

  -- See if we have already used this particular pill color on this run
  local pillColor = player:GetPill(0)
  for i = 1, #RPGlobals.run.pills do
    if RPGlobals.run.pills[i].color == pillColor then
      return
    end
  end

  -- This is the first time we have used this pill, so keep track of the pill color and effect
  local pillEntry = {
    color  = pillColor,
    effect = pillEffect,
    sprite = Sprite()
  }

  -- Preload the graphics for this pill color so that we can display it if the player presses tab
  pillEntry.sprite:Load("gfx/pills/pill" .. pillColor .. ".anm2", true)
  pillEntry.sprite:SetFrame("Default", 0)
  RPGlobals.run.pills[#RPGlobals.run.pills + 1] = pillEntry
end

function RPPills:HealthUp()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  RPGlobals.run.keeper.usedHealthUpPill = true
  player:AddCacheFlags(CacheFlag.CACHE_RANGE) -- 8
  player:EvaluateItems()
  -- We check to see if we are Keeper, have Greed's Gullet, and are at maximum hearts inside this function
end

function RPPills:Telepills()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local rooms = level:GetRooms()

  -- It is not possible to teleport to I AM ERROR rooms and Black Markets on The Chest / Dark Room
  local insertErrorRoom = false
  local insertBlackMarket = false
  if stage ~= 11 then
    insertErrorRoom = true

    -- There is a 2% chance have a Black Market inserted into the list of possibilities (according to blcd)
    RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
    math.randomseed(RPGlobals.RNGCounter.Telepills)
    local blackMarketRoll = math.random(1, 100) -- Item room, secret room, super secret room, I AM ERROR room
    if blackMarketRoll <= 2 then
      insertBlackMarket = true
    end
  end

  -- Find the indexes for all of the room possibilities
  local roomIndexes = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local gridIndex = rooms:Get(i).SafeGridIndex
    -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise
    roomIndexes[#roomIndexes + 1] = gridIndex
  end
  if insertErrorRoom then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_ERROR_IDX -- -2
  end
  if insertBlackMarket then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_BLACK_MARKET_IDX -- -6
  end

  -- Get a random room index
  RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
  math.randomseed(RPGlobals.RNGCounter.Telepills)
  local gridIndex = roomIndexes[math.random(1, #roomIndexes)]

  -- Teleport
  RPGlobals.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  game:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, RPGlobals.RoomTransition.TRANSITION_TELEPORT)

  -- We don't want to display the "use" animation, we just want to instantly teleport
  -- Pills are hard coded to queue the "use" animation, so stop it on the next frame
  RPGlobals.run.usedTelepills = true
end

function RPPills:PostRender()
  -- Only show pill identification if the user is pressing tab
  local tabPressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_MAP, i) then -- 13
      tabPressed = true
      break
    end
  end
  if tabPressed == false then
    return
  end

  -- Don't do anything if we have not taken any pills yet
  if #RPGlobals.run.pills == 0 then
    return
  end

  for i = 1, #RPGlobals.run.pills do
    local pillEntry = RPGlobals.run.pills[i]

    -- Show the pill sprite
    local x = 80
    local y = 77 + (20 * i)
    local pos = Vector(x, y)
    pillEntry.sprite:RenderLayer(0, pos)

    -- Show the pill effect as text
    local effectText = RPPills.effects[pillEntry.effect]
    Isaac.RenderText(effectText, x + 17, y - 7, 1, 1, 1, 2)
  end

end

function RPPills:CheckPHD()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if RPGlobals.run.PHDPills then
    -- We have already converted bad pill effects this run
    return
  end

  -- Check for the PHD / Virgo
  if player:HasCollectible(CollectibleType.COLLECTIBLE_PHD) == false and -- 75
     player:HasCollectible(CollectibleType.COLLECTIBLE_VIRGO) == false then -- 303

    return
  end

  RPGlobals.run.PHDPills = true
  Isaac.DebugString("Converting bad pill effects.")

  -- Change the text for any identified pills
  for i = 1, #RPGlobals.run.pills do
    local pillEntry = RPGlobals.run.pills[i]
    if pillEntry.effect == PillEffect.PILLEFFECT_BAD_TRIP then -- 1
      pillEntry.effect = PillEffect.PILLEFFECT_BALLS_OF_STEEL -- 2
    elseif pillEntry.effect == PillEffect.PILLEFFECT_HEALTH_DOWN then -- 6
      pillEntry.effect = PillEffect.PILLEFFECT_HEALTH_UP -- 7
    elseif pillEntry.effect == PillEffect.PILLEFFECT_RANGE_DOWN then -- 11
      pillEntry.effect = PillEffect.PILLEFFECT_RANGE_UP -- 12
    elseif pillEntry.effect == PillEffect.PILLEFFECT_SPEED_DOWN then -- 13
      pillEntry.effect = PillEffect.PILLEFFECT_SPEED_UP -- 14
    elseif pillEntry.effect == PillEffect.PILLEFFECT_TEARS_DOWN then -- 15
      pillEntry.effect = PillEffect.PILLEFFECT_TEARS_UP -- 16
    elseif pillEntry.effect == PillEffect.PILLEFFECT_LUCK_DOWN then -- 17
      pillEntry.effect = PillEffect.PILLEFFECT_LUCK_UP -- 18
    elseif pillEntry.effect == PillEffect.PILLEFFECT_PARALYSIS then -- 22
      pillEntry.effect = PillEffect.PILLEFFECT_PHEROMONES -- 24
    elseif pillEntry.effect == PillEffect.PILLEFFECT_WIZARD then -- 27
      pillEntry.effect = PillEffect.PILLEFFECT_POWER -- 36
    elseif pillEntry.effect == PillEffect.PILLEFFECT_ADDICTED then -- 29
      pillEntry.effect = PillEffect.PILLEFFECT_PERCS -- 28
    elseif pillEntry.effect == PillEffect.PILLEFFECT_RETRO_VISION then -- 37
      pillEntry.effect = PillEffect.PILLEFFECT_SEE_FOREVER -- 23
    elseif pillEntry.effect == PillEffect.PILLEFFECT_X_LAX then -- 39
      pillEntry.effect = PillEffect.PILLEFFECT_SOMETHINGS_WRONG -- 40
    elseif pillEntry.effect == PillEffect.PILLEFFECT_IM_EXCITED then -- 42
      pillEntry.effect = PillEffect.PILLEFFECT_IM_DROWSY -- 41
    end
  end
end

return RPPills
