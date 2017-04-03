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

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) and soulHearts > 0 then
    RPGlobals.run.soulJarSouls = RPGlobals.run.soulJarSouls + soulHearts
    player:AddSoulHearts(-1 * soulHearts)
    Isaac.DebugString("Soul heart collection is now at: " .. tostring(RPGlobals.run.soulJarSouls))
    if RPGlobals.run.soulJarSouls >= 8 then -- 4 soul hearts
      RPGlobals.run.soulJarSouls = RPGlobals.run.soulJarSouls - 8
      player:AddMaxHearts(2)
      player:AddHearts(2) -- The container starts empty
      Isaac.DebugString("Converted 4 soul hearts to a heart container.")
    end
  end
end

function RPSoulJar:CheckDamaged()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Do the special Maggy Devil Room mechanic
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    if RPGlobals.run.levelDamaged == false then
      game:SetLastDevilRoomStage(0) -- This ensures a 100% deal if no damage was taken
    end
  end
end

function RPSoulJar:SpriteDisplay()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local maxHearts = player:GetMaxHearts()
  local extraLives = player:GetExtraLives()

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

  local heartLength = 12
  if maxHearts > 12 then
    maxHearts = 12 -- After 6 heart containers, it wraps to a second row
  end
  local barOffset = (maxHearts / 2) * heartLength
  if extraLives > 9 then
    barOffset = barOffset + 20
    if player:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) then -- 212
      barOffset = barOffset + 6
    end
  elseif extraLives > 0 then
    barOffset = barOffset + 16
    if player:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) then -- 212
      barOffset = barOffset + 4
    end
  end

  local barX = 49 + barOffset -- Place to the right of the red heart containers
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

return RPSoulJar
