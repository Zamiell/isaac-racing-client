local RPCallbacks = {}

--
-- Includes
--

local RPGlobals   = require("src/rpglobals")
local RPFastClear = require("src/rpfastclear")

--
-- Miscellaneous game callbacks
--

-- ModCallbacks.MC_NPC_UPDATE (0)
function RPCallbacks:NPCUpdate(npc)
  --
  -- Lock Knights that are in the "warmup" animation
  -- (still seems to be buggy)
  --

  if (npc.Type == EntityType.ENTITY_KNIGHT or -- 41
      npc.Type == EntityType.ENTITY_FLOATING_KNIGHT or -- 254
      npc.Type == EntityType.ENTITY_BONE_KNIGHT) and -- 283
     npc.FrameCount >= 5 and
     npc.FrameCount <= 30 and
     RPGlobals.run.currentKnights[npc.Index] ~= nil then

    -- Keep the 5th frame of the spawn animation going
    npc:GetSprite():SetFrame("Down", 0)

    -- Make sure that it stays in place
    npc.Position = RPGlobals.run.currentKnights[npc.Index].pos
    npc.Velocity = Vector(0, 0)
  end

  --
  -- Lock Lil' Haunts that are in the "warmup" animation
  --

  if (npc.Type == EntityType.ENTITY_THE_HAUNT and npc.Variant == 10) and -- 260
     npc.FrameCount >= 5 and
     npc.FrameCount <= 16 and
     RPGlobals.run.currentLilHaunts[npc.Index] ~= nil then

    -- Make sure that it stays in place
    npc.Position = RPGlobals.run.currentLilHaunts[npc.Index].pos
    npc.Velocity = Vector(0, 0)
  end

  -- Look for enemies that are dying so that we can open the doors prematurely
  RPFastClear:NPCUpdate(npc)
end

-- ModCallbacks.MC_EVALUATE_CACHE (8)
function RPCallbacks:EvaluateCache(player, cacheFlag)
  local character = player:GetPlayerType()
  local maxHearts = player:GetMaxHearts()
  local coins = player:GetNumCoins()
  local coinContainers = 0

  --
  -- Manage Keeper's heart containers
  --

  if character == PlayerType.PLAYER_KEEPER and -- 14
     cacheFlag == CacheFlag.CACHE_RANGE then -- 8

    -- Find out how many coin containers we should have
    -- (2 is equal to 1 actual heart container)
    if coins >= 99 then
      coinContainers = 8
    elseif coins >= 75 then
      coinContainers = 6
    elseif coins >= 50 then
      coinContainers = 4
    elseif coins >= 25 then
      coinContainers = 2
    end
    local baseHearts = maxHearts - coinContainers

    -- We have to add the range cache to all health up items
    --   12  - Magic Mushroom (already has range cache)
    --   15  - <3
    --   16  - Raw Liver (gives 2 containers)
    --   22  - Lunch
    --   23  - Dinner
    --   24  - Dessert
    --   25  - Breakfast
    --   26  - Rotten Meat
    --   81  - Dead Cat
    --   92  - Super Bandage
    --   101 - The Halo (already has range cache)
    --   119 - Blood Bag
    --   121 - Odd Mushroom (Thick) (already has range cache)
    --   129 - Bucket of Lard (gives 2 containers)
    --   138 - Stigmata
    --   176 - Stem Cells
    --   182 - Sacred Heart (already has range cache)
    --   184 - Holy Grail
    --   189 - SMB Super Fan (already has range cache)
    --   193 - Meat!
    --   218 - Placenta
    --   219 - Old Bandage
    --   226 - Black Lotus
    --   230 - Abaddon
    --   253 - Magic Scab
    --   307 - Capricorn (already has range cache)
    --   312 - Maggy's Bow
    --   314 - Thunder Theighs
    --   334 - The Body (gives 3 containers)
    --   342 - Blue Cap
    --   346 - A Snack
    --   354 - Crack Jacks
    --   456 - Moldy Bread
    local HPItemArray = {
      12,  15,  16,  22,  23,
      24,  25,  26,  81,  92,
      101, 119, 121, 129, 138,
      176, 182, 184, 189, 193,
      218, 219, 226, 230, 253,
      307, 312, 314, 334, 342,
      346, 354, 456,
    }
    for i = 1, #HPItemArray do
      if player:HasCollectible(HPItemArray[i]) then
        if RPGlobals.run.keeper.healthItems[HPItemArray[i]] == nil then
          RPGlobals.run.keeper.healthItems[HPItemArray[i]] = true

          if HPItemArray[i] == CollectibleType.COLLECTIBLE_ABADDON then -- 230
            player:AddMaxHearts(-24, true) -- Remove all hearts
            player:AddMaxHearts(coinContainers, true) -- Give whatever containers we should have from coins
            player:AddHearts(24) -- This is needed because all the new heart containers will be empty
            -- We have no way of knowing what the current health was before, because "player:GetHearts()"
            -- returns 0 at this point. So, just give them max health.
            Isaac.DebugString("Set 0 heart containers to Keeper (Abaddon).")

          elseif HPItemArray[i] == CollectibleType.COLLECTIBLE_DEAD_CAT then -- 81
            player:AddMaxHearts(-24, true) -- Remove all hearts
            player:AddMaxHearts(2 + coinContainers, true) -- Give 1 heart container +
                                                          -- whatever containers we should have from coins
            player:AddHearts(24) -- This is needed because all the new heart containers will be empty
            -- We have no way of knowing what the current health was before, because "player:GetHearts()"
            -- returns 0 at this point. So, just give them max health.
            Isaac.DebugString("Set 1 heart container to Keeper (Dead Cat).")

          elseif baseHearts < 0 and
             HPItemArray[i] == CollectibleType.COLLECTIBLE_BODY then -- 334

            player:AddMaxHearts(6, true) -- Give 3 heart containers
            Isaac.DebugString("Gave 3 heart containers to Keeper.")

            -- Fill in the new containers
            player:AddCoins(1)
            player:AddCoins(1)
            player:AddCoins(1)

          elseif baseHearts < 2 and
                 (HPItemArray[i] == CollectibleType.COLLECTIBLE_RAW_LIVER or -- 16
                  HPItemArray[i] == CollectibleType.COLLECTIBLE_BUCKET_LARD or -- 129
                  HPItemArray[i] == CollectibleType.COLLECTIBLE_BODY) then -- 334

            player:AddMaxHearts(4, true) -- Give 2 heart containers
            Isaac.DebugString("Gave 2 heart containers to Keeper.")

            -- Fill in the new containers
            player:AddCoins(1)
            player:AddCoins(1)

          elseif baseHearts < 4 then
            player:AddMaxHearts(2, true) -- Give 1 heart container
            Isaac.DebugString("Gave 1 heart container to Keeper.")

            if HPItemArray[i] ~= CollectibleType.COLLECTIBLE_ODD_MUSHROOM_DAMAGE and -- 121
               HPItemArray[i] ~= CollectibleType.COLLECTIBLE_OLD_BANDAGE then -- 219

              -- Fill in the new container
              -- (Odd Mushroom (Thick) and Old Bandage do not give filled heart containers)
              player:AddCoins(1)
            end

          else
            Isaac.DebugString("Health up detected, but baseHearts are full.")
          end
        end
      end
    end
  end

  --
  -- Handle custom race stats
  --

  if RPGlobals.race == nil then
    return -- If "save.dat" reading fails, then there is no fallback mechanism for this, so hopefully it does not fail
  end

  for i = 1, #RPGlobals.race.startingItems do
    if RPGlobals.race.startingItems[i] == 600 and -- 13 luck
       cacheFlag == CacheFlag.CACHE_LUCK then -- 1024

      player.Luck = player.Luck + 13
    end
  end

  -- The Pageant Boy ruleset starts with 7 luck
  if RPGlobals.race.rFormat == "pageant" and
     cacheFlag == CacheFlag.CACHE_LUCK then -- 1024

    player.Luck = player.Luck + 7
  end
end

-- ModCallbacks.MC_POST_PLAYER_INIT (9)
-- (this will get called before the "RPInit:Run()" function)
function RPCallbacks:PostPlayerInit(player)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local mainPlayer = game:GetPlayer(0)
  local character = mainPlayer:GetPlayerType()

  if player.Variant == 0 then
    -- Check to see if we are on the BLCK CNDL Easter Egg
    level:AddCurse(LevelCurse.CURSE_OF_THE_CURSED, false) -- The second argument is "ShowName"
    local curses = level:GetCurses()
    if curses == 0 then
      RPGlobals.raceVars.blckCndlOn = true
    else
      RPGlobals.raceVars.blckCndlOn = false

      -- The client assumes that it is on by default, so it only needs to be alerted for the negative case
      Isaac.DebugString("BLCK CNDL off.")
    end
    level:RemoveCurse(LevelCurse.CURSE_OF_THE_CURSED)

    -- Check to see if we are on normal mode or hard mode
    RPGlobals.raceVars.difficulty = game.Difficulty
    Isaac.DebugString("Difficulty: " .. tostring(game.Difficulty))

    -- Check what character we are on
    if character == PlayerType.PLAYER_ISAAC then -- 0
      RPGlobals.raceVars.character = "Isaac"
    elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
      RPGlobals.raceVars.character = "Magdalene"
    elseif character == PlayerType.PLAYER_CAIN then -- 2
      RPGlobals.raceVars.character = "Cain"
    elseif character == PlayerType.PLAYER_JUDAS then -- 3
      RPGlobals.raceVars.character = "Judas"
    elseif character == PlayerType.PLAYER_XXX then -- 4
      RPGlobals.raceVars.character = "Blue Baby"
    elseif character == PlayerType.PLAYER_EVE then -- 5
      RPGlobals.raceVars.character = "Eve"
    elseif character == PlayerType.PLAYER_SAMSON then -- 6
      RPGlobals.raceVars.character = "Samson"
    elseif character == PlayerType.PLAYER_AZAZEL then -- 7
      RPGlobals.raceVars.character = "Azazel"
    elseif character == PlayerType.PLAYER_LAZARUS then -- 8
      RPGlobals.raceVars.character = "Lazarus"
    elseif character == PlayerType.PLAYER_EDEN then  -- 9
      RPGlobals.raceVars.character = "Eden"
    elseif character == PlayerType.PLAYER_THELOST then -- 10
      RPGlobals.raceVars.character = "The Lost"
    elseif character == PlayerType.PLAYER_LILITH then -- 13
      RPGlobals.raceVars.character = "Lilith"
    elseif character == PlayerType.PLAYER_KEEPER then -- 14
      RPGlobals.raceVars.character = "Keeper"
    elseif character == PlayerType.PLAYER_APOLLYON then -- 15
      RPGlobals.raceVars.character = "Apollyon"
    end

  elseif player.Variant == 1 then
    -- Check for co-op babies
    mainPlayer:AnimateSad() -- Play a sound effect to communicate that the player made a mistake
    player:Kill() -- This kills the co-op baby, but the character will still get their health back for some reason

    -- Since the player gets their health back, it is still possible to steal devil deals, so remove all unpurchased
    -- Devil Room items in the room (which will have prices of either -1 or -2)
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if entities[i].Type == EntityType.ENTITY_PICKUP and -- If this is a pedestal item (5.100)
         entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE and
         entities[i]:ToPickup().Price < 0 then

        entities[i]:Remove()
      end
    end
  end
end

-- ModCallbacks.MC_ENTITY_TAKE_DMG (11)
function RPCallbacks:EntityTakeDamage(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  local player = tookDamage:ToPlayer()
  if player ~= nil then
    --
    -- Magdalene damage tracking
    --

    local selfDamage = false
    for i = 0, 18 do -- We only need to iterate to 18
      local bit = (damageFlag & (1 << i)) >> i
      if (i == 5 or i == 18) and bit == 1 then -- 5 is DAMAGE_RED_HEARTS, 18 is DAMAGE_IV_BAG
        selfDamage = true
      end
    end
    if selfDamage == false then
      RPGlobals.run.levelDamaged = true
    end

    --
    -- Betrayal (custom)
    --

    if player:HasCollectible(CollectibleType.COLLECTIBLE_BETRAYAL_NOANIM) then
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        local npc = entities[i]:ToNPC()
        if npc ~= nil and entities[i]:IsVulnerableEnemy() then
          entities[i]:AddCharmed(150) -- 5 seconds
        end
      end
    end
  end

  --
  -- Globins softlock prevention
  --

  local npc = tookDamage:ToNPC()
  if npc ~= nil then
    if (npc.Type == EntityType.ENTITY_GLOBIN or
        npc.Type == EntityType.ENTITY_BLACK_GLOBIN) and
       RPGlobals.run.currentGlobins[npc.Index] == nil then

      RPGlobals.run.currentGlobins[npc.Index] = {
        npc       = npc,
        lastState = npc.State,
        regens    = 0,
      }
    end
  end
end

-- ModCallbacks.MC_INPUT_ACTION (13)
function RPCallbacks:InputAction(entity, inputHook, buttonAction)
  -- Disable resetting if the countdown is at 1
  if buttonAction == ButtonAction.ACTION_RESTART and RPGlobals.raceVars.resetEnabled == false then
    return false
  end
end

return RPCallbacks
