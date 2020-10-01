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
  -- We don't need to do anything if we don't have a Schoolbag
  -- or we don't have an item in the Schoolbag
  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    or g.run.schoolbag.item == 0
  ) then
    return
  end

  -- Local variables
  local maxCharges = g:GetItemMaxCharges(g.run.schoolbag.item)

  -- We don't need to do anything if the item is already charged
  if (
    g.run.schoolbag.charge >= maxCharges
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63
  ) then
    return
  end

  -- We don't need to do anything if the item is already double-charged
  if (
    g.run.schoolbag.chargeBattery >= maxCharges
    and g.p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63
  ) then
    return
  end

  -- Find out how many charges we should add
  local chargesToAdd = 1
  local shape = g.r:GetRoomShape()
  if shape >= 8 then
    chargesToAdd = 2
  elseif (
    g.p:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) -- 3
    and g.run.schoolbag.charge == maxCharges - 2
  ) then
    -- The AAA Battery grants an extra charge when the active item is one away from being fully
    -- charged
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
    elseif (
      g.run.schoolbag.item == CollectibleType.COLLECTIBLE_MOVING_BOX -- 523
      and g.run.movingBoxOpen
    ) then
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

  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    or g.p:GetActiveItem() == 0
  ) then
    return
  end

  -- Store the new active charge
  -- (we need to know how many charges we have if we pick up a second active item)
  g.run.schoolbag.lastCharge = activeCharge
  g.run.schoolbag.lastChargeBattery = batteryCharge
end

-- Called from the PostUpdate callback
-- Check for the vanilla Schoolbag and convert it to the Racing+ Schoolbag if necessary
function Schoolbag:ConvertVanilla()
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then -- 534
    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) -- 534
    Isaac.DebugString(
      "Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_SCHOOLBAG) .. " (Schoolbag)"
    )
    if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    end
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end
end

-- Called from the PostUpdate callback (the "CheckEntities:ReplacePedestal()" function)
-- (this code check runs only when the item is first spawned)
function Schoolbag:CheckSecondItem(pickup)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomFrameCount = g.r:GetFrameCount()

  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    and g.run.schoolbag.item == 0
    and pickup.Touched
    and g.itemConfig:GetCollectible(pickup.SubType).Type == ItemType.ITEM_ACTIVE -- 3
  ) then
    -- We don't want to put the item in the Schoolbag if we just entered the room and
    -- there is a touched item sitting on the ground for whatever reason
    if roomFrameCount == 1 then
      return false
    end

    -- We don't want to put the item in the Schoolbag if we dropped it from a Butter! trinket
    if (
      g.p:HasTrinket(TrinketType.TRINKET_BUTTER)
      and g.run.droppedButterItem == pickup.SubType
    ) then
      g.run.droppedButterItem = 0
      Isaac.DebugString(
        "Prevented putting item " .. tostring(pickup.SubType) .. " in the Schoolbag (from Butter)."
      )
      return false
    end

    -- We don't want to put the item in the Schoolbag if we dropped it from a Moving Box
    if g.run.droppedMovingBoxItem == pickup.SubType then
      g.run.droppedMovingBoxItem = 0
      Isaac.DebugString(
        "Prevented putting item " .. tostring(pickup.SubType)
        .. " in the Schoolbag (from Moving Box)."
      )
      return false
    end

    -- Put the item in our Schoolbag
    g.run.schoolbag.item = pickup.SubType
    g.run.schoolbag.charge = g.run.schoolbag.lastCharge
    g.run.schoolbag.chargeBattery = g.run.schoolbag.lastChargeBattery
    Schoolbag.sprites.item = nil
    Isaac.DebugString(
      "Put pedestal " .. tostring(pickup.SubType) .. " into the Schoolbag with "
      .. tostring(g.run.schoolbag.charge) .. " charges "
      .. "(and " .. tostring(g.run.schoolbag.chargeBattery) .. " Battery charges)."
    )

    if gameFrameCount == g.run.frameOfLastDD + 1 then
      -- If we took this item from a devil deal, then we want to delete the pedestal entirely
      -- (since the item was not on a pedestal to begin with,
      -- it would not make any sense to leave an empty pedestal)
      -- Unfortunately, the empty pedestal will still show for a single frame
      pickup:Remove()
    else
      -- Otherwise, empty the pedestal
      pickup.SubType = 0
      pickup:GetSprite():Play("Empty", true)
    end
    return true
  else
    return false
  end
end

-- Check to see if the Schoolbag item needs to be swapped back in
function Schoolbag:CheckEmptyActiveItem()
  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    or g.run.schoolbag.item == 0
    or g.p:GetActiveItem() ~= 0
    or not g.p:IsItemQueueEmpty()
  ) then
    return
  end

  -- They used their primary item (Pandora's Box, etc.),
  -- so put the Schoolbag item in the primary slot
  Isaac.DebugString(
    "Empty active detected; swapping in Schoolbag item " .. g.run.schoolbag.item .. "."
  )
  Schoolbag:Switch()

  -- Empty the contents of the Schoolbag
  g.run.schoolbag.item = 0
  Schoolbag.sprites.item = nil
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
  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    or g.run.schoolbag.item == 0
    or Schoolbag:IsActiveItemQueued()
  ) then
    -- This will allow switches while the use/pickup animation is occuring but
    -- prevent bugs where queued items will override things
    return
  end

  local hotkeySwitch
  if RacingPlusData ~= nil then
    hotkeySwitch = RacingPlusData:Get("hotkeySwitch")
  end
  if hotkeySwitch ~= nil and hotkeySwitch ~= 0 then
    -- They have a custom Schoolbag-switch hotkey bound, so we need check for that input
    -- (we use "IsButtonPressed()" instead of "IsButtonTriggered()" because
    -- the latter is not very responsive with fast sequences of inputs)
    -- (we check all inputs instead of "player.ControllerIndex" because
    -- a controller player might be using the keyboard for their custom hotkey)
    local pressed = false
    for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
      if Input.IsButtonPressed(hotkeySwitch, i) then
        pressed = true
        break
      end
    end
    if not pressed then
      g.run.schoolbag.pressed = false
      return
    elseif g.run.schoolbag.pressed then
      return
    end
  else
    -- They do not have a Schoolbag-switch hotkey bound
    -- Default to using the same button that is used for the vanilla Schoolbag
    -- (e.g. card/pill switch)
    -- (we use "IsActionPressed()" instead of "IsActionTriggered()" because
    -- the latter is not very responsive with fast sequences of inputs)
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
  Isaac.DebugString(
    "Put item " .. tostring(g.run.schoolbag.item) .. " into the Schoolbag with charge: "
    .. tostring(g.run.schoolbag.charge) .. "-"
    .. tostring(g.run.schoolbag.chargeBattery)
  )
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

function Schoolbag:Switch()
  -- Local variables
  local activeItem = g.p:GetActiveItem()
  local maxCharges = g:GetItemMaxCharges(g.run.schoolbag.item)

  -- Fix the bug where you can spam Schoolbag switches to get permanent invincibility from
  -- My Little Unicorn and Unicorn Stump
  if (
    (
      g.p:HasCollectible(CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN) -- 77
      or g.p:HasCollectible(CollectibleType.COLLECTIBLE_UNICORN_STUMP) -- 298
    )
    and g.p:HasInvincibility()
  ) then
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
  if (
    g.p:GetActiveCharge() == maxCharges
    and g.sfx:IsPlaying(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  ) then
    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  end
  if (
    g.p:GetActiveCharge() ~= 0
    and g.sfx:IsPlaying(SoundEffect.SOUND_BEEP) -- 171
  ) then

    g.sfx:Stop(SoundEffect.SOUND_BEEP) -- 171
  end

  -- Update the cache (in case the new or old item granted stats, like A Pony)
  -- (we don't want to update the familiar cache because it can cause bugs with Dino Baby and
  -- cause temporary familiars to despawn)
  local allCacheFlagsMinusFamiliars = (
    CacheFlag.CACHE_DAMAGE -- 1
    + CacheFlag.CACHE_FIREDELAY -- 2
    + CacheFlag.CACHE_SHOTSPEED -- 4
    + CacheFlag.CACHE_RANGE -- 8
    + CacheFlag.CACHE_SPEED -- 16
    + CacheFlag.CACHE_TEARFLAG -- 32
    + CacheFlag.CACHE_TEARCOLOR -- 64
    + CacheFlag.CACHE_FLYING -- 128
    + CacheFlag.CACHE_WEAPON -- 256
    + CacheFlag.CACHE_LUCK -- 1024
  )
  g.p:AddCacheFlags(allCacheFlagsMinusFamiliars)
  g.p:EvaluateItems()

  -- If the old active item granted a non-temporary costume, we need to remove it
  -- Only certain specific items grant permanent costumes;
  -- this list was determined by testing all active items through trial and error
  if (
    activeItem == CollectibleType.COLLECTIBLE_KAMIKAZE -- 40
    or activeItem == CollectibleType.COLLECTIBLE_MONSTROS_TOOTH -- 86
    or activeItem == CollectibleType.COLLECTIBLE_PONY -- 130
    or activeItem == CollectibleType.COLLECTIBLE_WHITE_PONY -- 181
  ) then
    g.p:RemoveCostume(g.itemConfig:GetCollectible(activeItem))
  end

  -- Set the item hold cooldown to 0 since this doesn't count as picking up a new item
  -- (this fixes the bug where you can't immediately pick up a new item after performing a Schoolbag
  -- switch)
  g.p.ItemHoldCooldown = 0

  -- Tell The Babies Mod to reload the sprite just in case the new active item has a costume and it
  -- messes up the sprite
  if SinglePlayerCoopBabies ~= nil then
    SinglePlayerCoopBabies.run.reloadSprite = true
  end
end

-- Called from the MC_POST_UPDATE callback
function Schoolbag:CheckRemoved()
  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    and not g.run.schoolbag.present
  ) then
    -- We just got the Schoolbag for the first time
    g.run.schoolbag.present = true
  end

  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    and g.run.schoolbag.present
  ) then
    -- We had the Schoolbag collectible at some point in the past and now it is gone
    g.run.schoolbag.present = false
    if g.run.schoolbag.item ~= 0 then
      -- Drop the item that was in the Schoolbag on the ground
      -- (spawn it with an InitSeed of 0 so that it will be replaced on the next frame)
      local position = g.r:FindFreePickupSpawnPosition(g.p.Position, 1, true)
      local collectible = g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_COLLECTIBLE, -- 100
        position,
        g.zeroVector,
        nil,
        g.run.schoolbag.item,
        0
      ):ToPickup()

      -- We need to transfer back the current charge to the item
      -- Furthermore, we do not need to worry about the case of The Battery overcharge,
      -- because by using the D4 or the D100, they will have rerolled away The Battery
      collectible.Charge = g.run.schoolbag.charge
      g.run.schoolbag.item = 0
    end
  end
end

function Schoolbag:PostNewRoom()
  -- Local variables
  local activeItem = g.p:GetActiveItem()
  local activeCharge = g.p:GetActiveCharge()
  local activeChargeBattery = g.p:GetBatteryCharge()

  if g.run.schoolbag.usedGlowingHourGlass == 0 then
    -- Record the state of the active item + the Schoolbag item in case we use a Glowing Hour Glass
    g.run.schoolbag.last = {
      active = {
        item = activeItem,
        charge = activeCharge,
        chargeBattery = activeChargeBattery,
      },
      schoolbag = {
        item = g.run.schoolbag.item,
        charge = g.run.schoolbag.charge,
        chargeBattery = g.run.schoolbag.chargeBattery,
      },
    }
  elseif g.run.schoolbag.usedGlowingHourGlass == 1 then
    -- We just used a Glowing Hour Glass,
    -- so mark to reset the active item + the Schoolbag item on the next render frame
    g.run.schoolbag.usedGlowingHourGlass = 2
  end
end

return Schoolbag
