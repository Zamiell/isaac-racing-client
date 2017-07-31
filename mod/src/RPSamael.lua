local SamaelMod = {}

--
-- Includes
--

local RPGlobals   = require("src/rpglobals")
local RPSchoolbag = require("src/rpschoolbag")

----Samael Character Mod---
--Version 1.6
--By Ghostbroster

--Settings
--local wraithModeKey = Keyboard.KEY_F --Which keyboard key activates wraith mode
--local controllerMode = false
--Changing this to true will allow wraith mode to be activated with the "item drop" button (Ctrl on a keyboard)
-- Currently the only practical way to allow controller input

--local wraithMeterXOffset = 45 --Wraith Meter HUD sprite offsets
--local wraithMeterYOffset = 50
--local showValues = false --Show charge and swingDelay values on screen

--References and junk
local scytheID = Isaac.GetEntityTypeByName("Samael Scythe") --Entity ID of the scythe weapon entity
local samaelID = Isaac.GetPlayerTypeByName("Samael") --Character ID of Samael
local projVariant = Isaac.GetEntityVariantByName("Magic Scythe") --Entity variant number of the scythe projectile
local specialAnim = Isaac.GetEntityTypeByName("Samael Special Animations") --Entity for showing special animations
local hitBoxType = 617 --Subtype of the scythe's hitbox entity (It is a subtype of a Sacrificial Dagger)
local hood = Isaac.GetCostumeIdByPath("gfx/characters/samaelhood.anm2") --Hood+horns+bandages costume
local cloak = Isaac.GetCostumeIdByPath("gfx/characters/samaelcloak.anm2") --Cloak costume
local samaelDeadEye = Isaac.GetItemIdByName("Samael Dead Eye") --Custom version of deadeye for Samael
local samaelChocMilk = Isaac.GetItemIdByName("Samael Chocolate Milk") --Replaces chocolate milk for Samael
local samaelDrFetus = Isaac.GetItemIdByName("Samael Dr. Fetus")
--Replaces Dr. Fetus for Samael if brimstone is also acquired
local samaelMarked = Isaac.GetItemIdByName("Samael Marked") --Replaces marked for Samael
local wraithItem = Isaac.GetItemIdByName("Wraith Skull") --Spacebar Wraith Mode Activation

--Wraith meter HUD sprite
local wraithMeter = Sprite()
wraithMeter:Load("gfx/samael_wraithmeter.anm2", true)
--local wraithIsCharged = false

--Static variables (can be used as tweaks/settings)
local scytheDamageMultiplier = 1.0 --Scythe damage = damage stat * this
local scytheProjectileDamageMultiplier = 1.0 --Scythe projectile damage = damage stat * this
local chargeTimeMax = 40 --Maximum number of frames to charge a projectile
local chargeTimeMid = 20 --Charge time at default fire delay (10)
local chargeTimeMin = 10 --Minimum number of frames to charge a projectile
local swingDelayCap = 30 --Cap on how high the swingDelay can be (maximum frames between scythe swings)
local knockbackMagnitude = 4 --How much of a knockback effect the scythe has
local luckCap = 15 --How much luck samael needs to get status effects 100% of the time with melee
--local maxSizeRange = 50 --How much range to get a scythe thats twice as big

--Dynamic variables (they change)
local spawned = false --Is the scythe spawned?
local scytheState = 0 --State of the scythe
local scytheScale = 1 --Size of the scythe
local scytheColor --For storing what colour the scythe should be
local chargeTime = 0 --Number of frames required to charge a projectile
local charge = 0 --Current charge (For charging a projectile)
local lastCharge = 0
--Amount charged before being released (used for mom's knife so you need to charge at least 5 frames)
local lastDirection = -1 --Saves the last attack direction in order to keep track of it while an attack is taking place
local hitPos = nil --Where the hitbox for the melee scythe should be placed
local swing = 0 --Alternating value that denotes whether the scythe is doing a left or right swing
local swingDelay = 0 --If above 0, this is the number of frames until the scythe can be swung again

local costumeEquipped = false --Are his costumes equipped?
local dying = false --Flag for dying animation (to activate custom death animation)
local itemChecks = {}
--Array for checking if certain items are held to give damage boosts (multishot items, blood clot etc)
local numItems = -1 --Number of items currently held (used to identify when you get a new item)
local canShoot = false --If false, stops the player from firing tears normally
local isaacDying = false

local hits = 0 --Number of hits the scythe made in the current swing
local properDamage = 3.5 --For keeping track of the player's proper damage stat when applying boosts
local deadEyeBoost = 0 --For keeping track of how much damage was added with deadeye
local epiphoraCounter = 0 --How many times you've swung in the same direction
local lastEpiphoraDirection = -1
local hideScythe = false --Visibly hide the scythe (used with mom's knife synergy)
local laserRingSpawned = false --For spawning tech x rings around samael when he swings
local mawSoundCanceler = 0 --For blocking the maw of the void sound effect with the Godhead synergy's light circle
--local spawnSkull = false

--Three Dollar Bill/Fruit Cake effects and other tear effect related variables
local rainbowEffects = {
  "slow",
  "fear",
  "fire",
  "confuse",
  "freeze",
  "creep",
  "poison",
  "pee",
  "charm",
}
local threeDollarBillEffect = "none"
local cakeEffects = {
  "parasite",
  "bone",
  "greed",
  "fire",
  "keeper",
  "light",
  "confuse",
  "shock",
  "freeze",
  "fear",
  "charm",
  "creep",
  "shrink",
  "fly",
  "poison",
  "slow",
}
local threeDollarBillTimer = 0
local fruitCakeEffect = "none"
local parasiteTriggered = false
local jacobTriggered = false

local wraithTime = 0 --Time left for wraith mode
local wraithCharge = 0 --How much the wraith ability has been charged (out of 100)
local wraithActive = false --Is wraith form active?
local wraithCooldown = 0 --Brief cooldown after wraith form where you still can't take damage
local lastFrameWraithCharge = 0 --% of wraith meter charged during last update
local wraithChargeCooldown = 0 --Cooldown before the wraith meter charges normally again
local wraithActivationCooldown = 0 --Minimum cooldown between wraith mode activations
local wraithChargePenalty = 0

local fireDelayPenalty = 0 --Nerfs
local fireDelayReduced = false

--local info = 0

-----------Post update function-----------
function SamaelMod:samaelPostUpdate()
  local player = Isaac.GetPlayer(0)
  if player:GetPlayerType() == samaelID then --If the player is Samael

    local level = Game():GetLevel()
    local room = level:GetCurrentRoom()

    --[[ We don't want to spawn the skull in the starting room
    if spawnSkull then
      if level:GetCurrentRoomIndex() == level:GetStartingRoomIndex() and Game():GetFrameCount() == 1 then
        Isaac.Spawn(5, 100, wraithItem, room:GetGridPosition(32), Vector(0,0), nil)
        local sign = Isaac.Spawn(specialAnim, 0, 0, room:GetGridPosition(33), Vector(0,0), nil):ToNPC()
        sign:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        sign:GetSprite():Play("Sign", 1)
        sign.CanShutDoors = false
      end
      spawnSkull = false
    end
    --]]

    if wraithActivationCooldown > 0 then
      wraithActivationCooldown = wraithActivationCooldown - 1
    end

    if mawSoundCanceler > 0 then
      SamaelMod:playSound(426, 0, 3)
      mawSoundCanceler = mawSoundCanceler - 1
    end

    local roomFrames = room:GetFrameCount() --Framecount of current room (to identify a new room)

    SamaelMod:wraithModeHandler()

    if player:HasCollectible(wraithItem) then
      player:SetActiveCharge(math.ceil(wraithCharge))
      -- Mute the annoying sound effect
      local sfx = SFXManager()
      sfx:Stop(SoundEffect.SOUND_BEEP) -- 171
    elseif RPGlobals.run.schoolbag.item == wraithItem then
      RPGlobals.run.schoolbag.charges = math.ceil(wraithCharge)
    end

    if wraithChargeCooldown > 0 then
      wraithChargeCooldown = wraithChargeCooldown - 1
    end

    if roomFrames == 1 then
      --Respawn scythe every room (It does not persist otherwise. I prefer it this way.
      -- It's easy to manage, since this is all you have to do to fix it.)
      --Isaac.SaveModData(SamaelMod, tostring(math.floor(wraithCharge))) --Also save the wraithCharge
      spawned = false
    end

    if not canShoot then
      player.FireDelay = 10 --Disable tears
    end

    --Custom death animation
    if player:GetSprite():IsPlaying("Death") then --When player dies
      if not dying then
        --Spawn the special animations entity
        local special = Isaac.Spawn(specialAnim, 0, 0, player.Position, Vector(0,0), player):ToNPC()
        special:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        special:GetSprite():Play("Death", 1) --Play custom death animation
        special.CanShutDoors = false
        dying = true --Set dying flag
      end
      player:GetSprite().Color = Color(0,0,0,0,0,0,0) --Make the player invisible
    elseif dying then --If the player is not dying, and the dying flag is on
      dying = false --Turn the flag off
      player:GetSprite().Color = Color(1,1,1,1,0,0,0)
    end

    --Three Dollar Bill
    if player:HasCollectible(CollectibleType.COLLECTIBLE_3_DOLLAR_BILL) then
      if threeDollarBillTimer <= 0 then
        threeDollarBillTimer = 100
        math.randomseed(Isaac.GetFrameCount() + Game():GetFrameCount())
        threeDollarBillEffect = rainbowEffects[ math.random( #rainbowEffects ) ]
        SamaelMod:getScytheColor()
      else
        threeDollarBillTimer = threeDollarBillTimer - 1
      end
    else
      threeDollarBillTimer = 0
      threeDollarBillEffect = "none"
    end

    --Only spawn epic fetus targets if the fire button has been briefly held down
    if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and charge < 5 then
      player.FireDelay = 3
    end

    if not spawned then --If scythe is not spawned
      local scythe = Isaac.Spawn(scytheID, 0, 0, player.Position, Vector(0,0), player) --Spawn the scythe
      scythe = scythe:ToNPC()
      SamaelMod:getScytheColor()
      scythe:GetSprite().Color = scytheColor
      scythe.GridCollisionClass = GridCollisionClass.COLLISION_NONE
      scythe:ClearEntityFlags(EntityFlag.FLAG_APPEAR) --Skip spawning animations
      scythe.CanShutDoors = false --Its not an enemy
      scytheState = 0 --Reset scythe state
      --Charge time persists, but set it back to the cap to trigger the flashing again if need be
      if charge > chargeTime then
        charge = chargeTime
      end
      spawned = true --Scythe is spawned
      laserRingSpawned = false
    end

    if chargeTime == 0 then --Set charge time on init (only really activates upon using the luamod command)
      SamaelMod:calcChargeTime()
    end

    --Replace deadeye with a custom item for samael
    if player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_EYE) then
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_DEAD_EYE)
      Isaac.DebugString("Removing collectible " .. CollectibleType.COLLECTIBLE_DEAD_EYE)
      player:AddCollectible(samaelDeadEye, 0, false)
    end
    --Replace chocolate milk with a custom item for samael
    if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK)
      Isaac.DebugString("Removing collectible " .. CollectibleType.COLLECTIBLE_CHOCOLATE_MILK)
      player:AddCollectible(samaelChocMilk, 0, false)
    end
    --Replace Dr Fetus with a custom item if brimstone is also aquired
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and
       player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then

      player:RemoveCollectible(CollectibleType.COLLECTIBLE_DR_FETUS)
      Isaac.DebugString("Removing collectible " .. CollectibleType.COLLECTIBLE_DR_FETUS)
      player:AddCollectible(samaelDrFetus, 0, false)
    elseif not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and
           player:HasCollectible(samaelDrFetus) then

      player:RemoveCollectible(samaelDrFetus)
      Isaac.DebugString("Removing collectible " .. tostring(samaelDrFetus) .. " (Samael Dr. Fetus)")
      player:AddCollectible(CollectibleType.COLLECTIBLE_DR_FETUS, 0, false)
    end
    --Marked is awful, replace it
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_MARKED)
      Isaac.DebugString("Removing collectible " .. CollectibleType.COLLECTIBLE_MARKED)
      player:AddCollectible(samaelMarked, 0, false)
    end
    --Cursed eye + dr fetus doesnt work, so lets just get rid of the shitty item
    if player:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE) and
       player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then

      player:RemoveCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE)
      Isaac.DebugString("Removing collectible " .. CollectibleType.COLLECTIBLE_CURSED_EYE)
    end

    --Checking for certain items that are incompatable with Samael's standard scythe swing,
    --and granting bonus damage for them
    if numItems ~= player:GetCollectibleCount() then
      local itemChecksNew = {
        player:GetCollectibleNum(CollectibleType.COLLECTIBLE_CHEMICAL_PEEL),
        player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BLOOD_CLOT),
        player:GetCollectibleNum(CollectibleType.COLLECTIBLE_CUPIDS_ARROW),
        player:GetCollectibleNum(CollectibleType.COLLECTIBLE_SAGITTARIUS),
        player:GetCollectibleNum(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)*2,
      }
      if numItems == -1 then --Resetting after player init
        itemChecks = {}
        for i = 1, #itemChecksNew do
          itemChecks[i] = 0
        end
      end
      for i = 1, #itemChecks do --Check if any of the values have changed
        if itemChecks[i] ~= itemChecksNew[i] then
          player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
          break
        end
      end
      itemChecks = itemChecksNew
      numItems = player:GetCollectibleCount()
      player:EvaluateItems()
    end
  else
    --Make sure custom items do not persist outside of Samael
    if player:HasCollectible(samaelDeadEye) then
      player:RemoveCollectible(samaelDeadEye)
      Isaac.DebugString("Removing collectible " .. tostring(samaelDeadEye) .. " (Samael Dead Eye)")
      player:AddCollectible(CollectibleType.COLLECTIBLE_DEAD_EYE, 0, false)
    end
    if player:HasCollectible(samaelChocMilk) then
      player:RemoveCollectible(samaelChocMilk)
      Isaac.DebugString("Removing collectible " .. tostring(samaelChocMilk) .. " (Samael Chocolate Milk)")
      player:AddCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, 0, false)
    end
    if player:HasCollectible(samaelDrFetus) then
      player:RemoveCollectible(samaelDrFetus)
      Isaac.DebugString("Removing collectible " .. tostring(samaelDrFetus) .. " (Samael Dr. Fetus)")
      player:AddCollectible(CollectibleType.COLLECTIBLE_DR_FETUS, 0, false)
    end
    if player:HasCollectible(samaelMarked) then
      player:RemoveCollectible(samaelMarked)
      Isaac.DebugString("Removing collectible " .. tostring(samaelMarked) .. " (Samael Marked)")
      player:AddCollectible(CollectibleType.COLLECTIBLE_MARKED, 0, false)
    end
    if not player:GetSprite():IsPlaying("Death") and dying then
      dying = false --Turn the flag off
      player:GetSprite().Color = Color(1,1,1,1,0,0,0)
    end
    if costumeEquipped then
      player:TryRemoveNullCostume(cloak)
      player:TryRemoveNullCostume(hood)
      costumeEquipped = false
    end
    --if spawnSkull then spawnSkull = false end
  end
end

--------Wraith mode functionalities--------
function SamaelMod:wraithModeHandler()
  local player = Isaac.GetPlayer(0)
  --local controller = player.ControllerIndex
  local roomFrames = Game():GetLevel():GetCurrentRoom():GetFrameCount()
  --Framecount of current room (to identify a new room)

  --Stop wraith form
  if wraithActive and
     (player:GetSprite():IsPlaying("Trapdoor") or
      roomFrames == 1 or
      dying or
      isaacDying or
      player:HasCollectible(wraithItem) == false) then

    SamaelMod:triggerWraithModeEnd()
  end
  if wraithCooldown > 0 then --On cooldown after wraith form wears off (briefly flashing and still invulnerable)
    wraithCooldown = wraithCooldown - 1
    if wraithCooldown % 4 == 0 then
      player:SetColor(Color(0.6,0.3,0.3,0.4,0,0,0), 2, 990, false, false)
    end
    if wraithCooldown == 0 then
      wraithActive = false
    end

  elseif wraithActive then --Full wraith form is active
    wraithTime = wraithTime - 1
    wraithCharge = 0
    player:GetSprite().Color = Color(0,0,0,0,0,0,0)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0,
                player.Position, Vector(0,0), player) --Smoke trail
    if wraithTime == 0 then --When wraith time is over
      wraithCooldown = 24
      player.MoveSpeed = player.MoveSpeed - 0.3
      --Isaac.DebugString("Decreased speed from the Wraith ability being over: " .. tostring(player.MoveSpeed))
      player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
      SamaelMod:playSound(316, 1.8, 1.25)
      --Black poof effect
      local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 0,
                               player.Position, Vector(0,0), player):ToEffect()
      poof:GetSprite().Color = Color(0, 0, 0, 0.66, 0, 0, 0)
      poof:FollowParent(player)
    end
  end
end

function SamaelMod:triggerWraithModeEnd()
  local player = Isaac.GetPlayer(0)

  if dying then
    player:SetColor(Color(0, 0, 0, 0, 0, 0, 0), 57, 999, false, false)
  end
  if wraithCooldown == 0 then
    player.MoveSpeed = player.MoveSpeed - 0.3
    --Isaac.DebugString("Decreased speed from the Wraith ability being over (inside triggerWraithModeEnd function): " ..
                      --tostring(player.MoveSpeed))
  end
  wraithActive = false
  wraithCooldown = 0
  wraithTime = 0
  player:GetSprite().Color = Color(1, 1, 1, 1, 0, 0, 0)
  player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
  Isaac.DebugString("Ended wraith mode.")
end

-----------NPC update function for the scythe entity-----------
function SamaelMod:scytheUpdate(scythe)
  local player = Isaac.GetPlayer(0)
  scythe = scythe:ToNPC()

  if player:GetPlayerType() ~= samaelID then
    scythe:Remove()
    return
  end
  if dying then
    return
  end

  local hitBox --Local variable to store reference to hitbox entity
  if scythe.Child == nil then --If the scythe has no child (no spawned hitbox)
    hitBox = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.SACRIFICIAL_DAGGER, hitBoxType,
                         player.Position, Vector(0,0), scythe) --Spawn the hitbox
    hitBox:ClearEntityFlags(EntityFlag.FLAG_APPEAR) --Skip appear animations
    hitBox = hitBox:ToFamiliar()
    scythe.Child = hitBox --Set it as the scythe's child
    hitBox.Parent = scythe --Set the scythe as its parent
    hitBox.CollisionDamage = 0 --No Collision damage until activated
    hitBox.Coins = -1
    --Coins is used to store directions, because the actual direction-related attributes
    --were crashing my game for some reason
    hitBox.Size = 40 --Set its size (how big of a radius)
    hitBox.Position = Vector(0,0) --Move it off of the screen
    hitBox.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
  else
    hitBox = scythe.Child:ToFamiliar() --If scythe has a child, then the hitbox exists. Set this as a reference to it
  end
  local sprite = scythe:GetSprite() --The Scythe's sprite
  local headDirection = player:GetHeadDirection()
  local fireDirection = player:GetFireDirection()
  local direction = -1
  local projVel = Vector(0,0) --For storing the proper velocity of a projectile (calculated later)
  --local proj = nil --For storing a projectile when fired

  --Keep the scythe on the player
  scythe.Position = Vector(player.Position.X, player.Position.Y)
  scythe.Velocity = player.Velocity

  if swingDelay > 0 then --Decrement the swingdelay (if it exists)
    swingDelay = swingDelay - 1
  end

  --Spawn a tech x laser around Samael when he swings his scythe with that item acquired
  if player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
    if scythe.Target == nil then
      laserRingSpawned = false
    end
    if not laserRingSpawned and scytheState == 2 then
      local laser = player:FireTechXLaser(player.Position, Vector(0,0), 66):ToLaser()
      laser.Parent = scythe
      if laser.Variant ~= 2 then
        laser.Variant = 2
        laser.SpriteScale = Vector(0.5, 1)
      end
      laser.TearFlags = laser.TearFlags | 1<<36
      laser.CollisionDamage = laser.CollisionDamage*0.3
      scythe.Target = laser
      laserRingSpawned = true
    end
  end

  --Hide the scythe whenever it is "thrown" via the mom's knife synergy
  if hideScythe or isaacDying then
    scythe:GetSprite().Color = Color(0,0,0,0,0,0,0)
    swingDelay = 4
  else
    if player:HasCollectible(samaelDeadEye) and
       not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then --Set redness for deadEye boost

      scytheColor.RO = (deadEyeBoost/properDamage)/2
    end
    scythe:GetSprite().Color = scytheColor --Set colour
  end

  if hideScythe and not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then
    hideScythe = false
  end

  --scytheState 0 = Idle, not attacking
  --scytheState 1 = Ready/Charging, holding down an attack direction (holding up the scythe)
  --scytheState 2 = Swinging the scythe

  --READY ATTACK: When the player is holding down a fire direction, and the scythe is not on cooldown
  if fireDirection ~= -1 and swingDelay == 0 then
    if not canShoot or player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then
      if charge < chargeTime then --Make the scythe being held up, unless the projectile attack is charged...
        if scytheScale >= 1.5 then
          sprite:SetFrame("BigSwing", 0) --Play scythe swing animation
        else
          sprite:SetFrame("Swing", 0) --Play scythe swing animation
        end
      elseif charge == chargeTime then --If the player has been charging long enough to fire a projectile, flash red
        if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then
          if scytheScale >= 1.5 then
            sprite:Play("BigCharge", 1)
          else
            sprite:Play("Charge", 1)
          end
        end
      end
      if not hideScythe then
        charge = charge+1 --Add charge
      end
    else
      if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then
        charge = charge + 1 --Add charge
      end
      if scytheScale >= 1.5 then
        sprite:Play("BigIdle", 1)
      else
        sprite:Play("Idle", 1)
      end
    end

    if scytheState == 2 then --If previous attack was interrupted (due to fast attack rate)
      hitBox.Coins = -1 --Reset hitbox (explained more later)
      hitBox.CollisionDamage = 0
      SamaelMod:deadEyeFunc()
      if swing == 0 then --Switch 'swing' value (left or right swing)
        swing = 1
      else
        swing = 0
      end
    end

    scytheState = 1 --Scythe is ready, or charging
    lastDirection = fireDirection --Update with current attack direction
    direction = lastDirection --Current direction for rendering
  end


  --INITIATE ATTACK: When the player releases the fire direction, swing the scythe
  if fireDirection == -1  and scytheState == 1 then --or swingDelay > 0
    --if scytheState == 1 then --If player was holding up the scythe
      --If they were charging long enough to fire a projectile...
    if charge >= chargeTime and
       not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) and
       not player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then

      --Choose the velocity of the projectile based on the last fire direction before release
      if lastDirection == Direction.UP then
        projVel = Vector(0, (-1)*player.ShotSpeed*10)
      elseif lastDirection == Direction.DOWN then
        projVel = Vector(0, player.ShotSpeed*10)
      elseif lastDirection == Direction.LEFT then
        projVel = Vector((-1)*player.ShotSpeed*10, 0)
      elseif lastDirection == Direction.RIGHT then
        projVel = Vector(player.ShotSpeed*10, 0)
      end
      projVel = projVel:__add(player.Velocity) --Add the players velocity to the projectile's velocity

      scythe:PlaySound(133, 1, 0, false, 0.66) --Play the tech firing sound (albeit somewhat pitch shifted)

      local numTears = SamaelMod:getNumTears()

      if numTears == 0 then --0 actually means 1 in this case
        SamaelMod:fireScytheProjectile(projVel, 0, 0, 0) --Normal shot
      elseif numTears == 2 and not player:HasCollectible(CollectibleType.COLLECTIBLE_THE_WIZ) then --double shot
        if lastDirection == Direction.UP or lastDirection == Direction.DOWN then
          SamaelMod:fireScytheProjectile(projVel, 0, 8, 0)
          SamaelMod:fireScytheProjectile(projVel, 0, -8, 0)
        elseif lastDirection == Direction.LEFT or lastDirection == Direction.RIGHT then
          SamaelMod:fireScytheProjectile(projVel, 0, 0, 8)
          SamaelMod:fireScytheProjectile(projVel, 0, 0, -8)
        end
      else --triple shot and above
        local arc = 20 --how wide the projectiles disperse (this value is actually half of the total angle)
        local angle
        for i=1,numTears do --For each projectile
          angle = -arc+(arc*2)*((i-1)/(numTears-1)) --Firing angle of this particular projectile
          --Apply the wiz effect (widen the angle and split into two groups)
          if player:HasCollectible(CollectibleType.COLLECTIBLE_THE_WIZ) then
            if i <= numTears/2 then
              angle = angle - 25
            else
              angle = angle + 25
            end
          end
          SamaelMod:fireScytheProjectile(projVel, angle, 0,0) --Fire the projectile
        end
      end

      --Loki's Horns & Mom's Eye
      local lokiTriggered = false
      if player:HasCollectible(CollectibleType.COLLECTIBLE_LOKIS_HORNS) or
         player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_EYE) then

        math.randomseed(Isaac.GetFrameCount() + Game():GetFrameCount())
        local luck = math.floor(player.Luck)+2
        if luck < 1 then luck = 1 end

        if player:HasCollectible(CollectibleType.COLLECTIBLE_LOKIS_HORNS) then
          if luck > 9 then luck = 9 end

          if math.random(10-luck) == 1 then
            if lastDirection ~= Direction.UP then
              SamaelMod:fireScytheProjectile(Vector(0, (-1)*player.ShotSpeed*10):__add(player.Velocity), 0, 0,0) end
            if lastDirection ~= Direction.DOWN then
              SamaelMod:fireScytheProjectile(Vector(0, player.ShotSpeed*10):__add(player.Velocity), 0, 0,0) end
            if lastDirection ~= Direction.LEFT then
              SamaelMod:fireScytheProjectile(Vector((-1)*player.ShotSpeed*10, 0):__add(player.Velocity), 0, 0,0) end
            if lastDirection ~= Direction.RIGHT then
              SamaelMod:fireScytheProjectile(Vector(player.ShotSpeed*10, 0):__add(player.Velocity), 0, 0,0) end
            lokiTriggered = true
          end
        end
        if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_EYE) and not lokiTriggered then
          if luck > 4 then luck = 4 end

          if math.random(5-luck) == 1 then
            if lastDirection == Direction.UP then
              SamaelMod:fireScytheProjectile(Vector(0, player.ShotSpeed*10):__add(player.Velocity), 0, 0,0)
            elseif lastDirection == Direction.DOWN then
              SamaelMod:fireScytheProjectile(Vector(0, (-1)*player.ShotSpeed*10):__add(player.Velocity), 0, 0,0)
            elseif lastDirection == Direction.LEFT then
              SamaelMod:fireScytheProjectile(Vector(player.ShotSpeed*10, 0):__add(player.Velocity), 0, 0,0)
            elseif lastDirection == Direction.RIGHT then
              SamaelMod:fireScytheProjectile(Vector((-1)*player.ShotSpeed*10, 0):__add(player.Velocity), 0, 0,0)
            end
          end
        end
      end

    end

    lastCharge = charge
    charge = 0 --Reset charge
    if scytheScale >= 1.5 then
      sprite:Play("BigSwing", 1) --Play scythe swing animation
    else
      sprite:Play("Swing", 1) --Play scythe swing animation
    end

    --Choose fruit cake effect
    if player:HasCollectible(CollectibleType.COLLECTIBLE_FRUIT_CAKE) then
      math.randomseed(Isaac.GetFrameCount() + Game():GetFrameCount())
      fruitCakeEffect = cakeEffects[ math.random( #cakeEffects ) ]
    elseif fruitCakeEffect ~= "none" then
      fruitCakeEffect = "none"
    end

    --Godhead light ring
    if player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then
      local god = player:SpawnMawOfVoid(25):ToLaser()
      mawSoundCanceler = 3
      SamaelMod:playSound(133, 1, 1.3)
      god.CollisionDamage = player.Damage*0.3
      god:SetBlackHpDropChance(0)
      local godSprite = god:GetSprite()
      godSprite:Load("gfx/007.008_light ring.anm2", true)
      godSprite:Play("LargeRedLaser", true)
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIPHORA) then
      SamaelMod:epiphoraFunc() --Epiphora
    end

    swingDelay = SamaelMod:calcSwingDelay()+1 --Set new swing delay (+1 so as to not count this frame)

    scythe:PlaySound(38, 1.75, 0, false, 1.2) --Play swinging sound
    scytheState = 2 --Set state to 2 (swinging scythe)
    direction = lastDirection --Set render direction to the saved firing direction
  end


  --CURRENTLY SWINGING THE SCYTHE
  if scytheState == 2 then
    direction = lastDirection
  end
  --If scythe is swinging, and the animation is between the frames where the scythe can hit enemies
  if scytheState == 2 and sprite:GetFrame() >= 1 and sprite:GetFrame() <= 5 then
     --On the first hit frame, send the attack direction to the hitBox entity and set its collision damage
    if sprite:GetFrame() == 1 then
       --I'm using Coins to store this value because the actual Direction attributes for familiars
       --was crashing the game. Oh well!
      hitBox.Coins = lastDirection
      hitBox.CollisionDamage = player.Damage*scytheDamageMultiplier
      if player:HasCollectible(CollectibleType.COLLECTIBLE_LOST_CONTACT) then
        hitBox.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
      end
      if wraithActive and
         player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and
         not player:HasCollectible(CollectibleType.COLLECTIBLE_LIBRA) then

        hitBox.CollisionDamage = hitBox.CollisionDamage * 1.75
      end
      if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or
         player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) or
         player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then

        hitBox.CollisionDamage = hitBox.CollisionDamage * 1.5
      end
      if player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER) and math.random(25) == 1 then
        local flameSpeed = 10
        --Choose the velocity of the projectile based on the last fire direction before release
        if lastDirection == Direction.UP then
          projVel = Vector(0, -flameSpeed)
        elseif lastDirection == Direction.DOWN then
          projVel = Vector(0, flameSpeed)
        elseif lastDirection == Direction.LEFT then
          projVel = Vector(-flameSpeed, 0)
        elseif lastDirection == Direction.RIGHT then
          projVel = Vector(flameSpeed, 0)
        end
        projVel = projVel:__add(player.Velocity) --Add the players velocity to the projectile's velocity
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RED_CANDLE_FLAME, 0, player.Position, projVel, player)
      end
    end
    hitPos = hitBox.Position
    if sprite:GetFrame() == 5 then --After this duration, get rid of the hitbox
      hitPos = nil
      hitBox.Coins = -1 --"No direction"
      hitBox.CollisionDamage = 0 --Remove the collision damage (just making sure it cant hurt anything)
      hitBox.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
      SamaelMod:deadEyeFunc()
    end
  elseif scytheState == 2 and
         (sprite:IsFinished("Swing") or sprite:IsFinished("BigSwing")) then --If the swinging animation finished

    sprite.Rotation = 0
    scytheState = 0
    if swing == 0 then --Switch the swide of the scythe
      swing = 1
    else
      swing = 0
    end
  end

  if scytheState == 0 then --When nothing else is going on, idle state
    if scytheScale >= 1.5 then
      sprite:Play("BigIdle", 1)
    else
      sprite:Play("Idle", 1)
    end
    direction = headDirection
  end

  if dying then
    direction = Direction.DOWN
    if scytheScale >= 1.5 then
      sprite:Play("BigIdle", 1)
    else
      sprite:Play("Idle", 1)
    end
    hitBox.CollisionDamage = 0
  end

  scythe.RenderZOffset = 0
  --Render the scythe at the correct angle and whatnot depending on the direction
  if direction == Direction.DOWN then
    sprite.Rotation = 0
    scythe.RenderZOffset = 10
    scythe.Position = Vector(player.Position.X, player.Position.Y+2*scytheScale)
    --scythe.SpriteOffset = Vector(0,-4)
  elseif direction == Direction.UP then
    sprite.Rotation = 180
    scythe.Position = Vector(player.Position.X, player.Position.Y-20*scytheScale)
    --scythe.SpriteOffset = Vector(0,-10)
  elseif direction == Direction.LEFT then
    sprite.Rotation = 90
    scythe.Position = Vector(player.Position.X-10*scytheScale, player.Position.Y-6*scytheScale)
   -- scythe.SpriteOffset = Vector(-10,1)
  elseif direction == Direction.RIGHT then
    sprite.Rotation = -90
    scythe.Position = Vector(player.Position.X+10*scytheScale, player.Position.Y-6*scytheScale)
    --scythe.SpriteOffset = Vector(10,5)
  end

  --Flipping the scythe when needed (alternating swings)
  if swing == 0 then
    sprite.FlipX = false
  else
    sprite.FlipX = true
    if direction == Direction.RIGHT then
      sprite.Rotation = 90
      --scythe.SpriteOffset = Vector(10,-20)
    elseif direction == Direction.LEFT then
      sprite.Rotation = -90
      --scythe.SpriteOffset = Vector(-10,-17)
    end
  end

  --Scale the scythe
  if scytheScale >= 1.5 then
    scythe.Scale = scytheScale-(scytheScale/2) --Using big scythe sprite
  else
    scythe.Scale = scytheScale --Using small scythe sprite
  end

end

-----------Return the number of tears the player would normally fire
function SamaelMod:getNumTears()
  local player = Isaac.GetPlayer(0)

  local numTears = 0 --Count the number of projectiles needed (from multishot items)
  numTears = numTears + 2*player:GetCollectibleNum(CollectibleType.COLLECTIBLE_20_20)
  numTears = numTears + 3*player:GetCollectibleNum(CollectibleType.COLLECTIBLE_INNER_EYE)
  numTears = numTears + 4*player:GetCollectibleNum(CollectibleType.COLLECTIBLE_MUTANT_SPIDER)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_THE_WIZ) then
    numTears = numTears+2*player:GetCollectibleNum(CollectibleType.COLLECTIBLE_THE_WIZ)
    if numTears % 2 == 1 then --Need an even number with the wiz
      numTears = numTears+1
    end
  end
  return numTears
end

-----------Fire one of samael's unique scythe projectiles-----------
function SamaelMod:fireScytheProjectile(projVel, angle, XOffset, YOffset)
  local player = Isaac.GetPlayer(0)
  projVel = projVel:Rotated(angle) --Apply the angle (for multishot and such)
  local pos = Vector(player.Position.X + XOffset, player.Position.Y + YOffset) --Apply offsets

  if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then --Fire dr fetus bomb
    player:FireBomb(pos, projVel)
  else --Fire scythe projectile
    local proj = player:FireTear(pos, projVel, true, false, true) --Fire the tear
    proj = proj:ToTear()
    local var = proj.Variant
    if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then
      proj:ChangeVariant(8)
    else
      --Exclude certain special tears(teeth,boogers,etc)
      if var~=2 and var~=26 and var~=27 and var~=28 and var~=30 and var~=31 and
         not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then

        proj:ChangeVariant(projVariant) --Change to custom scythe projectile
      elseif player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then
        proj:SetColor(Color(0,0,0,255,0,0,0), 999,999,false,false)
      else
        proj.Scale = proj.Scale*1.5
      end
      proj.TearFlags = proj.TearFlags | 1 << 1 --Add Piercing
      proj.TearFlags = proj.TearFlags | 1 --Add Spectral
      proj.SpriteScale = Vector(proj.Scale,proj.Scale) --Set proper size
    end
    proj.CollisionDamage = proj.CollisionDamage*scytheProjectileDamageMultiplier --Set new tear damage
    if player:HasCollectible(samaelChocMilk) then
      local chocBoost = math.min(charge/chargeTime, 3)
      proj.CollisionDamage = proj.CollisionDamage*chocBoost
      proj.Scale = math.max(proj.Scale, proj.Scale*chocBoost*(2/3))
    end
  end

end

----Custom deadeye functionality (increases damage every time a scythe swing hits something;
----bonus is lost when a swing misses----
function SamaelMod:deadEyeFunc()
  local player = Isaac.GetPlayer(0)
  if player:HasCollectible(samaelDeadEye) then
    if hits > 0 then
      if deadEyeBoost < properDamage*2 then
        --Add to deadEyeBoost to keep track of how much damage has been added by this effect
        deadEyeBoost = deadEyeBoost+properDamage*0.2
        player.Damage = player.Damage+properDamage*0.2 --Add damage
      end
    else
      player.Damage = player.Damage - deadEyeBoost --Revert damage to original value
      deadEyeBoost = 0
    end
  end
  hits = 0
end

-------Custom epiphora functionality (increased attack rate for attacking in the same direction repeatedly)-------
function SamaelMod:epiphoraFunc()
  if lastEpiphoraDirection == lastDirection then
    epiphoraCounter = epiphoraCounter + 1 --Add to counter
  else
    epiphoraCounter = 0
  end
  lastEpiphoraDirection = lastDirection
end

-----------Add colours to the scythe, if certain items are collected-----------
function SamaelMod:getScytheColor()
  local player = Isaac.GetPlayer(0)
  local color = Color(1,1,1,1,0,0,0)
  local red = {
    player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_MARTYR),
    player:HasCollectible(CollectibleType.COLLECTIBLE_CHEMICAL_PEEL),
    player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT),
    player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_CONTACTS),
    player:HasCollectible(CollectibleType.COLLECTIBLE_PACT),
    player:HasCollectible(CollectibleType.COLLECTIBLE_ABADDON),
    player:HasCollectible(CollectibleType.COLLECTIBLE_TOOTH_PICKS),
    player:HasCollectible(CollectibleType.COLLECTIBLE_STIGMATA),
  }
  local green = {
    player:HasCollectible(CollectibleType.COLLECTIBLE_SCORPIO),
    player:HasCollectible(CollectibleType.COLLECTIBLE_COMMON_COLD),
    player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC),
    player:HasCollectible(CollectibleType.COLLECTIBLE_SERPENTS_KISS),
    player:HasCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID),
  }
  local yellow = {
    player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE),
    player:HasCollectible(CollectibleType.COLLECTIBLE_SULFURIC_ACID),
    player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_PERFUME),
  }
  local orange = {
    player:HasCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND),
    player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_ONION),
    player:HasCollectible(CollectibleType.COLLECTIBLE_PARASITE),
    player:HasCollectible(samaelChocMilk),
  }
  --local purple = {player:HasCollectible(CollectibleType.COLLECTIBLE_SPOON_BENDER)}
  --local pink = {player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_EYESHADOW)}

  if threeDollarBillEffect == "fire" then table.insert(orange, true) end
  if threeDollarBillEffect == "poison" or threeDollarBillEffect == "creep" then table.insert(green, true) end
  if threeDollarBillEffect == "freeze" then table.insert(red, true) end
  if threeDollarBillEffect == "pee" then table.insert(yellow, true) end

  for i = 1, #red do
    if red[i] then
      color.R = color.R+0.8
    end
  end
  for i = 1, #green do
    if green[i] then
      color.G = color.G+1.5
    end
  end
  for i = 1, #yellow do
    if yellow[i] then
      color.R = color.R+1.5
      color.G = color.G+1.5
    end
  end
  for i = 1, #orange do
    if orange[i] then
      color.R = color.R+2
      color.G = color.G+1
    end
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SPOON_BENDER) then
    color.R = color.R+2
    color.B = color.B+2
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_EYESHADOW) or threeDollarBillEffect == "charm" then
    color.R = color.R+2
    color.B = color.B+1
  end

  --Normalize colour
  local max = math.max(color.R, color.G, color.B)
  local min = math.min(color.R-1, color.G-1, color.B-1)
  color.R = (color.R-min)/(max-min)
  color.G = (color.G-min)/(max-min)
  color.B = (color.B-min)/(max-min)

  --Lighten
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SACRED_HEART) then
    color.R = color.R + 0.5
    color.B = color.B + 0.5
    color.G = color.G + 0.5
  --Darken
  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_DARK_MATTER) or
         player:HasCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA) or
         threeDollarBillEffect == "fear" then

    color.R = color.R * 0.2
    color.B = color.B * 0.2
    color.G = color.G * 0.2
  --Darken less
  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_ONION) or
         player:HasCollectible(samaelChocMilk) or
         threeDollarBillEffect == "slow" then

    color.R = color.R * 0.5
    color.B = color.B * 0.5
    color.G = color.G * 0.5
  end

  scytheColor = color
end

-----------Play sound using dummy NPC if needed-----------
function SamaelMod:playSound(ID, volume, pitch)
  local sfx = SFXManager()
  sfx:Play(ID, volume, 0, false, pitch) -- (SoundEffect ID, float Volume, integer FrameDelay, boolean Loop, float Pitch)
end

-----------On player init (start/continue)-----------
function SamaelMod:PostPlayerInit(player)
  if player:GetPlayerType() ~= samaelID then --If the player is Samael
    return
  end

  -- Add Costumes
  player:AddNullCostume(cloak)
  player:AddNullCostume(hood)
  costumeEquipped = true

  numItems = -1
  swing = 0

  player.FireDelay = 5
  wraithTime = 0
  wraithActive = false
  charge = 0
  wraithCharge = 0 -- Just set it to 0, we don't care about keeping track of it between runs
end

-----------Cache update function for handling charge time and some damage stuff-----------
function SamaelMod:cacheUpdate(player, cacheFlag)
  if player:GetPlayerType() ~= samaelID then
    return
  end

  --Isaac.DebugString("Cache updating for: " .. tostring(cacheFlag))

  SamaelMod:calcChargeTime()
  SamaelMod:getScytheColor()

  --Allow or disable normal firing depending on items
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) or
     (player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) and
      not player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS)) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then

    canShoot = true
  else
    canShoot = false
  end

  if cacheFlag == CacheFlag.CACHE_RANGE then
    if player:HasCollectible(samaelMarked) then
      player.TearHeight = player.TearHeight - 3.15
    end
  end
  scytheScale = math.max(math.min((player.TearHeight * (-1)) / 23.75, 2), 1)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_PUPULA_DUPLEX) then
    scytheScale = math.max(math.min(scytheScale + 0.33, 2), 1)
  end

  if cacheFlag == CacheFlag.CACHE_DAMAGE then
    player.Damage = player.Damage + 1

    --Increase damage for having certain items (Chemical Peel, Blood Clot, Peircing tears, etc)
    for i = 1, #itemChecks do
      if itemChecks[i] > 0 then
        player.Damage = player.Damage + itemChecks[i]
      end
    end

    if player:HasCollectible(samaelDrFetus) then --damage boost when Brimstone overrides Dr Fetus
      player.Damage = player.Damage * 1.5
    end

    -- Mom's Knife nerf
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then -- 114
      player.Damage = player.Damage / 1.25
    end

    properDamage = player.Damage --Save proper damage stat
    deadEyeBoost = 0
  end

  if cacheFlag == CacheFlag.CACHE_SPEED then
    if player:HasCollectible(CollectibleType.COLLECTIBLE_PONY) == false and -- 130
       player:HasCollectible(CollectibleType.COLLECTIBLE_WHITE_PONY) == false then -- 181

      player.MoveSpeed = player.MoveSpeed - 0.15
      --Isaac.DebugString("Decreased speed in the speed cache for Samael: " .. tostring(player.MoveSpeed))
    end
    if wraithActive then
      player.MoveSpeed = player.MoveSpeed + 0.3
      --Isaac.DebugString("Increased speed in the speed cache for Samael (wraithActive): " ..
                          --tostring(player.MoveSpeed))
    end
  end

  if cacheFlag == CacheFlag.CACHE_FIREDELAY then
    if player:HasCollectible(samaelMarked) then
      player.MaxFireDelay = player.MaxFireDelay - math.ceil(player.MaxFireDelay / 8)
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) and
       not player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then

      fireDelayReduced = true
      fireDelayPenalty = math.min(player.MaxFireDelay*1.5, 30)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) and
           player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then

      fireDelayReduced = false
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
      fireDelayReduced = true
      fireDelayPenalty = math.min(player.MaxFireDelay*0.75, 25)
    else
      fireDelayReduced = false
    end
    if fireDelayReduced then player.MaxFireDelay = math.ceil(player.MaxFireDelay+fireDelayPenalty) end
  end

  if player:HasCollectible(442) then -- Dark Princes Crown
    if player:GetHearts() == 2 and cacheFlag == CacheFlag.CACHE_FIREDELAY then
      player.MaxFireDelay = math.ceil(player.MaxFireDelay*0.666)
    end
    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_DARK_PRINCESS_CROWN) and -- 442
     player:GetHearts() == 2 and
     cacheFlag == CacheFlag.CACHE_DAMAGE then

    player.Damage = player.Damage*1.666
  end
end

-----------Calculate # of frames needed to charge up a projectile-----------
function SamaelMod:calcChargeTime()
  local player = Isaac.GetPlayer(0)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and
     not player:HasCollectible(CollectibleType.COLLECTIBLE_LIBRA) then

    chargeTime = 1
    return
  end
  if player.MaxFireDelay < chargeTimeMax then --Calculate charge time (Parabola! Because why not)
    local x = player.MaxFireDelay
    local min = chargeTimeMin
    local mid = chargeTimeMid
    local max = chargeTimeMax
    --Using formulas to fit a parabola to three points
    local a = (mid*max - min*(max-10) - max*10)/((-1)*max*max*10+100*max)
    local b = (mid-min-a*(100))/10
    --local c = min
    chargeTime = math.floor(a*x*x + b*x + min) -- y = ax^2 + bx + c
  else
    chargeTime = chargeTimeMax --Cap chargetime
  end
end

-----------Calculate delay between scythe swings-----------
function SamaelMod:calcSwingDelay()
  local player = Isaac.GetPlayer(0)
  local delay = player.MaxFireDelay
  --Negate certain tears down effects for melee swings
  if fireDelayReduced then
    delay = delay-fireDelayPenalty
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then

    delay = (delay-3)/2.1
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and
     not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then

    delay = delay/3
  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) and
         not player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) and
         not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then

    delay = delay/4
  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) and
         player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then

    delay = delay/3
  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
    delay = delay/2.5
  end

  if delay > swingDelayCap then --Cap the swing delay
    delay = swingDelayCap
  end
  if wraithActive and wraithCooldown == 0 then --Swing delay is halved in wraith mode
    delay = delay*0.5
  end
  if threeDollarBillEffect == "pee" then
    delay = delay*0.5
  end

  for i = 1, math.min(epiphoraCounter, 8) do
    delay = delay - delay*(1/16)
  end

  delay = math.floor(delay)
  if delay < 1 then delay = 1 end

  return delay
end

-----------Callback function for the Scythe's hitbox (Its an invisible sacrificial dagger)-----------
function SamaelMod:hitBoxFunc(hitBox)
  -- Local variables
  local player = Isaac.GetPlayer(0)
  local character = player:GetPlayerType()

  if hitBox.Variant ~= FamiliarVariant.SACRIFICIAL_DAGGER or
     hitBox.SubType ~= hitBoxType then --If its the right entity

    return
  end

  if hitBox.Parent == nil or
     character ~= samaelID or
     dying then

    hitBox:Remove()
    return
   end

  hitBox.Size = 40 * scytheScale

  --Put it in the correct position, depending on the direction passed to it
  if hitBox.Coins == Direction.UP then
    hitBox.Position = Vector(player.Position.X, player.Position.Y - 45 * scytheScale)
  elseif hitBox.Coins == Direction.DOWN then
    hitBox.Position = Vector(player.Position.X, player.Position.Y + 35 * scytheScale)
  elseif hitBox.Coins == Direction.LEFT then
    hitBox.Position = Vector(player.Position.X - 40 * scytheScale, player.Position.Y)
  elseif hitBox.Coins == Direction.RIGHT then
    hitBox.Position = Vector(player.Position.X + 40 * scytheScale, player.Position.Y)
  else --If direction is -1, go offscreen
    hitBox.Position = Vector(0, 0)
  end

  hitBox.Velocity = Vector(0, 0)

  --Destroy poop
  if hitBox.Coins ~= -1 then
    local room = Game():GetLevel():GetCurrentRoom()
    local index = room:GetGridIndex(hitBox.Position) --Get grid index of hitBox's position
    local indexes = { --Array of that index and adjacent tiles
      index, index+1, index-1, index+room:GetGridWidth(), index-room:GetGridWidth(),
    }
    for i = 1, 5 do
      if player:HasCollectible(CollectibleType.COLLECTIBLE_SULFURIC_ACID) then
        room:DestroyGrid(indexes[i], 1) --Destroy rocks and poop on these tiles if the player has sulfuric acid
      else
        room:DamageGrid(indexes[i], 1) --Damage poop in any of these tiles
      end
    end
  end
end

-----------Damage callback for the player taking damage-----------
function SamaelMod:playerDamage(tookDamage, damage, damageFlags, damageSourceRef)
  --Resist all damage in wraith mode except for things like the IV bag or Razor
  if wraithActive and (damageFlags & DamageFlag.DAMAGE_RED_HEARTS) == 0 then
    return false
  end
end

-----------Damage callback for scythe hits/scythe projectiles-----------
function SamaelMod:scytheHits(tookDamage, damage, damageFlags, damageSourceRef)
  local player = Isaac.GetPlayer(0)
  --info = damageSourceRef.Type
  if ((damageSourceRef ~= nil and damageSourceRef.Entity ~= nil) or
      (damageSourceRef.Entity == nil and (damageFlags & DamageFlag.DAMAGE_LASER) ~= 0)) and
     player:GetPlayerType() == samaelID and
     tookDamage.Type ~= EntityType.ENTITY_PLAYER then

    local damageSource
    if damageSourceRef.Entity ~= nil then
      damageSource = damageSourceRef.Entity
    else
      damageSource = Isaac.GetPlayer(0)
    end
    local damType = damageSource.Type

    --New Wraith meter charging code
    if damType == EntityType.ENTITY_FAMILIAR or
       damType == EntityType.ENTITY_KNIFE or
       damType == EntityType.ENTITY_TEAR or
       damType == EntityType.ENTITY_PLAYER and
       tookDamage:IsVulnerableEnemy() and
       lastFrameWraithCharge == wraithCharge then

      if wraithChargeCooldown == 0 then
        if damType == EntityType.ENTITY_FAMILIAR and
           damageSource.Variant == FamiliarVariant.SACRIFICIAL_DAGGER and
           damageSource.SubType == hitBoxType then

          local addCharge = math.min(player.MaxFireDelay * 0.2, 20)
          wraithCharge = wraithCharge + addCharge
          --Isaac.DebugString("Added wraithCharge from #1: " .. tostring(addCharge))
        else
          local addCharge = math.min(math.max(player.MaxFireDelay, 1), 20)
          wraithCharge = wraithCharge + addCharge
          --Isaac.DebugString("Added wraithCharge from #2: " .. tostring(addCharge))
        end
        wraithChargeCooldown = player.MaxFireDelay
        wraithChargePenalty = 3
      else
        local addCharge = math.min(damage, 20) / wraithChargePenalty
        wraithCharge = wraithCharge + addCharge
        wraithChargePenalty = wraithChargePenalty + 2
        --Isaac.DebugString("Added wraithCharge from #3 damage: " .. tostring(addCharge))
      end
    end
    if damType == EntityType.ENTITY_FAMILIAR and
       damageSource.Variant == FamiliarVariant.SACRIFICIAL_DAGGER and
       damageSource.SubType == hitBoxType and tookDamage:IsVulnerableEnemy() then

      --damageSource = damageSource:ToFamiliar()
      tookDamage = tookDamage:ToNPC()
      --local sprite = damageSource.Parent:GetSprite()
      Isaac.Spawn(1000, 2, 0, tookDamage.Position, Vector(0, 0), tookDamage) --Blood effect
      tookDamage:PlaySound(77, 0.75, 0, false, 1.8) --Play hit sound

      --Get knockback bonus from items
      local knockBackBonus = 0
      if player:HasCollectible(CollectibleType.COLLECTIBLE_PISCES) then
        knockBackBonus = knockBackBonus + 1.5
      end
      if player:HasCollectible(CollectibleType.COLLECTIBLE_8_INCH_NAILS) then
        knockBackBonus = knockBackBonus + 1.5
      end
      if player:HasTrinket(TrinketType.TRINKET_BLISTER) then
        knockBackBonus = knockBackBonus + 1.5
      end
       --"Push" the enemy away from the player (knockback)
       local vel = tookDamage.Position:__sub(player.Position):Normalized():__mul(knockbackMagnitude+knockBackBonus)
      tookDamage:AddVelocity(vel)

      --Status condition stuff
      math.randomseed(Isaac.GetFrameCount() + Game():GetFrameCount())
      local luck = math.floor(player.Luck)
      if luck < 1 then luck = 1
      elseif luck > luckCap then luck = luckCap end

      if threeDollarBillEffect == "fire" or fruitCakeEffect == "fire" or (player.TearFlags & 1<<22) ~= 0 then --Burn
        tookDamage:AddBurn(damageSourceRef, 80, 5)
      end
      if fruitCakeEffect == "poison" or
         threeDollarBillEffect == "poison" or
         (player.TearFlags & 1<<4) ~= 0 or
         (player.TearFlags & 1<<12) ~= 0 or
         ((player:HasCollectible(103) or
           player:HasCollectible(393)) and
          math.random(luckCap+1-luck) == 1) then --Poison

        tookDamage:AddPoison(damageSourceRef, 80, 5)
      end
      if fruitCakeEffect == "slow" or
         (player.TearFlags & 1<<3) ~= 0 or
         ((player:HasCollectible(231) or
           player:HasCollectible(89) or
           threeDollarBillEffect == "slow") and
          math.random(luckCap+1-luck) == 1) then --Slow

        tookDamage:AddSlowing(damageSourceRef, 125, 2, Color(0.3,0.3,0.3,1,0,0,0))
      end
      if fruitCakeEffect == "freeze" or
         (player.TearFlags & 1<<5) ~= 0 or
         ((player:HasCollectible(110) or
           threeDollarBillEffect == "freeze") and
          math.random(luckCap+1-luck) == 1) then --Freeze

        tookDamage:AddFreeze(damageSourceRef, 80)
      end
      if fruitCakeEffect == "charm" or
         (player.TearFlags & 1<<13) ~= 0 or
         ((player:HasCollectible(200) or threeDollarBillEffect == "charm") and
         math.random(luckCap+1-luck) == 1) then --Charm

        tookDamage:AddCharmed(80)
      end
      if fruitCakeEffect == "confuse" or
         (player.TearFlags & 1<<14) ~= 0 or
         ((player:HasCollectible(201) or
           threeDollarBillEffect == "confuse") and
          math.random(luckCap+1-luck) == 1) then --Confuse

        tookDamage:AddConfusion(damageSourceRef, 80, false)
      end
      if fruitCakeEffect == "shrink" or
         (player.TearFlags & 1<<41) ~= 0 or
         (player:HasCollectible(398) and math.random(luckCap+1-luck) == 1) then --Shrink

        tookDamage:AddShrink(damageSourceRef, 80)
      end
      if fruitCakeEffect == "fear" or
         (player.TearFlags & 1<<20) ~= 0 or
         ((player:HasCollectible(228) or
           player:HasCollectible(230) or
           player:HasCollectible(259) or
           threeDollarBillEffect == "fear") and
          math.random(luckCap+1-luck) == 1) then --Fear

        tookDamage:AddFear(damageSourceRef, 80)
      end
      if (fruitCakeEffect == "greed" or
          player:HasCollectible(CollectibleType.COLLECTIBLE_EYE_OF_GREED)) and
         math.random(luckCap+1-luck) == 1 then --Eye of Greed

        tookDamage:AddMidasFreeze(damageSourceRef, 80)
      end

      if (fruitCakeEffect == "light" and math.random(2)==1) or
         (math.random(luckCap+1-luck)==1 and
          player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT)) then --Holy Light

        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0,
                    Isaac.GetFreeNearPosition(tookDamage.Position, tookDamage.Size), Vector(0,0), player)
      end
      if (threeDollarBillEffect == "creep" or
          fruitCakeEffect == "creep" or
          player:HasCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID)) and
         math.random(2) == 1 then --Mysterious Liquid

        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_GREEN, 0,
                    Isaac.GetFreeNearPosition(tookDamage.Position, tookDamage.Size), Vector(0,0), player)
      end
      if (fruitCakeEffect == "keeper" or
          player:HasCollectible(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER)) and
          math.random(luckCap+1-luck) == 1 then --Head of the Keepo

        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY,
                    Isaac.GetFreeNearPosition(tookDamage.Position, tookDamage.Size), Vector(0, 0), nil)
      end

      --Flies and spiders (guppy, mulligan, parisitoid)
      if player:HasPlayerForm(PlayerForm.PLAYERFORM_GUPPY) then
        player:AddBlueFlies(1, player.Position, tookDamage)
      elseif player:HasCollectible(CollectibleType.COLLECTIBLE_MULLIGAN) and math.random(6) == 1 then
        player:AddBlueFlies(1, player.Position, tookDamage)
      end
      if fruitCakeEffect == "fly" or
         (player:HasCollectible(CollectibleType.COLLECTIBLE_PARASITOID) and math.random(luckCap+1-luck) == 1) then
        if math.random(2) == 1 then
          player:AddBlueSpider(player.Position)
        else
          player:AddBlueFlies(1, player.Position, tookDamage)
        end
      end

      --Euthanasia
      if player:HasCollectible(CollectibleType.COLLECTIBLE_EUTHANASIA) and
         not tookDamage:IsBoss() and math.random(luckCap+1-luck) == 1 then

        local s = 10
        local directions = {
          Vector(-s, -s),
          Vector(-s, s),
          Vector(s, -s),
          Vector(s, s),
          Vector(0,-s*1.5),
          Vector(-s*1.5, 0),
          Vector(s*1.5, 0),
          Vector(0, s*1.5),
        }
        for i = 1, #directions do
          local needleTear = player:FireTear(tookDamage.Position, directions[i], false, true, false)
          needleTear:ChangeVariant(TearVariant.NEEDLE)
        end
        tookDamage:Kill()
      end

      --Little Horn
      if player:HasCollectible(CollectibleType.COLLECTIBLE_LITTLE_HORN) and
         not tookDamage:IsBoss() and math.random(luckCap+1-luck) == 1 then

        tookDamage:Kill()
      end

      local parasiteTear = 0
      --Split tears
      if player:HasCollectible(CollectibleType.COLLECTIBLE_PARASITE) or
         player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY) or
         player:HasCollectible(CollectibleType.COLLECTIBLE_COMPOUND_FRACTURE) then

        if not parasiteTriggered then
          parasiteTear = player:FireTear(tookDamage.Position, Vector(8,0):Rotated(math.random(360)),
                                         false, true, true):ToTear() --Fire the tear
          parasiteTear.CollisionDamage = parasiteTear.CollisionDamage*0.5
          parasiteTear.Scale = 0.66
          parasiteTear.Mass = 0
          parasiteTear.TearFlags = parasiteTear.TearFlags | 1 << 1 --Add piercing
          parasiteTriggered = true
        else
          parasiteTriggered = false
        end
      end
      --Jacob's ladder
      if (player:HasCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) and
          (parasiteTear == 0 or fruitCakeEffect == "shock")) or
         fruitCakeEffect == "shock" then

        if not jacobTriggered then
          local jacobTear = player:FireTear(tookDamage.Position, Vector(0,0):Rotated(math.random(360)),
                                            false, true, true):ToTear() --Fire the tear
          jacobTear.TearFlags = 1 << 53 --Add piercing
          jacobTear.CollisionDamage = 0.0
          jacobTear.Mass = 0
          jacobTear.Visible = false
          jacobTear:SetColor(Color(0,0,0,0,0,0,0), 999, 999, false, false)
          jacobTriggered = true
        else
          jacobTriggered = false
        end
      end

      hits = hits + 1
    elseif damageSource.Type == EntityType.ENTITY_FAMILIAR and tookDamage:IsVulnerableEnemy() then
      local addCharge = math.max(math.min(damage, tookDamage.HitPoints) * 0.33, 1)
      if addCharge > 20 then
        addCharge = 20
      end
      wraithCharge = wraithCharge + addCharge
      --Isaac.DebugString("Added wraithCharge from #4: " .. tostring(addCharge))
    end
    if wraithCharge > 100 then
      wraithCharge = 100
    end
  end
end

-----------Special animation effects-----------
function SamaelMod:specialAnimFunc(npc)
  local sprite = npc:GetSprite()
  local player = Isaac.GetPlayer(0)
   --Trigger the blood splatter effect for death animation
  if sprite:IsPlaying("Death") and
     sprite:IsEventTriggered("Blood") then

    Isaac.Spawn(1000, 77, 0, npc.Position, Vector(0, 0), npc)
    npc:PlaySound(28, 1, 0, false, 1)
    npc:MakeSplat(5.0)
  elseif sprite:IsPlaying("WraithDown") or
         sprite:IsPlaying("WraithUp") or
         sprite:IsPlaying("WraithLeft") or
         sprite:IsPlaying("WraithRight") then --Wraith mode

    if not wraithActive or wraithCooldown > 0 or player:GetSprite():IsPlaying("Trapdoor") then
      npc:Remove()
      return
    end
    npc.Position = player.Position
    npc.Velocity = player.Velocity
    local dir = player:GetHeadDirection()
    if not sprite:IsPlaying("WraithDown") and (dir == Direction.DOWN or dir == Direction.NO_DIRECTION) then
      sprite:Play("WraithDown", 1)
    elseif not sprite:IsPlaying("WraithUp") and dir == Direction.UP then
      sprite:Play("WraithUp", 1)
    elseif not sprite:IsPlaying("WraithLeft") and dir == Direction.LEFT then
      sprite:Play("WraithLeft", 1)
    elseif not sprite:IsPlaying("WraithRight") and dir == Direction.RIGHT then
      sprite:Play("WraithRight", 1)
    end
  end
end

------The only function that loops through every entity in the room.
------I tried to limit this mod to only do this once per update------
function SamaelMod:roomEntitiesLoop()
  local player = Isaac.GetPlayer(0)

  if player:GetPlayerType() ~= samaelID then
    return
  end

  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if (entity.Type == EntityType.ENTITY_FIREPLACE or
        entity.Type == EntityType.ENTITY_MOVABLE_TNT) and hitPos ~= nil then

      --Break fireplaces with scythe
      if entity.Position:Distance(hitPos) <= 55*scytheScale then
        entity:TakeDamage(player.Damage, 0, EntityRef(player), 5)
      end

    elseif entity.Type == EntityType.ENTITY_LASER then
      --custom techX stuff
      if entity.Parent == nil then
        entity:Remove()
      elseif entity.Parent.Type == scytheID then
        if scytheState ~= 2 then
          entity:Remove()
        else
          entity.Position = player.Position
          entity.Velocity = player.Velocity
        end
      elseif entity.Parent.Type == EntityType.ENTITY_BOMBDROP then
        entity.Position = entity.Parent.Position
        entity.Velocity = entity.Parent.Velocity
      end

    elseif entity.Type == EntityType.ENTITY_TEAR and
           entity.Variant == projVariant and
           not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then

      --Keep the size of the scythe projectiles consistent whenever it might change (proptosis, lump of coal, etc)
      entity = entity:ToTear()
      entity.SpriteScale = Vector(entity.Scale, entity.Scale)

    elseif entity.Type == EntityType.ENTITY_TEAR  then
      entity = entity:ToTear()
      local sprite = entity:GetSprite()
      if (entity.TearFlags & 1<<55) ~= 0 and sprite:GetFilename() ~= "gfx/samael_scythe_projectile.anm2" then
        --entity:ChangeVariant(8)
        sprite:Load("gfx/samael_scythe_projectile.anm2", true)
        sprite:Play("Idle", true)
        entity.SpriteScale = Vector(entity.Scale*0.75, entity.Scale*0.75)
      end
    elseif entity.Type == EntityType.ENTITY_KNIFE and
           (entity.SubType == 0 or entity.SubType == 1) and
           (entity.Parent.Type == EntityType.ENTITY_PLAYER or
            entity.Parent.Type == EntityType.ENTITY_KNIFE) then

      --Handling knives
      SamaelMod:knifeUpdate(entity:ToKnife())

    elseif entity.Type == EntityType.ENTITY_KNIFE and
           not entity.Parent.Parent == nil and
           entity.Parent.Parent.Type == EntityType.ENTITY_PLAYER and
           entity.Variant ~= 617 then

      entity = entity:ToKnife()
      entity:GetSprite():Load("gfx/samael_scythe_knife.anm2", true)
      entity:GetSprite():Play("Hidden", true)
      entity.Variant = 617
      if hideScythe then
        entity.SizeMulti = Vector(4*scytheScale,4*scytheScale)
        entity.SpriteScale = Vector(scytheScale,scytheScale)
      else
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
      end
    end
  end
end

-----------Readd costumes after rerolling-----------
function SamaelMod:postReroll()
  local player = Isaac.GetPlayer(0)
  if player:GetPlayerType() == samaelID then
    player:AddNullCostume(cloak)
    player:AddNullCostume(hood)
  end
end

-----------Wraith Skull item-----------
function SamaelMod:activateWraith()
  local player = Isaac.GetPlayer(0)

  wraithActivationCooldown = 280

  if player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT) then
    player:UseActiveItem(CollectibleType.COLLECTIBLE_CRACK_THE_SKY, false, false, false, false)
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_CURSE_OF_THE_TOWER) then
    player:UseActiveItem(CollectibleType.COLLECTIBLE_ANARCHIST_COOKBOOK, false, false, false, false)
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_VARICOSE_VEINS) then
    player:UseActiveItem(CollectibleType.COLLECTIBLE_TAMMYS_HEAD, false, false, false, false)
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_ATHAME) or
     player:HasCollectible(CollectibleType.COLLECTIBLE_MAW_OF_VOID) then

    player:SpawnMawOfVoid(100)
  end

  if player:HasCollectible(CollectibleType.COLLECTIBLE_BLACK_POWDER) then
    local pentagram = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PENTAGRAM_BLACKPOWDER, 0,
                                  player.Position, Vector(0,0), player):ToEffect()
    pentagram.State = 1
    pentagram.Size = 150
    pentagram.SpriteScale = Vector(0.75,0.75)
  end

  wraithActive = true
  wraithCharge = 0
  wraithTime = 100
  player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
  SamaelMod:playSound(33, 1, 1.1)
  player.MoveSpeed = player.MoveSpeed + 0.3
  --Isaac.DebugString("Increased speed from the Wraith ability being activated: " .. tostring(player.MoveSpeed))

  --Black poof effect
  local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 0,
                           player.Position, Vector(0, 0), player):ToEffect()
  poof:GetSprite().Color = Color(0, 0, 0, 0.66, 0, 0, 0)
  poof:FollowParent(player)

  --Special animation
  player:GetSprite().Color = Color(0, 0, 0, 0, 0, 0, 0)
  local special = Isaac.Spawn(specialAnim, 0, 0,
                              player.Position, Vector(0, 0), player):ToNPC() --Spawn the special animations entity
  special:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
  special:GetSprite():Play("WraithDown", 1) --Wraith form animation
  special:GetSprite().Color = Color(0.75,0.25,0.25,0.8,0,0,0)
  special.CanShutDoors = false
  special.Scale = player.SpriteScale.X
end

-----------Replacing knives with scythes-----------
function SamaelMod:knifeUpdate(knife)
  local sprite = knife:GetSprite()
  local player = Isaac.GetPlayer(0)

  if sprite:GetFilename() ~= "gfx/samael_scythe_knife.anm2" then --Replace the sprite
    sprite:Load("gfx/samael_scythe_knife.anm2", true)
    if scytheScale >= 1.5 then
      sprite:Play("Big", true)
    else
      sprite:Play("Idle", true)
    end
    knife.Variant = 617
    knife.SizeMulti = Vector(4, 4)
  end

  if knife.Variant == 617 and knife.SubType == 0 then
    --knife.SizeMulti = Vector(4 * scytheScale, 4 * scytheScale)
    knife.SizeMulti = Vector(1.5 * scytheScale, 1.5 * scytheScale)
    if scytheScale >= 1.5 then
      local X = scytheScale - (scytheScale / 2)
      X = X / 1.25
      local Y = scytheScale - (scytheScale / 2)
      Y = Y / 1.25
      knife.SpriteScale = Vector(X, Y)
    else
      --knife.SpriteScale = Vector(scytheScale, scytheScale)
      knife.SpriteScale = Vector(scytheScale / 1.25, scytheScale / 1.25)
    end

    if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
      --Only enable the knife-scythe when thrown (requires charging for at least 5 frames)
      if (knife:IsFlying() or knife.Parent.Type == EntityType.ENTITY_KNIFE) and
         not (sprite:IsPlaying("Idle") or sprite:IsPlaying("Big")) and
         lastCharge > 5 then

        knife.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
        if scytheScale >= 1.5 then
          sprite:Play("Big", true)
        else
          sprite:Play("Idle", true)
        end
        hideScythe = true

      elseif not (knife:IsFlying() or knife.Parent.Type == EntityType.ENTITY_KNIFE) and
             (sprite:IsPlaying("Idle") or sprite:IsPlaying("Big")) then

        --Hide and disable the knife-scythe when not thrown
        sprite:SetFrame("Hidden", 0)
        knife.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        hideScythe = false
      end
    end
    scytheColor = sprite.Color
  end
end

function SamaelMod.PostGameStartedReset()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  SamaelMod.SacDaggerAcquired = false

  wraithActive = false
  wraithCooldown = 0
  wraithTime = 0
  wraithCharge = 0

  numItems = -1
  itemChecks = {}

  if character == samaelID then
    player:AddCacheFlags(CacheFlag.CACHE_ALL) -- 0xFFFFFFFF
    player:EvaluateItems()
  end

  --Isaac.DebugString("Cleared all Samael variables.")
end

function SamaelMod:PostUpdateFixBugs()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Judas Shadow + Wraith Skull bug
  if character ~= samaelID then
    if player:HasCollectible(wraithItem) then
      player:RemoveCollectible(wraithItem)
      Isaac.DebugString("Removed the Wraith Skull since we are not on Samael anymore.")
    end
    if RPGlobals.run.schoolbag.item == wraithItem then
      RPGlobals.run.schoolbag.item = 0
      RPSchoolbag.sprites.item = nil
      Isaac.DebugString("Removed the Wraith Skull (from the Schoolbag) since we are not on Samael anymore.")
    end

    return
  end

  -- Sacrificial Dagger bug
  if SamaelMod.SacDaggerAcquired == false and
     player:HasCollectible(CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER) then -- 172

    SamaelMod.SacDaggerAcquired = true

    -- Check for an existing Sacrifical Dagger
    local foundSacDag = false
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_FAMILIAR and -- 3
         entity.Variant == FamiliarVariant.SACRIFICIAL_DAGGER and -- 35
         entity.SubType ~= hitBoxType then

        foundSacDag = true
        Isaac.DebugString("Found Sacrificial Dagger familiar entity: " .. tostring(entity.Index))
      end
    end
    if foundSacDag == false then
      -- Manually spawn a Sacrificial Dagger familiar (3.35)
      game:Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.SACRIFICIAL_DAGGER,
                 player.Position, Vector(0, 0), player, 0, 0)
      Isaac.DebugString("Spawned a new Sac Dagger familiar.")
    end
  end
end

-- Called from the "RPCheckEntities:NonGrid()" and "SamaelMod:CheckHairpin()" functions
function SamaelMod:CheckRechargeWraithSkull()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(wraithItem) and
     wraithCharge ~= 100 then

    wraithCharge = 100
    Isaac.DebugString("Manually charged the Wraith Skull (from Lil' Battery / Charged Key / Hairpin).")
  end
end

-- Called from the "RPPostNewRoom:NewRoom2()" function
function SamaelMod:CheckHairpin()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local player = game:GetPlayer(0)

  if player:HasCollectible(Isaac.GetItemIdByName("Wraith Skull")) and
     -- We don't want to check for "player:NeedsCharge()" because the Hairpin will actually work,
     -- but if the wraithCharge variable is not updated, then it will get uncharged on the next frame
     player:HasTrinket(TrinketType.TRINKET_HAIRPIN) and -- 120
     roomType == RoomType.ROOM_BOSS and -- 5
     level:GetCurrentRoomDesc().VisitedCount == 1 then

    Isaac.DebugString("Hairpin recharge detected.")
    SamaelMod:CheckRechargeWraithSkull()
  end
end

return SamaelMod
