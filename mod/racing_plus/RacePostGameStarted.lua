local RacePostGameStarted = {}

-- Includes
local g         = require("racing_plus/globals")
local Sprites   = require("racing_plus/sprites")
local Schoolbag = require("racing_plus/schoolbag")

local validDiversityActiveItems = {
	-- Rebirth items
	33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
	44, 45, 47, 49, 56, 58, 65, 66, 77, 78,
	83, 84, 85, 86, 93, 97, 102, 105, 107, 111,
	123, 124, 126, 127, 130, 133, 135, 136, 137, 145,
	146, 147, 158, 160, 164, 166, 171, 175, 177, 181,
	186, 192, 282, 285, 286, 287, 288, 289, 290, 291, -- D100 (283) and D4 (284) are banned
	292, 293, 294, 295, 296, 297, 298, 323, 324, 325,
	326, 338,

	-- Afterbirth items
	347, 348, 349, 351, 352, 357, 382, 383, 386, 396,
	406, 419, 421, 422, 427, 434, 437, 439, 441,

	-- Afterbirth+ items
	475, 476, 477, 478, 479, 480, 481, 482, 483, 484,
	485, 486, 487, 488, 490, 504, 507, 510, -- D Infinity (489) is banned

	-- Booster Pack items
	512, 515, 516, 521, 522, 523, 527, 536, 545,
}

local extraActiveItemBansS7 = {
  CollectibleType.COLLECTIBLE_MEGA_SATANS_BREATH, -- 441
  CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER, -- 84
  CollectibleType.COLLECTIBLE_CRYSTAL_BALL, -- 158
}

for _, item in ipairs(extraActiveItemBansS7) do
  g:TableRemove(validDiversityActiveItems, item)
end

local validDiversityPassiveItems = {
	-- Rebirth items
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  -- <3 (15), Raw Liver (16), Lunch (22), Dinner (23), Dessert (24), Breakfast (25), and Rotten Meat (26) are banned
  11, 12, 13, 14, 17, 18, 19, 20, 21, 27,
  -- Mom's Underwear (29), Moms Heels (30), Moms Lipstick (31), and Lucky Foot (46) are banned
  28, 32, 48, 50, 51, 52, 53, 54, 55, 57,
	60, 62, 63, 64, 67, 68, 69, 70, 71, 72,
	73, 74, 75, 76, 79, 80, 81, 82, 87, 88,
	89, 90, 91, 94, 95, 96, 98, 99, 100, 101,--/ Super Bandage (92) is banned
	103, 104, 106, 108, 109, 110, 112, 113, 114, 115,
	116, 117, 118, 119, 120, 121, 122, 125, 128, 129,
	131, 132, 134, 138, 139, 140, 141, 142, 143, 144,
	148, 149, 150, 151, 152, 153, 154, 155, 156, 157,
	159, 161, 162, 163, 165, 167, 168, 169, 170, 172,
	173, 174, 178, 179, 180, 182, 183, 184, 185, 187, -- Stem Cells (176) is banned
	188, 189, 190, 191, 193, 195, 196, 197, 198, 199, -- Magic 8 Ball (194) is banned
	200, 201, 202, 203, 204, 205, 206, 207, 208, 209,
	210, 211, 212, 213, 214, 215, 216, 217, 218, 219,
	220, 221, 222, 223, 224, 225, 227, 228, 229, 230, -- Black Lotus (226) is banned
	231, 232, 233, 234, 236, 237, 240, 241, 242, 243, -- Key Piece #1 (238) and Key Piece #2 (239) are banned
	244, 245, 246, 247, 248, 249, 250, 251, 252, 254, -- Magic Scab (253) is banned
	255, 256, 257, 259, 260, 261, 262, 264, 265, 266, -- Missing No. (258) is banned
	267, 268, 269, 270, 271, 272, 273, 274, 275, 276,
	277, 278, 279, 280, 281, 299, 300, 301, 302, 303,
	304, 305, 306, 307, 308, 309, 310, 311, 312, 313,
	314, 315, 316, 317, 318, 319, 320, 321, 322, 327,
	328, 329, 330, 331, 332, 333, 335, 336, 337, 340, -- The Body (334) and Safety Pin (339) are banned
	341, 342, 343, 345, -- Match Book (344) and A Snack (346) are banned

	-- Afterbirth items
	350, 353, 354, 356, 358, 359, 360, 361, 362, 363, -- Mom's Pearls (355) is banned
	364, 365, 366, 367, 368, 369, 370, 371, 372, 373,
	374, 375, 376, 377, 378, 379, 380, 381, 384, 385,
	387, 388, 389, 390, 391, 392, 393, 394, 395, 397,
	398, 399, 400, 401, 402, 403, 404, 405, 407, 408,
	409, 410, 411, 412, 413, 414, 415, 416, 417, 418,
	420, 423, 424, 425, 426, 429, 430, 431, 432, 433, -- PJs (428) is banned
	435, 436, 438, 440,

	-- Afterbirth+ items
	442, 443, 444, 445, 446, 447, 448, 449, 450, 451,
	452, 453, 454, 457, 458, 459, 460, 461, 462, 463, -- Dad's Lost Coin (455) and Moldy Bread (456) are banned
	464, 465, 466, 467, 468, 469, 470, 471, 472, 473,
	474, 491, 492, 493, 494, 495, 496, 497, 498, 499,
	500, 501, 502, 503, 505, 506, 508, 509,

	-- Booster Pack items
  511, 513, 514, 517, 518, 519, 520, 524, 525, 526,
  528, 529, 530, 531, 532, 533, 535, 537, 538, 539, -- Schoolbag (534) is given on every run already
  540, 541, 542, 543, 544, 546, 547, 548, 549,
}

local extraPassiveItemBansS7 = {
  CollectibleType.COLLECTIBLE_20_20, -- 245
  CollectibleType.COLLECTIBLE_CRICKETS_BODY, -- 224
  CollectibleType.COLLECTIBLE_MAXS_HEAD, -- 4
  CollectibleType.COLLECTIBLE_DEAD_EYE, -- 373
  CollectibleType.COLLECTIBLE_DEATHS_TOUCH, -- 237
  CollectibleType.COLLECTIBLE_DR_FETUS, -- 52
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
  CollectibleType.COLLECTIBLE_JUDAS_SHADOW, -- 311
  CollectibleType.COLLECTIBLE_LIL_BRIMSTONE, -- 275
  CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM, -- 12
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_MONSTROS_LUNG, -- 229
  CollectibleType.COLLECTIBLE_POLYPHEMUS, -- 169
  CollectibleType.COLLECTIBLE_PROPTOSIS, -- 261
  CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, -- 172
  CollectibleType.COLLECTIBLE_TECH_5, -- 244
  CollectibleType.COLLECTIBLE_TECH_X, -- 395

  CollectibleType.COLLECTIBLE_BRIMSTONE, -- 118
  CollectibleType.COLLECTIBLE_INCUBUS, -- 360
  CollectibleType.COLLECTIBLE_MAW_OF_VOID, -- 399

  CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT, -- 415
  CollectibleType.COLLECTIBLE_GODHEAD, -- 331
  CollectibleType.COLLECTIBLE_SACRED_HEART, -- 182

  CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, -- 69
  CollectibleType.COLLECTIBLE_JACOBS_LADDER, -- 494

  CollectibleType.COLLECTIBLE_TINY_PLANET, -- 233
  CollectibleType.COLLECTIBLE_SOY_MILK, -- 330
  CollectibleType.COLLECTIBLE_MIND, -- 333
}

for _, item in ipairs(extraPassiveItemBansS7) do
  g:TableRemove(validDiversityPassiveItems, item)
end

local validDiversityTrinkets = {
	-- Rebirth trinkets
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
	11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
	21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
	31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 48, 49, 50, 51,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61,

	-- Afterbirth trinkets
	62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
	72, 73, 74, 75, 76, 77, 78, 79, 80, 81,
	82, 83, 84, 86, 87, 88, 89, 90, -- Karma (85) is banned

	-- Afterbirth+ trinkets
	91, 92, 93, 94, 95, 96, 97, 98, 99, 100,
	101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
	111, 112, 113, 114, 115, 116, 117, 118, 119,

	-- Booster pack trinkets
	120, 121, 122, 123, 124, 125, 126, 127, 128,
}

local extraTrinketBansS7 = {
  TrinketType.TRINKET_OUROBOROS_WORM, -- 96
}

for _, trinket in ipairs(extraTrinketBansS7) do
  g:TableRemove(validDiversityTrinkets, trinket)
end

-- This occurs when first going into the game and after a reset occurs mid-race
function RacePostGameStarted:Main()
  -- Do special ruleset related initialization first
  -- (we want to be able to do runs of them without using the R+ client)
  if g.race.rFormat == "pageant" then
    RacePostGameStarted:Pageant()
    return
  end

  --
  -- Race validation
  --

  -- If we are not in a race, don't do anything special
  if g.race.status == "none" then
    return
  end

  -- Local variables
  local character = g.p:GetPlayerType()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Validate that we are not on a custom challenge
  if challenge ~= 0 and
     g.race.rFormat ~= "custom" then

    g.g:Fadeout(0.05, g.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
    Isaac.DebugString("We are in a race but also in a custom challenge; fading out back to the menu.")
    return
  end

  -- Validate the difficulty (hard mode / Greed mode) for races
  if g.race.difficulty == "normal" and
     g.g.Difficulty ~= Difficulty.DIFFICULTY_NORMAL then -- 0

    Isaac.DebugString("Race error: Supposed to be on easy mode (currently on " .. tostring(g.g.Difficulty) .. ").")
    return

  elseif g.race.difficulty == "hard" and
         g.g.Difficulty ~= Difficulty.DIFFICULTY_HARD then -- 1

    Isaac.DebugString("Race error: Supposed to be on hard mode (currently on " .. tostring(g.g.Difficulty) .. ").")
    return
  end

  if g.race.rFormat == "seeded" and
     g.race.status == "in progress" then

    -- Validate that we are on the intended seed
    if g.seeds:GetStartSeedString() ~= g.race.seed then
      -- Doing a "seed #### ####" here does not work for some reason, so mark to reset on the next frame
      g.run.restart = true
      Isaac.DebugString("Restarting because we were not on the right seed.")
      return true
    end

  elseif g.race.rFormat == "unseeded" or
          g.race.rFormat == "diversity" or
          g.race.rFormat == "pageant" then

    -- Validate that we are not on a set seed
    -- (this will be true if we are on a set seed or on a challenge,
    -- but we won't get this far if we are on a challenge)
    if customRun and
       not g.debug then -- Make an exception if we are trying to debug something on a certain seed

      -- If the run started with a set seed, this will change the reset behavior to that of an unseeded run
      g.seeds:Reset()

      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      g.run.restart = true
      Isaac.DebugString("Restarting because we were on a set seed.")
      return true
    end
  end

  -- Validate that we are on the right character
  if character ~= g.race.character and
     g.race.rFormat ~= "custom" then

    -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
    g.run.restart = true
    Isaac.DebugString("Restarting because we were not on the right character.")
    return true
  end

  -- The Racing+ client will look for this message to determine that
  -- the user has successfully downloaded and is running the Racing+ Lua mod
  Isaac.DebugString("Race validation succeeded.")

  -- Give extra items depending on the format
  if g.race.rFormat == "unseeded" then
    if g.race.ranked and g.race.solo then
      RacePostGameStarted:UnseededRankedSolo()
    else
      RacePostGameStarted:Unseeded()
    end

  elseif g.race.rFormat == "seeded" then
    RacePostGameStarted:Seeded()

  elseif g.race.rFormat == "diversity" then
    -- If the diversity race has not started yet, don't give the items
    if g.raceVars.started then
      g.run.diversity = true -- Mark to not remove the 3 placeholder items later on
      RacePostGameStarted:Diversity()
    end

  elseif g.race.rFormat == "seededMO" then
    RacePostGameStarted:SeededMO()
  end
end

function RacePostGameStarted:Unseeded()
  -- Unseeded is like vanilla, but the player will still start with More Options to reduce resetting time
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
  -- We don't want the costume to show
  Isaac.DebugString("Removing collectible 414 (More Options)")
  -- We don't need to show this on the item tracker to reduce clutter
  g.run.removeMoreOptions = true
  -- More Options will be removed upon entering the first Treasure Room
end

function RacePostGameStarted:Seeded()
  -- Local variables
  local character = g.p:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_COMPASS) then -- 21
    -- Eden can start with The Compass
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_COMPASS) -- 21
  end
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    -- Eden and Samael start with the Schoolbag
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end

  -- Give the player the "Instant Start" item(s)
  local replacedD6 = false
  for _, itemID in ipairs(g.race.startingItems) do
    if itemID == 600 then
      -- The 13 luck is a special case
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_13_LUCK, 0, false)
    else
      -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
      g.p:AddCollectible(itemID, g:GetItemMaxCharges(itemID), true)

      -- Remove it from all the pools
      g.itemPool:RemoveCollectible(itemID)

      -- Find out if Crown of Light is one of the starting items
      if itemID == 415 then
        -- Remove the 2 soul hearts that it gives
        g.p:AddSoulHearts(-4)

        -- Re-heal Judas back to 1 red heart so that they can properly use the Crown of Light
        -- (this should do nothing on all of the other characters)
        g.p:AddHearts(1)
      end
    end
  end

  -- Find out if we replaced the D6
  local newActiveItem = g.p:GetActiveItem()
  local newActivecharge = g.p:GetActiveCharge()
  if newActiveItem ~= CollectibleType.COLLECTIBLE_D6 then -- 105
    -- We replaced the D6 with an active item, so put the D6 back and put this item in the Schoolbag
    replacedD6 = true
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    Schoolbag:Put(newActiveItem, newActivecharge)
  end

  -- Give the player extra Schoolbag items, depending on the character
  if not replacedD6 then
    if character == PlayerType.PLAYER_MAGDALENA then -- 1
      Schoolbag:Put(CollectibleType.COLLECTIBLE_YUM_HEART, "max") -- 45
    elseif character == PlayerType.PLAYER_JUDAS then -- 3
      Schoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, "max") -- 34
    elseif character == PlayerType.PLAYER_XXX then -- 4
      Schoolbag:Put(CollectibleType.COLLECTIBLE_POOP, "max") -- 36
    elseif character == PlayerType.PLAYER_EVE then -- 5
      Schoolbag:Put(CollectibleType.COLLECTIBLE_RAZOR_BLADE, "max") -- 126
    elseif character == PlayerType.PLAYER_THELOST then -- 10
      Schoolbag:Put(CollectibleType.COLLECTIBLE_D4, "max") -- 284
    elseif character == PlayerType.PLAYER_LILITH then -- 13
      Schoolbag:Put(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, "max") -- 357
    elseif character == PlayerType.PLAYER_KEEPER then -- 14
      Schoolbag:Put(CollectibleType.COLLECTIBLE_WOODEN_NICKEL, "max") -- 349
    elseif character == PlayerType.PLAYER_APOLLYON then -- 15
      Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
    end
  end

  -- Reorganize the items on the item tracker so that the "Instant Start" item comes after the Schoolbag item
  for _, itemID in ipairs(g.race.startingItems) do
    if itemID == 600 then
      itemID = tostring(CollectibleType.COLLECTIBLE_13_LUCK)
      Isaac.DebugString("Removing collectible " .. itemID .. " (13 Luck)")
      Isaac.DebugString("Adding collectible " .. itemID .. " (13 Luck)")
    else
      Isaac.DebugString("Removing collectible " .. itemID)
      Isaac.DebugString("Adding collectible " .. itemID)
    end
  end

  -- Add item bans for seeded mode
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Since this race type has a custom death mechanic, we also want to remove the Broken Ankh
  -- (since we need the custom revival to always take priority over random revivals)
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_BROKEN_ANKH) -- 28

  -- Initialize the sprites for the starting room
  -- (don't show these graphics until the race starts)
  if g.race.status == "in progress" then
    if #g.race.startingItems == 1 then
      Sprites:Init("seeded-starting-item", "seeded-starting-item")
      Sprites:Init("seeded-item1", tostring(g.race.startingItems[1]))
    elseif #g.race.startingItems == 2 then
      Sprites:Init("seeded-starting-build", "seeded-starting-build")
      Sprites:Init("seeded-item2", tostring(g.race.startingItems[1]))
      Sprites:Init("seeded-item3", tostring(g.race.startingItems[2]))
    elseif #g.race.startingItems == 4 then
      -- Only the Mega Blast build has 4 starting items
      Sprites:Init("seeded-starting-build", "seeded-starting-build")
      Sprites:Init("seeded-item2", tostring(g.race.startingItems[2]))
      Sprites:Init("seeded-item3", tostring(g.race.startingItems[3]))
      Sprites:Init("seeded-item4", tostring(g.race.startingItems[1])) -- This will be to the left of 2
      Sprites:Init("seeded-item5", tostring(g.race.startingItems[4])) -- This will be to the right of 3
    end
  end

  Isaac.DebugString("Added seeded items.")
end

function RacePostGameStarted:Diversity()
  -- Local variables
  local startSeed = g.seeds:GetStartSeed()
  local character = g.p:GetPlayerType()
  local trinket1 = g.p:GetTrinket(0) -- This will be 0 if there is no trinket
  local challenge = Isaac.GetChallenge()

  -- Give the player extra starting items (for diversity races)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    -- Eden and Samael start with the Schoolbag already
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) then
    -- More Options will be removed upon entering the first Treasure Room
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414

    -- We don't want the costume to show
    g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
    Isaac.DebugString("Removing collectible 414 (More Options)")

    -- We don't need to show this on the item tracker to reduce clutter
    g.run.removeMoreOptions = true
  end

  -- The server will have sent us the starting items
  local startingItems = g.race.startingItems

  -- We need to generate the starting items if we are in Season 7
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then
    math.randomseed(startSeed)

    -- Get 1 random active item
    local activeRandomIndex = math.random(1, #validDiversityActiveItems)
    local activeItem = validDiversityActiveItems[activeRandomIndex]
    startingItems[#startingItems + 1] = activeItem

    -- Get 3 random unique passive items
    for i = 1, 3 do
      while true do
        -- Initialize the PRNG and get a random element from the slice
        -- (if we don't do this, it will use a seed of 1)
        local randomPassiveIndex = math.random(1, #validDiversityPassiveItems)
        local passiveItem = validDiversityPassiveItems[randomPassiveIndex]

        -- Do character specific item bans
        local valid = true
        if character == PlayerType.PLAYER_CAIN then -- 2
          if passiveItem == CollectibleType.COLLECTIBLE_LUCKY_FOOT then -- 46
            valid = false
          end
        elseif character == PlayerType.PLAYER_EVE then -- 5
          if passiveItem == CollectibleType.COLLECTIBLE_DEAD_BIRD then -- 117
            valid = false
          elseif passiveItem == CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON then -- 122
            valid = false
          end
        elseif character == PlayerType.PLAYER_SAMSON then -- 6
          if passiveItem == CollectibleType.COLLECTIBLE_BLOODY_LUST then -- 157
            valid = false
          end
        elseif character == PlayerType.PLAYER_LAZARUS then -- 8
          if passiveItem == CollectibleType.COLLECTIBLE_ANEMIC then -- 214
            valid = false
          end
        elseif character == PlayerType.PLAYER_THELOST then -- 10
          if passiveItem == CollectibleType.COLLECTIBLE_HOLY_MANTLE then -- 313
            valid = false
          end
        elseif character == PlayerType.PLAYER_LILITH then -- 13
          if passiveItem == CollectibleType.COLLECTIBLE_CAMBION_CONCEPTION then -- 412
            valid = false
          end
        elseif character == PlayerType.PLAYER_KEEPER then -- 14
          if passiveItem == CollectibleType.COLLECTIBLE_ABADDON then -- 230
            valid = false
          end
        end

        -- Ensure this item is unique
        if g:TableContains(startingItems, passiveItem) then
          valid = false
        end

        if valid then
          startingItems[#startingItems + 1] = passiveItem
          break
        end
      end
    end

    -- Get 1 random trinket
    local trinketRandomIndex = math.random(1, #validDiversityTrinkets)
    local trinket = validDiversityTrinkets[trinketRandomIndex]
    startingItems[#startingItems + 1] = trinket
  end

  -- Give the player their five random diversity starting items
  for i, itemID in ipairs(startingItems) do
    if i == 1 then
      -- Item 1 is the active
      Schoolbag:Put(itemID, "max")
      if g.run.schoolbag.item == CollectibleType.COLLECTIBLE_EDENS_SOUL then -- 490
        g.run.schoolbag.charge = 0 -- This is the only item that does not start with any charges
      end

      -- Give them the item so that the player gets any inital pickups (e.g. Remote Detonator)
      g.p:AddCollectible(itemID, 0, true)

      -- Swap back for the D6
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false)

      -- Update the cache (in case we had an active item that granted stats, like A Pony)
      g.p:AddCacheFlags(CacheFlag.CACHE_ALL)
      g.p:EvaluateItems()

      -- Remove the costume, if any (some items give a costume, like A Pony)
      g.p:RemoveCostume(g.itemConfig:GetCollectible(itemID))

    elseif i == 2 or i == 3 or i == 4 then
      -- Items 2, 3, and 4 are the passives
      -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
      g.p:AddCollectible(itemID, g:GetItemMaxCharges(itemID), true)

      -- Remove it from all of the item pools
      -- (make an exception for items that you can normally get duplicates of)
      if itemID ~= CollectibleType.COLLECTIBLE_CUBE_OF_MEAT and -- 73
          itemID ~= CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES then -- 207

        g.itemPool:RemoveCollectible(itemID)
        if itemID == CollectibleType.COLLECTIBLE_INCUBUS then -- 360
          g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1)
        elseif itemID == CollectibleType.COLLECTIBLE_SACRED_HEART then -- 182
          g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2)
        elseif itemID == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
          g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3)
        end
      end

    elseif i == 5 then
      -- Item 5 is the trinket
      g.p:TryRemoveTrinket(trinket1) -- It is safe to feed 0 to this function
      g.p:AddTrinket(itemID)
      g.p:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false)
      -- Use the custom Smelter so that the item tracker knows about the trinket we consumed

      -- Regive Paper Clip to Cain, for example
      if trinket1 ~= 0 then
        g.p:AddTrinket(trinket1) -- The game crashes if 0 is fed to this function
      end

      -- Remove it from the trinket pool
      g.itemPool:RemoveTrinket(itemID)
    end
  end

  -- Add item bans for diversity races
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_TECH_X) -- 395
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_D4) -- 284
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_D100) -- 283
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DINF) -- 489
  if g.run.schoolbag.item == CollectibleType.COLLECTIBLE_BLOOD_RIGHTS then -- 186
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_ISAACS_HEART) -- 276
  end
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_ISAACS_HEART) then -- 276
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BLOOD_RIGHTS) -- 186
  end
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then -- 330
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LIBRA) -- 304
    end
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_LIBRA) then -- 304
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) -- 330
    end
  end

  -- Initialize the sprites for the starting room
  Sprites:Init("diversity-active", "diversity-active")
  Sprites:Init("diversity-passives", "diversity-passives")
  Sprites:Init("diversity-trinket", "diversity-trinket")
  Sprites:Init("diversity-item1", tostring(startingItems[1]))
  Sprites:Init("diversity-item2", tostring(startingItems[2]))
  Sprites:Init("diversity-item3", tostring(startingItems[3]))
  Sprites:Init("diversity-item4", tostring(startingItems[4]))
  Sprites:Init("diversity-item5", tostring(startingItems[5]))

  Isaac.DebugString("Added diversity items.")
end

function RacePostGameStarted:Pageant()
  -- Add the extra items
  -- (the extra luck is handled in the EvaluateCache callback)
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  Schoolbag:Put(CollectibleType.COLLECTIBLE_DADS_KEY, "max") -- 175
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MAXS_HEAD, 0, false) -- 4
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MAXS_HEAD) -- 4
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 246
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 246
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_BELLY_BUTTON, 0, false) -- 458
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BELLY_BUTTON) -- 458
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_CANCER, 0, false) -- 301
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CANCER) -- 301
  g.p:AddTrinket(TrinketType.TRINKET_CANCER) -- 39
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CANCER) -- 39

  -- Delete the trinket that drops from the Belly Button
  local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, -1, false, false) -- 5.350
  for _, pickup in ipairs(pickups) do
    pickup:Remove()
  end

  Isaac.DebugString("Added Pageant Boy ruleset items.")
end

function RacePostGameStarted:UnseededRankedSolo()
  -- The client will populate the starting items for the current season into the "startingItems" variable
  for _, itemID in ipairs(g.race.startingItems) do
    g.p:AddCollectible(itemID, 12, true)
    g.itemPool:RemoveCollectible(itemID)
  end
end

function RacePostGameStarted:SeededMO()
  -- Local variables
  local character = g.p:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_COMPASS) then -- 21
    -- Eden can start with The Compass
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_COMPASS) -- 21
  end
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    -- Eden and Samael start with the Schoolbag
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end

  -- Give the player extra Schoolbag items, depending on the character
  if character == PlayerType.PLAYER_MAGDALENA then -- 1
    Schoolbag:Put(CollectibleType.COLLECTIBLE_YUM_HEART, "max") -- 45
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, "max") -- 34
  elseif character == PlayerType.PLAYER_XXX then -- 4
    Schoolbag:Put(CollectibleType.COLLECTIBLE_POOP, "max") -- 36
  elseif character == PlayerType.PLAYER_EVE then -- 5
    Schoolbag:Put(CollectibleType.COLLECTIBLE_RAZOR_BLADE, "max") -- 126
  elseif character == PlayerType.PLAYER_THELOST then -- 10
    Schoolbag:Put(CollectibleType.COLLECTIBLE_D4, "max") -- 284
  elseif character == PlayerType.PLAYER_LILITH then -- 13
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, "max") -- 357
  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    Schoolbag:Put(CollectibleType.COLLECTIBLE_WOODEN_NICKEL, "max") -- 349
  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
  end

  -- Add item bans for seeded mode
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Since this race type has a custom death mechanic, we also want to remove the Broken Ankh
  -- (since we need the custom revival to always take priority over random revivals)
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_BROKEN_ANKH) -- 28

  -- Seeded MO specific things
  g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 105
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DINF) -- 59

  Isaac.DebugString("Added seeded MO items.")
end

return RacePostGameStarted
