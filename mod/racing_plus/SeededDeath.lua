local SeededDeath = {}

-- Includes
local g         = require("racing_plus/globals")
local Schoolbag = require("racing_plus/schoolbag")

-- Enums
SeededDeath.state = {
  DISABLED = 0,
  DEATH_ANIMATION = 1,
  CHANGING_ROOMS = 2,
  FETAL_POSITION = 3,
  GHOST_FORM = 4,
}

-- Variables
SeededDeath.debuffTime = 45 -- In seconds

-- ModCallbacks.MC_POST_UPDATE (1)
function SeededDeath:PostUpdate()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local previousRoomIndex = g.l:GetPreviousRoomIndex()
  local character = g.p:GetPlayerType()
  local playerSprite = g.p:GetSprite()

  -- Fix the bug where The Forgotten will not be properly faded
  -- if he switched from The Soul immediately before the debuff occured
  if g.run.fadeForgottenFrame ~= 0 and
     gameFrameCount >= g.run.fadeForgottenFrame then

    g.run.fadeForgottenFrame = 0

    -- Re-fade the player
    playerSprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)
  end

  -- Check to see if the (fake) death animation is over
  if g.run.seededDeath.state == SeededDeath.state.DEATH_ANIMATION and
     g.run.seededDeath.reviveFrame ~= 0 and
     gameFrameCount >= g.run.seededDeath.reviveFrame then

    g.run.seededDeath.reviveFrame = 0
    g.run.seededDeath.state = SeededDeath.state.CHANGING_ROOMS
    g.p.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4
    g.seeds:RemoveSeedEffect(SeedEffect.SEED_PERMANENT_CURSE_UNKNOWN) -- 59
    g.seeds:AddSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) -- 70

    if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
      -- The "Revive()" function is bugged with The Forgotton;
      -- he will be revived with one soul heart unless he is given a bone heart first
      g.p:AddBoneHearts(1)
    elseif character == PlayerType.PLAYER_THESOUL then -- 17
      -- If we died on The Soul, we want to remove all of The Forgotton's bone hearts,
      -- emulating what happens if you die with Dead Cat
      g.p:AddBoneHearts(-24)
      g.p:AddBoneHearts(1)
    end
    local enterDoor = g.l.EnterDoor
    local door = g.r:GetDoor(enterDoor)
    local direction = door and door.Direction or Direction.NO_DIRECTION
    local transition = g.RoomTransition.TRANSITION_NONE -- 0
    if g.run.seededDeath.guppysCollar then
      transition = g.RoomTransition.TRANSITION_GUPPYS_COLLAR -- 8
    end
    g.g:StartRoomTransition(previousRoomIndex, direction, transition)
    g.l.LeaveDoor = enterDoor

    if character == PlayerType.PLAYER_THESOUL then -- 17
      -- If we are The Soul, the manual revival will not work properly
      -- Thus, manually switch to the Forgotten to avoid this
      g.run.switchForgotten = true
    end
  end

  -- Check to see if the debuff is over
  if g.run.seededDeath.state == SeededDeath.state.GHOST_FORM then
    local elapsedTime = g.run.seededDeath.time - Isaac.GetTime()
    if elapsedTime <= 0 then
      g.run.seededDeath.state = SeededDeath.state.DISABLED
      g.run.seededDeath.time = 0
      SeededDeath:DebuffOff()
      g.p:AnimateHappy()
      Isaac.DebugString("Seeded death debuff complete.")
    end
  end
end

-- ModCallbacks.MC_POST_RENDER (2)
function SeededDeath:PostRender()
  -- Local variables
  local playerSprite = g.p:GetSprite()

  if g.run.seededDeath.state == SeededDeath.state.FETAL_POSITION then
    -- Keep the player in place during the "AppearVanilla" animation
    g.p.Position = g.run.seededDeath.position

    if not playerSprite:IsPlaying("AppearVanilla") then
      g.run.seededDeath.state = SeededDeath.state.GHOST_FORM
    end
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function SeededDeath:PostNewRoom()
  -- Local variables
  local effects = g.p:GetEffects()

  -- Add a temporary Holy Mantle effect for Keeper after a seeded revival
  if g.run.tempHolyMantle then
    effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) -- 313
    g.p:AddCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)) -- 313
  end

  -- Make any Checkpoints not touchable
  if g.run.seededDeath.state > 0 then
    local checkpoints = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                         CollectibleType.COLLECTIBLE_CHECKPOINT, false, false)
    for _, checkpoint in ipairs(checkpoints) do
      checkpoint:ToPickup().Timeout = 10000000
      Isaac.DebugString("Delayed a Checkpoint due to seeded death.")
    end
  end

  -- Put the player in the fetal position (the "AppearVanilla" animation)
  if g.run.seededDeath.state == SeededDeath.state.CHANGING_ROOMS then
    -- Do not continue on with the custom death mechanic if the 50% roll for Guppy's Collar was successful
    if g.run.seededDeath.guppysCollar then
      g.run.seededDeath.state = SeededDeath.state.DISABLED
      g.run.seededDeath.guppysCollar = false
      return
    end

    g.run.seededDeath.state = SeededDeath.state.FETAL_POSITION

    -- Start the debuff and set the finishing time to be in the future
    SeededDeath:DebuffOn()
    local debuffTimeMilliseconds = SeededDeath.debuffTime * 1000
    if g.debug then
      debuffTimeMilliseconds = 5000
    end
    g.run.seededDeath.time = Isaac.GetTime() + debuffTimeMilliseconds

    -- Play the animation where Isaac lies in the fetal position
    g.p:PlayExtraAnimation("AppearVanilla")

    g.run.seededDeath.position = Vector(g.p.Position.X, g.p.Position.Y)
  end
end

function SeededDeath:EntityTakeDmg(damageAmount, damageFlag)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomType = g.r:GetType()
  local hearts = g.p:GetHearts()
  local eternalHearts = g.p:GetEternalHearts()
  local soulHearts = g.p:GetSoulHearts()
  local boneHearts = g.p:GetBoneHearts()
  local extraLives = g.p:GetExtraLives()
  local challenge = Isaac.GetChallenge()

  -- Make the player invulnerable during the death animation
  if g.run.seededDeath.state == SeededDeath.state.DEATH_ANIMATION then
    return false
  end

  -- Check to see if this is a situation where the custom death mechanic should apply
  if (g.run.seededDeath.state == SeededDeath.state.DISABLED or
      g.run.seededDeath.state == SeededDeath.state.GHOST_FORM) and
     (g.race.rFormat ~= "seeded" and
      g.race.rFormat ~= "seeded-mo" and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)")) then -- 10

    return
  end

  -- Check to see if this is fatal damage
  local totalHealth = hearts + eternalHearts + soulHearts + boneHearts
  if damageAmount < totalHealth then
    return
  end

  -- Furthermore, this will not be fatal damage if we have two different kinds of hearts
  -- e.g. a bomb explosion deals 2 damage, but if the player has one half soul heart and one half red heart,
  -- the game will only remove the soul heart
  if (hearts > 0 and soulHearts > 0) or
     (hearts > 0 and boneHearts > 0) or
     (soulHearts > 0 and boneHearts > 0) then

    return
  end

  -- Check to see if they have a revival item
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) then -- 212
    -- Having Guppy's Collar causes the extra lives to always be set to 1
    -- We handle Guppy's Collar manually
    extraLives = extraLives - 1
  end
  if g.p:HasTrinket(TrinketType.TRINKET_MISSING_POSTER) and -- 23
     not g.p:HasTrinket(TrinketType.TRINKET_MYSTERIOUS_PAPER) then -- 21
     -- (Mysterious Paper has a chance to give Missing Poster on every frame)

    -- Having Missing Poster does not affect the extra lives variable, so manually account for this
    extraLives = extraLives + 1
  end
  if extraLives > 0 then
    return
  end

  -- Do not revive the player if they are killing themselves via taking a devil deal
  local bit = (damageFlag & (1 << 10)) >> 10 -- DamageFlag.DAMAGE_DEVIL
  if bit == 1 then
    return
  end

  -- Do not revive the player if they are trying to get a "free" item in either
  -- a Sacrifice Room or the Boss Rush
  if roomType == RoomType.ROOM_SACRIFICE or -- 13
     roomType == RoomType.ROOM_BOSSRUSH then -- 17

    return
  end

  -- Calculate if Guppy's Collar should work
  g.run.seededDeath.guppysCollar = false
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) then -- 212
    g.RNGCounter.GuppysCollar = g:IncrementRNG(g.RNGCounter.GuppysCollar)
    math.randomseed(g.RNGCounter.GuppysCollar)
    local reviveChance = math.random(1, 2)
    if reviveChance == 1 then
      g.run.seededDeath.guppysCollar = true
    end
  end

  Isaac.DebugString("Fatal damage detected; invoking the custom death mechanic.")
  g.run.seededDeath.state = SeededDeath.state.DEATH_ANIMATION
  g.run.seededDeath.reviveFrame = gameFrameCount + 46
  g.p:PlayExtraAnimation("Death")
  g.sfx:Play(SoundEffect.SOUND_ISAACDIES, 1, 0, false, 1) -- 217

  -- We need to disable the controls, or the player will be able to move around during the death animation
  g.p.ControlsEnabled = false

  -- We need to disable the collision, or else enemies will be able to push around the body during the death animation
  g.p.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0

  -- Hide the player's health to obfucate the fact that they are still technically alive
  g.seeds:RemoveSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) -- 70
  g.seeds:AddSeedEffect(SeedEffect.SEED_PERMANENT_CURSE_UNKNOWN) -- 59

  -- Drop all trinkets and pocket items
  if not g.run.seededDeath.guppysCollar then
    local pos1 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
    g.p:DropTrinket(pos1, false)
    local pos2 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
    g.p:DropPoketItem(0, pos2)
    local pos3 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
    g.p:DropPoketItem(1, pos3)
  end

  return false
end

-- Prevent people from abusing the death mechanic to use a Sacrifice Room
function SeededDeath:PostNewRoomCheckSacrificeRoom()
  local roomType = g.r:GetType()
  local gridSize = g.r:GetGridSize()

  if g.run.seededDeath.state ~= SeededDeath.state.GHOST_FORM or
     roomType ~= RoomType.ROOM_SACRIFICE then -- 13

    return
  end

  g.p:AnimateSad()
  for i = 1, gridSize do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 8
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end

    end
  end
  Isaac.DebugString("Deleted the spikes in a Sacrifice Room (during a seeded death debuff).")
end

function SeededDeath:DebuffOn()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local playerSprite = g.p:GetSprite()
  local character = g.p:GetPlayerType()

  -- Store the current level
  g.run.seededDeath.stage = stage

  -- Set their health to explicitly 1.5 soul hearts
  -- (or custom values for Keeper & The Forgotton)
  g.p:AddMaxHearts(-24, true)
  g.p:AddSoulHearts(-24)
  g.p:AddBoneHearts(-12)
  if character == PlayerType.PLAYER_KEEPER then -- 14
    g.p:AddMaxHearts(2, true) -- One coin container
    g.p:AddHearts(2)
  elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    g.p:AddMaxHearts(2, true)
    g.p:AddHearts(1)
  elseif character == PlayerType.PLAYER_THESOUL then -- 17
    g.p:AddHearts(1)
  else
    g.p:AddSoulHearts(3)
  end

  -- Store their active item charge for later
  g.run.seededDeath.charge = g.p:GetActiveCharge()

  -- Store their Schoolbag item and remove it
  -- (we need to check to see if it is equal to 0 in case they die twice in a row)
  if g.run.schoolbag.item ~= 0 then
    g.run.seededDeath.sbItem = g.run.schoolbag.item
    g.run.seededDeath.sbCharge = g.run.schoolbag.charge
    g.run.seededDeath.sbChargeBattery = g.run.schoolbag.chargeBattery
    g.run.schoolbag.item = 0
    g.run.schoolbag.charge = 0
    g.run.schoolbag.chargeBattery = 0
  end

  -- Store their size for later, and then reset it to default
  -- (in case they had items like Magic Mushroom and so forth)
  g.run.seededDeath.spriteScale = g.p.SpriteScale
  g.p.SpriteScale = Vector(1, 1)

  -- Store their golden bomb / key status
  g.run.seededDeath.goldenBomb = g.p:HasGoldenBomb()
  g.run.seededDeath.goldenKey = g.p:HasGoldenKey()

  -- We need to remove every item (and store it for later)
  -- ("player:GetCollectibleNum()" is bugged if you feed it a number higher than the total amount of items and
  -- can cause the game to crash)
  for i = 1, g:GetTotalItemCount() do
    local numItems = g.p:GetCollectibleNum(i)
    if numItems > 0 and
       g.p:HasCollectible(i) then

      -- Checking both "GetCollectibleNum()" and "HasCollectible()" prevents bugs such as Lilith having 1 Incubus
      for j = 1, numItems do
        g.run.seededDeath.items[#g.run.seededDeath.items + 1] = i
        g.p:RemoveCollectible(i)
        local debugString = "Removing collectible " .. tostring(i)
        if i == CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM then
          debugString = debugString .. " (Schoolbag)"
        end
        Isaac.DebugString(debugString)
        g.p:TryRemoveCollectibleCostume(i, false)
      end
    end
  end

  -- Now that we have deleted every item, update the players stats
  g.p:EvaluateItems()

  -- Remove any golden bombs and keys
  g.p:RemoveGoldenBomb()
  g.p:RemoveGoldenKey()

  -- Remove the Dead Eye multiplier, if any
  for i = 1, 100 do
    -- Each time this function is called, it only has a chance of working,
    -- so just call it 100 times to be safe
    g.p:ClearDeadEyeCharge()
  end

  -- Fade the player
  playerSprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)

  -- The fade will now work if we just switched from The Soul on the last frame,
  -- so mark to redo the fade a few frames from now
  if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    g.run.fadeForgottenFrame = gameFrameCount + 6 -- If we wait 5 frames or less, then the fade will not stick
  end
end

function SeededDeath:DebuffOff()
  -- Local variables
  local stage = g.l:GetStage()
  local playerSprite = g.p:GetSprite()
  local character = g.p:GetPlayerType()
  local effects = g.p:GetEffects()

  -- Unfade the character
  playerSprite.Color = g.color

  -- Store the current active item, red hearts, soul/black hearts, bombs, keys, and pocket items
  local subPlayer = g.p:GetSubPlayer()
  local activeItem = g.p:GetActiveItem()
  local activeCharge = g.p:GetActiveCharge()
  local hearts = g.p:GetHearts()
  local maxHearts = g.p:GetMaxHearts()
  local soulHearts = g.p:GetSoulHearts()
  local blackHearts = g.p:GetBlackHearts()
  if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    soulHearts = subPlayer:GetSoulHearts()
    blackHearts = subPlayer:GetBlackHearts()
  end
  local boneHearts = g.p:GetBoneHearts()
  local bombs = g.p:GetNumBombs()
  local keys = g.p:GetNumKeys()
  local card1 = g.p:GetCard(0)
  local pill1 = g.p:GetPill(0)

  -- Add all of the items from the array
  for _, itemID in ipairs(g.run.seededDeath.items) do
    -- Make an exception for The Quarter and The Dollar,
    -- since it will just give us extra money
    if itemID ~= CollectibleType.COLLECTIBLE_QUARTER and -- 74
       itemID ~= CollectibleType.COLLECTIBLE_DOLLAR then -- 18

      g.p:AddCollectible(itemID, 0, false)

      -- The Halo of Flies item actually gives two Halo of Flies, so we need to remove one
      if itemID == CollectibleType.COLLECTIBLE_HALO_OF_FLIES then -- 10
        g.p:RemoveCollectible(itemID)
      end
    end
  end

  -- Reset the items in the array
  g.run.seededDeath.items = {}

  -- Set the charge to the way it was before the debuff was applied
  g.p:SetActiveCharge(g.run.seededDeath.charge)

  -- Restore the Schoolbag item, if any
  g.run.schoolbag.item = g.run.seededDeath.sbItem
  g.run.schoolbag.charge = g.run.seededDeath.sbCharge
  g.run.schoolbag.chargeBattery = g.run.seededDeath.sbChargeBattery
  g.run.seededDeath.sbItem = 0
  g.run.seededDeath.sbCharge = 0
  g.run.seededDeath.sbChargeBattery = 0

  -- Check to see if the active item changed
  -- (meaning that the player picked up a new active item during their ghost state)
  local newActiveItem = g.p:GetActiveItem()
  if activeItem ~= 0 and
     newActiveItem ~= activeItem then

    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) and
       g.run.schoolbag.item == 0 then

      -- There is room in the Schoolbag, so put it in the Schoolbag
      Schoolbag:Put(activeItem, activeCharge)
      Isaac.DebugString("SeededDeath - Put the ghost active inside the Schoolbag.")

    else
      -- There is no room in the Schoolbag, so spawn it on the ground
      local position = g.r:FindFreePickupSpawnPosition(g.p.Position, 1, true)
      local pedestal = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, activeItem, -- 5.100
                                   position, g.zeroVector, nil):ToPickup()
      -- (we do not care about the seed beacuse it will be replaced on the next frame)
      pedestal.Charge = activeCharge
      pedestal.Touched = true
      Isaac.DebugString("SeededDeath - Put the old active item on the ground since there was no room for it.")
    end
  end

  -- Set their size to the way it was before the debuff was applied
  g.p.SpriteScale = g.run.seededDeath.spriteScale

  -- Set the health to the way it was before the items were added
  g.p:AddMaxHearts(-24, true) -- Remove all hearts
  g.p:AddSoulHearts(-24)
  g.p:AddBoneHearts(-24)
  g.p:AddMaxHearts(maxHearts, true)
  g.p:AddBoneHearts(boneHearts)
  g.p:AddHearts(hearts)
  for i = 1, soulHearts do
    local bitPosition = math.floor((i - 1) / 2)
    local bit = (blackHearts & (1 << bitPosition)) >> bitPosition
    if bit == 0 then -- Soul heart
      g.p:AddSoulHearts(1)
    else -- Black heart
      g.p:AddBlackHearts(1)
    end
  end

  -- If The Soul is active when the debuff ends, the health will not be handled properly,
  -- so manually set everything
  if character == PlayerType.PLAYER_THESOUL then -- 17
    g.p:AddBoneHearts(-24)
    g.p:AddBoneHearts(1)
    g.p:AddHearts(-24)
    g.p:AddHearts(1)
  end

  -- Set the inventory to the way it was before the items were added
  g.p:AddBombs(-99)
  g.p:AddBombs(bombs)
  g.p:AddKeys(-99)
  g.p:AddKeys(keys)
  if g.run.seededDeath.goldenBomb then
    g.run.seededDeath.goldenBomb = false
    if stage == g.run.seededDeath.stage then
      g.p:AddGoldenBomb()
    end
  end
  if g.run.seededDeath.goldenKey then
    g.run.seededDeath.goldenKey = false
    if stage == g.run.seededDeath.stage then
      g.p:AddGoldenKey()
    end
  end

  -- We also have to account for Caffeine Pill,
  -- which is the only item in the game that directly puts a pocket item into your inventory
  if card1 ~= 0 then
    g.p:SetCard(0, card1)
  else
    g.p:SetPill(0, pill1)
  end

  -- Delete all newly-spawned pickups in the room
  -- (re-giving back some items will cause pickups to spawn)
  local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false) -- 5
  for _, pickup in ipairs(pickups) do
    if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE and -- 100
       pickup.FrameCount == 0 then

      pickup:Remove()
    end
  end

  -- Fix character-specific bugs
  if character == PlayerType.PLAYER_LILITH then -- 13
    -- If Lilith had Incubus, the debuff will grant an extra Incubus, so account for this
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_INCUBUS) then -- 360
      g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360
    end
  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Keeper will get extra blue flies if he was given any items that grant soul hearts
    local blueFlies = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, -1, false, false) -- 3.43
    for i, fly in ipairs(blueFlies) do
      fly:Remove()
    end

    -- Keeper will start with one coin container, which can lead to chain deaths
    -- Give Keeper a temporary Wooden Cross effect
    g.run.tempHolyMantle = true
    effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) -- 313
    g.p:AddCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)) -- 313
  end

  -- Make any Checkpoints touchable again
  local checkpoints = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                       CollectibleType.COLLECTIBLE_CHECKPOINT, false, false)
  for _, checkpoint in ipairs(checkpoints) do
    checkpoint:ToPickup().Timeout = -1
  end
end

return SeededDeath
