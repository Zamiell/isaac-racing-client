local SoulJar = {}

-- Includes
local g = require("racing_plus/globals")

-- Variables
SoulJar.sprites = {}

function SoulJar:PostNewLevel()
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    return
  end

  -- This ensures a 100% deal to start with
  g.g:SetLastDevilRoomStage(0)
end

function SoulJar:EntityTakeDmg(damageFlag)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    return
  end

  -- Soul Jar damage tracking
  local selfDamage = false
  local bit1 = (damageFlag & (1 << 5)) >> 5 -- DamageFlag.DAMAGE_RED_HEARTS
  local bit2 = (damageFlag & (1 << 18)) >> 18 -- DamageFlag.DAMAGE_IV_BAG
  if bit1 == 1 or bit2 == 1 then
    selfDamage = true
  end
  if not selfDamage then
    g.g:SetLastDevilRoomStage(g.run.lastDDLevel)
  end
end

-- Check the player's health for the Soul Jar mechanic
function SoulJar:PostUpdate()
  -- Local variables
  local soulHearts = g.p:GetSoulHearts()

  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
    return
  end

  if soulHearts <= 0 then
    return
  end

  g.run.soulJarSouls = g.run.soulJarSouls + soulHearts
  g.p:AddSoulHearts(-1 * soulHearts)
  Isaac.DebugString("Soul heart collection is now at: " .. tostring(g.run.soulJarSouls))
  while g.run.soulJarSouls >= 8 do -- This has to be in a while loop because of items like Abaddon
    g.run.soulJarSouls = g.run.soulJarSouls - 8  -- 4 soul hearts
    g.p:AddMaxHearts(2, true)
    g.p:AddHearts(2) -- The container starts empty
    Isaac.DebugString("Converted 4 soul hearts to a heart container.")
  end
end

function SoulJar:SpriteDisplay()
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR) then
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
    -- This is custom replaced with an 8 charge bar
    SoulJar.sprites.barLines:Play("BarOverlay12", true)
  end

  -- Place the bar to the right of the heart containers
  -- (which will depend on how many heart containers we have)
  local barX = 49 + g:GetHeartXOffset()
  local barY = 17
  local barVector = Vector(barX, barY)

  -- Draw the charge bar 1/3 (the background)
  SoulJar.sprites.barBack:Render(barVector, g.zeroVector, g.zeroVector)
  SoulJar.sprites.barBack:Update()

  -- Draw the charge bar 2/3 (the bar itself, clipped appropriately)
  local meterMultiplier = 3 -- 3 for a 8 charge item
  local meterClip = 26 - (g.run.soulJarSouls * meterMultiplier)
  SoulJar.sprites.barMeter:Render(barVector, Vector(0, meterClip), g.zeroVector)
  SoulJar.sprites.barMeter:Update()

  -- Draw the charge bar 3/3 (the segment lines on top)
  SoulJar.sprites.barLines:Render(barVector, g.zeroVector, g.zeroVector)
  SoulJar.sprites.barLines:Update()
end

return SoulJar
