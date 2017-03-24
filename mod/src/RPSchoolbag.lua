local RPSchoolbag = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Schoolbag variables
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
  local maxCharges = RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.run.schoolbag.item)

  if RPGlobals.run.schoolbag.item == 0 or
     RPGlobals.run.schoolbag.charges >= maxCharges then

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

  -- Add the correct amount of charges
  RPGlobals.run.schoolbag.charges = RPGlobals.run.schoolbag.charges + chargesToAdd
  if RPGlobals.run.schoolbag.charges > maxCharges then
    RPGlobals.run.schoolbag.charges = maxCharges
  end
  -- We deliberately don't track The Battery charges, since the game handles this in a weird way
  -- (in the future, the Racing+ mod might completely recode The Battery to address this)

  -- Also keep track of Eden's Soul
  RPGlobals.run.edensSoulCharges = RPGlobals.run.edensSoulCharges + chargesToAdd
  if RPGlobals.run.edensSoulCharges > 12 then
    RPGlobals.run.edensSoulCharges = 12
  end
end

function RPSchoolbag:SpriteDisplay()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local maxCharges = RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.run.schoolbag.item)
  local itemX = 45
  local itemY = 50
  local barXOffset = 17
  local barYOffset = 1
  local itemVector = Vector(itemX, itemY)
  local barVector = Vector(itemX + barXOffset, itemY + barYOffset)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) == false or
     RPGlobals.run.schoolbag.item == 0 then

    return
  end

  if RPSchoolbag.sprites.item == nil then
    -- Load the sprites
    RPSchoolbag.sprites.item = Sprite()
    RPSchoolbag.sprites.item:Load("gfx/items2/collectibles/" .. RPGlobals.run.schoolbag.item .. ".anm2", true)
    RPSchoolbag.sprites.item:Play("Default", true)
    RPSchoolbag.sprites.barBack = Sprite()
    RPSchoolbag.sprites.barBack:Load("gfx/ui/ui_chargebar.anm2", true)
    RPSchoolbag.sprites.barBack:Play("BarEmpty", true)
    RPSchoolbag.sprites.barMeter = Sprite()
    RPSchoolbag.sprites.barMeter:Load("gfx/ui/ui_chargebar.anm2", true)
    RPSchoolbag.sprites.barMeter:Play("BarFull", true)
    RPSchoolbag.sprites.barLines = Sprite()
    RPSchoolbag.sprites.barLines:Load("gfx/ui/ui_chargebar.anm2", true)
    if maxCharges > 12 then
      RPSchoolbag.sprites.barLines:Play("BarOverlay1", true)
    else
      RPSchoolbag.sprites.barLines:Play("BarOverlay" .. tostring(maxCharges), true)
    end
  end

  -- Draw the item image
  RPSchoolbag.sprites.item:Update()
  RPSchoolbag.sprites.item:Render(itemVector, Vector(0, 0), Vector(0, 0))

  if maxCharges ~= 0 then
    -- Draw the charge bar 1/3 (the background)
    RPSchoolbag.sprites.barBack:Update()
    RPSchoolbag.sprites.barBack:Render(barVector, Vector(0, 0), Vector(0, 0))

    -- Draw the charge bar 2/3 (the bar itself, clipped appropriately)
    RPSchoolbag.sprites.barMeter:Update()
    local meterMultiplier = 24 / maxCharges
    local meterClip = 26 - (RPGlobals.run.schoolbag.charges * meterMultiplier)
    RPSchoolbag.sprites.barMeter:Render(barVector, Vector(0, meterClip), Vector(0, 0))

    -- Draw the charge bar 3/3 (the segment lines on top)
    RPSchoolbag.sprites.barLines:Update()
    RPSchoolbag.sprites.barLines:Render(barVector, Vector(0, 0), Vector(0, 0))
  end
end

function RPSchoolbag:CheckActiveCharges()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local charges = player:GetActiveCharge()

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) == false or
     player:GetActiveItem() == 0 or
     charges == RPGlobals.run.schoolbag.lastCharge then

    return
  end

  -- Store the new active charge
  -- (we need to know how many charges we have if we pick up a second active item)
  RPGlobals.run.schoolbag.lastCharge = charges
  Isaac.DebugString("Active item charges changed: " .. tostring(charges))
end

-- Check to see if the Schoolbag item needs to be swapped back in
function RPSchoolbag:CheckEmptyActive()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) == false or
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
  local roomIndex = level:GetCurrentRoomIndex()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) == false or
     RPGlobals.run.schoolbag.item == 0 or
     roomIndex ~= RPGlobals.LevelGridIndex.GRIDINDEX_BOSS_RUSH or -- -5
     room:IsAmbushActive() == false or
     RPGlobals.run.schoolbag.bossRushActive then

    return
  end

  -- We started the Boss Rush, so give an extra charge
  RPGlobals.run.schoolbag.bossRushActive = true
  RPSchoolbag:AddCharge()
end

-- Check for input for a Schoolbag switch
function RPSchoolbag:CheckInput()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()

  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) == false or
     RPGlobals.run.schoolbag.item == 0 or
     player:IsHoldingItem() == true then
    return
  end

  local switchPressed = false
  for i = 0, 3 do -- There are 4 possible players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_DROP, i) then -- 11
      switchPressed = true
      break
    end
  end
  if switchPressed and RPGlobals.run.schoolbag.pressed == false then
    RPGlobals.run.schoolbag.pressed = true
    RPSchoolbag:Switch()

    -- Put the old item in the Schoolbag
    RPGlobals.run.schoolbag.item = activeItem
    RPGlobals.run.schoolbag.charges = activeCharge
    RPSchoolbag.sprites.item = nil

  elseif switchPressed == false then
    RPGlobals.run.schoolbag.pressed = false
  end
end

function RPSchoolbag:Switch()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local sfx = SFXManager()
  local maxCharges = RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.run.schoolbag.item)

  -- Set the new active item
  player:AddCollectible(RPGlobals.run.schoolbag.item, RPGlobals.run.schoolbag.charges, false)

  -- Fix the bug where the charge sound will play if the item is fully charged or partially charged
  if player:GetActiveCharge() == maxCharges and
     sfx:IsPlaying(SoundEffect.SOUND_BATTERYCHARGE) then -- 170

    sfx:AdjustVolume(SoundEffect.SOUND_BATTERYCHARGE, 0)
  end
  if player:GetActiveCharge() ~= 0 and
     sfx:IsPlaying(SoundEffect.SOUND_BEEP) then -- 171

    sfx:AdjustVolume(SoundEffect.SOUND_BEEP, 0) -- 171
  end

  -- Update the cache (in case the old / the new item granted stats, like A Pony)
  player:AddCacheFlags(CacheFlag.CACHE_ALL)
  player:EvaluateItems()

  -- Remove the costume, if any (some items give a costume, like A Pony)
  if activeItem ~= 0 then
    local configItem = RPGlobals:GetConfigItem(activeItem) -- This will crash the game with an item ID of 0
    player:RemoveCostume(configItem)
  end
end

return RPSchoolbag
