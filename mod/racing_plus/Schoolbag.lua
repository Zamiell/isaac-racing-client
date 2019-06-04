local Schoolbag = {}

-- Includes
local g = require("racing_plus/globals")

-- Variables
Schoolbag.sprites = {}

function Schoolbag:Put(item, charge)
  g.run.schoolbag.item = item
  Schoolbag.sprites.item = nil
  if charge == "max" then
    g.run.schoolbag.charge = g:GetItemMaxCharges(item)
  else
    g.run.schoolbag.charge = charge
  end

  local string = "Adding collectible " .. tostring(item)
  if item ~= 0 then
    string = string .. " (" .. g.itemConfig:GetCollectible(item).Name .. ")"
  end
  Isaac.DebugString(string)

  g.itemPool:RemoveCollectible(item)
end

function Schoolbag:Remove()
  g.run.schoolbag.item = 0
  Schoolbag.sprites.item = nil
end

function Schoolbag:AddCharge(singleCharge)
  -- Local variables
  local maxCharges = g:GetItemMaxCharges(g.run.schoolbag.item)

  -- We don't need to do anything if we don't have a Schoolbag or we don't have an item in the Schoolbag
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) or
     g.run.schoolbag.item == 0 then

    return
  end

  -- We don't need to do anything if the item is already charged
  if g.run.schoolbag.charge >= maxCharges and
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then -- 63

    return
  end

  -- We don't need to do anything if the item is already double-charged
  if g.run.schoolbag.chargeBattery >= maxCharges and
  g.p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then -- 63

    return
  end

  -- Find out how many charges we should add
  local chargesToAdd = 1
  local shape = g.r:GetRoomShape()
  if shape >= 8 then -- -5

    chargesToAdd = 2

  elseif g.p:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
         g.run.schoolbag.charge == maxCharges - 2 then

    -- The AAA Battery grants an extra charge when the active item is one away from being fully charged
    chargesToAdd = 2
  end
  if singleCharge ~= nil then
    -- We might only want to add a single charge to the Schoolbag item in certain situations
    chargesToAdd = 1
  end

  -- Add the correct amount of charges (accounting for The Battery)
  g.run.schoolbag.charge = g.run.schoolbag.charge + chargesToAdd
  if g.run.schoolbag.charge > maxCharges then
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then -- 63
      local extraChargesToAdd = g.run.schoolbag.charge - maxCharges
      g.run.schoolbag.chargeBattery = g.run.schoolbag.chargeBattery + extraChargesToAdd
      if g.run.schoolbag.chargeBattery > maxCharges then
        g.run.schoolbag.chargeBattery = maxCharges
      end
    end
    g.run.schoolbag.charge = maxCharges
  end
end

function Schoolbag:SpriteDisplay()
  -- Local variables
  local maxCharges = g:GetItemMaxCharges(g.run.schoolbag.item)
  local itemX = 45
  local itemY = 50
  local barXOffset = 17
  local barYOffset = 1
  local itemVector = Vector(itemX, itemY)
  local barVector = Vector(itemX + barXOffset, itemY + barYOffset)

  if g.seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then --- 10
    return
  end

  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    return
  end

  -- Load the sprites
  if Schoolbag.sprites.item == nil then
    local fileName
    if g.run.schoolbag.item == 0 then
      -- We don't have anything inside of the Schoolbag, so show a faded Schoolbag sprite
      fileName = "gfx/items/collectibles/Schoolbag_Empty.png"

    elseif g.run.schoolbag.item == CollectibleType.COLLECTIBLE_MOVING_BOX and -- 523
       g.run.movingBoxOpen then

      -- We need custom logic to handle Moving Box, which has two different sprites
      fileName = "gfx/items/collectibles/collectibles_523_movingbox_open.png"
    else
      fileName = g.itemConfig:GetCollectible(g.run.schoolbag.item).GfxFileName
    end

    Schoolbag.sprites.item = Sprite()
    Schoolbag.sprites.item:Load("gfx/schoolbag_item.anm2", false)
    Schoolbag.sprites.item:ReplaceSpritesheet(0, fileName)
    Schoolbag.sprites.item:LoadGraphics()
    Schoolbag.sprites.item:Play("Default", true)
    Schoolbag.sprites.barBack = Sprite()
    Schoolbag.sprites.barBack:Load("gfx/ui/ui_chargebar.anm2", true)
    Schoolbag.sprites.barBack:Play("BarEmpty", true)
    Schoolbag.sprites.barMeter = Sprite()
    Schoolbag.sprites.barMeter:Load("gfx/ui/ui_chargebar.anm2", true)
    Schoolbag.sprites.barMeter:Play("BarFull", true)
    Schoolbag.sprites.barMeterBattery = Sprite()
    Schoolbag.sprites.barMeterBattery:Load("gfx/ui/ui_chargebar_battery.anm2", true)
    Schoolbag.sprites.barMeterBattery:Play("BarFull", true)
    Schoolbag.sprites.barLines = Sprite()
    Schoolbag.sprites.barLines:Load("gfx/ui/ui_chargebar.anm2", true)
    if maxCharges > 12 then
      Schoolbag.sprites.barLines:Play("BarOverlay1", true)
    else
      Schoolbag.sprites.barLines:Play("BarOverlay" .. tostring(maxCharges), true)
    end

    -- Fade the placeholder image (the Schoolbag icon)
    if g.run.schoolbag.item == 0 then
      Schoolbag.sprites.item.Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      Schoolbag.sprites.item.Scale = Vector(0.75, 0.75)
    end
  end

  -- Draw the item image
  Schoolbag.sprites.item:Update()
  Schoolbag.sprites.item:Render(itemVector, g.zeroVector, g.zeroVector)

  -- Draw the charge bar
  if maxCharges ~= 0 then
    -- The background
    Schoolbag.sprites.barBack:Update()
    Schoolbag.sprites.barBack:Render(barVector, g.zeroVector, g.zeroVector)

    -- The bar itself, clipped appropriately
    Schoolbag.sprites.barMeter:Update()
    local meterMultiplier = 24 / maxCharges
    local meterClip = 26 - (g.run.schoolbag.charge * meterMultiplier)
    Schoolbag.sprites.barMeter:Render(barVector, Vector(0, meterClip), g.zeroVector)

    -- The bar for The Battery charges
    Schoolbag.sprites.barMeterBattery:Update()
    meterClip = 26 - (g.run.schoolbag.chargeBattery * meterMultiplier)
    Schoolbag.sprites.barMeterBattery:Render(barVector, Vector(0, meterClip), g.zeroVector)

    -- The segment lines on top
    Schoolbag.sprites.barLines:Update()
    Schoolbag.sprites.barLines:Render(barVector, g.zeroVector, g.zeroVector)
  end
end

-- Called from the PostUpdate callback
function Schoolbag:CheckActiveCharges()
  -- Local variables
  local activeCharge = g.p:GetActiveCharge()
  local batteryCharge = g.p:GetBatteryCharge()

  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) or
     g.p:GetActiveItem() == 0 then

    return
  end

  -- Store the new active charge
  -- (we need to know how many charges we have if we pick up a second active item)
  g.run.schoolbag.lastCharge = activeCharge
  g.run.schoolbag.lastChargeBattery = batteryCharge
end

-- Called from the PostUpdate callback (the "CheckEntities:ReplacePedestal()" function)
-- (essentially this code check runs only when the item is first spawned)
function Schoolbag:CheckSecondItem(pickup)
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) and
     g.run.schoolbag.item == 0 and
     pickup.Touched and
     g.itemConfig:GetCollectible(pickup.SubType).Type == ItemType.ITEM_ACTIVE then -- 3

    -- We don't want to put the item in the Schoolbag if we dropped it from a Butter! trinket
    if g.p:HasTrinket(TrinketType.TRINKET_BUTTER) and
       g.run.droppedButterItem == pickup.SubType then

      g.run.droppedButterItem = 0
      Isaac.DebugString("Prevented putting item " .. tostring(pickup.SubType) .. " in the Schoolbag (from Butter).")
      return false
    end

    -- We don't want to put the item in the Schoolbag if we dropped it from a Moving Box
    if g.run.droppedMovingBoxItem == pickup.SubType then
      g.run.droppedMovingBoxItem = 0
      Isaac.DebugString("Prevented putting item " .. tostring(pickup.SubType) .. " in the Schoolbag (from Moving Box).")
      return false
    end

    -- Put the item in our Schoolbag
    g.run.schoolbag.item = pickup.SubType
    g.run.schoolbag.charge = g.run.schoolbag.lastCharge
    g.run.schoolbag.chargeBattery = g.run.schoolbag.lastChargeBattery
    Schoolbag.sprites.item = nil
    Isaac.DebugString("Put pedestal " .. tostring(pickup.SubType) .. " into the Schoolbag with " ..
                      tostring(g.run.schoolbag.charge) .. " charges (and " ..
                      tostring(g.run.schoolbag.chargeBattery) .. " Battery charges).")

    -- Empty the pedestal
    pickup.SubType = 0
    pickup:GetSprite():Play("Empty", true)

    return true
  else
    return false
  end
end

-- Check to see if the Schoolbag item needs to be swapped back in
function Schoolbag:CheckEmptyActive()
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) or
     g.run.schoolbag.item == 0 or
     g.p:GetActiveItem() ~= 0 or
     not g.p:IsItemQueueEmpty() then

    return
  end

  -- They used their primary item (Pandora's Box, etc.), so put the Schoolbag item in the primary slot
  Isaac.DebugString("Empty active detected; swapping in Schoolbag item " .. g.run.schoolbag.item .. ".")
  Schoolbag:Switch()

  -- Empty the contents of the Schoolbag
  g.run.schoolbag.item = 0
  Schoolbag.sprites.item = nil
end

function Schoolbag:CheckBossRush()
  -- Local variables
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()

  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) or
     g.run.schoolbag.item == 0 or
     roomIndexUnsafe ~= GridRooms.ROOM_BOSSRUSH_IDX or -- -5
     not g.r:IsAmbushActive() or
     g.run.schoolbag.bossRushActive then

    return
  end

  -- We started the Boss Rush, so give an extra charge
  g.run.schoolbag.bossRushActive = true
  Schoolbag:AddCharge()
end

-- Check for Schoolbag switch inputs
function Schoolbag:CheckInput()
  -- Local variables
  local activeItem = g.p:GetActiveItem()
  local activeCharge = g.p:GetActiveCharge()
  local batteryCharge = g.p:GetBatteryCharge()

  -- We don't care about detecting inputs if we don't have the Schoolbag,
  -- we don't have anything in the Schoolbag,
  -- or we currently have an active item held overhead
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) or
     g.run.schoolbag.item == 0 or
     Schoolbag:IsActiveItemQueued() then
     -- This will allow switches while the use/pickup animation is occuring but
     -- prevent bugs where queued items will override things

    return
  end

  local button = g.race.hotkeySwitch
  if button ~= 0 and button ~= nil then
    -- If they have a custom Schoolbag-switch key bound, then use that
    -- (we use "IsButtonPressed()" instead of "IsButtonTriggered()" because
    -- the latter is not very responsive with fast sequences of inputs)
    -- (we check all inputs instead of "player.ControllerIndex" because
    -- a controller player might be using the keyboard for their custom hotkey)
    local pressed = false
    for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
      if Input.IsButtonPressed(g.race.hotkeySwitch, i) then
        pressed = true
      end
    end
    if not pressed then
      g.run.schoolbag.pressed = false
      return
    elseif g.run.schoolbag.pressed then
      return
    end
  else
    -- If they do not have a custom key bound, then default to the same button that is used for card/pill switching
    -- We use "IsActionPressed()" instead of "IsActionTriggered()" because
    -- the latter is not very responsive with fast sequences of inputs
    if not Input.IsActionPressed(ButtonAction.ACTION_DROP, g.p.ControllerIndex) then -- 11
      g.run.schoolbag.pressed = false
      return
    elseif g.run.schoolbag.pressed then
      return
    end
  end
  g.run.schoolbag.pressed = true

  -- Put the item from the Schoolbag in the active slot
  Schoolbag:Switch()

  -- Put the old item in the Schoolbag
  g.run.schoolbag.item = activeItem
  g.run.schoolbag.charge = activeCharge
  g.run.schoolbag.chargeBattery = batteryCharge
  Schoolbag.sprites.item = nil
  Isaac.DebugString("Put item " .. tostring(g.run.schoolbag.item) .. " into the Schoolbag with charge: " ..
                    tostring(g.run.schoolbag.charge) .. "-" ..
                    tostring(g.run.schoolbag.chargeBattery))
end

function Schoolbag:IsActiveItemQueued()
  if g.p.QueuedItem.Item == nil then
    return false
  end

  if g.p.QueuedItem.Item.Type == ItemType.ITEM_ACTIVE then -- 3
    return true
  else
    return false
  end
end

-- Called from the "Schoolbag:CheckInput()" function
function Schoolbag:Switch()
  -- Local variables
  local activeItem = g.p:GetActiveItem()
  local maxCharges = g:GetItemMaxCharges(g.run.schoolbag.item)

  -- Fix the bug where you can spam Schoolbag switches to get permanent invincibility from
  -- My Little Unicorn and Unicorn Stump
  if (g.p:HasCollectible(CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN) or -- 77
      g.p:HasCollectible(CollectibleType.COLLECTIBLE_UNICORN_STUMP)) and -- 298
     g.p:HasInvincibility() then

      g.p:ClearTemporaryEffects()
    Isaac.DebugString("Ended My Little Unicorn / Unicorn Stump invulnerability early.")
  end

  -- Set the new active item
  g.p:AddCollectible(g.run.schoolbag.item, 0, false) -- We set the charges manually in the next line
  g.p:DischargeActiveItem() -- This is necessary to prevent some bugs with The Battery
  local totalCharges = g.run.schoolbag.charge + g.run.schoolbag.chargeBattery
  g.p:SetActiveCharge(totalCharges)
  Isaac.DebugString("Set charges to: " .. tostring(totalCharges))

  -- Fix the bug where the charge sound will play if the item is fully charged or partially charged
  if g.p:GetActiveCharge() == maxCharges and
     g.sfx:IsPlaying(SoundEffect.SOUND_BATTERYCHARGE) then -- 170

    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  end
  if g.p:GetActiveCharge() ~= 0 and
     g.sfx:IsPlaying(SoundEffect.SOUND_BEEP) then -- 171

    g.sfx:Stop(SoundEffect.SOUND_BEEP) -- 171
  end

  -- Update the cache (in case the new or old item granted stats, like A Pony)
  -- (we don't want to update the familiar cache because it can cause bugs with Dino Baby and
  -- cause temporary familiars to despawn)
  local allCacheFlagsMinusFamiliars = CacheFlag.CACHE_DAMAGE + -- 1
                                      CacheFlag.CACHE_FIREDELAY + -- 2
                                      CacheFlag.CACHE_SHOTSPEED + -- 4
                                      CacheFlag.CACHE_RANGE + -- 8
                                      CacheFlag.CACHE_SPEED + -- 16
                                      CacheFlag.CACHE_TEARFLAG + -- 32
                                      CacheFlag.CACHE_TEARCOLOR + -- 64
                                      CacheFlag.CACHE_FLYING + -- 128
                                      CacheFlag.CACHE_WEAPON + -- 256
                                      CacheFlag.CACHE_LUCK -- 1024
  g.p:AddCacheFlags(allCacheFlagsMinusFamiliars)
  g.p:EvaluateItems()

  -- Remove the costume, if any (some items give a costume, like A Pony)
  if activeItem ~= 0 then
    g.p:RemoveCostume(g.itemConfig:GetCollectible(activeItem))
  end

  -- Set the item hold cooldown to 0 since this doesn't count as picking up a new item
  -- (this fixes the bug where you can't immediately pick up a new item after performing a Schoolbag switch)
  g.p.ItemHoldCooldown = 0

  -- Tell The Babies Mod to reload the sprite just in case the new active item has a costume and it messes up the sprite
  if SinglePlayerCoopBabies ~= nil then
    SinglePlayerCoopBabies.run.reloadSprite = true
  end
end

return Schoolbag
