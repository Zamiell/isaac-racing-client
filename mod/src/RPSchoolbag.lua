local RPSchoolbag = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Variables
--

RPSchoolbag.sprites = {}

--
-- Schoolbag functions
--

function RPSchoolbag:AddCharge()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local maxCharges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)

  -- We don't need to do anything if we don't have a Schoolbag or we don't have an item in the Schoolbag
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false or
     RPGlobals.run.schoolbag.item == 0 then

    return
  end

  -- We don't need to do anything if the item is already charged
  if RPGlobals.run.schoolbag.charges >= maxCharges and
     player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) == false then -- 63

    return
  end

  -- We don't need to do anything if the item is already double-charged
  if RPGlobals.run.schoolbag.chargesBattery >= maxCharges and
     player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then -- 63

    return
  end

  -- Find out how many charges we should add
  local chargesToAdd = 1
  local shape = room:GetRoomShape()
  if shape >= 8 then -- -5

    chargesToAdd = 2

  elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
         RPGlobals.run.schoolbag.charges == maxCharges - 2 then

    -- The AAA Battery grants an extra charge when the active item is one away from being fully charged
    chargesToAdd = 2
  end

  -- Add the correct amount of charges (accounting for The Battery)
  RPGlobals.run.schoolbag.charges = RPGlobals.run.schoolbag.charges + chargesToAdd
  if RPGlobals.run.schoolbag.charges > maxCharges then
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then -- 63
      local extraChargesToAdd = RPGlobals.run.schoolbag.charges - maxCharges
      RPGlobals.run.schoolbag.chargesBattery = RPGlobals.run.schoolbag.chargesBattery + extraChargesToAdd
      if RPGlobals.run.schoolbag.chargesBattery > maxCharges then
        RPGlobals.run.schoolbag.chargesBattery = maxCharges
      end
    end
    RPGlobals.run.schoolbag.charges = maxCharges
  end

  -- Also keep track of Eden's Soul
  -- (charges on this specific item are tracked in order to fix vanilla bugs with the item)
  if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_EDENS_SOUL then -- 490
    RPGlobals.run.edensSoulCharges = RPGlobals.run.edensSoulCharges + chargesToAdd
    if RPGlobals.run.edensSoulCharges > 12 then
      RPGlobals.run.edensSoulCharges = 12
    end
  end
end

function RPSchoolbag:SpriteDisplay()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local maxCharges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
  local itemX = 45
  local itemY = 50
  local barXOffset = 17
  local barYOffset = 1
  local itemVector = Vector(itemX, itemY)
  local barVector = Vector(itemX + barXOffset, itemY + barYOffset)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false then
    return
  end

  -- Load the sprites
  if RPSchoolbag.sprites.item == nil then
    -- By default, use the item ID as the file name for the ANM2 to load
    local fileName = RPGlobals.run.schoolbag.item
    if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_MOVING_BOX and -- 523
       RPGlobals.run.movingBoxOpen then

      -- We need custom logic to handle Moving Box, which has two different sprites
      fileName = "523-2"
    elseif RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_DEBUG then
      fileName = "Debug"
    elseif RPGlobals.run.schoolbag.item == Isaac.GetItemIdByName("Wraith Skull") then
      fileName = "Wraith_Skull"
    end

    RPSchoolbag.sprites.item = Sprite()
    RPSchoolbag.sprites.item:Load("gfx/items2/collectibles/" .. fileName .. ".anm2", true)
    RPSchoolbag.sprites.item:Play("Default", true)
    RPSchoolbag.sprites.barBack = Sprite()
    RPSchoolbag.sprites.barBack:Load("gfx/ui/ui_chargebar.anm2", true)
    RPSchoolbag.sprites.barBack:Play("BarEmpty", true)
    RPSchoolbag.sprites.barMeter = Sprite()
    RPSchoolbag.sprites.barMeter:Load("gfx/ui/ui_chargebar.anm2", true)
    RPSchoolbag.sprites.barMeter:Play("BarFull", true)
    RPSchoolbag.sprites.barMeterBattery = Sprite()
    RPSchoolbag.sprites.barMeterBattery:Load("gfx/ui/ui_chargebar_battery.anm2", true)
    RPSchoolbag.sprites.barMeterBattery:Play("BarFull", true)
    RPSchoolbag.sprites.barLines = Sprite()
    RPSchoolbag.sprites.barLines:Load("gfx/ui/ui_chargebar.anm2", true)
    if maxCharges > 12 then
      RPSchoolbag.sprites.barLines:Play("BarOverlay1", true)
    else
      RPSchoolbag.sprites.barLines:Play("BarOverlay" .. tostring(maxCharges), true)
    end

    -- Fade the placeholder image (the Schoolbag icon)
    if RPGlobals.run.schoolbag.item == 0 then
      RPSchoolbag.sprites.item.Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      RPSchoolbag.sprites.item.Scale = Vector(0.75, 0.75)
    end
  end

  -- Draw the item image
  RPSchoolbag.sprites.item:Update()
  RPSchoolbag.sprites.item:Render(itemVector, Vector(0, 0), Vector(0, 0))

  -- Draw the charge bar
  if maxCharges ~= 0 then
    -- The background
    RPSchoolbag.sprites.barBack:Update()
    RPSchoolbag.sprites.barBack:Render(barVector, Vector(0, 0), Vector(0, 0))

    -- The bar itself, clipped appropriately
    RPSchoolbag.sprites.barMeter:Update()
    local meterMultiplier = 24 / maxCharges
    local meterClip = 26 - (RPGlobals.run.schoolbag.charges * meterMultiplier)
    RPSchoolbag.sprites.barMeter:Render(barVector, Vector(0, meterClip), Vector(0, 0))

    -- The bar for The Battery charges
    RPSchoolbag.sprites.barMeterBattery:Update()
    meterClip = 26 - (RPGlobals.run.schoolbag.chargesBattery * meterMultiplier)
    RPSchoolbag.sprites.barMeterBattery:Render(barVector, Vector(0, meterClip), Vector(0, 0))

    -- The segment lines on top
    RPSchoolbag.sprites.barLines:Update()
    RPSchoolbag.sprites.barLines:Render(barVector, Vector(0, 0), Vector(0, 0))
  end
end

-- Called from the PostUpdate callback
function RPSchoolbag:CheckActiveCharges()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false or
     player:GetActiveItem() == 0 then

    return
  end

  -- Store the new active charge
  -- (we need to know how many charges we have if we pick up a second active item)
  RPGlobals.run.schoolbag.lastCharge = activeCharge
  RPGlobals.run.schoolbag.lastChargeBattery = batteryCharge
end

-- Called from the PostUpdate callback (the "RPCheckEntities:ReplacePedestal()" function)
-- (essentially this code check runs only when the item is first spawned)
function RPSchoolbag:CheckSecondItem(entity)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) and
     RPGlobals.run.schoolbag.item == 0 and
     entity:ToPickup().Touched then

    -- We don't want to put the item in the Schoolbag if we dropped it from a Butter! trinket
    if player:HasTrinket(TrinketType.TRINKET_BUTTER) and
       RPGlobals.run.droppedButterItem == entity.SubType then

      RPGlobals.run.droppedButterItem = 0
      Isaac.DebugString("Prevented putting item " .. tostring(entity.SubType) .. " in the Schoolbag.")
      return false
    end

    -- Put the item in our Schoolbag and delete the pedestal
    RPGlobals.run.schoolbag.item = entity.SubType
    RPGlobals.run.schoolbag.charges = RPGlobals.run.schoolbag.lastCharge
    RPGlobals.run.schoolbag.chargesBattery = RPGlobals.run.schoolbag.lastChargeBattery
    RPSchoolbag.sprites.item = nil
    entity:Remove()
    Isaac.DebugString("Put pedestal " .. tostring(entity.SubType) .. " into the Schoolbag with " ..
                      tostring(RPGlobals.run.schoolbag.charges) .. " charges (and" ..
                      tostring(RPGlobals.run.schoolbag.chargesBattery) .. " Battery charges).")
    return true
  else
    return false
  end
end

-- Check to see if the Schoolbag item needs to be swapped back in
function RPSchoolbag:CheckEmptyActive()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false or
     RPGlobals.run.schoolbag.item == 0 or
     player:GetActiveItem() ~= 0 or
     player:IsItemQueueEmpty() == false then

    return
  end

  -- They used their primary item (Pandora's Box, etc.), so put the Schoolbag item in the primary slot
  Isaac.DebugString("Empty active detected; swapping in Schoolbag item " .. RPGlobals.run.schoolbag.item .. ".")
  RPSchoolbag:Switch()

  -- Empty the contents of the Schoolbag
  RPGlobals.run.schoolbag.item = 0
  RPSchoolbag.sprites.item = nil
end

function RPSchoolbag:CheckBossRush()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndexUnsafe = level:GetCurrentRoomIndex()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false or
     RPGlobals.run.schoolbag.item == 0 or
     roomIndexUnsafe ~= GridRooms.ROOM_BOSSRUSH_IDX or -- -5
     room:IsAmbushActive() == false or
     RPGlobals.run.schoolbag.bossRushActive then

    return
  end

  -- We started the Boss Rush, so give an extra charge
  RPGlobals.run.schoolbag.bossRushActive = true
  RPSchoolbag:AddCharge()
end

-- Check for Schoolbag switch inputs
function RPSchoolbag:CheckInput()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()

  -- We don't care about detecting inputs if we don't have the Schoolbag,
  -- we don't have anything in the Schoolbag,
  -- or we currently have an active item held overhead
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) == false or
     RPGlobals.run.schoolbag.item == 0 or
     RPSchoolbag:IsActiveItemQueued() then
     -- This will allow switches while the use/pickup animation is occuring but
     -- prevent bugs where queued items will override things

    return
  end

  local button = RPGlobals.race.hotkeySwitch
  if button ~= 0 then
    -- If they have a custom Schoolbag-switch key bound, then use that
    -- (we use "IsButtonPressed()" instead of "IsButtonTriggered()" because
    -- the latter is not very responsive with fast sequences of inputs)
    -- (we check all inputs instead of "player.ControllerIndex" because
    -- a controller player might be using the keyboard for their custom hotkey)
    local pressed = false
    for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
      if Input.IsButtonPressed(RPGlobals.race.hotkeySwitch, i) then
        pressed = true
      end
    end
    if pressed == false then
      RPGlobals.run.schoolbag.pressed = false
      return
    elseif RPGlobals.run.schoolbag.pressed then
      return
    end
  else
    -- If they do not have a custom key bound, then default to the same button that is used for card/pill switching
    -- We use "IsActionPressed()" instead of "IsActionTriggered()" because
    -- the latter is not very responsive with fast sequences of inputs
    if Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex) == false then -- 11
      RPGlobals.run.schoolbag.pressed = false
      return
    elseif RPGlobals.run.schoolbag.pressed then
      return
    end
  end
  RPGlobals.run.schoolbag.pressed = true

  -- Put the item from the Schoolbag in the active slot
  RPSchoolbag:Switch()

  -- Put the old item in the Schoolbag
  RPGlobals.run.schoolbag.item = activeItem
  RPGlobals.run.schoolbag.charges = activeCharge
  RPGlobals.run.schoolbag.chargesBattery = batteryCharge
  RPSchoolbag.sprites.item = nil
  Isaac.DebugString("Put item " .. tostring(RPGlobals.run.schoolbag.item) .. " into the Schoolbag with charge: " ..
                    tostring(RPGlobals.run.schoolbag.charges) .. "-" ..
                    tostring(RPGlobals.run.schoolbag.chargesBattery))
end

function RPSchoolbag:IsActiveItemQueued()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player.QueuedItem.Item == nil then
    return false
  end

  if player.QueuedItem.Item.Type == ItemType.ITEM_ACTIVE then -- 3
    return true
  else
    return false
  end
end

-- Called from the "RPSchoolbag:CheckInput()" function
function RPSchoolbag:Switch()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local itemConfig = Isaac.GetItemConfig()
  local sfx = SFXManager()
  local maxCharges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)

  -- Fix the bug where you can spam Schoolbag switches to get permanent invincibility from
  -- My Little Unicorn and Unicorn Stump
  if (player:HasCollectible(CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN) or -- 77
      player:HasCollectible(CollectibleType.COLLECTIBLE_UNICORN_STUMP)) and -- 298
     player:HasInvincibility() then

    player:ClearTemporaryEffects()
    Isaac.DebugString("Ended My Little Unicorn / Unicorn Stump invulnerability early.")
  end

  -- Set the new active item
  player:AddCollectible(RPGlobals.run.schoolbag.item, 0, false) -- We set the charges manually in the next line
  player:DischargeActiveItem() -- This is necessary to prevent some bugs with The Battery
  local totalCharges = RPGlobals.run.schoolbag.charges + RPGlobals.run.schoolbag.chargesBattery
  player:SetActiveCharge(totalCharges)
  Isaac.DebugString("Set charges to: " .. tostring(totalCharges))

  -- Fix the bug where the charge sound will play if the item is fully charged or partially charged
  if player:GetActiveCharge() == maxCharges and
     sfx:IsPlaying(SoundEffect.SOUND_BATTERYCHARGE) then -- 170

    sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  end
  if player:GetActiveCharge() ~= 0 and
     sfx:IsPlaying(SoundEffect.SOUND_BEEP) then -- 171

    sfx:Stop(SoundEffect.SOUND_BEEP) -- 171
  end

  -- Update the cache (in case the old / the new item granted stats, like A Pony)
  player:AddCacheFlags(CacheFlag.CACHE_ALL) -- 0xFFFFFFFF
  player:EvaluateItems()

  -- Remove the costume, if any (some items give a costume, like A Pony)
  if activeItem ~= 0 then
    player:RemoveCostume(itemConfig:GetCollectible(activeItem))
  end

  -- Set the item hold cooldown to 0 since this doesn't count as picking up a new item
  -- (this fixes the bug where you can't immediately pick up a new item after performing a Schoolbag switch)
  player.ItemHoldCooldown = 0
end

return RPSchoolbag
