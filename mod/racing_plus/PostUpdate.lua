local PostUpdate = {}

-- Includes
local g                  = require("racing_plus/globals")
local Pills              = require("racing_plus/pills")
local CheckEntities      = require("racing_plus/checkentities")
local FastClear          = require("racing_plus/fastclear")
local FastDrop           = require("racing_plus/fastdrop")
local Schoolbag          = require("racing_plus/schoolbag")
local SoulJar            = require("racing_plus/souljar")
local FastTravel         = require("racing_plus/fasttravel")
local PostItemPickup     = require("racing_plus/postitempickup")
local Race               = require("racing_plus/race")
local Speedrun           = require("racing_plus/speedrun")
local SpeedrunPostUpdate = require("racing_plus/speedrunpostupdate")
local ChangeCharOrder    = require("racing_plus/changecharorder")
local BossRush           = require("racing_plus/bossrush")

-- Check various things once per game frame (30 times a second)
-- (this will not fire while the floor/room is loading)
-- ModCallbacks.MC_POST_UPDATE (1)
function PostUpdate:Main()
  PostUpdate:CheckStartTime()
  PostUpdate:CheckRoomCleared()
  PostUpdate:CheckKeeperHearts()
  PostUpdate:CheckItemPickup()
  PostUpdate:CheckTransformations()
  PostUpdate:CheckCharacter()
  PostUpdate:CheckHauntSpeedup()
  PostUpdate:CheckMomStomp()
  PostUpdate:CheckManualRechargeActive()
  PostUpdate:CheckMutantSpiderInnerEye()
  PostUpdate:CrownOfLight()
  PostUpdate:CheckLilithExtraIncubus()
  PostUpdate:CheckWishbone()
  PostUpdate:CheckWalnut()
  PostUpdate:Fix9VoltSynergy()
  BossRush:PostUpdate()

  -- Check on every frame to see if we need to open the doors
  -- (we can't just add this as a new MC_POST_UPDATE callback because
  -- it causes a bug where the Womb 2 trapdoor appears for a frame)
  FastClear:PostUpdate()

  -- Check to see if we are leaving a crawlspace (and if we are softlocked in a Boss Rush)
  FastTravel:CheckCrawlspaceExit()
  FastTravel:CheckCrawlspaceSoftlock()

  CheckEntities:Grid() -- Check all the grid entities in the room
  CheckEntities:NonGrid() -- Check all the non-grid entities in the room

  -- Check for item drop inputs (fast-drop)
  FastDrop:CheckDropInput()
  FastDrop:CheckDropInputTrinket()
  FastDrop:CheckDropInputPocket()

  -- Check for Schoolbag switch inputs
  -- (and other miscellaneous Schoolbag activities)
  Schoolbag:CheckActiveCharges()
  Schoolbag:CheckEmptyActiveItem()
  Schoolbag:CheckInput()
  Schoolbag:ConvertVanilla()
  Schoolbag:CheckRemoved()

  -- Check the player's health for the Soul Jar mechanic
  SoulJar:PostUpdate()

  Pills:CheckPHD()

  -- Handle things for races
  Race:PostUpdate()

  -- Handle things for multi-character speedruns
  SpeedrunPostUpdate:Main()

  -- Handle things for the "Change Char Order" custom challenge
  ChangeCharOrder:PostUpdate()
end

-- Check to see if we need to start the timers
function PostUpdate:CheckStartTime()
  if g.run.startedTime == 0 then
    g.run.startedTime = Isaac.GetTime()
  end
end

-- Keep track of the when the room is cleared and the total amount of rooms cleared on this run thus far
function PostUpdate:CheckRoomCleared()
  -- Local variables
  local roomClear = g.r:IsClear()

  -- Check the clear status of the room and compare it to what it was a frame ago
  if roomClear == g.run.currentRoomClearState then
    return
  end

  g.run.currentRoomClearState = roomClear

  if not roomClear then
    return
  end

  if not g.run.fastCleared then
    Isaac.DebugString("Vanilla room clear detected!")
  end

  -- If the room just got changed to a cleared state, increment the variables for the bag familiars
  FastClear:IncrementBagFamiliars()

  -- Give a charge to the player's Schoolbag item
  Schoolbag:AddCharge()

  -- Handle speedrun tasks
  Speedrun:RoomCleared()
end

-- Keep track of our hearts if we are Keeper
-- (to fix the Greed's Gullet bug and the double coin / nickel healing bug)
function PostUpdate:CheckKeeperHearts()
  -- Local variables
  local character = g.p:GetPlayerType()
  local maxHearts = g.p:GetMaxHearts()
  local coins = g.p:GetNumCoins()

  if character ~= PlayerType.PLAYER_KEEPER then -- 14
    return
  end

  -- Find out how many coin containers we should have
  -- (2 is equal to 1 actual heart container)
  local coinContainers = 0
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

  if baseHearts ~= g.run.keeper.baseHearts then
    -- Our health changed; we took a devil deal, took a health down pill, or went from 1 heart to 2 hearts
    local heartsDiff = baseHearts - g.run.keeper.baseHearts
    g.run.keeper.baseHearts = g.run.keeper.baseHearts + heartsDiff
    Isaac.DebugString("Set new Keeper baseHearts to: " .. tostring(g.run.keeper.baseHearts) ..
                      " (from detection, change was " .. tostring(heartsDiff) .. ")")
  end

  -- Check Keeper coin count
  if coins ~= g.run.keeper.coins then
    local coinDifference = coins - g.run.keeper.coins
    if coinDifference > 0 then
      for i = 1, coinDifference do
        local newCoins = g.p:GetNumCoins()
        if g.p:GetHearts() < g.p:GetMaxHearts() and
           newCoins ~= 25 and
           newCoins ~= 50 and
           newCoins ~= 75 and
           newCoins ~= 99 then

          g.p:AddHearts(2)
          g.p:AddCoins(-1)
        end
      end
    end

    -- Set the new coin count (we re-get it since it may have changed)
    g.run.keeper.coins = g.p:GetNumCoins()
  end
end

function PostUpdate:CheckItemPickup()
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- Only run the below code once per item
  if g.p:IsItemQueueEmpty() then
    if g.run.pickingUpItem ~= 0 then
      -- Check to see if we need to do something specific after this item is added to our inventory
      local postItemFunction = PostItemPickup.functions[g.run.pickingUpItem]
      if postItemFunction ~= nil and
         roomIndex == g.run.pickingUpItemRoom then
         -- (don't do any custom inventory work if we have changed rooms in the meantime)

        postItemFunction()
      end
      g.run.pickingUpItem = 0
    end
    return
  elseif g.run.pickingUpItem ~= 0 then
    return
  end

  -- Mark which item we are picking up
  g.run.pickingUpItem = g.p.QueuedItem.Item.ID
  g.run.pickingUpItemRoom = roomIndex

  -- Mark to draw the streak text for this item
  g.run.streakText = g.p.QueuedItem.Item.Name
  g.run.streakFrame = Isaac.GetFrameCount()

  -- Keep track of our passive items over the course of the run
  if g.p.QueuedItem.Item.Type ~= ItemType.ITEM_ACTIVE then -- 3
    g.run.passiveItems[#g.run.passiveItems + 1] = g.p.QueuedItem.Item.ID
    if g.p.QueuedItem.Item.ID == CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE then
      Isaac.DebugString("Adding collectible 3001 (Mutant Spider's Inner Eye)")
    end
    SpeedrunPostUpdate:CheckFirstCharacterStartingItem()
  end
end

function PostUpdate:CheckTransformations()
  for i = 0, PlayerForm.NUM_PLAYER_FORMS - 1 do
    local hasForm = g.p:HasPlayerForm(i)
    if hasForm ~= g.run.transformations[i] then
      g.run.transformations[i] = hasForm
      g.run.streakText = g.Transformations[i + 1]
      g.run.streakFrame = Isaac.GetFrameCount()

      if i == PlayerForm.PLAYERFORM_DRUGS then -- 5
        PostItemPickup.InsertNearestPill()
      end
    end
  end
end

function PostUpdate:CheckCharacter()
  local character = g.p:GetPlayerType()
  if g.run.currentCharacter == character then
    return
  end
  g.run.currentCharacter = character

  if character ~= PlayerType.PLAYER_THEFORGOTTEN and -- 16
     character ~= PlayerType.PLAYER_THESOUL then -- 17

    return
  end

  -- Fix the bug where the player can accidently switch characters and go down a trapdoor
  if g.run.trapdoor.state == 0 then
    local effects = Isaac.FindByType(EntityType.ENTITY_EFFECT, -1, -1, false, false) -- 1000
    for _, entity in ipairs(effects) do
      if (entity.Variant == EffectVariant.TRAPDOOR_FAST_TRAVEL or
          entity.Variant == EffectVariant.CRAWLSPACE_FAST_TRAVEL or
          entity.Variant == EffectVariant.WOMB_TRAPDOOR_FAST_TRAVEL or
          entity.Variant == EffectVariant.BLUE_WOMB_TRAPDOOR_FAST_TRAVEL or
          entity.Variant == EffectVariant.HEAVEN_DOOR_FAST_TRAVEL) and
         g.p.Position:Distance(entity.Position) <= 40 then

        local effect = entity:ToEffect()
        effect.State = 1
        effect:GetSprite():Play("Closed", true)
      end
    end
  end
end

-- Speed up the first Lil' Haunt attached to a Haunt (3/3)
function PostUpdate:CheckHauntSpeedup()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local blackChampionHaunt = g.run.speedLilHauntsBlack
  if g.run.speedLilHauntsFrame == 0 or
     gameFrameCount < g.run.speedLilHauntsFrame then

    return
  end
  g.run.speedLilHauntsFrame = 0
  g.run.speedLilHauntsBlack = false
  Isaac.DebugString("Reset Lil' Haunt detach variables.")

  local lilHaunts = Isaac.FindByType(EntityType.ENTITY_THE_HAUNT, 10, 0, false, true) -- 260
  local hauntCount = Isaac.CountEntities(nil, EntityType.ENTITY_THE_HAUNT, 0, -1) -- 260
  Isaac.DebugString("Haunt count: " .. tostring(hauntCount))

  -- As a sanity check, don't do anything if there are no Haunts in the room
  if hauntCount == 0 then
    return
  end

  -- If there is more than one Haunt, detach every Lil Haunt, because tracking everything will be too hard
  if hauntCount > 1 then
    Isaac.DebugString("Detaching all of the Lil' Haunts in the room.")
    for _, lilHaunt in ipairs(lilHaunts) do
      PostUpdate:DetachLilHaunt(lilHaunt:ToNPC())
    end
    return
  end

  if blackChampionHaunt then
    Isaac.DebugString("Detaching two of the Lil' Haunts in the room.")
  else
    Isaac.DebugString("Detaching only one of the Lil' Haunts in the room.")
  end
  local lilHauntIndexes = {}
  for _, lilHaunt in ipairs(lilHaunts) do
    lilHauntIndexes[#lilHauntIndexes + 1] = lilHaunt.Index
  end
  table.sort(lilHauntIndexes)
  for _, lilHaunt in ipairs(lilHaunts) do
    if lilHaunt.Index == lilHauntIndexes[1] then
      PostUpdate:DetachLilHaunt(lilHaunt:ToNPC())
    end
    if lilHaunt.Index == lilHauntIndexes[2] and
       blackChampionHaunt then

      PostUpdate:DetachLilHaunt(lilHaunt:ToNPC())
    end
  end
end

-- Subverting the teleport on the Mom fight can result in a buggy interaction where Mom does not stomp
-- Force Mom to stomp by teleporting the player to the middle of the room for one frame
function PostUpdate:CheckMomStomp()
  if not g.run.forceMomStomp then
    return
  end

  -- Local variables
  local roomFrameCount = g.r:GetFrameCount()
  local centerPos = g.r:GetCenterPos()

  if roomFrameCount == 19 then
    g.run.forceMomStompPos = g.p.Position
    g.p.Position = centerPos
    g.p.Visible = false

    local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
    for _, familiar in ipairs(familiars) do
      familiar.Visible = false
    end
    local knives = Isaac.FindByType(EntityType.ENTITY_KNIFE, -1, -1, false, false) -- 8
    for _, knife in ipairs(knives) do
      knife.Visible = false
    end
    local scythes = Isaac.FindByType(EntityType.ENTITY_SAMAEL_SCYTHE, -1, -1, false, false) -- 8
    for _, scythe in ipairs(scythes) do
      scythe.Visible = false
    end

  elseif roomFrameCount == 20 then
    g.p.Position = g.run.forceMomStompPos
    g.p.Visible = true

  elseif roomFrameCount == 21 then
    -- We have to delay a frame before making familiars and knives visible,
    -- since they lag behind the position of the player by a frame
    local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
    for _, familiar in ipairs(familiars) do
      familiar.Visible = true
    end
    local knives = Isaac.FindByType(EntityType.ENTITY_KNIFE, -1, -1, false, false) -- 8
    for _, knife in ipairs(knives) do
      knife.Visible = true
    end
    local scythes = Isaac.FindByType(EntityType.ENTITY_SAMAEL_SCYTHE, -1, -1, false, false) -- 8
    for _, scythe in ipairs(scythes) do
      scythe.Visible = true
    end

    g.run.forceMomStomp = false
  end
end

-- Check to see if an item that messes with item pedestals got canceled
-- (this has to be done a frame later or else it won't work)
function PostUpdate:CheckManualRechargeActive()
  if g.run.rechargeItemFrame == g.g:GetFrameCount() then
    g.run.rechargeItemFrame = 0
    g.p:FullCharge()
    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  end
end

-- Check for Mutant Spider's Inner Eye (a custom item)
function PostUpdate:CheckMutantSpiderInnerEye()
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE) and
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then -- 153

    -- This custom item is set to not be shown on the item tracker
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER, 0, false) -- 153
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_INNER_EYE, 0, false) -- 2
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2
  end
end

function PostUpdate:DetachLilHaunt(npc)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Detach them
  npc.State = NpcState.STATE_MOVE -- 4

  -- We need to manually set them to visible (or else they will be invisible for some reason)
  npc.Visible = true

  -- We need to manually set the color, or else the Lil' Haunt will remain faded
  npc:SetColor(g.color, 0, 0, false, false)

  -- We need to manually set their collision or else tears will pass through them
  npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4

  Isaac.DebugString("Manually detached a Lil' Haunt with index " .. tostring(npc.Index) ..
                    " on frame: " .. tostring(gameFrameCount))
end

-- Check to see if the player just picked up the a Crown of Light from a Basement 1 Treasure Room fart-reroll
function PostUpdate:CrownOfLight()
  -- Local variables
  local stage = g.l:GetStage()
  local challenge = Isaac.GetChallenge()

  if not g.run.removedCrownHearts and
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     g.run.roomsEntered == 1 then -- They are still in the starting room

    -- The player started with Crown of Light, so we don't need to even go into the below code block
    g.run.removedCrownHearts = true
  end
  if not g.run.removedCrownHearts and
     stage == 1 and
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     (((g.race.rFormat == "unseeded" or
        g.race.rFormat == "diversity") and
       g.race.status == "in progress") or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)")) then

     -- Remove the two soul hearts that the Crown of Light gives
     g.run.removedCrownHearts = true
     g.p:AddSoulHearts(-4)
  end
end

-- In R+7 Season 4 and Racing+ Rebalanced,
-- we want to remove the Lilith's extra Incubus if they attempt to switch characters
function PostUpdate:CheckLilithExtraIncubus()
  -- Local variables
  local character = g.p:GetPlayerType()

  if g.run.extraIncubus and
     character ~= PlayerType.PLAYER_LILITH then -- 13

    g.run.extraIncubus = false
    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360
    Isaac.DebugString("Removed the extra Incubus.")
  end
end

function PostUpdate:CheckWishbone()
  if g.run.haveWishbone then
    if not g.p:HasTrinket(TrinketType.TRINKET_WISH_BONE) then -- 104
      g.run.haveWishbone = false
      local wishBones = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, -- 5.350
                                         TrinketType.TRINKET_WISH_BONE, false, false) -- 104
      if #wishBones == 0 then
        g.sfx:Play(SoundEffect.SOUND_WALNUT, 1, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch
        -- (we reuse the Walnut breaking sound effect for this)
      end
    end
  else
    if g.p:HasTrinket(TrinketType.TRINKET_WISH_BONE) then -- 104
      g.run.haveWishbone = true
    end
  end
end

function PostUpdate:CheckWalnut()
  if g.run.haveWalnut then
    if not g.p:HasTrinket(TrinketType.TRINKET_WALNUT) then -- 108
      g.run.haveWalnut = false
      local walnuts = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, -- 5.350
                                       TrinketType.TRINKET_WALNUT, false, false) -- 108
      if #walnuts == 0 then
        g.sfx:Play(SoundEffect.SOUND_WALNUT, 1, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch
      end
    end
  else
    if g.p:HasTrinket(TrinketType.TRINKET_WALNUT) then -- 108
      g.run.haveWalnut = true
    end
  end
end

-- Fix The Battery + 9 Volt synergy (2/2)
function PostUpdate:Fix9VoltSynergy()
  if g.run.giveExtraCharge then
    g.run.giveExtraCharge = false
    g.p:SetActiveCharge(g.p:GetActiveCharge() + 1)
  end
end

return PostUpdate
