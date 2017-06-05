--
-- The Racing+ Lua Mod
-- by Zamiel
--

--[[

TODO Samael:
- Dead Eye + Knife doesn't work
- look at satan
- fix red guys
- fortunes
- relook at rules

TODO:
- Implement time offsets, show on the first room of each floor
- Opponent's shadows

TODO DIFFICULT:
- Fix Isaac babies spawning on top of you
- Fix Isaac beams never hitting you
- Fix Conquest beams
- Speed up the spawning of the first ghost on The Haunt fight

TODO CAN'T FIX:
- Fix Dead Eye on poop / red poop / static TNT barrels (can't modify existing items, no "player:GetDeadEyeCharge()"
  function)
- Make a 3rd color hue on the map for rooms that are not cleared but you have entered.
- Make fast-clear apply to Challenge rooms and the Boss Rush ("room:SetAmbushDone()" doesn't do anything)

--]]

-- Register the mod (the second argument is the API version)
local RacingPlus = RegisterMod("Racing+", 1)

-- The Lua code is split up into separate files for organizational purposes
local RPGlobals         -- Global variables
local RPNPCUpdate       -- The NPCUpdate callback
local RPPostUpdate      -- The PostUpdate callback
local RPPostRender      -- The PostRender callback
local RPCallbacks       -- Miscellaneous callbacks
local RPPostGameStarted -- The PostGameStarted callback
local RPItems           -- Collectible item functions
local RPCards           -- Card functions
local RPPills           -- Pill functions
local SamaelMod         -- Samael functions
local RPDebug           -- Debug functions

local function requireFiles()
  -- The filenames have to be lowercase because on Linux, all files are renamed to lowercase by the game for some reason
  RPGlobals         = require("src/rpglobals")
  RPNPCUpdate       = require("src/rpnpcupdate")
  RPPostUpdate      = require("src/rppostupdate")
  RPPostRender      = require("src/rppostrender")
  RPCallbacks       = require("src/rpcallbacks")
  RPPostGameStarted = require("src/rppostgamestarted")
  RPItems           = require("src/rpitems")
  RPCards           = require("src/rpcards")
  RPPills           = require("src/rppills")
  SamaelMod         = require("src/rpsamael")
  RPDebug           = require("src/rpdebug")
end

-- The "requireFiles" function will fail if we have the "--luadebug" flag on
if pcall(requireFiles) == false then
  -- There is a bug where users with the "--luadebug" flag on do not have the mod directory inside the package path
  -- So, add it to the package path manually
  local modDirectory = string.gsub(debug.getinfo(1).source, "^@(.+)main.lua$", "%1");
  package.path = package.path .. ";" .. modDirectory .. "?.lua"
  requireFiles()
end

-- Initiailize the "RPGlobals.run" table
RPGlobals:InitRun()

-- Make a copy of this object so that we can use it elsewhere
RPGlobals.RacingPlus = RacingPlus -- (this is needed for loading the "save.dat" file)

-- Define miscellaneous callbacks
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,        RPNPCUpdate.Main) -- 0
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE,       RPPostUpdate.Main) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_POST_RENDER,       RPPostRender.Main) -- 2
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,    RPCallbacks.EvaluateCache) -- 8
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT,  RPCallbacks.PostPlayerInit) -- 9
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   RPCallbacks.EntityTakeDamage) -- 11
RacingPlus:AddCallback(ModCallbacks.MC_INPUT_ACTION,      RPCallbacks.InputAction) -- 13
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, RPPostGameStarted.Main) -- 15
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,    RPCallbacks.PostNewLevel) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,     RPCallbacks.PostNewRoom) -- 19

-- Define item callbacks
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Main) -- Will get called for all items
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Teleport,  CollectibleType.COLLECTIBLE_TELEPORT) -- 44
-- (this callback is also used by Broken Remote)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.BlankCard, CollectibleType.COLLECTIBLE_BLANK_CARD) -- 286
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Undefined, CollectibleType.COLLECTIBLE_UNDEFINED) -- 324
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.GlowingHourGlass,
                                                 CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS) -- 422
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Void,      CollectibleType.COLLECTIBLE_VOID) -- 477

-- Define custom item callbacks
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.BookOfSin,   CollectibleType.COLLECTIBLE_BOOK_OF_SIN_SEEDED)
-- Replacing Book of Sin (97)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPItems.Smelter,     CollectibleType.COLLECTIBLE_SMELTER_LOGGER)
-- Replacing Smelter (479)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RPDebug.Main,        CollectibleType.COLLECTIBLE_DEBUG)
-- Debug (custom item, 263)

-- Define card/pill callbacks
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport,   Card.CARD_FOOL) -- 1
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport,   Card.CARD_EMPEROR) -- 5
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport,   Card.CARD_HERMIT) -- 10
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Strength,   Card.CARD_STRENGTH) -- 12
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport,   Card.CARD_STARS) -- 18
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport,   Card.CARD_MOON) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_USE_CARD, RPCards.Teleport,   Card.CARD_JOKER) -- 31
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, RPPills.Telepills,  PillEffect.PILLEFFECT_TELEPILLS) -- 19
RacingPlus:AddCallback(ModCallbacks.MC_USE_PILL, RPPills.Gulp,       PillEffect.PILLEFFECT_GULP_LOGGER)
-- This is a callback for a custom "Gulp!" pill; we can't use the original because
-- by the time the callback is reached, the trinkets are already consumed

-- Samael callback
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, SamaelMod.postReroll, CollectibleType.COLLECTIBLE_D4)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, SamaelMod.postReroll, CollectibleType.COLLECTIBLE_D100)
local wraithItem = Isaac.GetItemIdByName("Wraith Skull") --Spacebar Wraith Mode Activation
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM, SamaelMod.activateWraith, wraithItem)
--RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, SamaelMod.decapitation, EntityType.ENTITY_ISAAC)
-- (commented out because the extra animation wastes time)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, SamaelMod.roomEntitiesLoop)
--RacingPlus:AddCallback(ModCallbacks.MC_POST_RENDER, SamaelMod.onRender)
-- (commented out because we will always use the active item)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, SamaelMod.samaelPostUpdate)
local scytheID = Isaac.GetEntityTypeByName("Samael Scythe") --Entity ID of the scythe weapon entity
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, SamaelMod.scytheUpdate, scytheID)
local specialAnim = Isaac.GetEntityTypeByName("Samael Special Animations") --Entity for showing special animations
RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE, SamaelMod.specialAnimFunc, specialAnim)
RacingPlus:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, SamaelMod.hitBoxFunc, FamiliarVariant.SACRIFICIAL_DAGGER)
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SamaelMod.scytheHits)
RacingPlus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SamaelMod.playerDamage, EntityType.ENTITY_PLAYER)
RacingPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SamaelMod.PostPlayerInit)
RacingPlus:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SamaelMod.cacheUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, SamaelMod.PostGameStartedReset)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, SamaelMod.PostUpdateFixBugs)

-- Welcome banner
local hyphens = ''
for i = 1, 23 + string.len(RPGlobals.version) do
  hyphens = hyphens .. "-"
end
Isaac.DebugString("+" .. hyphens .. "+")
Isaac.DebugString("| Racing+ " .. RPGlobals.version .. " initialized. |")
Isaac.DebugString("+" .. hyphens .. "+")
