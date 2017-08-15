--
-- The Racing+ Lua Mod
-- by Zamiel
--

--[[

TODO:
- hear reset sounds on eden
- fix mimics in code
- undo mom's heart change
- Implement time offsets, show on the first room of each floor
- Opponent's shadows

TODO DIFFICULT:
- Fix Isaac beams never hitting you
- Fix Conquest beams
- Speed up the spawning of the first ghost on The Haunt fight

TODO CAN'T FIX:
- Fix Dead Eye on poop / red poop / static TNT barrels (can't modify existing items, no "player:GetDeadEyeCharge()"
  function)
- Make a 3rd color hue on the map for rooms that are not cleared but you have entered.
- Make fast-clear apply to Challenge rooms and the Boss Rush ("room:SetAmbushDone()" doesn't do anything)

POST-FLIP ACTIONS:
1) Remove duplicated start room for The Chest / Dark Room
2) Remove Y-flipped Gurdy rooms from The Chest
3) Double Gate room - Move the Gates all the way down
    The Chest - #20040, #30040
    Dark Room - #20012, #30012
4) Mega Maw rooms - Move the Mega Maws (to a custom position depending on the room)
    The Chest - #20269, #20039, #20059, #30269, #30039, #30059
    Dark Room - #20011, #20052, #20080, #30011, #30052, #30080

--]]

-- Register the mod (the second argument is the API version)
local RacingPlus = RegisterMod("Racing+", 1)

-- The Lua code is split up into separate files for organizational purposes
local RPGlobals             = require("src/rpglobals") -- Global variables
local RPNPCUpdate           = require("src/rpnpcupdate") -- The NPCUpdate callback (0)
local RPPostUpdate          = require("src/rppostupdate") -- The PostUpdate callback (1)
local RPPostRender          = require("src/rppostrender") -- The PostRender callback (2)
local RPEvaluateCache       = require("src/rpevaluatecache") -- The EvaluateCache callback (8)
local RPPostPlayerInit      = require("src/rppostplayerinit") -- The PostPlayerInit callback (9)
local RPEntityTakeDmg       = require("src/rpentitytakedmg") -- The EntityTakeDmg callback (11)
local RPInputAction         = require("src/rpinputaction") -- The InputAction callback (13)
local RPPostGameStarted     = require("src/rppostgamestarted") -- The PostGameStarted callback (15)
local RPPostNewLevel        = require("src/rppostnewlevel") -- The PostNewLevel callback (18)
local RPPostNewRoom         = require("src/rppostnewroom") -- The PostNewRoom callback (19)
local RPPostNPCDeath        = require("src/rppostnpcdeath") -- The RPPostNPCDeath callback (29)
local RPPostPickupSelection = require("src/rppostpickupselection") -- The PostPickupSelection callback (37)
local RPItems               = require("src/rpitems") -- Collectible item callbacks (23 & 3)
local RPCards               = require("src/rpcards") -- Card callbacks (5)
local RPPills               = require("src/rppills") -- Pill callbacks (10)
local RPFastClear           = require("src/rpfastclear") -- Functions relating to the "Fast-Clear" feature
local RPSamael              = require("src/rpsamael") -- Samael functions
local RPDebug               = require("src/rpdebug") -- Debug functions

-- Initiailize the "RPGlobals.run" table
RPGlobals:InitRun()

-- Make a copy of this object so that we can use it elsewhere
RPGlobals.RacingPlus = RacingPlus -- (this is needed for loading the "save.dat" file)

-- Define NPC callbacks (0)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.Main) -- 0
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPFastClear.NPCUpdate) -- 0
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC24,  EntityType.ENTITY_GLOBIN) -- 24
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC27,  EntityType.ENTITY_HOST) -- 27
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC27,  EntityType.ENTITY_MOBILE_HOST) -- 204
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC42,  EntityType.ENTITY_STONEHEAD) -- 42
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC42,  EntityType.ENTITY_CONSTANT_STONE_SHOOTER) -- 202
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC42,  EntityType.ENTITY_BRIMSTONE_HEAD) -- 203
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC42,  EntityType.ENTITY_GAPING_MAW) -- 235
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC42,  EntityType.ENTITY_BROKEN_GAPING_MAW) -- 236
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC213, EntityType.ENTITY_MOMS_HAND) -- 213
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC213, EntityType.ENTITY_MOMS_DEAD_HAND) -- 287
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC219, EntityType.ENTITY_WIZOOB) -- 219
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC219, EntityType.ENTITY_RED_GHOST) -- 285
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC273, EntityType.ENTITY_THE_LAMB) -- 273
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC275, EntityType.ENTITY_MEGA_SATAN_2) -- 273
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC300, EntityType.ENTITY_MUSHROOM) -- 300

-- Define miscellaneous callbacks
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,           RPPostUpdate.Main) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_RENDER,           RPPostRender.Main) -- 2
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,        RPEvaluateCache.Main) -- 8
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,      RPPostPlayerInit.Main) -- 9
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,       RPEntityTakeDmg.Main) -- 11
RacingPlus:AddCallback(ModCallbacks.MC_INPUT_ACTION,          RPInputAction.Main) -- 13
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,     RPPostGameStarted.Main) -- 15
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,        RPPostNewLevel.Main) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,         RPPostNewRoom.Main) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_POST_NPC_INIT,         RPFastClear.PostNPCInit) -- 27
RacingPlus:AddCallback(ModCallbacks.MC_POST_NPC_DEATH,        RPPostNPCDeath.NPC45, EntityType.ENTITY_MOM) -- 29 / 45
RacingPlus:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, RPPostPickupSelection.Main) -- 37
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE,    RPFastClear.PostEntityRemove) -- 67
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL,      RPFastClear.PostEntityKill) -- 68

-- Define pre-use item callback (23)
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.WeNeedToGoDeeper,
                                                     CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER) -- 84
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.BookOfSin, CollectibleType.COLLECTIBLE_BOOK_OF_SIN) -- 97
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.Smelter,   CollectibleType.COLLECTIBLE_SMELTER) -- 479

-- Define post-use item callbacks (3)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Main) -- 3; will get called for all items
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Teleport,  CollectibleType.COLLECTIBLE_TELEPORT) -- 44
-- (this callback is also used by Broken Remote)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.BlankCard, CollectibleType.COLLECTIBLE_BLANK_CARD) -- 286
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Undefined, CollectibleType.COLLECTIBLE_UNDEFINED) -- 324
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.GlowingHourGlass,
                                                 CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS) -- 422
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Void,      CollectibleType.COLLECTIBLE_VOID) -- 477
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.MovingBox, CollectibleType.COLLECTIBLE_MOVING_BOX) -- 523

-- Define custom item callbacks (3)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPDebug.Main, CollectibleType.COLLECTIBLE_DEBUG)

-- Define card callbacks (5)
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport, Card.CARD_FOOL) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport, Card.CARD_EMPEROR) -- 5
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport, Card.CARD_HERMIT) -- 10
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Strength, Card.CARD_STRENGTH) -- 12
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport, Card.CARD_STARS) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport, Card.CARD_MOON) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport, Card.CARD_JOKER) -- 31

-- Define pill callbacks (10)
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, RPPills.HealthUp,  PillEffect.PILLEFFECT_HEALTH_UP) -- 7
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, RPPills.Telepills, PillEffect.PILLEFFECT_TELEPILLS) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, RPPills.Gulp,      PillEffect.PILLEFFECT_GULP_LOGGER)
-- This is a callback for a custom "Gulp!" pill; we can't use the original because
-- by the time the callback is reached, the trinkets are already consumed

-- Samael callbacks
local wraithItem  = Isaac.GetItemIdByName("Wraith Skull") --Spacebar Wraith Mode Activation
local scytheID    = Isaac.GetEntityTypeByName("Samael Scythe") --Entity ID of the scythe weapon entity
local specialAnim = Isaac.GetEntityTypeByName("Samael Special Animations") --Entity for showing special animations
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          RPSamael.postReroll, CollectibleType.COLLECTIBLE_D4)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          RPSamael.postReroll, CollectibleType.COLLECTIBLE_D100)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          RPSamael.activateWraith, wraithItem)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPSamael.roomEntitiesLoop)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPSamael.samaelPostUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPSamael.scytheUpdate, scytheID)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPSamael.specialAnimFunc, specialAnim)
RacingPlus:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,   RPSamael.hitBoxFunc, FamiliarVariant.SACRIFICIAL_DAGGER)
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   RPSamael.scytheHits)
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   RPSamael.playerDamage, EntityType.ENTITY_PLAYER)
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,  RPSamael.PostPlayerInit)
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,    RPSamael.cacheUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, RPSamael.PostGameStartedReset)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPSamael.PostUpdateFixBugs)

-- Welcome banner
local hyphens = ''
for i = 1, 23 + string.len(RPGlobals.version) do
  hyphens = hyphens .. "-"
end
Isaac.DebugString("+" .. hyphens .. "+")
Isaac.DebugString("| Racing+ " .. RPGlobals.version .. " initialized. |")
Isaac.DebugString("+" .. hyphens .. "+")
