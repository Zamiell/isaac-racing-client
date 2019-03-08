local RPPostRender = {}

-- Includes
local RPGlobals         = require("src/rpglobals")
local RPSaveDat         = require("src/rpsavedat")
local RPSprites         = require("src/rpsprites")
local RPSchoolbag       = require("src/rpschoolbag")
local RPSoulJar         = require("src/rpsouljar")
local RPPostUpdate      = require("src/rppostupdate")
local RPUseItem         = require("src/rpuseitem")
local RPPills           = require("src/rppills")
local RPFastTravel      = require("src/rpfasttravel")
local RPFastDrop        = require("src/rpfastdrop")
local RPTimer           = require("src/rptimer")
local RPSpeedrun        = require("src/rpspeedrun")
local RPChangeCharOrder = require("src/rpchangecharorder")
local RPSeededDeath     = require("src/rpseededdeath")

-- Check various things once per draw frame (60 times a second)
-- (this will fire while the floor/room is loading)
-- ModCallbacks.MC_POST_RENDER (2)
function RPPostRender:Main()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Read the "save.dat" file and do nothing else on this frame if reading failed
  RPSaveDat:Load()

  -- Keep track of whether the race is finished or not
  -- (we need to check for "open" because it is possible to quit at the main menu and
  -- then join another race before starting the game)
  if RPGlobals.race.status == "none" or RPGlobals.race.status == "open" then
    RPGlobals.raceVars.started = false
  end

  -- Restart the game if Easter Egg or character validation failed
  RPPostRender:CheckRestart()

  -- Get rid of the slow fade-in at the beginning of a run
  if RPGlobals.run.erasedFadeIn == false then
    RPGlobals.run.erasedFadeIn = true
    game:Fadein(0.15) -- This fine is fine tuned from trial and error to be a good speed
    return
  end

  -- Draw graphics
  RPSprites:Display()
  RPSchoolbag:SpriteDisplay()
  RPSoulJar:SpriteDisplay()
  RPTimer:Display()
  RPTimer:DisplayRun()
  RPTimer:DisplaySecond()
  RPPills:PostRender()
  RPChangeCharOrder:DisplayCharSelectRoom()
  RPPostRender:DisplayTopLeftText()
  RPFastDrop:PostRender() -- Custom challenge related text
  RPPostRender:DrawInvalidSaveFile()

  -- Check for inputs
  RPPostRender:CheckConsoleInput()
  RPPostRender:CheckResetInput()
  RPPostRender:CheckKnifeDirection()

  -- Ban Basement 1 Treasure Rooms (1/2)
  RPPostUpdate:CheckBanB1TreasureRoom()

  -- Make Cursed Eye seeded
  RPPostRender:CheckCursedEye()

  -- Stop the animation after using Telepills or Blank Card
  -- (this has to be in the PostRender callback because game frames do not tick when the use animation is happening)
  if RPGlobals.run.usedTelepills then
    RPGlobals.run.usedTelepills = false
    player:StopExtraAnimation()
  end

  -- Check for trapdoor related things
  RPFastTravel:CheckTrapdoor()

  -- Check to see if we are subverting a teleport from Gurdy, Mom, Mom's Heart, or It Lives
  RPPostRender:CheckSubvertTeleport()

  -- Check for the seeded death mechanic
  -- (this is not in the "RPPostRender:Race()" function because it also applies to speedruns)
  RPSeededDeath:PostRender()

  -- Do race specific stuff
  RPPostRender:Race()

  -- Do speedrun related checks
  RPSpeedrun:CheckRestart()
  RPSpeedrun:DisplayCharProgress()
  RPSpeedrun:DrawItemCycleButtonText()
  RPSpeedrun:CheckSeason5Mod()
  RPChangeCharOrder:CheckChangeCharOrder()
end

-- Restart the game if Easter Egg or character validation failed
-- (we can't do this in the "PostGameStarted" callback because
-- the "restart" command will fail when the game is first loading)
function RPPostRender:CheckRestart()
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local startSeedString = seeds:GetStartSeedString()
  local customRun = seeds:IsCustomRun()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local challenge = Isaac.GetChallenge()

  if RPGlobals.run.restart == false then
    return
  end
  RPGlobals.run.restart = false

  -- First, we need to do the fully unlocked save file check
  if RPGlobals.saveFile.state == 1 then
    if challenge ~= Challenge.CHALLENGE_NULL then -- 0
      RPGlobals:ExecuteCommand("challenge " .. tostring(Challenge.CHALLENGE_NULL)) -- 0
    end
    if character ~= PlayerType.PLAYER_EDEN then -- 9
      RPGlobals:ExecuteCommand("restart " .. tostring(PlayerType.PLAYER_EDEN)) -- 9
    end
    if startSeedString ~= RPGlobals.saveFile.seed then
      RPGlobals:ExecuteCommand("seed " .. RPGlobals.saveFile.seed)
    end
    return

  elseif RPGlobals.saveFile.state == 2 then
    if challenge ~= RPGlobals.saveFile.old.challenge then -- 0
      RPGlobals:ExecuteCommand("challenge " .. tostring(RPGlobals.saveFile.old.challenge))
    end
    if character ~= RPGlobals.saveFile.old.character then
      RPGlobals:ExecuteCommand("restart " .. tostring(RPGlobals.saveFile.old.character))
    end
    if customRun ~= RPGlobals.saveFile.old.seededRun then
      -- This will change the reset behavior to that of an unseeded run
      seeds:Reset()
      RPGlobals:ExecuteCommand("restart")
    end
    if RPGlobals.saveFile.old.seededRun and
       startSeedString ~= RPGlobals.saveFile.old.seed then

      RPGlobals:ExecuteCommand("seed " .. RPGlobals.saveFile.old.seed)
    end
    return
  end

  -- Change the seed of the run if need be
  local intendedSeed
  if RPGlobals.race.rFormat == "seeded" and
     RPGlobals.race.status == "in progress" then

    intendedSeed = RPGlobals.race.seed

  elseif RPSpeedrun.inSeededSpeedrun then
    intendedSeed = RPSpeedrun.R7SeededSeeds[RPSpeedrun.charNum]
  end
  if intendedSeed ~= nil and
     startSeedString ~= intendedSeed then

    -- Change the seed of the run and restart the game
    RPGlobals:ExecuteCommand("seed " .. intendedSeed)
    -- (we can perform another restart immediately afterwards to change the character and nothing will go wrong)
  end

  -- The "restart" command takes an optional argument to specify the character; we might want to specify this
  local command = "restart"
  if RPSpeedrun:InSpeedrun() then
    local currentChar = RPSpeedrun:GetCurrentChar()
    if currentChar == nil or RPSpeedrun:CheckValidCharOrder() == false then
      -- The character order is not set properly; we will display an error to the user later on
      return
    end
    command = command .. " " .. currentChar
  elseif RPGlobals.race.status ~= "none" then
    command = command .. " " .. RPGlobals.race.character
  end

  RPGlobals:ExecuteCommand(command)
end

-- Keep track that we opened the console on this run so that we can disable the fast-resetting feature
-- (so that typing an "r" into the console does not cause a fast-reset)
function RPPostRender:CheckConsoleInput()
  -- We don't need to perform any additional checks if we have already opened the console on this run
  if RPGlobals.run.consoleOpened then
    return
  end

  -- Check to see if the player is opening the console
  if Input.IsButtonTriggered(Keyboard.KEY_GRAVE_ACCENT, 0) then -- 28
    RPGlobals.run.consoleOpened = true
    Isaac.DebugString("The console was opened for the first time on this run.")
  end
end

-- Check for fast-reset inputs
function RPPostRender:CheckResetInput()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local isaacFrameCount = Isaac.GetFrameCount()

  -- Disable the fast-reset feature on the "Unseeded (Lite)" ruleset
  if RPGlobals.race.rFormat == "unseeded-lite" then
    return
  end

  -- Disable the fast-reset feature if we have opened the console on this run
  -- (so that typing an "r" into the console does not cause a fast-reset)
  if RPGlobals.run.consoleOpened then
    return
  end

  -- Don't fast-reset if any modifiers are pressed
  -- (with the exception of shift, since the speedrunner MasterofPotato uses shift)
  if Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL, 0) or -- 341
     Input.IsButtonPressed(Keyboard.KEY_LEFT_ALT, 0) or -- 342
     Input.IsButtonPressed(Keyboard.KEY_LEFT_SUPER, 0) or -- 343
     Input.IsButtonPressed(Keyboard.KEY_RIGHT_CONTROL, 0) or -- 345
     Input.IsButtonPressed(Keyboard.KEY_RIGHT_ALT, 0) or -- 346
     Input.IsButtonPressed(Keyboard.KEY_RIGHT_SUPER, 0) then -- 347

    return
  end

  -- Check to see if the player has pressed the restart input
  -- (we check all inputs instead of "player.ControllerIndex" because
  -- a controller player might be using the keyboard to reset)
  local pressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionTriggered(ButtonAction.ACTION_RESTART, i) then -- 16
      pressed = true
      break
    end
  end
  if pressed == false then
    return
  end

  if stage == 1 or
     isaacFrameCount <= RPGlobals.run.fastResetFrame + 60 then

    RPSpeedrun.fastReset = true
    -- A fast reset means to reset the current character, a slow/normal reset means to go back to the first character
    RPGlobals:ExecuteCommand("restart")
  else
    -- To fast reset on floors 2 and beyond, we need to double tap R
    RPGlobals.run.fastResetFrame = isaacFrameCount
  end
end

-- Fix the bug where diagonal knife throws have a 1-frame window when playing on keyboard (1/2)
function RPPostRender:CheckKnifeDirection()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) == false or -- 114
     player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then -- 168
     -- (Epic Fetus is the only thing that overwrites Mom's Knife)

    return
  end

  local knifeDirection = {}
  for i = 1, 4 do -- This corresponds to the "ButtonAction.ACTION_SHOOTX" enum
    knifeDirection[i] = Input.IsActionPressed(i + 3, 0) -- e.g. ButtonAction.ACTION_SHOOTLEFT is 4
  end
  RPGlobals.run.knifeDirection[#RPGlobals.run.knifeDirection + 1] = knifeDirection
  if #RPGlobals.run.knifeDirection > 2 then -- We want there to be a 3-frame window instead of a 1-frame window
    table.remove(RPGlobals.run.knifeDirection, 1)
  end

  --[[
  Isaac.DebugString("         L R U D")
  for i, directionTable in ipairs(RPGlobals.run.knifeDirection) do
    local frame = #RPGlobals.run.knifeDirection - i
    local debugString = "Frame " .. tostring(frame) .. ": "
    for j = 1, 4 do
      if directionTable[j] then
        debugString = debugString .. "X "
      else
        debugString = debugString .. "O "
      end
    end
    Isaac.DebugString(debugString)
  end
  --]]
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
      local touchingRedChest = false
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        if entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_REDCHEST and -- 360
           entity.SubType == 0 and -- A subtype of 0 indicates that it is opened, a 1 indicates that it is unopened
           player.Position.X >= entity.Position.X - 24 and -- 25 is a touch too big
           player.Position.X <= entity.Position.X + 24 and
           player.Position.Y >= entity.Position.Y - 24 and
           player.Position.Y <= entity.Position.Y + 24 then

          touchingRedChest = true
        end
      end
      if touchingRedChest then
        Isaac.DebugString("Red Chest teleport detected.")
      else
        Isaac.DebugString("Cursed Eye teleport detected.")
        RPUseItem:Item44()
      end
    end
  end
end

-- Check to see if we are subverting a teleport from Gurdy, Mom, Mom's Heart, or It Lives
function RPPostRender:CheckSubvertTeleport()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)

  if RPGlobals.run.teleportSubverted == false then
    return
  end
  RPGlobals.run.teleportSubverted = false

  -- Find the correct position to teleport to, depending on which door we entered from
  local pos
  if stage == 6 then
    -- We can't use "level.EnterDoor" for Mom because it gives a random result every time,
    -- but "level.LeaveDoor" seems to be consistent
    Isaac.DebugString("Entering the Mom fight. LeaveDoor is \"" .. tostring(level.LeaveDoor) .. "\".")
    if level.LeaveDoor == Direction.LEFT then -- 0 (2x2 left top)
      pos = Vector(560, 280) -- (the default position if you enter the room from the right door)
    elseif level.LeaveDoor == Direction.UP then -- 1 (2x2 top left)
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    elseif level.LeaveDoor == Direction.RIGHT then -- 2 (2x2 right top)
      pos = Vector(80, 280) -- (the default position if you enter the room from the left door)
    elseif level.LeaveDoor == Direction.DOWN then -- 3 (2x2 bottom left)
      pos = Vector(320, 160) -- (the default position if you enter the room from the top door)
    elseif level.LeaveDoor == 4 then -- 2x2 left bottom
      pos = Vector(560, 280) -- (the default position if you enter the room from the right door)
    elseif level.LeaveDoor == 5 then -- 2x2 top right
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    elseif level.LeaveDoor == 6 then -- 2x2 right bottom
      pos = Vector(80, 280) -- (the default position if you enter the room from the left door)
    elseif level.LeaveDoor == 7 then -- 2x2 bottom right
      pos = Vector(320, 160) -- (the default position if you enter the room from the top door)
    else
       -- If we teleported into the room, use the default position
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    end
  else
    -- This will work for Gurdy / Mom's Heart / It Lives!
    if level.EnterDoor == Direction.LEFT then -- 0
      pos = Vector(80, 280) -- (the default position if you enter the room from the left door)
    elseif level.EnterDoor == Direction.UP then -- 1
      pos = Vector(320, 160) -- (the default position if you enter the room from the top door)
    elseif level.EnterDoor == Direction.RIGHT then -- 2
      pos = Vector(560, 280) -- (the default position if you enter the room from the right door)
    elseif level.EnterDoor == Direction.DOWN then -- 3
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    else
      -- If we teleported into the room, use the default position
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    end
  end

  -- Teleport them and make them visible again
  player.Position = pos
  player.SpriteScale = RPGlobals.run.teleportSubvertScale

  -- Also, teleport all of the familiars (and make them visible again)
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_FAMILIAR then -- 3
      entity.Position = pos
      entity.Visible = true
    end
  end
end

function RPPostRender:DisplayTopLeftText()
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local seedString = seeds:GetStartSeedString()

  -- We want to place informational text for the player to the right of the heart containers
  -- (which will depend on how many heart containers we have)
  local x = 55 + RPSoulJar:GetHeartXOffset()
  local y = 10
  local lineLength = 15

  if RPGlobals.raceVars.victoryLaps > 0 then
    -- Display the number of victory laps
    -- (this should have priority over showing the seed)
    Isaac.RenderText("Victory Lap #" .. tostring(RPGlobals.raceVars.victoryLaps), x, y, 2, 2, 2, 2)

  elseif RPGlobals.run.endOfRunText then
    -- Show some run summary information
    -- (it will be removed if they exit the room)
    Isaac.RenderText("Seed: " .. seedString, x, y, 2, 2, 2, 2)
    y = y + lineLength
    local text = "Total rooms: " .. RPGlobals.run.roomsEntered
    if RPSpeedrun:InSpeedrun() then
      -- We can't put average time on a 3rd line because it will be blocked by the Checkpoint item text
      text = text .. ", avg. time per char: " .. RPSpeedrun:GetAverageTimePerCharacter()
    end
    Isaac.RenderText(text, x, y, 2, 2, 2, 2)

    -- Draw a 3rd line to show the total frames
    if RPSpeedrun:InSpeedrun() == false or
       RPSpeedrun:IsOnFinalCharacter() then
       local frames
      if RPSpeedrun:InSpeedrun() then
        frames = RPSpeedrun.finishedFrames
      else
        frames = RPGlobals.raceVars.finishedFrames
      end
      local seconds = RPGlobals:Round(frames / 60, 3)
       y = y + lineLength
      text = "Total frames: " .. tostring(frames) .. " (" .. tostring(seconds) .. "s)"
      Isaac.RenderText(text, x, y, 2, 2, 2, 2)
    end

  elseif RPGlobals.race.status == "in progress" and
         RPGlobals.run.roomsEntered <= 1 and
         Isaac.GetTime() - RPGlobals.raceVars.startedTime <= 2000 then

    -- Only show it in the first two seconds of the race
    Isaac.RenderText("Race ID: " .. RPGlobals.race.id, x, y, 2, 2, 2, 2)
  end
end

-- Do race specific stuff
function RPPostRender:Race()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local player = game:GetPlayer(0)

  -- If we are not in a race, do nothing
  if RPGlobals.race.status == "none" then
    -- Remove graphics as soon as the race is over
    RPSprites:Init("top", 0)
    RPSprites:ClearStartingRoomGraphicsTop()
    RPSprites:ClearStartingRoomGraphicsBottom()
    RPSprites:ClearPostRaceStartGraphics()
    if RPGlobals.raceVars.finished == false then
      RPSprites:Init("place", 0) -- Keep the place there at the end of a race
    end
    return
  end

  --
  -- Race validation stuff
  --

  -- Show warning messages
  if RPGlobals.race.hard and
     game.Difficulty ~= Difficulty.DIFFICULTY_HARD then -- 1

    RPSprites:Init("top", "error-hard-mode") -- Error: You are on hard mode.
    return

  elseif RPGlobals.race.hard == false and
         game.Difficulty ~= Difficulty.DIFFICULTY_NORMAL and -- 0
         RPGlobals.race.rFormat ~= "custom" then

    RPSprites:Init("top", "error-hard-mode") -- Error: You are on hard mode.
    return

  elseif RPSprites.sprites.top ~= nil and
         RPSprites.sprites.top.spriteName == "error-hard-mode" then

    RPSprites:Init("top", 0)
  end

  --
  -- Grahpics for the "Race Start" room
  --

  -- Show the graphics for the "Race Start" room (the top half)
  if RPGlobals.race.status == "open" and
     roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3

    RPSprites:Init("top", "wait") -- "Wait for the race to begin!"
    RPSprites:Init("myStatus", RPGlobals.race.myStatus)
    RPSprites:Init("ready", tostring(RPGlobals.race.placeMid))
    -- We use "placeMid" to hold this variable, since it isn't used before a race starts
    RPSprites:Init("slash", "slash")
    RPSprites:Init("readyTotal", tostring(RPGlobals.race.numEntrants))
  else
    if RPSprites.sprites.top ~= nil and RPSprites.sprites.top.spriteName == "wait" then
      -- There can be other things on the "top" sprite location and we don't want to have to reload it on every frame
      RPSprites:Init("top", 0)
    end
    RPSprites:ClearStartingRoomGraphicsTop()
  end

  -- Show the graphics for the "Race Start" room (the bottom half)
  if (RPGlobals.race.status == "open" or RPGlobals.race.status == "starting") and
     roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3

    if RPGlobals.race.ranked or RPGlobals.race.solo == false then
      RPSprites:Init("raceRanked", "ranked")
      RPSprites:Init("raceRankedIcon", "ranked-icon")
    else
      RPSprites:Init("raceRanked", "unranked")
      RPSprites:Init("raceRankedIcon", "unranked-icon")
    end
    RPSprites:Init("raceFormat", RPGlobals.race.rFormat)
    RPSprites:Init("raceFormatIcon", RPGlobals.race.rFormat .. "-icon")
    RPSprites:Init("goal", "goal")
    RPSprites:Init("raceGoal", RPGlobals.race.goal)
  else
    RPSprites:ClearStartingRoomGraphicsBottom()
  end

  --
  -- Countdown graphics
  --

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

    elseif RPGlobals.race.countdown == 1 then
      RPSprites:Init("top", "1")
    end
  end

  --
  -- Race active
  --

  if RPGlobals.race.status == "in progress" then
    -- The client will set countdown equal to 0 and the status equal to "in progress" at the same time
    if RPGlobals.raceVars.started == false then
      -- Reset some race-related variables
      RPGlobals.raceVars.started = true
      -- We don't want to show the place graphic until we get to the 2nd floor
      RPGlobals.raceVars.startedTime = Isaac.GetTime() -- Mark when the race started
      RPGlobals.raceVars.startedFrame = Isaac.GetFrameCount() -- Also mark the frame the race started
      Isaac.DebugString("Starting the race! (" .. tostring(RPGlobals.race.rFormat) .. ")")
    end

    -- Find out how much time has passed since the race started
    local elapsedTime = (Isaac.GetTime() - RPGlobals.raceVars.startedTime) / 1000
    -- "Isaac.GetTime()" is analogous to Lua's "os.clock()"
    -- This will be in milliseconds, so we divide by 1000 to get seconds

    -- Draw the "Go!" graphic
    if elapsedTime < 3 then
      RPSprites:Init("top", "go")
    else
      RPSprites:Init("top", 0)
    end

    -- Draw the graphic that shows what place we are in
    if stage >= 2 and -- Our place is irrelevant on the first floor, so don't bother showing it
       RPGlobals.race.solo == false then -- Its irrelevant to show "1st" when there is only one person in the race

      RPSprites:Init("place", tostring(RPGlobals.race.placeMid))
    else
      RPSprites:Init("place", 0)
    end
  end

  -- Remove graphics as soon as we enter another room
  -- (this is done separately from the above if block in case the client and mod become desynchronized)
  if RPGlobals.raceVars.started == true and RPGlobals.run.roomsEntered > 1 then
    RPSprites:ClearPostRaceStartGraphics()
  end

  -- Hold the player in place when in the Race Room (to emulate the Gaping Maws effect)
  -- (this looks glitchy and jittery if is done in the PostUpdate callback, so do it here instead)
  if roomIndex == GridRooms.ROOM_DEBUG_IDX and -- -3
     RPGlobals.raceVars.started == false then
    -- The starting position is 320, 380
    player.Position = Vector(320, 380)
  end
end

function RPPostRender:DrawInvalidSaveFile()
  if RPGlobals.saveFile.fullyUnlocked then
    return
  end

  local x = 115
  local y = 70
  Isaac.RenderText("Error: You must use a fully unlocked save file to", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("play the Racing+ mod. This is so that all", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("players will have consistent items in races", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("and speedruns. You can download a fully", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("unlocked save file at:", x, y, 2, 2, 2, 2)
  x = x - 42
  y = y + 20
  Isaac.RenderText("https://www.speedrun.com/afterbirthplus/resources", x, y, 2, 2, 2, 2)
end

return RPPostRender
