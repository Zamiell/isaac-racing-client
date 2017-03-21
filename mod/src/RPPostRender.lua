local RPPostRender = {}

--
-- Includes
--

local RPGlobals    = require("src/rpglobals")
local RPInit       = require("src/rpinit")
local RPSprites    = require("src/rpsprites")
local RPSchoolbag  = require("src/rpschoolbag")
local RPSoulJar    = require("src/rpsouljar")
local RPPostUpdate = require("src/rppostupdate")
local RPItems      = require("src/rpitems")

--
-- PostRender functions
--

-- Check various things once per draw frame (60 times a second)
-- (this will fire while the floor/room is loading)
-- ModCallbacks.MC_POST_RENDER (2)
function RPPostRender:Main()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)

  -- Read the "save.dat" file and do nothing else on this frame if reading failed
  RPPostRender:ReadSaveDat()
  if RPGlobals.race == nil then
    return
  end

  -- Make sure that some race related variables are reset
  -- (we need to check for "open" because it is possible to quit at the main menu and
  -- then join another race before starting the game)
  if RPGlobals.race.status == "none" or RPGlobals.race.status == "open" then
    RPGlobals.raceVars.started = false
  end
  if (RPGlobals.race.status == "none" or RPGlobals.race.status == "open") and
     RPGlobals.raceVars.finished == false then -- Don't reset the timer if we have completed the run

    RPGlobals.raceVars.startedTime = 0 -- Remove the timer after we finish or quit a race (1/2)
    RPSprites:Init("clock", 0) -- Remove the timer after we finish or quit a race (2/2)
  end

  -- Draw graphics
  RPSprites:Display()
  RPSchoolbag:SpriteDisplay()
  RPSoulJar:SpriteDisplay()

  -- Update the timer that shows on the bottom-left hand corner of the screen when the player is in a race
  RPSprites:TimerUpdate()

  -- Check to see if we are starting a run
  -- (this does not work if we put it in a PostUpdate callback because that only starts on the first frame of movement)
  -- (this does not work if we put it in a PlayerInit callback because Eve/Keeper are given their active items after the
  -- callback has fired)
  -- (gameFrameCount will be at 0 until the first frame of player movement)
  if gameFrameCount == 0 and RPGlobals.run.initializing == 0 then
    RPGlobals.run.initializing = 1 -- Mark that we are at stage 1 of initialization
    -- We have to stall doing run initialization until we can read the "save.dat" file
    RPGlobals.raceVars.loadOnNextFrame = true
    return -- Don't do anything else on this frame
  elseif RPGlobals.run.initializing == 1 then
    RPGlobals.run.initializing = 2 -- Mark that we are at stage 2 of initialization
    RPInit:Run()
    return -- Don't do anything else on this frame
  elseif gameFrameCount > 0 and RPGlobals.run.initializing == 2 then
    RPGlobals.run.initializing = 0
  end

  -- Keep track of when we change floors
  RPPostRender:CheckChangeFloor()

  -- Keep track of when we change rooms
  RPPostRender:CheckChangeRoom()

  -- Ban Basement 1 Treasure Rooms
  RPPostUpdate:CheckBanB1TreasureRoom()

  -- Make Cursed Eye seeded
  RPPostRender:CheckCursedEye()

  -- Stop the animation after using Telepills or Blank Card
  -- (this has to be in the PostRender callback because game frames do not tick when the use animation is happening)
  if RPGlobals.run.usedTelepills then
    RPGlobals.run.usedTelepills = false
    player:StopExtraAnimation()
  end

  -- Do race specific stuff
  RPPostRender:Race()
end

-- Read the "save.dat" file for updates from the Racing+ client
function RPPostRender:ReadSaveDat()
  -- Local variables
  local isaacFrameCount = Isaac:GetFrameCount()

  if RPGlobals.race == nil or -- The "race" table will only be nil if reading the "save.dat" file failed
     RPGlobals.raceVars.loadOnNextFrame or -- We need to check on the first frame of the run
     (RPGlobals.race.status == "starting" and isaacFrameCount % 2 == 0) or
     -- We want to check for updates on every other frame if the race is starting so that the countdown is smooth
     isaacFrameCount % 30 == 0 then
     -- Otherwise, only check for updates every half second, since file reads are expensive

    -- Mark that we don't need to check this on every single frame
    RPGlobals.raceVars.loadOnNextFrame = false

    -- The server will write data for us to the "save.dat" file in the mod subdirectory
    -- From: https://www.reddit.com/r/themoddingofisaac/comments/5q3ml0/tutorial_saving_different_moddata_for_each_run/
    if RPGlobals.race ~= nil then
      RPGlobals.oldRace = RPGlobals.race
    end
    RPGlobals.race = load("return " .. Isaac.LoadModData(RPGlobals.RacingPlus))() -- This loads the "save.dat" file

    -- Sometimes loading can fail, I'm not sure why; give up for now and try again on the next frame
    if RPGlobals.race == nil then
      Isaac.DebugString("Loading the \"save.dat\" file failed. Trying again on the next frame...")
      return
    end

    -- If anything changed, write it to the log
    if RPGlobals.oldRace.status ~= RPGlobals.race.status then
      Isaac.DebugString("ModData status changed: " .. RPGlobals.race.status)
    end
    if RPGlobals.oldRace.rType ~= RPGlobals.race.rType then
      Isaac.DebugString("ModData rType changed: " .. RPGlobals.race.rType)
    end
    if RPGlobals.oldRace.rFormat ~= RPGlobals.race.rFormat then
      Isaac.DebugString("ModData rFormat changed: " .. RPGlobals.race.rFormat)
    end
    if RPGlobals.oldRace.character ~= RPGlobals.race.character then
      Isaac.DebugString("ModData character changed: " .. RPGlobals.race.character)
    end
    if RPGlobals.oldRace.goal ~= RPGlobals.race.goal then
      Isaac.DebugString("ModData goal changed: " .. RPGlobals.race.goal)
    end
    if RPGlobals.oldRace.seed ~= RPGlobals.race.seed then
      Isaac.DebugString("ModData seed changed: " .. RPGlobals.race.seed)
    end
    if #RPGlobals.oldRace.startingItems ~= #RPGlobals.race.startingItems then
      Isaac.DebugString("ModData startingItems amount changed: " .. tostring(#RPGlobals.race.startingItems))
    end
    if RPGlobals.oldRace.currentSeed ~= RPGlobals.race.currentSeed then
      Isaac.DebugString("ModData currentSeed changed: " .. RPGlobals.race.currentSeed)
    end
    if RPGlobals.oldRace.countdown ~= RPGlobals.race.countdown then
      Isaac.DebugString("ModData countdown changed: " .. tostring(RPGlobals.race.countdown))
    end
  end
end

-- Keep track of when we change floors
-- (this has to be in the PostRender callback because we don't want to wait for the floor transition animation to
-- complete before teleporting away from the Dark Room)
function RPPostRender:CheckChangeFloor()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == RPGlobals.run.currentFloor then
    return
  end

  -- Find out if we performed a Sacrifice Room teleport
  if stage == 11 and stageType == 0 and RPGlobals.run.currentFloor ~= 10 then -- 11.0 is Dark Room
    -- We arrivated at the Dark Room without going through Sheol
    level:SetStage(RPGlobals.run.currentFloor + 1, 0) -- Return to one after the the floor we were on before
    -- (the first argument is "LevelStage", which is 0 indexed for some reason, the second argument is StageType)
    -- (we don't have to call "level:StartStageTransition()" because we are already in one)
    Isaac.DebugString("Sacrifice Room teleport detected.")
    -- (this code block will be entered from doing "stage 11" on the debug console,
    -- but it won't move you away from the Dark Room because there is not a stage transition occuring)
    -- (in this situation, if they use a Forget Me Now, they will return to the intended floor)
    return
  end

  -- Set the new floor
  RPGlobals.run.currentFloor = stage

  -- Reset some per level flags
  RPGlobals.run.levelDamaged = false
  RPGlobals.run.replacedPedestals = {}

  -- Reset the RNG of some items that should be seeded per floor
  local floorSeed = level:GetDungeonPlacementSeed()
  RPGlobals.RNGCounter.Teleport = floorSeed
  RPGlobals.RNGCounter.Undefined = floorSeed
  RPGlobals.RNGCounter.Telepills = floorSeed
  for i = 1, 100 do -- Increment the RNG 100 times so that players cannot use knowledge of Teleport! teleports
                    -- to determine where the Telepills destination will be
    RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
  end
end

-- Keep track of when we change rooms
-- (this has to be in the PostRender callback because we want the "Go!" graphic to be removed at the
-- beginning of the room transition animation)
function RPPostRender:CheckChangeRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomFrameCount = room:GetFrameCount()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local roomClear = room:IsClear()
  local player = game:GetPlayer(0)
  local activeCharge = player:GetActiveCharge()
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local sfx = SFXManager()

  if roomFrameCount == 0 and RPGlobals.run.roomEntering == false then
     RPGlobals.run.roomEntering = true
     RPGlobals.run.roomsEntered = RPGlobals.run.roomsEntered + 1
     RPGlobals.run.currentRoomClearState = roomClear -- This is needed so that we don't get credit for clearing a room
                                       -- when bombing from a room with enemies into an empty room

    -- Reset the lists we use to keep track of certain enemies
    RPGlobals.run.currentGlobins = {} -- Used for softlock prevention
    RPGlobals.run.currentKnights = {} -- Used to delete invulnerability frames
    RPGlobals.run.currentLilHaunts = {} -- Used to delete invulnerability frames

    -- Clear some room-based flags
    RPGlobals.run.naturalTeleport = false
    RPGlobals.run.crawlspace.entering = false
    RPGlobals.run.bossHearts = { -- Copied from RPGlobals
      spawn       = false,
      extra       = false,
      extraIsSoul = false,
      position    = {},
      velocity    = {},
    }
    RPGlobals.run.schoolbag.bossRushActive = false

    -- Manually handle coming back from a crawlspace
    if RPGlobals.run.crawlspace.exiting then
      RPGlobals.run.crawlspace.exiting = false
      player.Position = RPGlobals.run.crawlspace.position
      player.SpriteScale = RPGlobals.run.crawlspace.scale
    end

    -- Check to see if we need to remove the heart container from a Strength card on Keeper
    if RPGlobals.run.keeper.usedStrength and RPGlobals.run.keeper.baseHearts == 4 then
      RPGlobals.run.keeper.baseHearts = 2
      RPGlobals.run.keeper.usedStrength = false
      player:AddMaxHearts(-2, true) -- Take away a heart container
      Isaac.DebugString("Took away 1 heart container from Keeper (via a Strength card).")
    end

    -- Check to see if we need to remove More Options in a diversity race
    if roomType == RoomType.ROOM_TREASURE and -- 4
       player:HasCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) and -- 414
       RPGlobals.race.rFormat == "diversity" and
       RPGlobals.raceVars.removedMoreOptions == false then

      RPGlobals.raceVars.removedMoreOptions = true
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
    end

    -- Check health (to fix the bug where we don't die at 0 hearts)
    -- (this happens if Keeper uses Guppy's Paw or when Magdalene takes a devil deal that grants soul/black hearts)
    if maxHearts == 0 and soulHearts == 0 then
      player:Kill()
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then
      -- Recharge our active item if we used the Glowing Hour Glass with a Schoolbag
      if RPGlobals.run.schoolbag.nextRoomCharge then
        RPGlobals.run.schoolbag.nextRoomCharge = false
        player:SetActiveCharge(RPGlobals.run.schoolbag.lastRoomSlot1Charges)
      end

      -- Keep track of our last Schoolbag item
      RPGlobals.run.schoolbag.lastRoomItem = RPGlobals.run.schoolbag.item
      RPGlobals.run.schoolbag.lastRoomSlot1Charges = activeCharge
      RPGlobals.run.schoolbag.lastRoomSlot2Charges = RPGlobals.run.schoolbag.charges
    end

    -- Extend the Maw of the Void / Athame ring into the next room
    if RPGlobals.run.blackRingTime > 1 then
      player:SpawnMawOfVoid(RPGlobals.run.blackRingTime) -- The argument is "Timeout"

      -- The "player:SpawnMawOfVoid()" will spawn a Maw of the Void ring, but we might be extending an Athame ring,
      -- so we have to reset the Black HP drop chance
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        if entities[i].Type == EntityType.ENTITY_LASER and -- 7
           entities[i].Variant == 1 and -- A Brimstone laser
           entities[i].SubType == 3 then -- A Maw of the Void or Athame ring

          entities[i]:ToLaser():SetBlackHpDropChance(RPGlobals.run.blackRingDropChance)
        end
      end

      -- "player:SpawnMawOfVoid()" will cause a new Maw sound effect to play, so mute it
      sfx:Stop(SoundEffect.SOUND_MAW_OF_VOID)
    end

    -- Spawn a Get out of Jail Free Card if we have arrived on The Chest / Dark Room
    -- (this can't be in the "CheckChangeFloor()" function because the items won't show up)
    if (RPGlobals.race.goal == "Mega Satan" or
        RPGlobals.raceVars.finished) and
       stage == 11 and -- If this is The Chest or Dark Room
       level:GetCurrentRoomIndex() == level:GetStartingRoomIndex() and
       RPGlobals.raceVars.placedJailCard == false then

      RPGlobals.raceVars.placedJailCard = true

      -- Get out of Jail Free Card (5.300.47)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, RPGlobals:GridToPos(6, 0), Vector(0, 0),
                 nil, Card.CARD_GET_OUT_OF_JAIL, roomSeed)
      Isaac.DebugString("Placed the Get out of Jail Free Card.")
    end

  elseif roomFrameCount > 0 then
    RPGlobals.run.roomEntering = false
  end
end

-- Make Cursed Eye seeded
-- (this has to be in the PostRender callback because game frames do not tick when
-- the teleport animation is happening)
function RPPostRender:CheckCursedEye()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()
  local hearts = player:GetHearts()
  local soulHearts = player:GetSoulHearts()

  if player:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE) and -- 316
     playerSprite:IsPlaying("TeleportUp") and
     RPGlobals.run.naturalTeleport == false then -- Only catch Cursed Eye teleports

    -- Account for the Cursed Skull trinket
    if player:HasTrinket(TrinketType.TRINKET_CURSED_SKULL) and -- 43
       ((hearts == 1 and soulHearts == 0) or
        (hearts == 0 and soulHearts == 1)) then -- 1/2 of a heart remaining

      Isaac.DebugString("Cursed Skull teleport detected.")
    else
      -- Account for Devil Room teleports from Red Chests
      local entities = Isaac.GetRoomEntities()
      local touchingRedChest = false
      for i = 1, #entities do
        if entities[i].Type == EntityType.ENTITY_PICKUP and -- 5
           entities[i].Variant == PickupVariant.PICKUP_REDCHEST and -- 360
           entities[i].SubType == 0 and -- A subtype of 0 indicates that it is opened, a 1 indicates that it is unopened
           player.Position.X >= entities[i].Position.X - 24 and -- 25 is a touch too big
           player.Position.X <= entities[i].Position.X + 24 and
           player.Position.Y >= entities[i].Position.Y - 24 and
           player.Position.Y <= entities[i].Position.Y + 24 then

          touchingRedChest = true
        end
      end
      if touchingRedChest then
        Isaac.DebugString("Red Chest teleport detected.")
      else
        Isaac.DebugString("Cursed Eye teleport detected.")
        RPItems:Teleport()
      end
    end
  end
end

-- Do race specific stuff
function RPPostRender:Race()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- If we are not in a race, do nothing
  if RPGlobals.race.status == "none" then
    RPGlobals.raceVars.freshRun = false
    return
  end

  -- Show warning messages
  if RPGlobals.raceVars.blckCndlOn == false and
         RPGlobals.raceVars.startedTime == 0 then

    -- Check to see if we are on the BLCK CNDL Easter Egg
    RPSprites:Init("top", "error-BLCK-CNDL") -- Error: Turn on the "BLCK CNDL" Easter Egg.
    return

  elseif RPGlobals.raceVars.difficulty ~= 0 and
         RPGlobals.raceVars.startedTime == 0 then

    -- Check to see if we are on hard mode
    RPSprites:Init("top", "error-hard-mode") -- Error: You are on hard mode.
    return

  elseif RPGlobals.race.character ~= RPGlobals.raceVars.character and
         RPGlobals.raceVars.startedTime == 0 then

    -- Check to see if we are on the right character
    RPSprites:Init("top", "error-character") -- Error: You are on the wrong character.
    return

  elseif RPGlobals.race.seed ~= "-" and
         RPGlobals.race.seed ~= RPGlobals.race.currentSeed and
         RPGlobals.raceVars.startedTime == 0 then

    -- Check to see if we are on the right seed
    RPSprites:Init("top", "error-seed")
    return

  elseif RPGlobals.raceVars.freshRun == false then
    -- Check to see if we have reset the game since we have entered the lobby
    RPSprites:Init("top", "error-new-run")
    return

  elseif RPGlobals.spriteTable.top ~= nil and
         (RPGlobals.spriteTable.top.spriteName == "error-BLCK-CNDL" or
          RPGlobals.spriteTable.top.spriteName == "error-hard-mode" or
          RPGlobals.spriteTable.top.spriteName == "error-character" or
          RPGlobals.spriteTable.top.spriteName == "error-seed" or
          RPGlobals.spriteTable.top.spriteName == "error-new-run") then

    RPSprites:Init("top", 0)
  end

  -- Show the "Wait for the race to begin!" graphic/text
  if RPGlobals.race.status == "open" then
    RPSprites:Init("top", "wait")
    RPSprites:Init("myStatus", RPGlobals.race.myStatus)
    RPSprites:Init("raceType", RPGlobals.race.rType)
    RPSprites:Init("raceFormat", RPGlobals.race.rFormat)
  else
    if RPGlobals.spriteTable.top ~= nil and RPGlobals.spriteTable.top.spriteName == "wait" then
      -- There can be other things on the "top" sprite location and we don't want to have to reload it on every frame
      RPSprites:Init("top", 0)
    end
    RPSprites:Init("myStatus", 0)
    RPSprites:Init("raceType", 0)
    RPSprites:Init("raceFormat", 0)
  end

  -- Show the appropriate countdown graphic/text
  if RPGlobals.race.status == "starting" then
    if RPGlobals.race.countdown == 10 then
      RPSprites:Init("top", "10")

    elseif RPGlobals.race.countdown == 5 then
      RPSprites:Init("top", "5")

    elseif RPGlobals.race.countdown == 4 then
      RPSprites:Init("top", "4")

    elseif RPGlobals.race.countdown == 3 then
      RPSprites:Init("top", "3")

    elseif RPGlobals.race.countdown == 2 then
      RPSprites:Init("top", "2")

      -- Disable resetting to prevent a bug where the "game:ChangeRoom()" function
      -- fires at the same time as a reset, causing lag
      RPGlobals.raceVars.resetEnabled = false

    elseif RPGlobals.race.countdown == 1 then
      RPSprites:Init("top", "1")
    end
  end

  -- The client will set countdown equal to 0 and the status equal to "in progress" at the same time,
  -- so this next part can't be in the above if block
  -- (the client will manually withold the true "in progress" update in order to keep things synchronized)
  if RPGlobals.race.status == "in progress" and RPGlobals.raceVars.started == false then -- The countdown has reached 0
    -- Draw the "Go!" graphic
    RPSprites:Init("top", "go")

    -- Mark when the race started
    -- (we want to do this here because we don't want to show the timer if
    -- they close the game and come back in the middle of ta race)
    RPGlobals.raceVars.startedTime = Isaac.GetTime()

    -- Start the race
    RPInit:RaceStart()
  end

  if RPGlobals.race.status == "in progress" then
    RPSprites:Init("place", tostring(RPGlobals.race.place))
  else
    -- Remove graphics as soon as the race is over
    RPSprites:ClearStartingRoomGraphics()
  end

  -- Remove graphics as soon as we enter another room (the starting room counts as room #1)
  if RPGlobals.run.roomsEntered > 1 then
    -- Remove the "Go!" graphic
    RPSprites:Init("top", 0)

    -- Remove all graphics drawn on the starting room
    RPSprites:ClearStartingRoomGraphics()
  end

  -- Hold the player in place if the race has not started yet (emulate the Gaping Maws effect)
  -- (this looks very glitchy and jittery if is done in the PostUpdate callback, so do it here instead)
  if RPGlobals.raceVars.started == false and RPGlobals.run.roomsEntered == 1 then
    -- The starting position is 320, 380
    player.Position = Vector(320, 380)
  end
end

return RPPostRender
