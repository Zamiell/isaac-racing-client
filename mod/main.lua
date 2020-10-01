--
-- The Racing+ Lua Mod
-- by Zamiel
--

--[[

Directory: racing+_857628390
Steam Workshop URL: https://steamcommunity.com/sharedfiles/filedetails/?id=857628390

TODO:
- In Rep, change health:
  - Give Judas full red heart
  - Give Cain + Eve + Apollyon half soul heart
- Implement time offsets, show on the first room of each floor

POST-FLIP ACTIONS:
1) Remove the duplicated start rooms for The Chest / Dark Room
2) Un-flip Y-flipped Gurdy rooms:
   The Chest - #20018, #30018
3) Un-flip double Gate rooms (and enable all of the doors)
   The Chest - #20040, #30040
   Dark Room - #20012, #30012
4) Un-flip some Mega Maw rooms:
   The Chest - #20039, #30039, #20269, #30269
   Dark Room - #20011, #30011

--]]

-- Integrate Mod Config Menu by piber20
-- (waiting for Rep to integrate since "save.dat" files are complicated to manage)
-- require("scripts.modconfig")

-- Integrate MinimapAPI by Taz & Wofsauge
-- https://github.com/TazTxUK/MinimapAPI/wiki/Integrating-MinimapAPI-into-a-standalone-mod
-- (waiting for Rep to integrate since "save.dat" files are complicated to manage)
-- require("scripts.minimapapi.init")

-- Register the mod (the second argument is the API version)
local RacingPlus = RegisterMod("Racing+", 1)

-- The Lua code is split up into separate files for organizational purposes
-- File names must be in a uniquely named directory because no two mods can have the same require
-- path
-- In the code, file names must be in lowercase for Linux compatibility purposes;
-- the actual files themselves can have capital letters
local g = require("racing_plus/globals") -- Global variables
local NPCUpdate = require("racing_plus/npcupdate") -- 0
local PostUpdate = require("racing_plus/postupdate") -- 1
local PostRender = require("racing_plus/postrender") -- 2
local UseItem = require("racing_plus/useitem") -- 3
local UseCard = require("racing_plus/usecard") -- 5
local EvaluateCache = require("racing_plus/evaluatecache") -- 8
local PostPlayerInit = require("racing_plus/postplayerinit") -- 9
local UsePill = require("racing_plus/usepill") -- 10
local EntityTakeDmg = require("racing_plus/entitytakedmg") -- 11
local PostCurseEval = require("racing_plus/postcurseeval") -- 12
local InputAction = require("racing_plus/inputaction") -- 13
local PostGameStarted = require("racing_plus/postgamestarted") -- 15
local PostNewLevel = require("racing_plus/postnewlevel") -- 18
local PostNewRoom = require("racing_plus/postnewroom") -- 19
local GetCard = require("racing_plus/getcard") -- 20
local ExecuteCmd = require("racing_plus/executecmd") -- 22
local PreUseItem = require("racing_plus/preuseitem") -- 23
local PreEntitySpawn = require("racing_plus/preentityspawn") -- 24
local PostNPCInit = require("racing_plus/postnpcinit") -- 27
local PostNPCRender = require("racing_plus/postnpcrender") -- 28
local PostPickupInit = require("racing_plus/postpickupinit") -- 34
local PostPickupUpdate = require("racing_plus/postpickupupdate") -- 35
local PostLaserInit = require("racing_plus/postlaserinit") -- 47
local PostEffectInit = require("racing_plus/posteffectinit") -- 54
local PostEffectUpdate = require("racing_plus/posteffectupdate") -- 55
local PostBombInit = require("racing_plus/postbombinit") -- 57
local PostBombUpdate = require("racing_plus/postbombupdate") -- 58
local PostFireTear = require("racing_plus/postfiretear") -- 61
local PreGetCollectible = require("racing_plus/pregetcollectible") -- 62
local GetPillEffect = require("racing_plus/getpilleffect") -- 65
local PostEntityKill = require("racing_plus/postentitykill") -- 68
local PreNPCUpdate = require("racing_plus/prenpcupdate") -- 69
local PreRoomEntitySpawn = require("racing_plus/preroomentityspawn") -- 71
local FastClear = require("racing_plus/fastclear")
local Schoolbag = require("racing_plus/schoolbag")
local Speedrun = require("racing_plus/speedrun")
local Season7 = require("racing_plus/season7")
local Samael = require("racing_plus/samael")
local JrFetus = require("racing_plus/jrfetus")
local Mahalath = require("racing_plus/mahalath")
local PotatoDummy = require("racing_plus/potatodummy")
local Debug = require("racing_plus/debug")

-- Initialize the "g.run" table
g:InitRun()

-- Make a copy of this object so that we can use it elsewhere
g.RacingPlus = RacingPlus -- (this is needed for saving and loading the "save.dat" file)

-- Set some specific global variables so that other mods can access Racing+ game state
RacingPlusGlobals = g
RacingPlusSchoolbag = Schoolbag
RacingPlusSpeedrun = Speedrun

-- Define miscellaneous callbacks
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, NPCUpdate.Main) -- 0
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate.Main) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_RENDER, PostRender.Main) -- 2
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, UseItem.Main) -- 3
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Main) -- 5
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, EvaluateCache.Main) -- 8
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PostPlayerInit.Main) -- 9
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, UsePill.Main) -- 10
RacingPlus:AddCallback(ModCallbacks.MC_POST_CURSE_EVAL, PostCurseEval.Main) -- 12
RacingPlus:AddCallback(ModCallbacks.MC_INPUT_ACTION, InputAction.Main) -- 13
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, PostGameStarted.Main) -- 15
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_END, Speedrun.PostGameEnd) -- 16
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, PostNewLevel.Main) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom.Main) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_GET_CARD, GetCard.Main) -- 20
RacingPlus:AddCallback(ModCallbacks.MC_EXECUTE_CMD, ExecuteCmd.Main) -- 22
RacingPlus:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, PreEntitySpawn.Main) -- 24
RacingPlus:AddCallback(ModCallbacks.MC_POST_NPC_INIT, FastClear.PostNPCInit) -- 27
RacingPlus:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, PostPickupUpdate.Main) -- 35
RacingPlus:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, PostBombUpdate.Main) -- 58
RacingPlus:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, PostFireTear.Main) -- 61
RacingPlus:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, PreGetCollectible.Main) -- 62
RacingPlus:AddCallback(ModCallbacks.MC_GET_PILL_EFFECT, GetPillEffect.Main) -- 65
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, FastClear.PostEntityRemove) -- 67
RacingPlus:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PostEntityKill.Main) -- 68
RacingPlus:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, PreRoomEntitySpawn.Main) -- 71

-- Define NPC callbacks (0)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.Globin,
  EntityType.ENTITY_GLOBIN -- 24
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.FearImmunity,
  EntityType.ENTITY_HOST -- 27
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.Chub,
  EntityType.ENTITY_CHUB -- 28
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.FlamingHopper,
  EntityType.ENTITY_FLAMINGHOPPER -- 54
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.Pin,
  EntityType.ENTITY_PIN -- 62
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.Death,
  EntityType.ENTITY_DEATH -- 66
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.FreezeImmunity,
  EntityType.ENTITY_BLASTOCYST_BIG -- 74
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.FreezeImmunity,
  EntityType.ENTITY_BLASTOCYST_MEDIUM -- 75
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.FreezeImmunity,
  EntityType.ENTITY_BLASTOCYST_SMALL -- 76
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.FearImmunity,
  EntityType.ENTITY_MOBILE_HOST -- 204
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.SpeedupHand,
  EntityType.ENTITY_MOMS_HAND -- 213
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  FastClear.Ragling,
  EntityType.ENTITY_RAGLING -- 246
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.SpeedupHand,
  EntityType.ENTITY_MOMS_DEAD_HAND -- 287
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.SpeedupGhost,
  EntityType.ENTITY_WIZOOB -- 219
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.Dingle,
  EntityType.ENTITY_DINGLE -- 261
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.SpeedupGhost,
  EntityType.ENTITY_RED_GHOST -- 285
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.TheLamb,
  EntityType.ENTITY_THE_LAMB -- 273
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.MegaSatan2,
  EntityType.ENTITY_MEGA_SATAN_2 -- 273
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  FastClear.Stoney,
  EntityType.ENTITY_STONEY -- 302
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.FearImmunity,
  EntityType.ENTITY_FORSAKEN -- 403
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.UltraGreed, -- 406
  EntityType.ENTITY_ULTRA_GREED
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.BigHorn,
  EntityType.ENTITY_BIG_HORN -- 411
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  NPCUpdate.Matriarch,
  EntityType.ENTITY_MATRIARCH -- 413
)

-- Define post-use item callbacks (3)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.Teleport, -- This callback is also used by Broken Remote
  CollectibleType.COLLECTIBLE_TELEPORT -- 44
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.D6,
  CollectibleType.COLLECTIBLE_D6 -- 105
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.ForgetMeNow,
  CollectibleType.COLLECTIBLE_FORGET_ME_NOW -- 127
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.BlankCard,
  CollectibleType.COLLECTIBLE_BLANK_CARD -- 286
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.Undefined,
  CollectibleType.COLLECTIBLE_UNDEFINED -- 324
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.Void,
  CollectibleType.COLLECTIBLE_VOID -- 477
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.MovingBox,
  CollectibleType.COLLECTIBLE_MOVING_BOX -- 523
)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, Debug.Main, CollectibleType.COLLECTIBLE_DEBUG)

-- Define post-use item callbacks for seeding player-generated pedestals (3)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.PlayerGeneratedPedestal,
  CollectibleType.COLLECTIBLE_BLUE_BOX -- 297
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.PlayerGeneratedPedestal,
  CollectibleType.COLLECTIBLE_EDENS_SOUL -- 490
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM,
  UseItem.PlayerGeneratedPedestal,
  CollectibleType.COLLECTIBLE_MYSTERY_GIFT -- 515
)

-- Define card callbacks (5)
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_FOOL) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_EMPEROR) -- 5
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Justice, Card.CARD_JUSTICE) -- 9
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_HERMIT) -- 10
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Strength, Card.CARD_STRENGTH) -- 12
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_STARS) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_MOON) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.Teleport, Card.CARD_JOKER) -- 31
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.BlackRune, Card.RUNE_BLACK) -- 41
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, UseCard.QuestionMark, Card.CARD_QUESTIONMARK) -- 48

-- Define pill callbacks (10)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.HealthDown,
  PillEffect.PILLEFFECT_HEALTH_DOWN -- 6
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.HealthUp,
  PillEffect.PILLEFFECT_HEALTH_UP -- 7
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.Telepills,
  PillEffect.PILLEFFECT_TELEPILLS -- 19
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.OneMakesYouLarger,
  PillEffect.PILLEFFECT_LARGER -- 32
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.OneMakesYouSmaller,
  PillEffect.PILLEFFECT_SMALLER -- 33
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.InfestedExclamation,
  PillEffect.PILLEFFECT_INFESTED_EXCLAMATION -- 34
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.InfestedQuestion,
  PillEffect.PILLEFFECT_INFESTED_QUESTION -- 35
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.PowerPill,
  PillEffect.PILLEFFECT_POWER -- 36
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.RetroVision,
  PillEffect.PILLEFFECT_RETRO_VISION -- 37
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_PILL,
  UsePill.Horf,
  PillEffect.PILLEFFECT_HORF -- 44
)

-- Define entity damage callbacks (11)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG,
  EntityTakeDmg.Player,
  EntityType.ENTITY_PLAYER -- 1
)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG,
  Season7.EntityTakeDmgRemoveArmor,
  EntityType.ENTITY_ULTRA_GREED -- 406
)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG,
  Season7.EntityTakeDmgRemoveArmor,
  EntityType.ENTITY_HUSH -- 407
)

-- Define pre-use item callbacks (23)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.WeNeedToGoDeeper,
  CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER -- 84
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.BookOfSin,
  CollectibleType.COLLECTIBLE_BOOK_OF_SIN -- 97
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.DeadSeaScrolls,
  CollectibleType.COLLECTIBLE_DEAD_SEA_SCROLLS -- 124
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.GuppysHead,
  CollectibleType.COLLECTIBLE_GUPPYS_HEAD -- 145
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.GlowingHourGlass,
  CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS -- 422
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.Smelter,
  CollectibleType.COLLECTIBLE_SMELTER -- 479
)

-- Define pre-use item callbacks for preventing item pedestal effects (23)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.PreventItemPedestalEffects,
  CollectibleType.COLLECTIBLE_D6 -- 105
  -- This callback will also fire for D100, D Infinity when used as a D6/D100, and Dice Shard
  -- However, we will want to explicitly hook D100 and D Infinity since they be able to use the
  -- provided recharge to get infinite item uses
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.PreventItemPedestalEffects,
  CollectibleType.COLLECTIBLE_D100 -- 283
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.PreventItemPedestalEffects,
  CollectibleType.COLLECTIBLE_DIPLOPIA -- 347
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.PreventItemPedestalEffects,
  CollectibleType.COLLECTIBLE_VOID -- 477
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.PreventItemPedestalEffects,
  CollectibleType.COLLECTIBLE_CROOKED_PENNY -- 485
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.PreventItemPedestalEffects,
  CollectibleType.COLLECTIBLE_DINF -- 489
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_USE_ITEM,
  PreUseItem.PreventItemPedestalEffects,
  CollectibleType.COLLECTIBLE_MOVING_BOX -- 523
)

-- Define post-NPC-initialization callbacks (27)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_NPC_INIT,
  PostNPCInit.Baby,
  EntityType.ENTITY_BABY -- 38
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_NPC_INIT,
  Season7.PostNPCInitIsaac,
  EntityType.ENTITY_ISAAC -- 102
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_NPC_INIT,
  PostNPCInit.TheHaunt,
  EntityType.ENTITY_THE_HAUNT -- 260
)

-- Define post-NPC-render callbacks (28)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_NPC_RENDER,
  PostNPCRender.Pitfall,
  EntityType.ENTITY_PITFALL -- 291
)

-- Define post pickup init callbacks (34)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_INIT,
  PostPickupInit.Coin,
  PickupVariant.PICKUP_COIN -- 20
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_INIT,
  PostPickupInit.CheckSpikedChestUnavoidable,
  PickupVariant.PICKUP_SPIKEDCHEST -- 52
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_INIT,
  PostPickupInit.CheckSpikedChestUnavoidable,
  PickupVariant.PICKUP_MIMICCHEST -- 54
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_INIT,
  PostPickupInit.TarotCard,
  PickupVariant.PICKUP_TAROTCARD -- 300
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_INIT,
  PostPickupInit.BigChest,
  PickupVariant.PICKUP_BIGCHEST -- 340
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_INIT,
  PostPickupInit.Trophy,
  PickupVariant.PICKUP_TROPHY -- 370
)

-- Define post pickup update callbacks (35)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_UPDATE,
  PostPickupUpdate.Heart,
  PickupVariant.PICKUP_HEART -- 10
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_UPDATE,
  PostPickupUpdate.Coin,
  PickupVariant.PICKUP_COIN -- 20
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_UPDATE,
  PostPickupUpdate.Collectible,
  PickupVariant.PICKUP_COLLECTIBLE -- 100
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_UPDATE,
  PostPickupUpdate.TarotCard,
  PickupVariant.PICKUP_TAROTCARD -- 300
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PICKUP_UPDATE,
  PostPickupUpdate.Trinket,
  PickupVariant.PICKUP_TRINKET -- 350
)

-- Define post laser init callbacks (47)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_LASER_INIT,
  PostLaserInit.GiantRed,
  g.LaserVariant.LASER_GIANT_RED -- 6
)

-- Define post effect init callbacks (54)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_INIT,
  PostEffectInit.Poof01,
  EffectVariant.POOF01 -- 15
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_INIT,
  PostEffectInit.HotBombFire,
  EffectVariant.HOT_BOMB_FIRE -- 51
)

-- Define post effect update callbacks (55)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.Devil,
  EffectVariant.DEVIL -- 6
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.TearPoof,
  EffectVariant.TEAR_POOF_A -- 12
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.TearPoof,
  EffectVariant.TEAR_POOF_B -- 13
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.HeavenLightDoor,
  EffectVariant.HEAVEN_LIGHT_DOOR -- 39
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.DiceFloor,
  EffectVariant.DICE_FLOOR -- 76
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.Trapdoor,
  EffectVariant.TRAPDOOR_FAST_TRAVEL
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.Trapdoor,
  EffectVariant.WOMB_TRAPDOOR_FAST_TRAVEL
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.Trapdoor,
  EffectVariant.BLUE_WOMB_TRAPDOOR_FAST_TRAVEL
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.Crawlspace,
  EffectVariant.CRAWLSPACE_FAST_TRAVEL
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.HeavenDoor,
  EffectVariant.HEAVEN_DOOR_FAST_TRAVEL
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.VoidPortal,
  EffectVariant.VOID_PORTAL_FAST_TRAVEL
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.MegaSatanTrapdoor,
  EffectVariant.MEGA_SATAN_TRAPDOOR
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.CrackTheSkyBase,
  EffectVariant.CRACK_THE_SKY_BASE
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE,
  PostEffectUpdate.StickyNickel,
  EffectVariant.STICKY_NICKEL
)

-- Define post bomb init callbacks (57)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_BOMB_INIT,
  PostBombInit.SetTimer,
  BombVariant.BOMB_TROLL -- 3
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_BOMB_INIT,
  PostBombInit.SetTimer,
  BombVariant.BOMB_SUPERTROLL -- 4
)

-- Define post entity kill callbacks (68)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.Mom,
  EntityType.ENTITY_MOM -- 45
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.MomsHeart,
  EntityType.ENTITY_MOMS_HEART -- 78
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.Fallen,
  EntityType.ENTITY_FALLEN -- 81
  -- (to handle fast-drops)
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.Angel,
  EntityType.ENTITY_URIEL -- 271
  -- (to handle fast-drops)
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.Angel,
  EntityType.ENTITY_GABRIEL -- 272
  -- (to handle fast-drops)
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.UltraGreed,
  EntityType.ENTITY_ULTRA_GREED -- 406
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.MomsHeart, -- Hush uses the Mom's Heart callback
  EntityType.ENTITY_HUSH -- 407
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL,
  PostEntityKill.RoomClearDelayNPC,
  EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC
)

--Define pre NPC update callbacks (69)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_NPC_UPDATE,
  PreNPCUpdate.Hand,
  EntityType.ENTITY_MOMS_HAND -- 213
)
RacingPlus:AddCallback(
  ModCallbacks.MC_PRE_NPC_UPDATE,
  PreNPCUpdate.Hand,
  EntityType.ENTITY_MOMS_DEAD_HAND -- 287
)

-- Samael callbacks
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE, -- 0
  Samael.scytheUpdate,
  EntityType.ENTITY_SAMAEL_SCYTHE
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE, -- 0
  Samael.specialAnimFunc,
  EntityType.ENTITY_SAMAEL_SPECIAL_ANIMATIONS
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_UPDATE, -- 1
  Samael.roomEntitiesLoop
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_UPDATE, -- 1
  Samael.PostUpdate
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_UPDATE, -- 1
  Samael.PostUpdateFixBugs
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM, -- 3
  Samael.postReroll,
  CollectibleType.COLLECTIBLE_D4 -- 284
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM, -- 3
  Samael.postReroll,
  CollectibleType.COLLECTIBLE_D100 -- 283
)
RacingPlus:AddCallback(
  ModCallbacks.MC_USE_ITEM, -- 3
  Samael.activateWraith, -- 3
  CollectibleType.COLLECTIBLE_WRAITH_SKULL
)
RacingPlus:AddCallback(
  ModCallbacks.MC_FAMILIAR_UPDATE, -- 6
  Samael.hitBoxFunc, -- 6
  FamiliarVariant.SACRIFICIAL_DAGGER -- 35
)
RacingPlus:AddCallback(
  ModCallbacks.MC_EVALUATE_CACHE, -- 8
  Samael.cacheUpdate
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_PLAYER_INIT, -- 9
  Samael.PostPlayerInit
)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG, -- 11
  Samael.scytheHits
)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG, -- 11
  Samael.playerDamage,
  EntityType.ENTITY_PLAYER -- 1
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_GAME_STARTED, -- 15
  Samael.PostGameStartedReset
)

-- Jr. Fetus callbacks
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE, -- 0
  JrFetus.UpdateDrFetus,
  Isaac.GetEntityTypeByName("Dr Fetus Jr")
)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG, -- 11
  JrFetus.DrFetusTakeDamage,
  Isaac.GetEntityTypeByName("Dr Fetus Jr")
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_EFFECT_UPDATE, -- 55
  JrFetus.UpdateMissileTarget,
  Isaac.GetEntityVariantByName("FetusBossTarget")
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_ENTITY_KILL, -- 68
  JrFetus.DrFetusEmbryoKill,
  Isaac.GetEntityTypeByName("Dr Fetus Boss Embryo")
)

-- Mahalath callbacks
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE, -- 0
  Mahalath.check_girl,
  Isaac.GetEntityTypeByName("Mahalath")
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE, -- 0
  Mahalath.check_mouth,
  Isaac.GetEntityTypeByName("Barf Mouth")
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE, -- 0
  Mahalath.check_balls,
  Isaac.GetEntityTypeByName("Barf Ball")
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE,
  Mahalath.check_bomb,
  Isaac.GetEntityTypeByName("Barf Bomb")
)
RacingPlus:AddCallback(
  ModCallbacks.MC_NPC_UPDATE, -- 0
  Mahalath.check_del,
  EntityType.ENTITY_DELIRIUM -- 412
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_UPDATE, -- 1
  Mahalath.PostUpdate
)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG, -- 11
  Mahalath.take_dmg
)

-- Potato Dummy callbacks
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_UPDATE, -- 1
  PotatoDummy.PostUpdate
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_RENDER, -- 2
  PotatoDummy.PostRender
)
RacingPlus:AddCallback(
  ModCallbacks.MC_ENTITY_TAKE_DMG, -- 11
  PotatoDummy.EntityTakeDmg,
  EntityType.ENTITY_NERVE_ENDING -- 231
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_GAME_STARTED, -- 15
  PotatoDummy.PostGameStarted
)
RacingPlus:AddCallback(
  ModCallbacks.MC_POST_NEW_ROOM, -- 19
  PotatoDummy.PostNewRoom
)

-- MinimapAPI init
if MinimapAPI ~= nil then
  local customIcons = Sprite()
  customIcons:Load("gfx/pills/custom_icons.anm2", true)
  -- Getting rid of the ugly white pixel
  MinimapAPI:AddIcon("PillOrangeOrange", customIcons, "CustomIconPillOrangeOrange", 0) -- 3
  -- Red dots / red --> full red
  MinimapAPI:AddIcon("PillReddotsRed", customIcons, "CustomIconPillReddotsRed", 0) -- 5
  -- Pink red / red --> white / red
  MinimapAPI:AddIcon("PillPinkRed", customIcons, "CustomIconPillPinkRed", 0) -- 6
  -- Getting rid of the ugly white pixel
  MinimapAPI:AddIcon("PillYellowOrange", customIcons, "CustomIconPillYellowOrange", 0) -- 8
  -- White dots / white --> full white dots
  MinimapAPI:AddIcon("PillOrangedotsWhite", customIcons, "CustomIconPillOrangedotsWhite", 0) -- 9
  -- Cleaner sprite for Emergency Contact
  MinimapAPI:AddIcon("MomsContract", customIcons, "CustomIconMomsContract", 0) -- 50
  -- New sprite for Blank Rune
  MinimapAPI:AddIcon("BlankRune", customIcons, "CustomIconBlankRune", 0) -- 40
  MinimapAPI:AddPickup(
    "BlankRune",
    "BlankRune",
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_TAROTCARD, -- 300
    Card.RUNE_BLANK, -- 40
    MinimapAPI.PickupNotCollected,
    "runes",
    1200
  )
  -- New sprite for Black Rune
  MinimapAPI:AddIcon("BlackRune", customIcons, "CustomIconBlackRune", 0) -- 41
  MinimapAPI:AddPickup(
    "BlackRune",
    "BlackRune",
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_TAROTCARD, -- 300
    Card.RUNE_BLACK, -- 41
    MinimapAPI.PickupNotCollected,
    "runes",
    1200
  )
  -- New sprite for Rules Card
  MinimapAPI:AddIcon("Rules", customIcons, "CustomIconRules", 0) -- 44
  MinimapAPI:AddPickup(
    "Rules",
    "Rules",
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_TAROTCARD, -- 300
    Card.CARD_RULES, -- 44
    MinimapAPI.PickupNotCollected,
    "cards",
    1200
  )
  -- New sprite for Suicide King
  MinimapAPI:AddIcon("SuicideKing", customIcons, "CustomIconSuicideKing", 0) -- 46
  MinimapAPI:AddPickup(
    "SuicideKing",
    "SuicideKing",
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_TAROTCARD, -- 300
    Card.CARD_SUICIDE_KING, -- 46
    MinimapAPI.PickupNotCollected,
    "cards",
    1200
  )
  -- New sprite for ? Card
  MinimapAPI:AddIcon("QuestionMark", customIcons, "CustomIconQuestionMark", 0) -- 48
  MinimapAPI:AddPickup(
    "QuestionMark",
    "QuestionMark",
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_TAROTCARD, -- 300
    Card.CARD_QUESTIONMARK, -- 48
    MinimapAPI.PickupNotCollected,
    "cards",
    1200
  )
end

-- Bugfix for Mod Config Menu
local mcmexists, MCM = pcall(require, "scripts.modconfig")
if mcmexists then
  MCM.RoomIsSafe = function()
    return true
  end
end

-- Welcome banner
local hyphens = ""
for i = 1, 23 + string.len(g.version) do
  hyphens = hyphens .. "-"
end
Isaac.DebugString("+" .. hyphens .. "+")
Isaac.DebugString("| Racing+ " .. g.version .. " initialized. |")
Isaac.DebugString("+" .. hyphens .. "+")
