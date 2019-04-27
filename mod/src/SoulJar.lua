local SoulJar = {}

-- Includes
local g = require("src/globals")

-- Variables
SoulJar.sprites = {}

function SoulJar:PostNewLevel()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if not player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    return
  end

  -- This ensures a 100% deal to start with
  g.run.lastDDLevel = game:GetLastDevilRoomStage()
  game:SetLastDevilRoomStage(0)
end

function SoulJar:EntityTakeDmg(damageFlag)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if not player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    return
  end

  local selfDamage = false
  for i = 0, 21 do -- There are 21 damage flags
    local bit = (damageFlag & (1 << i)) >> i

    -- Soul Jar damage tracking
    if (i == 5 or i == 18) and bit == 1 then -- 5 is DAMAGE_RED_HEARTS, 18 is DAMAGE_IV_BAG
      selfDamage = true
    end
  end
  if not selfDamage then
    game:SetLastDevilRoomStage(g.run.lastDDLevel)
  end
end

-- Check the player's health for the Soul Jar mechanic
function SoulJar:PostUpdate()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local soulHearts = player:GetSoulHearts()

  if not player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    return
  end

  if soulHearts <= 0 then
    return
  end

  g.run.soulJarSouls = g.run.soulJarSouls + soulHearts
  player:AddSoulHearts(-1 * soulHearts)
  Isaac.DebugString("Soul heart collection is now at: " .. tostring(g.run.soulJarSouls))
  while g.run.soulJarSouls >= 8 do -- This has to be in a while loop because of items like Abaddon
    g.run.soulJarSouls = g.run.soulJarSouls - 8  -- 4 soul hearts
    player:AddMaxHearts(2, true)
    player:AddHearts(2) -- The container starts empty
    Isaac.DebugString("Converted 4 soul hearts to a heart container.")
  end
end

function SoulJar:SpriteDisplay()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if not player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    return
  end

  -- Load the sprites
  if SoulJar.sprites.barBack == nil then
    SoulJar.sprites.barBack = Sprite()
    SoulJar.sprites.barBack:Load("gfx/ui/ui_chargebar2.anm2", true)
    SoulJar.sprites.barBack:Play("BarEmpty", true)

    SoulJar.sprites.barMeter = Sprite()
    SoulJar.sprites.barMeter:Load("gfx/ui/ui_chargebar2.anm2", true)
    SoulJar.sprites.barMeter:Play("BarFull", true)

    SoulJar.sprites.barLines = Sprite()
    SoulJar.sprites.barLines:Load("gfx/ui/ui_chargebar2.anm2", true)
    SoulJar.sprites.barLines:Play("BarOverlay12", true) -- This is custom replaced with an 8 charge bar
  end

  -- Place the bar to the right of the heart containers
  -- (which will depend on how many heart containers we have)
  local barX = 49 + SoulJar:GetHeartXOffset()
  local barY = 17
  local barVector = Vector(barX, barY)

  -- Draw the charge bar 1/3 (the background)
  SoulJar.sprites.barBack:Render(barVector, Vector(0, 0), Vector(0, 0))
  SoulJar.sprites.barBack:Update()

  -- Draw the charge bar 2/3 (the bar itself, clipped appropriately)
  local meterMultiplier = 3 -- 3 for a 8 charge item
  local meterClip = 26 - (g.run.soulJarSouls * meterMultiplier)
  SoulJar.sprites.barMeter:Render(barVector, Vector(0, meterClip), Vector(0, 0))
  SoulJar.sprites.barMeter:Update()

  -- Draw the charge bar 3/3 (the segment lines on top)
  SoulJar.sprites.barLines:Render(barVector, Vector(0, 0), Vector(0, 0))
  SoulJar.sprites.barLines:Update()
end

function SoulJar:GetHeartXOffset()
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

return SoulJar
