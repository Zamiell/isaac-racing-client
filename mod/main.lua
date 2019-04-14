--
-- The Racing+ Lua Mod
-- by Zamiel
--

--[[

TODO:
- Make text selected in race chat
- Store game, room, level, etc. (re-ask Kil after Repentence release if this is okay to do)
- Implement time offsets, show on the first room of each floor
- Opponent's shadows

TODO DIFFICULT:
- Fix Isaac beams never hitting you
- Fix Conquest beams hitting you

TODO CAN'T FIX:
- Make a 3rd color hue on the map for rooms that are not cleared but you have entered
- Make fast-clear apply to Challenge rooms and the Boss Rush
  ("room:SetAmbushDone()" doesn't do anything)

POST-FLIP ACTIONS:
1) Remove the duplicated start rooms for The Chest / Dark Room
2) Un-flip Y-flipped Gurdy rooms:
    The Chest - #20018, #30018
3) Un-flip double Gate rooms
    The Chest - #20040, #30040
    Dark Room - #20012, #30012
4) Un-flip some Mega Maw rooms:
    The Chest - #20039, #30039, #20269, #30269
    Dark Room - #20011, #30011

--]]

-- Register the mod (the second argument is the API version)
local RacingPlus = RegisterMod("Racing+", 1)

-- The Lua code is split up into separate files for organizational purposes
-- (file names must be in lowercase for Linux compatibility purposes)
local g                   = require("src/globals") -- Global variables
local NPCUpdate           = require("src/npcupdate") -- 0
local PostUpdate        = require("src/postupdate") -- 1
local PostRender          = require("src/postrender") -- 2
local UseItem             = require("src/useitem") -- 3
local UseCard             = require("src/usecard") -- 5
local EvaluateCache       = require("src/evaluatecache") -- 8
local PostPlayerInit      = require("src/postplayerinit") -- 9
local UsePill             = require("src/usepill") -- 10
local EntityTakeDmg       = require("src/entitytakedmg") -- 11
local InputAction         = require("src/inputaction") -- 13
local PostGameStarted     = require("src/postgamestarted") -- 15
local PostNewLevel        = require("src/postnewlevel") -- 18
local PostNewRoom         = require("src/postnewroom") -- 19
local ExecuteCmd          = require("src/executecmd") -- 22
local PreUseItem          = require("src/preuseitem") -- 23
local PreEntitySpawn      = require("src/preentityspawn") -- 24
local PostNPCInit         = require("src/postnpcinit") -- 27
local PostPickupInit      = require("src/postpickupinit") -- 34
local PostPickupSelection = require("src/postpickupselection") -- 37
local PostLaserInit       = require("src/postlaserinit") -- 47
local PostEntityKill      = require("src/postentitykill") -- 68
local PreRoomEntitySpawn  = require("src/preroomentityspawn") -- 71
local FastClear           = require("src/fastclear") -- Functions for the "Fast-Clear" feature
local Schoolbag           = require("src/schoolbag") -- Functions for the Schoolbag custom item
local Speedrun            = require("src/speedrun") -- Functions for custom challenges
local Samael              = require("src/samael") -- Samael functions
local JrFetus             = require("src/jrfetus") -- Jr. Fetus functions (2/2)
local Mahalath            = require("src/mahalath") -- Mahalath functions
local Debug               = require("src/debug") -- Debug functions

-- Initiailize the "g.run" table
g:InitRun()

-- Make a copy of this object so that we can use it elsewhere
g.RacingPlus = RacingPlus -- (this is needed for saving and loading the "save.dat" file)

-- Set some specific global variables so that other mods can access Racing+ game state
RacingPlusGlobals = g
RacingPlusSchoolbag = Schoolbag
RacingPlusSpeedrun = Speedrun

-- Define NPC callbacks (0)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, FastClear.NPCUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC24,
                                                   EntityType.ENTITY_GLOBIN) -- 24
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC27,
                                                   EntityType.ENTITY_HOST) -- 27
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC27,
                                                   EntityType.ENTITY_MOBILE_HOST) -- 204
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC28,
                                                   EntityType.ENTITY_CHUB) -- 28
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC42,
                                                   EntityType.ENTITY_STONEHEAD) -- 42
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC54,
                                                   EntityType.ENTITY_FLAMINGHOPPER) -- 54
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC66,
                                                   EntityType.ENTITY_DEATH) -- 66
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC42,
                                                   EntityType.ENTITY_CONSTANT_STONE_SHOOTER) -- 202
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC42,
                                                   EntityType.ENTITY_BRIMSTONE_HEAD) -- 203
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC42,
                                                   EntityType.ENTITY_GAPING_MAW) -- 235
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC42,
                                                   EntityType.ENTITY_BROKEN_GAPING_MAW) -- 236
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC213,
                                                   EntityType.ENTITY_MOMS_HAND) -- 213
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, FastClear.NPC246,
                                                   EntityType.ENTITY_RAGLING) -- 246
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC213,
                                                   EntityType.ENTITY_MOMS_DEAD_HAND) -- 287
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC219,
                                                   EntityType.ENTITY_WIZOOB) -- 219
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC261,
                                                   EntityType.ENTITY_DINGLE) -- 261
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC219,
                                                   EntityType.ENTITY_RED_GHOST) -- 285
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC273,
                                                   EntityType.ENTITY_THE_LAMB) -- 273
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC275,
                                                   EntityType.ENTITY_MEGA_SATAN_2) -- 273
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, FastClear.NPC302,
                                                   EntityType.ENTITY_STONEY) -- 302
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC411,
                                                   EntityType.ENTITY_BIG_HORN) -- 411
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.NPC413,
                                                   EntityType.ENTITY_MATRIARCH) -- 413

-- Define miscellaneous callbacks
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,           PostUpdate.Main) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_RENDER,           PostRender.Main) -- 2
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,        EvaluateCache.Main) -- 8
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,      PostPlayerInit.Main) -- 9
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,       EntityTakeDmg.Main, -- 11
                                                              EntityType.ENTITY_PLAYER) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_INPUT_ACTION,          InputAction.Main) -- 13
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,     PostGameStarted.Main) -- 15
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_END,         Speedrun.PostGameEnd) -- 16
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,        PostNewLevel.Main) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,         PostNewRoom.Main) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_EXECUTE_CMD,           ExecuteCmd.Main) -- 22
RacingPlus:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN,      PreEntitySpawn.Main) -- 24
RacingPlus:AddCallback(ModCallbacks.MC_POST_NPC_INIT,         FastClear.PostNPCInit) -- 27
RacingPlus:AddCallback(ModCallbacks.MC_POST_NPC_INIT,         PostNPCInit.NPC260, -- 27
                                                              EntityType.ENTITY_THE_HAUNT) -- 260
RacingPlus:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT,      PostPickupInit.Main) -- 34
RacingPlus:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, PostPickupSelection.Main) -- 37
RacingPlus:AddCallback(ModCallbacks.MC_POST_LASER_INIT,       PostLaserInit.Main) -- 47
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE,    FastClear.PostEntityRemove) -- 67
RacingPlus:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, PreRoomEntitySpawn.Main) -- 71

-- Define post-use item callbacks (3)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Main) -- 3
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Item44,
                                                 CollectibleType.COLLECTIBLE_TELEPORT) -- 44
-- (this callback is also used by Broken Remote)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Item127,
                                                 CollectibleType.COLLECTIBLE_FORGET_ME_NOW) -- 127
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Item286,
                                                 CollectibleType.COLLECTIBLE_BLANK_CARD) -- 286
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Item324,
                                                 CollectibleType.COLLECTIBLE_UNDEFINED) -- 324
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Item477,
                                                 CollectibleType.COLLECTIBLE_VOID) -- 477
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Item515,
                                                 CollectibleType.COLLECTIBLE_MYSTERY_GIFT) -- 515
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Item523,
                                                 CollectibleType.COLLECTIBLE_MOVING_BOX) -- 523
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, Debug.Main,
                                                 CollectibleType.COLLECTIBLE_DEBUG)

-- Define post-use item callbacks for seeding player-generated pedestals (3)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.PlayerGeneratedPedestal,
                                                 CollectibleType.COLLECTIBLE_BLUE_BOX) -- 297
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.PlayerGeneratedPedestal,
                                                 CollectibleType.COLLECTIBLE_EDENS_SOUL) -- 490
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.PlayerGeneratedPedestal,
                                                 CollectibleType.COLLECTIBLE_MYSTERY_GIFT) -- 515

-- Define card callbacks (5)
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_FOOL) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_EMPEROR) -- 5
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_HERMIT) -- 10
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Strength, Card.CARD_STRENGTH) -- 12
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_STARS) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_MOON) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_JOKER) -- 31

-- Define pill callbacks (10)
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, UsePill.Main) -- 10
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, UsePill.HealthUp,
                                                 PillEffect.PILLEFFECT_HEALTH_UP) -- 7
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, UsePill.Telepills,
                                                 PillEffect.PILLEFFECT_TELEPILLS) -- 19

-- Define pre-use item callbacks (23)
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.Item84, -- 23
                                                     CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER) -- 84
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.Item97, -- 23
                                                     CollectibleType.COLLECTIBLE_BOOK_OF_SIN) -- 97
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Speedrun.PreventD6, -- 23
                                                     CollectibleType.COLLECTIBLE_D6) -- 105
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.Item124, -- 23
                                                     CollectibleType.COLLECTIBLE_DEAD_SEA_SCROLLS) -- 124
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.Item422, -- 23
                                                     CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS) -- 422
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.Item479, -- 23
                                                     CollectibleType.COLLECTIBLE_SMELTER) -- 479

-- Define pre-use item callbacks for preventing item pedestal effects (23)
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.PreventItemPedestalEffects, -- 23
                                                     CollectibleType.COLLECTIBLE_D6) -- 105
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.PreventItemPedestalEffects, -- 23
                                                     CollectibleType.COLLECTIBLE_D100) -- 283
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.PreventItemPedestalEffects, -- 23
                                                     CollectibleType.COLLECTIBLE_DIPLOPIA) -- 347
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.PreventItemPedestalEffects, -- 23
                                                     CollectibleType.COLLECTIBLE_VOID) -- 477
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.PreventItemPedestalEffects, -- 23
                                                     CollectibleType.COLLECTIBLE_CROOKED_PENNY) -- 485
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.PreventItemPedestalEffects, -- 23
                                                     CollectibleType.COLLECTIBLE_DINF) -- 489
RacingPlus:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PreUseItem.PreventItemPedestalEffects, -- 23
                                                     CollectibleType.COLLECTIBLE_MOVING_BOX) -- 523

-- Define post-entity-kill callbacks (68)
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, FastClear.PostEntityKill) -- 68
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Main) -- 68
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Entity45,
                                                         EntityType.ENTITY_MOM) -- 45
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Entity78,
                                                         EntityType.ENTITY_MOMS_HEART) -- 78
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Entity81, -- (to handle fast-drops)
                                                         EntityType.ENTITY_FALLEN) -- 81
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Entity271, -- (to handle fast-drops)
                                                         EntityType.ENTITY_URIEL) -- 271
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Entity271, -- (to handle fast-drops)
                                                         EntityType.ENTITY_GABRIEL) -- 272
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Entity78,
                                                         EntityType.ENTITY_HUSH) -- 407

-- Samael callbacks
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        Samael.scytheUpdate, -- 0
                                                          Isaac.GetEntityTypeByName("Samael Scythe"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        Samael.specialAnimFunc, -- 0
                                                          Isaac.GetEntityTypeByName("Samael Special Animations"))
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       Samael.roomEntitiesLoop) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       Samael.PostUpdate) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       Samael.PostUpdateFixBugs) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          Samael.postReroll, -- 3
                                                          CollectibleType.COLLECTIBLE_D4) -- 284
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          Samael.postReroll, -- 3
                                                          CollectibleType.COLLECTIBLE_D100) -- 283
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,          Samael.activateWraith, -- 3
                                                          Isaac.GetItemIdByName("Wraith Skull"))
RacingPlus:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,   Samael.hitBoxFunc, -- 6
                                                          FamiliarVariant.SACRIFICIAL_DAGGER) -- 35
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,    Samael.cacheUpdate) -- 8
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,  Samael.PostPlayerInit) -- 9
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   Samael.scytheHits) -- 11
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   Samael.playerDamage, -- 11
                                                          EntityType.ENTITY_PLAYER) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Samael.PostGameStartedReset) -- 15

-- Jr. Fetus callbacks
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,         JrFetus.UpdateDrFetus,
                                                           Isaac.GetEntityTypeByName("Dr Fetus Jr"))
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,    JrFetus.DrFetusTakeDamage,
                                                           Isaac.GetEntityTypeByName("Dr Fetus Jr"))
RacingPlus:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, JrFetus.UpdateMissileTarget)
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL,   JrFetus.DrFetusEmbryoKill,
                                                           Isaac.GetEntityTypeByName("Dr Fetus Boss Embryo"))
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,      JrFetus.PostNewRoom)
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,  JrFetus.PostGameStarted)

-- Mahalath callbacks
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       Mahalath.PostUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        Mahalath.check_girl, Isaac.GetEntityTypeByName("Mahalath"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        Mahalath.check_mouth,
                                                          Isaac.GetEntityTypeByName("Barf Mouth"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        Mahalath.check_balls,
                                                          Isaac.GetEntityTypeByName("Barf Ball"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        Mahalath.check_bomb, Isaac.GetEntityTypeByName("Barf Bomb"))
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        Mahalath.check_del, EntityType.ENTITY_DELIRIUM) -- 412
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   Mahalath.take_dmg)
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,     Mahalath.PostNewRoom)
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Mahalath.PostGameStarted)

-- Welcome banner
local hyphens = ''
for i = 1, 23 + string.len(g.version) do
  hyphens = hyphens .. "-"
end
Isaac.DebugString("+" .. hyphens .. "+")
Isaac.DebugString("| Racing+ " .. g.version .. " initialized. |")
Isaac.DebugString("+" .. hyphens .. "+")
