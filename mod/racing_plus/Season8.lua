local Season8 = {}

-- Includes
local g         = require("racing_plus/globals")
local Schoolbag = require("racing_plus/schoolbag")

-- Constants
Season8.startingItems = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
  CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, -- 172
  CollectibleType.COLLECTIBLE_20_20, -- 245
  CollectibleType.COLLECTIBLE_PROPTOSIS, -- 261
  CollectibleType.COLLECTIBLE_LIL_BRIMSTONE, -- 275
  CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM, -- 12
  CollectibleType.COLLECTIBLE_TECH_5, -- 244
  CollectibleType.COLLECTIBLE_POLYPHEMUS, -- 169
  CollectibleType.COLLECTIBLE_MAXS_HEAD, -- 4
  CollectibleType.COLLECTIBLE_DEATHS_TOUCH, -- 237
  CollectibleType.COLLECTIBLE_DEAD_EYE, -- 373
  CollectibleType.COLLECTIBLE_CRICKETS_BODY, -- 224
  CollectibleType.COLLECTIBLE_DR_FETUS, -- 52
  CollectibleType.COLLECTIBLE_MONSTROS_LUNG, -- 229
}
Season8.goodDevilItems = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_BRIMSTONE, -- 118
  CollectibleType.COLLECTIBLE_MAW_OF_VOID, -- 399
  CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, -- 172
  CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER, -- 84
  CollectibleType.COLLECTIBLE_MEGA_SATANS_BREATH, -- 441
  CollectibleType.COLLECTIBLE_INCUBUS, -- 360
  CollectibleType.COLLECTIBLE_ABADDON, -- 230
  CollectibleType.COLLECTIBLE_DEATHS_TOUCH, -- 237
  CollectibleType.COLLECTIBLE_LIL_BRIMSTONE, -- 275
  CollectibleType.COLLECTIBLE_SUCCUBUS, -- 417
}
Season8.goodAngelItems = {
  CollectibleType.COLLECTIBLE_GODHEAD, -- 331
  CollectibleType.COLLECTIBLE_SACRED_HEART, -- 182
  CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT, -- 415
  CollectibleType.COLLECTIBLE_MIND, -- 333
}
Season8.pillEffects = {
  PillEffect.PILLEFFECT_BALLS_OF_STEEL, -- 2
  PillEffect.PILLEFFECT_BOMBS_ARE_KEYS, -- 3
  PillEffect.PILLEFFECT_HEALTH_DOWN, -- 6
  PillEffect.PILLEFFECT_HEALTH_UP, -- 7
  PillEffect.PILLEFFECT_PRETTY_FLY, -- 10
  PillEffect.PILLEFFECT_SPEED_DOWN, -- 13
  PillEffect.PILLEFFECT_SPEED_UP, -- 14
  PillEffect.PILLEFFECT_TEARS_DOWN, -- 15
  PillEffect.PILLEFFECT_TEARS_UP, -- 16
  PillEffect.PILLEFFECT_TELEPILLS, -- 19
  PillEffect.PILLEFFECT_48HOUR_ENERGY, -- 20
  PillEffect.PILLEFFECT_SEE_FOREVER, -- 23
  PillEffect.PILLEFFECT_POWER, -- 36
  PillEffect.PILLEFFECT_IM_DROWSY, -- 41
  PillEffect.PILLEFFECT_GULP, -- 43
}

-- Variables
Season8.touchedItems = {} -- Reset at the beginning of a new run on the first character
Season8.touchedTrinkets = {} -- Reset at the beginning of a new run on the first character
Season8.remainingCards = {} -- Reset at the beginning of a new run on the first character
Season8.runPillEffects = {} -- Reset at the beginning of a new run on the first character
Season8.identifiedPills = {} -- Reset at the beginning of a new run on the first character
Season8.starterSprites = {} -- Reset whenever a new item is touched
Season8.devilSprites = {} -- Reset whenever a new item is touched
Season8.angelSprites = {} -- Reset whenever a new item is touched

-- ModCallbacks.MC_POST_UPDATE (1)
function Season8:PostUpdate()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return
  end

  -- On every frame, check to see if we are holding an item above our heads
  if g.p:IsItemQueueEmpty() then
    return
  end

  if g.p.QueuedItem.Item.Type == ItemType.ITEM_TRINKET then -- 2
    if not g:TableContains(Season8.touchedTrinkets, g.p.QueuedItem.Item.ID) then
      Season8.touchedTrinkets[#Season8.touchedTrinkets + 1] = g.p.QueuedItem.Item.ID
    end
  elseif g.p.QueuedItem.Item.ID ~= CollectibleType.COLLECTIBLE_CHECKPOINT then
    if not g:TableContains(Season8.touchedItems, g.p.QueuedItem.Item.ID) then
      Season8.touchedItems[#Season8.touchedItems + 1] = g.p.QueuedItem.Item.ID
      Season8.starterSprites = {}
      Season8.devilSprites = {}
      Season8.angelSprites = {}
    end
  end
end

function Season8:Pedestals(pickup)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") or
     not g:TableContains(Season8.touchedItems, pickup.SubType) or
     pickup.Touched then

    -- Don't do anything special with this item
    return pickup.SubType
  end

  -- This is a "set" drop that we have already touched
  local itemName = g.itemConfig:GetCollectible(pickup.SubType).Name
  if pickup.SubType == CollectibleType.COLLECTIBLE_CUBE_OF_MEAT and -- 73
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_CUBE_OF_MEAT) and -- 73
     not g:TableContains(Season8.touchedItems, CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES) then -- 207

    Isaac.DebugString("Season 8 - Replacing set-drop item \"" .. itemName .. "\" " ..
                      "with Ball of Bandages (special case).")
    return CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES -- 207

  elseif pickup.SubType == CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES and -- 207
         not g.p:HasCollectible(CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES) and -- 207
         not g:TableContains(Season8.touchedItems, CollectibleType.COLLECTIBLE_CUBE_OF_MEAT) then -- 73

    Isaac.DebugString("Season 8 - Replacing set-drop item \"" .. itemName .. "\" with Cube of Meat (special case).")
    return CollectibleType.COLLECTIBLE_CUBE_OF_MEAT -- 73
  end

  Isaac.DebugString("Season 8 - Replacing set-drop item \"" .. itemName .. "\" with a random item.")
  return 0
end

-- Called from the "PostItemPickup:InsertTrinket()" function
function Season8:RemoveTrinket(trinket)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return
  end

  if not g:TableContains(Season8.touchedTrinkets, trinket) then
    Season8.touchedTrinkets[#Season8.touchedTrinkets + 1] = trinket
  end
end

-- Called from the "SpeedrunPostUpdate:CheckCheckpointTouched()" function
function Season8:CheckpointTouched()
  Season8.identifiedPills = g:TableClone(g.run.pills)
end

-- ModCallbacks.MC_POST_RENDER (2)
function Season8:PostRender()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return
  end

  -- Make the text persist for at least 2 seconds after the player presses tab
  local tabPressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_MAP, i) then -- 13
      tabPressed = true
      break
    end
  end
  if not tabPressed then
    return
  end

  local remainingStarters = {}
  for _, item in ipairs(Season8.startingItems) do
    if not g:TableContains(Season8.touchedItems, item) then
      remainingStarters[#remainingStarters + 1] = item
    end
  end
  local remainingDevil = {}
  for _, item in ipairs(Season8.goodDevilItems) do
    if not g:TableContains(Season8.touchedItems, item) then
      remainingDevil[#remainingDevil + 1] = item
    end
  end
  local remainingAngel = {}
  for _, item in ipairs(Season8.goodAngelItems) do
    if not g:TableContains(Season8.touchedItems, item) then
      remainingAngel[#remainingAngel + 1] = item
    end
  end
  local itemsPerRow = 11

  -- Draw stats about the items/trinkets/cards remaining
  local card = g.p:GetCard(0)
  local pill = g.p:GetPill(0)
  local screenSize = g:GetScreenSize()
  local x = screenSize[1] - 180
  if #Season8.touchedItems >= 100 or
     #Season8.touchedTrinkets >= 100 then

    -- The extra digit will run off the right side of the screen
    x = x - 10
  end
  local baseY = screenSize[2] - 130
  if card ~= 0 or
     pill ~= 0 then

    baseY = baseY - 20
  end
  if #remainingStarters > itemsPerRow then
    baseY = baseY - 20
  end
  local y = baseY
  g.font:DrawString("Items touched:", x, y, g.kcolor, 0, true)
  y = y + 20
  g.font:DrawString("Trinkets touched:", x, y, g.kcolor, 0, true)
  y = y + 20
  g.font:DrawString("Cards used:", x, y, g.kcolor, 0, true)

  y = baseY
  x = x + 125

  -- Brittle Bones (549) is the highest item and there are 5 unused item IDs
  local string
  string = tostring(#Season8.touchedItems) .. " / " .. tostring(549 - 5)
  g.font:DrawString(string, x, y, g.kcolor, 0, true)
  y = y + 20

  string = tostring(#Season8.touchedTrinkets) .. " / " .. tostring(TrinketType.NUM_TRINKETS - 1)
  g.font:DrawString(string, x, y, g.kcolor, 0, true)
  y = y + 20

  local cardsUsed = Card.NUM_CARDS - 1 - #Season8.remainingCards
  string = tostring(cardsUsed) .. " / " .. tostring(Card.NUM_CARDS - 1)
  g.font:DrawString(string, x, y, g.kcolor, 0, true)
  y = y + 20

  -- Draw icons for some important specific items
  local scale = 0.7
  local baseX = screenSize[1] - 235
  local yAdjustment = 23 -- The item sprites need to be adjusted further down than a line of text would

  x = baseX
  string = "Starters:"
  g.font:DrawString(string, x, y, g.kcolor, 0, true)
  x = x + 50
  y = y + yAdjustment
  for i, item in ipairs(remainingStarters) do
    if Season8.starterSprites[i] == nil then
      Season8.starterSprites[i] = Sprite()
      Season8.starterSprites[i]:Load("gfx/005.100_collectible.anm2", false)
      local itemConfig = g.itemConfig:GetCollectible(item)
      local spriteFilePath = itemConfig.GfxFileName
      Season8.starterSprites[i]:ReplaceSpritesheet(1, spriteFilePath)
      Season8.starterSprites[i]:LoadGraphics()
      Season8.starterSprites[i].Scale = Vector(scale, scale)
      Season8.starterSprites[i]:SetFrame("Idle", 0)
    end
    if i == itemsPerRow + 1 then -- Split it up into two separate rows
      y = y + 20
      x = baseX + 50
    end
    x = x + (22 * scale)
    local pos = Vector(x, y)
    Season8.starterSprites[i]:Render(pos, g.zeroVector, g.zeroVector)
  end
  y = y - yAdjustment + 20

  x = baseX
  string = "Devil:"
  g.font:DrawString(string, x, y, g.kcolor, 0, true)
  x = x + 50
  y = y + yAdjustment
  for i, item in ipairs(remainingDevil) do
    if Season8.devilSprites[i] == nil then
      Season8.devilSprites[i] = Sprite()
      Season8.devilSprites[i]:Load("gfx/005.100_collectible.anm2", false)
      local itemConfig = g.itemConfig:GetCollectible(item)
      local spriteFilePath = itemConfig.GfxFileName
      Season8.devilSprites[i]:ReplaceSpritesheet(1, spriteFilePath)
      Season8.devilSprites[i]:LoadGraphics()
      Season8.devilSprites[i].Scale = Vector(scale, scale)
      Season8.devilSprites[i]:SetFrame("Idle", 0)
    end
    x = x + (22 * scale)
    local pos = Vector(x, y)
    Season8.devilSprites[i]:Render(pos, g.zeroVector, g.zeroVector)
  end
  y = y - yAdjustment + 20

  x = baseX
  string = "Angel:"
  g.font:DrawString(string, x, y, g.kcolor, 0, true)
  x = x + 50
  y = y + yAdjustment
  for i, item in ipairs(remainingAngel) do
    if Season8.angelSprites[i] == nil then
      Season8.angelSprites[i] = Sprite()
      Season8.angelSprites[i]:Load("gfx/005.100_collectible.anm2", false)
      local itemConfig = g.itemConfig:GetCollectible(item)
      local spriteFilePath = itemConfig.GfxFileName
      Season8.angelSprites[i]:ReplaceSpritesheet(1, spriteFilePath)
      Season8.angelSprites[i]:LoadGraphics()
      Season8.angelSprites[i].Scale = Vector(scale, scale)
      Season8.angelSprites[i]:SetFrame("Idle", 0)
    end
    x = x + (22 * scale)
    local pos = Vector(x, y)
    Season8.angelSprites[i]:Render(pos, g.zeroVector, g.zeroVector)
  end
end

-- ModCallbacks.MC_USE_CARD (5)
function Season8:UseCard(card)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return
  end

  -- Remove this card from the card pool
  if g:TableContains(Season8.remainingCards, card) then
    g:TableRemove(Season8.remainingCards, card)
    Isaac.DebugString("Season8:UseCard() - Used and removed card: " .. tostring(card))
  else
    Isaac.DebugString("Season8:UseCard() - Used card " .. tostring(card) .. " (but it was not " ..
                      "in the \"remainingCards\" table, so it must have been a duplicate card " ..
                      "from a Jera or something like that.")
  end
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season8:PostGameStartedFirstCharacter()
  -- Reset variables
  Season8.touchedItems = {}
  Season8.touchedTrinkets = {}
  Season8.remainingCards = {}
  Season8.runPillEffects = {}
  Season8.identifiedPills = {}

  -- Fill the card pool with all of the possible cards
  for i = 1, Card.NUM_CARDS - 1 do -- 55
    -- Make an exception for Blank Rune, which should be always removed
    if i ~= Card.RUNE_BLANK then -- 40
      Season8.remainingCards[#Season8.remainingCards + 1] = i
    end
  end

  -- Fill the pill pool with all of the possible pill effects
  -- (for all 7 characters)
  local seed = g.seeds:GetStartSeed()
  local chosenEffects = {}
  for i = 1, 13 do
    local randomEffectIndex
    while true do
      seed = g:IncrementRNG(seed)
      math.randomseed(seed)
      randomEffectIndex = math.random(1, #Season8.pillEffects)
      if not g:TableContains(chosenEffects, randomEffectIndex) then
        chosenEffects[#chosenEffects + 1] = randomEffectIndex
        break
      end
    end
    Season8.runPillEffects[i] = Season8.pillEffects[randomEffectIndex]
  end
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season8:PostGameStarted()
  Isaac.DebugString("In the R+7 (Season 8) challenge.")

  -- Local variables
  local character = g.p:GetPlayerType()

  -- Everyone starts with the Schoolbag in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Do character-specific actions
  if character == PlayerType.PLAYER_ISAAC then -- 0
    Schoolbag:Put(CollectibleType.COLLECTIBLE_D6, 6) -- 105

  elseif character == PlayerType.PLAYER_CAIN then -- 2
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
    g.p:AddSoulHearts(1)

  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    g.p:AddHearts(1)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, 3) -- 34

  elseif character == PlayerType.PLAYER_EVE then -- 5
    Schoolbag:Put(CollectibleType.COLLECTIBLE_RAZOR_BLADE, 3) -- 126
    g.p:AddHearts(-2)
    g.p:AddSoulHearts(1)

    -- Setting the red hearts does not automatically trigger Whore of Babylon
    -- (dealing the damage procs Dead Bird, so we temporarily remove the collectible)
    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD) -- 117
    g.p:TakeDamage(0, DamageFlag.DAMAGE_FAKE, EntityRef(g.p), 0)
    g.sfx:Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT) -- 55
    g.p:StopExtraAnimation()
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD, 0, false) -- 117
    Isaac.DebugString("Removing collectible 117 (Dead Bird)")

  elseif character == PlayerType.PLAYER_LAZARUS2 then -- 11
    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible 214 (Anemic)")
    Isaac.DebugString("Adding collectible 214 (Anemic)")

    g.p:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 249
    g.p:AddSoulHearts(1)

  elseif character == PlayerType.PLAYER_BLACKJUDAS then -- 12
    g.p:AddBlackHearts(3)

  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, 6) -- 477
    g.p:AddSoulHearts(1)

    -- Prevent resetting for Void + Mega Blast
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MEGA_SATANS_BREATH) -- 441
  end

  -- All of the character's starting items are removed from all pools
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LUCKY_FOOT) -- 46
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_PAPER_CLIP) -- 19
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL) -- 34
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON) -- 122
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD) -- 117
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_RAZOR_BLADE) -- 126
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_ANEMIC) -- 214
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 249
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VOID) -- 477

  -- Some revival items are removed from all pools (since these characters in in the lineup)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_JUDAS_SHADOW) -- 311
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LAZARUS_RAGS) -- 332

  -- Remove previously touched items from pools
  for _, item in ipairs(Season8.touchedItems) do
    g.itemPool:RemoveCollectible(item)
  end

  -- Remove previously touched trinkets from pools
  for _, trinket in ipairs(Season8.touchedTrinkets) do
    g.itemPool:RemoveTrinket(trinket)
  end

  -- Remember the pills from the previous run(s)
  g.run.pills = g:TableClone(Season8.identifiedPills)
  if #g.run.pills > 0 then
    for _, pill in ipairs(g.run.pills) do
      g.itemPool:IdentifyPill(pill.color)
    end
  end
end

-- ModCallbacks.MC_GET_CARD (20)
function Season8:GetCard(rng, currentCard, playing, runes, onlyRunes)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return
  end

  -- Debug
  Isaac.DebugString("Season8:GetCard() - " ..
                    "currentCard: " .. tostring(currentCard) .. ", " ..
                    "playing: " .. tostring(playing) .. ", " ..
                    "runes: " .. tostring(runes) .. ", " ..
                    "onlyRunes: " .. tostring(onlyRunes))
  local cards = ""
  for _, card in ipairs(Season8.remainingCards) do
    cards = cards .. tostring(card) .. ", "
  end
  Isaac.DebugString("Season8:GetCard() - " .. tostring(#Season8.remainingCards) .. " cards remaining: " ..
                    "(" .. tostring(cards) .. ")")

  if g:TableContains(Season8.remainingCards, currentCard) then
    -- They have not used this card/rune yet
    Isaac.DebugString("Season8:GetCard() - Card " .. tostring(currentCard) .. " is not yet used.")
    return currentCard
  end

  -- They have used this card/rune, so we need to pick a new card/rune ID
  -- First, handle the case of only runes (e.g. Rune Bag)
  if onlyRunes then
    -- Make a list of the remaining runes in the pool
    local remainingRunes = {}
    for i = Card.RUNE_HAGALAZ, Card.RUNE_BLACK do -- 32, 41
      if g:TableContains(Season8.remainingCards, i) then
        remainingRunes[#remainingRunes + 1] = i
      end
    end

    if #remainingRunes == 0 then
      -- All of the runes are used, so delete the rune drop
      Isaac.DebugString("Season8:GetCard() - All runes are used, returning 0.")
      return Card.CARD_NULL -- 0
    end

    -- Return a random rune
    math.randomseed(rng:GetSeed())
    local randomIndex = math.random(1, #remainingRunes)
    Isaac.DebugString("Season8:GetCard() - There are " .. tostring(#remainingRunes) .. " runes remaining.")
    Isaac.DebugString("Season8:GetCard() - Returning a custom rune of: " .. tostring(remainingRunes[randomIndex]))
    return remainingRunes[randomIndex]
  end

  -- Second, handle the case of a random card drop
  -- (this could be random tarot cards, or random tarot cards + random playing cards,
  -- or random tarot cards + random playing cards + random runes, etc.)
  local remainingCards = {}
  for i = Card.CARD_FOOL, Card.CARD_WORLD do -- 1, 22
    if g:TableContains(Season8.remainingCards, i) then
      remainingCards[#remainingCards + 1] = i
    end
  end
  if playing then
    for i = Card.CARD_CLUBS_2, Card.CARD_JOKER do -- 23, 31
      if g:TableContains(Season8.remainingCards, i) then
        remainingCards[#remainingCards + 1] = i
      end
    end
    for i = Card.CARD_CHAOS, Card.CARD_ERA_WALK do -- 42, 54
      if g:TableContains(Season8.remainingCards, i) then
        remainingCards[#remainingCards + 1] = i
      end
    end
  end
  if runes then
    for i = Card.RUNE_HAGALAZ, Card.RUNE_BLACK do -- 32, 41
      if g:TableContains(Season8.remainingCards, i) then
        remainingCards[#remainingCards + 1] = i
      end
    end
  end

  if #remainingCards == 0 then
    -- All of the cards are used, so delete the card drop
    Isaac.DebugString("Season8:GetCard() - All cards are used, returning 0.")
    return Card.CARD_NULL -- 0
  end

  -- Return a random card
  math.randomseed(rng:GetSeed())
  local randomIndex = math.random(1, #remainingCards)
  Isaac.DebugString("Season8:GetCard() - There are " .. tostring(#remainingCards) .. " cards remaining. " ..
                    "Returning a custom card of: " .. tostring(remainingCards[randomIndex]))
  return remainingCards[randomIndex]
end

-- ModCallbacks.MC_POST_PICKUP_UPDATE (35)
-- PickupVariant.PICKUP_TAROTCARD (300)
function Season8:PostPickupUpdateTarotCard(pickup)
  -- Local variables
  local roomFrameCount = g.r:GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return
  end

  -- If we just re-entered a room that we have previously been in, ignore all cards
  if not g.r:IsFirstVisit() and
     pickup.FrameCount == 1 and
     roomFrameCount == 1 then

    return
  end

  -- We only care about freshly spawned cards
  -- (we cannot use the POST_PICKUP_INIT callback because the position is yet not initialized there)
  if pickup.FrameCount ~= 1 or
     pickup.SpawnerType == EntityType.ENTITY_PLAYER then -- 1
     -- (we need to ignore cards that the player drops,
     -- or else they would be able to infinitely spawn new cards)

    return
  end

  -- Check to make sure that this card has not already been used
  -- e.g. "set" drops, like ? Card and Black Rune in Devil Rooms
  if not g:TableContains(Season8.remainingCards, pickup.SubType) then
    pickup:Remove()

    -- Spawn a random card in its place
    Isaac.DebugString("Season 8 - Replacing card " .. tostring(pickup.SubType) .. " with a new " ..
                      "random card due to it already being used. " ..
                      "(This should only happen in Devil Room #4 and #7.)")
    local newCard = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, -- 5.300
                              pickup.Position, pickup.Velocity, pickup.SpawnerEntity, 0, pickup.InitSeed)

    -- If it is a shop item, we need to copy over the shop properties
    -- so that the replaced card is not automatically bought
    newCard.Price = pickup.Price
    newCard.ShopItemId = pickup.ShopItemId
  end
end

-- ModCallbacks.MC_POST_PICKUP_UPDATE (35)
-- PickupVariant.PICKUP_TRINKET (350)
function Season8:PostPickupUpdateTrinket(pickup)
  -- Local variables
  local roomFrameCount = g.r:GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return
  end

  -- If we just re-entered a room that we have previously been in, ignore all trinkets
  if not g.r:IsFirstVisit() and
     pickup.FrameCount == 1 and
     roomFrameCount == 1 then

    return
  end

  -- We only care about freshly spawned trinkets
  -- (we cannot use the POST_PICKUP_INIT callback because the position is yet not initialized there)
  if pickup.FrameCount ~= 1 or
     pickup.SpawnerType == EntityType.ENTITY_PLAYER then -- 1
     -- (we need to ignore trinkets that the player drops,
     -- or else they would be able to infinitely spawn new trinkets)

    return
  end

  -- Check to make sure that this trinket has not already been touched
  -- e.g. "set" drops, like Left Hand from Ultra Pride
  if g:TableContains(Season8.touchedTrinkets, pickup.SubType) then
    pickup:Remove()

    -- Spawn a random trinket in its place
    Isaac.DebugString("Season 8 - Replacing trinket " .. tostring(pickup.SubType) .. " with a new " ..
                      "random trinket due to it already being touched..")
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, -- 5.350
              pickup.Position, pickup.Velocity, pickup.SpawnerEntity, 0, pickup.InitSeed)
  end
end

-- ModCallbacks.MC_GET_PILL_EFFECT (65)
function Season8:GetPillEffect(selectedPillEffect, pillColor)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    Isaac.DebugString("Season 8 - Replacing a pill effect of " .. tostring(selectedPillEffect) ..
                      " with " .. tostring(Season8.runPillEffects[pillColor]) .. ".")
    return Season8.runPillEffects[pillColor]
  end
end

function Season8:PHD()
  -- The player just picked up PHD or Virgo, so we may need to swap out some pill effects
  -- (all of the pill effects were chosen at the beginning of the first character)
  for i, effect in ipairs(Season8.runPillEffects) do
    if effect == PillEffect.PILLEFFECT_HEALTH_DOWN then -- 6
      Season8.runPillEffects[i] = PillEffect.PILLEFFECT_HEALTH_UP -- 7
    elseif effect == PillEffect.PILLEFFECT_SPEED_DOWN then -- 13
      Season8.runPillEffects[i] = PillEffect.PILLEFFECT_SPEED_UP -- 14
    elseif effect == PillEffect.PILLEFFECT_TEARS_DOWN then -- 15
      Season8.runPillEffects[i] = PillEffect.PILLEFFECT_TEARS_UP -- 16
    end
  end
end

return Season8
