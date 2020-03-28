local Season6 = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")

--
-- Constants
--

Season6.itemStarts = {
  { CollectibleType.COLLECTIBLE_MOMS_KNIFE }, -- 114
  { CollectibleType.COLLECTIBLE_TECH_X }, -- 395
  { CollectibleType.COLLECTIBLE_EPIC_FETUS }, -- 168
  { CollectibleType.COLLECTIBLE_IPECAC }, -- 149
  { CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER }, -- 172
  { CollectibleType.COLLECTIBLE_20_20 }, -- 245
  { CollectibleType.COLLECTIBLE_PROPTOSIS }, -- 261
  { CollectibleType.COLLECTIBLE_LIL_BRIMSTONE }, -- 275
  { CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM }, -- 12
  { CollectibleType.COLLECTIBLE_TECH_5 }, -- 244
  { CollectibleType.COLLECTIBLE_POLYPHEMUS }, -- 169
  { CollectibleType.COLLECTIBLE_MAXS_HEAD }, -- 4
  { CollectibleType.COLLECTIBLE_DEATHS_TOUCH }, -- 237
  { CollectibleType.COLLECTIBLE_DEAD_EYE }, -- 373
  { CollectibleType.COLLECTIBLE_CRICKETS_BODY }, -- 224
  { CollectibleType.COLLECTIBLE_DR_FETUS }, -- 52
  { CollectibleType.COLLECTIBLE_MONSTROS_LUNG }, -- 229
  { CollectibleType.COLLECTIBLE_JUDAS_SHADOW }, -- 311
  {
    CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, -- 69
    CollectibleType.COLLECTIBLE_STEVEN, -- 50
  },
  {
    CollectibleType.COLLECTIBLE_JACOBS_LADDER, -- 494
    CollectibleType.COLLECTIBLE_THERES_OPTIONS, -- 249
  },
  { CollectibleType.COLLECTIBLE_BRIMSTONE }, -- 118
  { CollectibleType.COLLECTIBLE_INCUBUS }, -- 360
  { CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT }, -- 415
  { CollectibleType.COLLECTIBLE_SACRED_HEART }, -- 182
  {
    CollectibleType.COLLECTIBLE_MUTANT_SPIDER, -- 153
    CollectibleType.COLLECTIBLE_INNER_EYE, -- 2
  },
  {
    CollectibleType.COLLECTIBLE_TECHNOLOGY, -- 68
    CollectibleType.COLLECTIBLE_LUMP_OF_COAL, -- 132
  },
  {
    CollectibleType.COLLECTIBLE_FIRE_MIND, -- 257
    CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID, -- 317
    CollectibleType.COLLECTIBLE_13_LUCK, -- Custom
  },
}

Season6.big4 = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
}

-- This is how long the randomly-selected item start is "locked-in"
Season6.itemLockTime = 60 * 1000 -- 1 minute

-- This is how often the special "Veto" button can be used
Season6.vetoButtonLength = 5 * 60 * 1000 -- 5 minutes

-- Variables
Season6.timeItemAssigned = 0 -- Reset when the time limit elapses
Season6.lastBuildItem = 0 -- Set when a new build is assigned
Season6.lastBuildItemOnFirstChar = 0 -- Set when a new build is assigned on the first character
Season6.vetoList = {}
Season6.vetoSprites = {}
Season6.vetoTimer = 0

-- Handle the "Veto" button
-- Called from the "CheckEntities:Grid()" function
function Season6:CheckVetoButton(gridEntity)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     Speedrun.charNum ~= 1 or
     g.run.roomsEntered ~= 1 or
     gridEntity:GetSaveState().State ~= 3 then

    return
  end

  -- Add the item to the veto list
  Season6.vetoList[#Season6.vetoList + 1] = Season6.lastBuildItem
  if #Season6.vetoList > 5 then
    table.remove(Season6.vetoList, 1)
  end

  -- Add the sprite to the sprite list
  Season6.vetoSprites = {}
  for i, veto in ipairs(Season6.vetoList) do
    Season6.vetoSprites[i] = Sprite()
    Season6.vetoSprites[i]:Load("gfx/schoolbag_item.anm2", false)
    local fileName = g.itemConfig:GetCollectible(veto).GfxFileName
    Season6.vetoSprites[i]:ReplaceSpritesheet(0, fileName)
    Season6.vetoSprites[i]:LoadGraphics()
    Season6.vetoSprites[i]:SetFrame("Default", 1)
    Season6.vetoSprites[i].Scale = Vector(0.75, 0.75)
  end

  -- Play a poop sound
  g.sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, 1) -- 37

  -- Reset the timer and restart the game
  Season6.vetoTimer = Isaac.GetTime() + Season6.vetoButtonLength
  Season6.timeItemAssigned = 0
  g.run.restart = true
  Isaac.DebugString("Restarting because we vetoed item: " .. tostring(Season6.lastBuildItem))
end

-- ModCallbacks.MC_POST_RENDER (2)
function Season6:PostRender()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     Speedrun.charNum ~= 1 or
     g.run.roomsEntered ~= 1 then

    return
  end

  -- Don't draw the Veto text if there is not a valid order set
  if not Speedrun:CheckValidCharOrder() then
    return
  end

  -- Draw the sprites that correspond to the items that are currently on the veto list
  local x = -45
  for i = 1, #Season6.vetoList do
    local itemPosGame = g:GridToPos(11, 7)
    local itemPos = Isaac.WorldToRenderPosition(itemPosGame)
    x = x + 15
    itemPos = Vector(itemPos.X + x, itemPos.Y)
    Season6.vetoSprites[i]:Render(itemPos, g.zeroVector, g.zeroVector)
  end

  if Season6.vetoTimer == 0 then
    -- Draw the "Veto" text
    local posGame = g:GridToPos(11, 5)
    local pos = Isaac.WorldToRenderPosition(posGame)
    local string = "Veto"
    local length = g.font:GetStringWidthUTF8(string)
    g.font:DrawString(string, pos.X - (length / 2), pos.Y, g.kcolor, 0, true)
  end
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season6:PostGameStartedFirstCharacter()
  Speedrun.remainingItemStarts = g:TableClone(Season6.itemStarts)
  if Isaac.GetTime() - Season6.timeItemAssigned >= Season6.itemLockTime then
    Speedrun.selectedItemStarts = {}
  end
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season6:PostGameStarted()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 6) challenge.")

  -- If Eden starts with The Compass as the random passive item or a banned trinket, restart the game
  if character == PlayerType.PLAYER_EDEN and -- 9
     (g.p:HasCollectible(CollectibleType.COLLECTIBLE_COMPASS) or -- 21
      g.p:HasTrinket(TrinketType.TRINKET_CAINS_EYE) or -- 59
      g.p:HasTrinket(TrinketType.TRINKET_BROKEN_ANKH)) then -- 28

    g.run.restart = true
    Speedrun.fastReset = true
    Isaac.DebugString("Restarting because Eden started with either The Compass, Cain's Eye, or Broken Ankh.")
    return
  end

  -- Everyone starts with the Schoolbag in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Everyone starts with the Compass in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_COMPASS) -- 21
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Since this season has a custom death mechanic, we also want to remove the Broken Ankh
  -- (since we need the custom revival to always take priority over random revivals)
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_BROKEN_ANKH) -- 28

  -- Everyone starts with a random passive item / build
  -- Check to see if the player has played a run with one of the big 4
  local alreadyStartedBig4 = false
  for _, startedBuild in ipairs(Speedrun.selectedItemStarts) do
    for _, big4Item in ipairs(Season6.big4) do
      if startedBuild[1] == big4Item then
        alreadyStartedBig4 = true
        break
      end
    end
  end
  Isaac.DebugString("Already started a run with the big 4: " .. tostring(alreadyStartedBig4))

  -- Disable starting a big 4 item on the first character
  if Speedrun.charNum == 1 then
    alreadyStartedBig4 = true
  end

  -- Check to see if a start is already assigned for this character number
  -- (dying and resetting should not reassign the selected starting item)
  Isaac.DebugString("Number of builds that we have already started: " .. tostring(#Speedrun.selectedItemStarts))
  local startingBuild = Speedrun.selectedItemStarts[Speedrun.charNum]
  if startingBuild == nil then
    -- Get a random start
    local seed = g.seeds:GetStartSeed()
    local randomAttempts = 0
    while true do
      seed = g:IncrementRNG(seed)
      math.randomseed(seed)
      local startingBuildIndex
      if alreadyStartedBig4 then
        startingBuildIndex = math.random(5, #Speedrun.remainingItemStarts)
      elseif Speedrun.charNum >= 2 and Speedrun.charNum <= 6 then
        local startBig4 = math.random(1, 8 - Speedrun.charNum)
        if startBig4 == 1 then
          startingBuildIndex = math.random(1, 4)
        else
          startingBuildIndex = math.random(5, #Speedrun.remainingItemStarts)
        end
      elseif Speedrun.charNum == 7 then
        -- Guarantee at least one big 4 start
        startingBuildIndex = math.random(1, 4)
      else
        startingBuildIndex = math.random(1, #Speedrun.remainingItemStarts)
      end
      startingBuild = Speedrun.remainingItemStarts[startingBuildIndex]

      local valid = true

      -- If we are on the first character, we do not want to play a build that we have already played recently
      if Speedrun.charNum == 1 and
         (startingBuild[1] == Season6.lastBuildItem or
          startingBuild[1] == Season6.lastBuildItemOnFirstChar) then

        valid = false
      end

      -- Check to see if we already started this item
      for _, startedBuild in ipairs(Speedrun.selectedItemStarts) do
        if startedBuild[1] == startingBuild[1] then
          valid = false
          break
        end
      end

      -- Check to see if we banned this item
      local charOrder = RacingPlusData:Get("charOrder-R7S6")
      for i = 8, #charOrder do
        local item = charOrder[i]

        -- Convert builds to the primary item
        if item == 1006 then
          item = CollectibleType.COLLECTIBLE_CHOCOLATE_MILK -- 69
        elseif item == 1005 then
          item = CollectibleType.COLLECTIBLE_JACOBS_LADDER -- 494
        elseif item == 1001 then
          item = CollectibleType.COLLECTIBLE_MUTANT_SPIDER -- 153
        elseif item == 1002 then
          item = CollectibleType.COLLECTIBLE_TECHNOLOGY -- 68
        elseif item == 1003 then
          item = CollectibleType.COLLECTIBLE_FIRE_MIND -- 257
        end

        if startingBuild[1] == item then
          valid = false
          break
        end
      end

      -- Check to see if this start synergizes with this character (character/item bans)
      if character == PlayerType.PLAYER_JUDAS then -- 3
        if startingBuild[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW then -- 311
          valid = false
        end

      elseif character == PlayerType.PLAYER_EVE then -- 5
        if startingBuild[1] == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
          valid = false
        end

      elseif character == PlayerType.PLAYER_AZAZEL then -- 7
        if startingBuild[1] == CollectibleType.COLLECTIBLE_IPECAC or -- 149
           startingBuild[1] == CollectibleType.COLLECTIBLE_MUTANT_SPIDER or -- 153
           startingBuild[1] == CollectibleType.COLLECTIBLE_CRICKETS_BODY or -- 224
           startingBuild[1] == CollectibleType.COLLECTIBLE_DEAD_EYE or -- 373
           startingBuild[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW or -- 331
           startingBuild[1] == CollectibleType.COLLECTIBLE_FIRE_MIND or -- 257
           startingBuild[1] == CollectibleType.COLLECTIBLE_JACOBS_LADDER then -- 494

          valid = false
        end

      elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
        if startingBuild[1] == CollectibleType.COLLECTIBLE_DEATHS_TOUCH or -- 237
           startingBuild[1] == CollectibleType.COLLECTIBLE_FIRE_MIND or -- 257
           startingBuild[1] == CollectibleType.COLLECTIBLE_LIL_BRIMSTONE or -- 275
           startingBuild[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW or -- 311
           startingBuild[1] == CollectibleType.COLLECTIBLE_INCUBUS then -- 350

          valid = false
        end
      end

      -- Check to see if we vetoed this item and we are on the first character
      if Speedrun.charNum == 1 then
        for _, veto in ipairs(Season6.vetoList) do
          if veto == startingBuild[1] then
            valid = false
            break
          end
        end
      end

      -- Just in case, prevent the possibility of having an infinite loop here
      if randomAttempts >= 100 then
        valid = true
      end

      if valid then
        -- Keep track of what item we start so that we don't get the same two starts in a row
        Season6.lastBuildItem = startingBuild[1]
        if Speedrun.charNum == 1 then
          Season6.lastBuildItemOnFirstChar = startingBuild[1]
        end
        Isaac.DebugString("Set the last starting build to: " .. tostring(Season6.lastBuildItem))

        -- Remove it from the remaining item pool
        table.remove(Speedrun.remainingItemStarts, startingBuildIndex)

        -- Keep track of what item we are supposed to be starting on this character / run
        Speedrun.selectedItemStarts[#Speedrun.selectedItemStarts + 1] = startingBuild

        -- Mark down the time that we assigned this item
        Season6.timeItemAssigned = Isaac.GetTime()

        -- Break out of the infinite loop
        Isaac.DebugString("Assigned a starting item of: " .. tostring(startingBuild[1]))
        break
      end

      randomAttempts = randomAttempts + 1
    end

  else
    Isaac.DebugString("Already assigned an item: " .. tostring(startingBuild[1]))
  end

  -- Give the items to the player (and remove the items from the pools)
  for _, item in ipairs(startingBuild) do
    -- Eden might have already started with this item, so reset the run if so
    if character == PlayerType.PLAYER_EDEN and -- 9
       g.p:HasCollectible(item) then

      g.run.restart = true
      Speedrun.fastReset = true
      Isaac.DebugString("Restarting because Eden naturally started with the selected starting item of: " ..
                        tostring(item))
      return
    end

    g.p:AddCollectible(item, 0, false)
    g.itemPool:RemoveCollectible(item)

    if item == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
      -- Also remove the additional soul hearts from Crown of Light
      g.p:AddSoulHearts(-4)

      -- Re-heal Judas back to 1 red heart so that they can properly use the Crown of Light
      -- (this should do nothing on all of the other characters)
      g.p:AddHearts(1)
    end
  end

  -- Spawn a "Veto" button on the first character
  if Season6.vetoTimer ~= 0 and
     Isaac.GetTime() >= Season6.vetoTimer then

      Season6.vetoTimer = 0
  end
  if Speedrun.charNum == 1 and
     Season6.vetoTimer == 0 then

    local pos = g:GridToPos(11, 6)
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function Season6:PostNewRoom()
  -- Local variables
  local stage = g.l:GetStage()
  local startingRoomIndex = g.l:GetStartingRoomIndex()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local challenge = Isaac.GetChallenge()

  -- Delete the veto button if we are re-entering the starting room
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") and
     stage == 1 and
     roomIndex == startingRoomIndex and
     g.run.roomsEntered ~= 1 then

    g.r:RemoveGridEntity(117, 0, false)
  end
end

-- ModCallbacks.MC_POST_BOMB_UPDATE (58)
function Season6:PostBombUpdate(bomb)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") then
    return
  end

  if bomb.SpawnerType ~= EntityType.ENTITY_PLAYER or -- 1
     bomb.FrameCount ~= 1 then

    return
  end

  -- Find out if this bomb has the homing flag
  local homing = (bomb.Flags & (1 << 2)) >> 2
  if homing == 0 then
    return
  end

  -- Don't do anything if we do not have Sacred Heart
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SACRED_HEART) then -- 182
    return
  end

  -- Don't do anything if we have Dr. Fetus or Bobby Bomb (normal homing bombs)
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or -- 52
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_BOBBY_BOMB) then -- 125

    return
  end

  -- Remove the homing bombs from Sacred Heart
  -- (bombs use tear flags for some reason)
  bomb.Flags = bomb.Flags & ~TearFlags.TEAR_HOMING -- 1 << 2
end

-- ModCallbacks.MC_POST_ENTITY_KILL (68)
function Season6:PostEntityKill(entity)
  -- Local variables
  local challenge = Isaac.GetChallenge()
  local stage = g.l:GetStage()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") then
    return
  end

  -- We only care about when a boss dies
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end
  if not npc:IsBoss() then
    return
  end

  -- Reset the starting item timer if we just killed the Basement 2 boss
  if stage == 2 then
    Season6.timeItemAssigned = 0
  end
end

return Season6
