--
-- The Racing+ Lua Mod
-- by Zamiel
--

--[[

TODO:
- play with SecondaryActiveItem (can't replace item?)
- USE QUEUE ITEM FOR CHECKPOINT
- USE QUEUE ITEM FOR SCHOOLBAG
- change trinket bans to trinket pool API
- add better bombs (waiting on him to rewrite)
- Implement time offsets, show on the first room of each floor
- Opponent's shadows

TODO DIFFICULT:
- Fix Isaac beams never hitting you
- Fix Conquest beams hitting you

TODO CAN'T FIX:
- Make a 3rd color hue on the map for rooms that are not cleared but you have entered
- Make fast-clear apply to Challenge rooms and the Boss Rush ("room:SetAmbushDone()" doesn't do anything)

POST-FLIP ACTIONS:
1) Remove the duplicated start rooms for The Chest / Dark Room
2) Un-flip Y-flipped Gurdy rooms:
    The Chest - #20018, #30018
3) Un-flip double Gate rooms
    The Chest - #20040, #30040
    Dark Room - #20012, #30012
4) Un-flip some Mega Maw rooms:
    The Chest - #20269, #20039, #30269, #30039
    Dark Room - #20011, #30011

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
local RPExecuteCmd          = require("src/rpexecutecmd") -- The ExecuteCmd callback (22)
local RPPostNPCInit         = require("src/rppostnpcinit") -- The NPCInit callback (27)
local RPPostPickupInit      = require("src/rppostpickupinit") -- The PostPickupInit callback (34)
local RPPostPickupSelection = require("src/rppostpickupselection") -- The PostPickupSelection callback (37)
local RPPostEntityKill      = require("src/rppostentitykill") -- The PostEntityKill callback (68)
local RPItems               = require("src/rpitems") -- Collectible item callbacks (23 & 3)
local RPCards               = require("src/rpcards") -- Card callbacks (5)
local RPPills               = require("src/rppills") -- Pill callbacks (10)
local RPFastClear           = require("src/rpfastclear") -- Functions relating to the "Fast-Clear" feature
local RPSpeedrun            = require("src/rpspeedrun") -- Functions relating to the custom challenges
local RPSamael              = require("src/rpsamael") -- Samael functions
local RPJrFetus             = require("src/rpjrfetus") -- Jr. Fetus functions (2/2)
local RPMahalath            = require("src/rpmahalath") -- Mahalath functions
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
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPFastClear.NPC246, EntityType.ENTITY_RAGLING) -- 246
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC213, EntityType.ENTITY_MOMS_DEAD_HAND) -- 287
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC219, EntityType.ENTITY_WIZOOB) -- 219
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC219, EntityType.ENTITY_RED_GHOST) -- 285
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC273, EntityType.ENTITY_THE_LAMB) -- 273
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC275, EntityType.ENTITY_MEGA_SATAN_2) -- 273
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC300, EntityType.ENTITY_MUSHROOM) -- 300
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPFastClear.NPC302, EntityType.ENTITY_STONEY) -- 302
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, RPNPCUpdate.NPC411, EntityType.ENTITY_BIG_HORN) -- 411

-- Define miscellaneous callbacks
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,           RPPostUpdate.Main) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_RENDER,           RPPostRender.Main) -- 2
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,        RPEvaluateCache.Main) -- 8
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,      RPPostPlayerInit.Main) -- 9
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,       RPEntityTakeDmg.Main) -- 11
RacingPlus:AddCallback(ModCallbacks.MC_INPUT_ACTION,          RPInputAction.Main) -- 13
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,     RPPostGameStarted.Main) -- 15
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_END,         RPSpeedrun.PostGameEnd) -- 16
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,        RPPostNewLevel.Main) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,         RPPostNewRoom.Main) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_EXECUTE_CMD,           RPExecuteCmd.Main) -- 22
RacingPlus:AddCallback(ModCallbacks.MC_POST_NPC_INIT,         RPPostNPCInit.Main) -- 27
RacingPlus:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT,      RPPostPickupInit.Main) -- 34
RacingPlus:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, RPPostPickupSelection.Main) -- 37
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE,    RPFastClear.PostEntityRemove) -- 67

-- Define pre-use item callback (23)
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.WeNeedToGoDeeper,
                                                     CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER) -- 84
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.BookOfSin, CollectibleType.COLLECTIBLE_BOOK_OF_SIN) -- 97
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.GlowingHourGlass,
                                                     CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS) -- 422
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.Smelter,   CollectibleType.COLLECTIBLE_SMELTER) -- 479

-- Define pre-use item callbacks for items that deal with item pedestals
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.PreventItemPedestalEffects,
                                                     CollectibleType.COLLECTIBLE_D6) -- 105
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.PreventItemPedestalEffects,
                                                     CollectibleType.COLLECTIBLE_D100) -- 283
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.PreventItemPedestalEffects,
                                                     CollectibleType.COLLECTIBLE_DIPLOPIA) -- 347
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.PreventItemPedestalEffects,
                                                     CollectibleType.COLLECTIBLE_VOID) -- 477
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.PreventItemPedestalEffects,
                                                     CollectibleType.COLLECTIBLE_CROOKED_PENNY) -- 485
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.PreventItemPedestalEffects,
                                                     CollectibleType.COLLECTIBLE_DINF) -- 489
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, RPItems.PreventItemPedestalEffects,
                                                     CollectibleType.COLLECTIBLE_MOVING_BOX) -- 523

-- Define post-use item callbacks (3)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Main) -- 3; will get called for all items
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Teleport,  CollectibleType.COLLECTIBLE_TELEPORT) -- 44
-- (this callback is also used by Broken Remote)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.BlankCard, CollectibleType.COLLECTIBLE_BLANK_CARD) -- 286
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Undefined, CollectibleType.COLLECTIBLE_UNDEFINED) -- 324

RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Void,        CollectibleType.COLLECTIBLE_VOID) -- 477
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.MysteryGift, CollectibleType.COLLECTIBLE_MYSTERY_GIFT) -- 515
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.MovingBox,   CollectibleType.COLLECTIBLE_MOVING_BOX) -- 523

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

-- Define NPC kill callbacks (68)
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, RPFastClear.PostEntityKill) -- 68
-- (will get called for all kills)
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, RPPostEntityKill.NPC45, EntityType.ENTITY_MOM) -- 45
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, RPPostEntityKill.NPC78, EntityType.ENTITY_MOMS_HEART) -- 78
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, RPPostEntityKill.NPC81, EntityType.ENTITY_FALLEN) -- 81
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, RPPostEntityKill.NPC271, EntityType.ENTITY_URIEL) -- 271
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, RPPostEntityKill.NPC271, EntityType.ENTITY_GABRIEL) -- 272
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, RPPostEntityKill.NPC78, EntityType.ENTITY_HUSH) -- 407

-- Samael callbacks
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          RPSamael.postReroll, CollectibleType.COLLECTIBLE_D4) -- 284
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          RPSamael.postReroll, CollectibleType.COLLECTIBLE_D100) -- 283
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          RPSamael.activateWraith,
                                                          Isaac.GetItemIdByName("Wraith Skull"))
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPSamael.roomEntitiesLoop)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPSamael.PostUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPSamael.PostUpdateFixBugs)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPSamael.scytheUpdate,
                                                          Isaac.GetEntityTypeByName("Samael Scythe"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPSamael.specialAnimFunc,
                                                          Isaac.GetEntityTypeByName("Samael Special Animations"))
RacingPlus:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,   RPSamael.hitBoxFunc, FamiliarVariant.SACRIFICIAL_DAGGER) -- 35
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   RPSamael.scytheHits)
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   RPSamael.playerDamage, EntityType.ENTITY_PLAYER) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,  RPSamael.PostPlayerInit)
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,    RPSamael.cacheUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, RPSamael.PostGameStartedReset)

-- Jr. Fetus callbacks
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,         RPJrFetus.UpdateDrFetus,
                                                           Isaac.GetEntityTypeByName("Dr Fetus Jr"))
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,    RPJrFetus.DrFetusTakeDamage,
                                                           Isaac.GetEntityTypeByName("Dr Fetus Jr"))
RacingPlus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, RPJrFetus.UpdateMissileTarget)
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,    RPJrFetus.DrFetusEmbryoTakeDamage,
                                                           Isaac.GetEntityTypeByName("Dr Fetus Boss Embryo"))
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,      RPJrFetus.PostNewRoom)
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,  RPJrFetus.PostGameStarted)

-- Mahalath callbacks
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPMahalath.PostUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPMahalath.check_girl, Isaac.GetEntityTypeByName("Mahalath"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPMahalath.check_mouth,
                                                          Isaac.GetEntityTypeByName("Barf Mouth"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPMahalath.check_balls,
                                                          Isaac.GetEntityTypeByName("Barf Ball"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPMahalath.check_bomb, Isaac.GetEntityTypeByName("Barf Bomb"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPMahalath.check_del, EntityType.ENTITY_DELIRIUM) -- 412
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   RPMahalath.take_dmg)
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,     RPMahalath.PostNewRoom)
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, RPMahalath.PostGameStarted)


-- Welcome banner
local hyphens = ''
for i = 1, 23 + string.len(RPGlobals.version) do
  hyphens = hyphens .. "-"
end
Isaac.DebugString("+" .. hyphens .. "+")
Isaac.DebugString("| Racing+ " .. RPGlobals.version .. " initialized. |")
Isaac.DebugString("+" .. hyphens .. "+")
