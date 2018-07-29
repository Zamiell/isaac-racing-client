local RPSoulJar = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Variables
--

RPSoulJar.sprites = {}

--
-- Soul Jar functions
--

-- Check the player's health for the Soul Jar mechanic
function RPSoulJar:CheckHealth()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local soulHearts = player:GetSoulHearts()

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) == false then
    return
  end

  if soulHearts <= 0 then
    return
  end

  RPGlobals.run.soulJarSouls = RPGlobals.run.soulJarSouls + soulHearts
  player:AddSoulHearts(-1 * soulHearts)
  Isaac.DebugString("Soul heart collection is now at: " .. tostring(RPGlobals.run.soulJarSouls))
  while RPGlobals.run.soulJarSouls >= 8 do -- This has to be in a while loop because of items like Abaddon
    RPGlobals.run.soulJarSouls = RPGlobals.run.soulJarSouls - 8  -- 4 soul hearts
    player:AddMaxHearts(2)
    player:AddHearts(2) -- The container starts empty
    Isaac.DebugString("Converted 4 soul hearts to a heart container.")
  end
end

function RPSoulJar:CheckDamaged()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Do the special Maggy Devil Room mechanic
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) == false then
    return
  end

  if RPGlobals.run.levelDamaged == false then
    game:SetLastDevilRoomStage(0) -- This ensures a 100% deal if no damage was taken
  end
end

function RPSoulJar:SpriteDisplay()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) == false then
    return
  end

  -- Load the sprites
  if RPSoulJar.sprites.barBack == nil then
    RPSoulJar.sprites.barBack = Sprite()
    RPSoulJar.sprites.barBack:Load("gfx/ui/ui_chargebar2.anm2", true)
    RPSoulJar.sprites.barBack:Play("BarEmpty", true)

    RPSoulJar.sprites.barMeter = Sprite()
    RPSoulJar.sprites.barMeter:Load("gfx/ui/ui_chargebar2.anm2", true)
    RPSoulJar.sprites.barMeter:Play("BarFull", true)

    RPSoulJar.sprites.barLines = Sprite()
    RPSoulJar.sprites.barLines:Load("gfx/ui/ui_chargebar2.anm2", true)
    RPSoulJar.sprites.barLines:Play("BarOverlay12", true) -- This is custom replaced with an 8 charge bar
  end

  -- Place the bar to the right of the heart containers
  -- (which will depend on how many heart containers we have)
  local barX = 49 + RPSoulJar:GetHeartXOffset()
  local barY = 17
  local barVector = Vector(barX, barY)

  -- Draw the charge bar 1/3 (the background)
  RPSoulJar.sprites.barBack:Render(barVector, Vector(0, 0), Vector(0, 0))
  RPSoulJar.sprites.barBack:Update()

  -- Draw the charge bar 2/3 (the bar itself, clipped appropriately)
  local meterMultiplier = 3 -- 3 for a 8 charge item
  local meterClip = 26 - (RPGlobals.run.soulJarSouls * meterMultiplier)
  RPSoulJar.sprites.barMeter:Render(barVector, Vector(0, meterClip), Vector(0, 0))
  RPSoulJar.sprites.barMeter:Update()

  -- Draw the charge bar 3/3 (the segment lines on top)
  RPSoulJar.sprites.barLines:Render(barVector, Vector(0, 0), Vector(0, 0))
  RPSoulJar.sprites.barLines:Update()
end

function RPSoulJar:GetHeartXOffset()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local boneHearts = player:GetBoneHearts()
  local extraLives = player:GetExtraLives()

  local heartLength = 12 -- This is how long each heart is on the UI in the upper left hand corner
  -- (this is not in pixels, but in draw coordinates; you can see that it is 13 pixels wide in the "ui_hearts.png" file)
  local combinedHearts = maxHearts + soulHearts + (boneHearts * 2) -- There are no half bone hearts
  if combinedHearts > 12 then
    combinedHearts = 12 -- After 6 hearts, it wraps to a second row
  end

  local offset = (combinedHearts / 2) * heartLength
  if extraLives > 9 then
    offset = offset + 20
    if player:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) then -- 212
      offset = offset + 6
    end
  elseif extraLives > 0 then
    offset = offset + 16
    if player:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) then -- 212
      offset = offset + 4
    end
  end

  return offset
end

return RPSoulJar
