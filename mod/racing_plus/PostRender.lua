local PostRender = {}

-- Includes
local g                 = require("racing_plus/globals")
local SaveDat           = require("racing_plus/savedat")
local Sprites           = require("racing_plus/sprites")
local Schoolbag         = require("racing_plus/schoolbag")
local SoulJar           = require("racing_plus/souljar")
local PostUpdate        = require("racing_plus/postupdate")
local UseItem           = require("racing_plus/useitem")
local Pills             = require("racing_plus/pills")
local FastTravel        = require("racing_plus/fasttravel")
local ChangeKeybindings = require("racing_plus/changekeybindings")
local Timer             = require("racing_plus/timer")
local Speedrun          = require("racing_plus/speedrun")
local ChangeCharOrder   = require("racing_plus/changecharorder")
local SeededDeath       = require("racing_plus/seededdeath")

-- Check various things once per draw frame (60 times a second)
-- (this will fire while the floor/room is loading)
-- ModCallbacks.MC_POST_RENDER (2)
function PostRender:Main()
  -- Read the "save.dat" file and do nothing else on this frame if reading failed
  SaveDat:Load()

  -- Keep track of whether the race is finished or not
  -- (we need to check for "open" because it is possible to quit at the main menu and
  -- then join another race before starting the game)
  if g.race.status == "none" or g.race.status == "open" then
    g.raceVars.started = false
  end

  -- Restart the game if Easter Egg or character validation failed
  PostRender:CheckRestart()

  -- Get rid of the slow fade-in at the beginning of a run
  if not g.run.erasedFadeIn then
    g.run.erasedFadeIn = true
    g.g:Fadein(0.15) -- This fine is fine tuned from trial and error to be a good speed
    return
  end

  -- Draw graphics
  Sprites:Display()
  PostRender:DrawStreakText()
  Schoolbag:SpriteDisplay()
  SoulJar:SpriteDisplay()
  Timer:Display()
  Timer:DisplayRun()
  Timer:DisplaySecond()
  Pills:PostRender()
  ChangeCharOrder:PostRender()
  ChangeKeybindings:PostRender()
  PostRender:DisplayTopLeftText()
  PostRender:DrawInvalidSaveFile()

  -- Check for inputs
  PostRender:CheckConsoleInput()
  PostRender:CheckResetInput()
  PostRender:CheckKnifeDirection()

  -- Ban Basement 1 Treasure Rooms (1/2)
  PostUpdate:CheckBanB1TreasureRoom()

  -- Make Cursed Eye seeded
  PostRender:CheckCursedEye()

  -- Stop the animation after using Telepills or Blank Card
  -- (this has to be in the PostRender callback because game frames do not tick when the use animation is happening)
  if g.run.usedTelepills then
    g.run.usedTelepills = false
    g.p:StopExtraAnimation()
  end

  -- Check for trapdoor related things
  FastTravel:CheckTrapdoor()

  -- Check to see if we are subverting a teleport from Gurdy, Mom, Mom's Heart, or It Lives
  PostRender:CheckSubvertTeleport()

  -- Check for the seeded death mechanic
  -- (this is not in the "PostRender:Race()" function because it also applies to speedruns)
  SeededDeath:PostRender()

  -- Do race specific stuff
  PostRender:Race()

  -- Do speedrun related checks
  Speedrun:CheckRestart()
  Speedrun:DisplayCharProgress()
  Speedrun:DrawVetoButtonText()
  Speedrun:CheckSeason5Mod()
  Speedrun:CheckSeason5ModOther()
end

-- We replace the vanilla streak text because it blocks the map occasionally
function PostRender:DrawStreakText()
  if g.run.streakFrame == 0 then
    return
  end

  -- Players who prefer the vanilla streak text will have a separate mod enabled
  if VanillaStreakText ~= nil then
    return
  end

  -- The streak text will slowly fade out
  local elapsedFrames = Isaac.GetFrameCount() - g.run.streakFrame
  local framesBeforeFade = 50
  local fade
  if elapsedFrames <= framesBeforeFade then
    fade = 1
  else
    local fadeFrames = elapsedFrames - framesBeforeFade
    fade = 1 - (0.02 * fadeFrames)
  end
  if fade <= 0 then
    g.run.streakFrame = 0
    return
  end

  -- Draw the string
  local posGame = g:GridToPos(6, 0) -- Below the top door
  local pos = Isaac.WorldToRenderPosition(posGame)
  local f = Font()
  f:Load("font/droid.fnt")
  --f:Load("font/pftempestasevencondensed.fnt")
  local color = KColor(1, 1, 1, fade)
  local scale = 1
  --local scale = 1.3
  local length = f:GetStringWidthUTF8(g.run.streakText) * scale
  f:DrawStringScaled(g.run.streakText, pos.X - (length / 2), pos.Y, scale, scale, color, 0, true)
end

-- Restart the game if Easter Egg or character validation failed
-- (we can't do this in the "PostGameStarted" callback because
-- the "restart" command will fail when the game is first loading)
function PostRender:CheckRestart()
  -- Local variables
  local character = g.p:GetPlayerType()
  local startSeedString = g.seeds:GetStartSeedString()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  if not g.run.restart then
    return
  end
  g.run.restart = false

  -- First, we need to do the fully unlocked save file check
  if g.saveFile.state == g.saveFileState.GOING_TO_EDEN then
    if challenge ~= Challenge.CHALLENGE_NULL then -- 0
      g:ExecuteCommand("challenge " .. tostring(Challenge.CHALLENGE_NULL)) -- 0
    end
    if character ~= PlayerType.PLAYER_EDEN then -- 9
      g:ExecuteCommand("restart " .. tostring(PlayerType.PLAYER_EDEN)) -- 9
    end
    if startSeedString ~= g.saveFile.seed then
      g:ExecuteCommand("seed " .. g.saveFile.seed)
    end
    return

  elseif g.saveFile.state == g.saveFileState.GOING_BACK then
    if challenge ~= g.saveFile.old.challenge then -- 0
      g:ExecuteCommand("challenge " .. tostring(g.saveFile.old.challenge))
    end
    if character ~= g.saveFile.old.character then
      g:ExecuteCommand("restart " .. tostring(g.saveFile.old.character))
    end
    if customRun ~= g.saveFile.old.seededRun then
      -- This will change the reset behavior to that of an unseeded run
      g.seeds:Reset()
      g:ExecuteCommand("restart")
    end
    if g.saveFile.old.seededRun and
       startSeedString ~= g.saveFile.old.seed then

      g:ExecuteCommand("seed " .. g.saveFile.old.seed)
    end
    return
  end

  -- Change the seed of the run if need be
  local intendedSeed
  if g.race.rFormat == "seeded" and
     g.race.status == "in progress" then

    intendedSeed = g.race.seed

  elseif Speedrun.inSeededSpeedrun then
    intendedSeed = Speedrun.R7SeededSeeds[Speedrun.charNum]
  end
  if intendedSeed ~= nil and
     startSeedString ~= intendedSeed then

    -- Change the seed of the run and restart the game
    g:ExecuteCommand("seed " .. intendedSeed)
    -- (we can perform another restart immediately afterwards to change the character and nothing will go wrong)
  end

  -- The "restart" command takes an optional argument to specify the character; we might want to specify this
  local command = "restart"
  if Speedrun:InSpeedrun() then
    local currentChar = Speedrun:GetCurrentChar()
    if currentChar == nil or
       not Speedrun:CheckValidCharOrder() then

      -- The character order is not set properly; we will display an error to the user later on
      return
    end
    command = command .. " " .. currentChar
  elseif g.race.status ~= "none" then
    command = command .. " " .. g.race.character
  end

  g:ExecuteCommand(command)
end

-- Keep track that we opened the console on this run so that we can disable the fast-resetting feature
-- (so that typing an "r" into the console does not cause a fast-reset)
function PostRender:CheckConsoleInput()
  -- We don't need to perform any additional checks if we have already opened the console on this run
  if g.run.consoleOpened then
    return
  end

  -- Check to see if the player is opening the console
  if Input.IsButtonTriggered(Keyboard.KEY_GRAVE_ACCENT, 0) then -- 28
    g.run.consoleOpened = true
    Isaac.DebugString("The console was opened for the first time on this run.")
  end
end

-- Check for fast-reset inputs
function PostRender:CheckResetInput()
  -- Local variables
  local stage = g.l:GetStage()
  local isaacFrameCount = Isaac.GetFrameCount()

  -- Disable the fast-reset feature on the "Unseeded (Lite)" ruleset
  if g.race.rFormat == "unseeded-lite" then
    return
  end

  -- Disable the fast-reset feature if we have opened the console on this run
  -- (so that typing an "r" into the console does not cause a fast-reset)
  if g.run.consoleOpened then
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
  if not pressed then
    return
  end

  if stage == 1 or
     isaacFrameCount <= g.run.fastResetFrame + 60 then

    Speedrun.fastReset = true
    -- A fast reset means to reset the current character, a slow/normal reset means to go back to the first character
    g:ExecuteCommand("restart")
  else
    -- To fast reset on floors 2 and beyond, we need to double tap R
    g.run.fastResetFrame = isaacFrameCount
  end
end

-- Fix the bug where diagonal knife throws have a 1-frame window when playing on keyboard (1/2)
function PostRender:CheckKnifeDirection()
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) or -- 114
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then -- 168
     -- (Epic Fetus is the only thing that overwrites Mom's Knife)

    return
  end

  local knifeDirection = {}
  for i = 1, 4 do -- This corresponds to the "ButtonAction.ACTION_SHOOTX" enum
    knifeDirection[i] = Input.IsActionPressed(i + 3, 0) -- e.g. ButtonAction.ACTION_SHOOTLEFT is 4
  end
  g.run.knifeDirection[#g.run.knifeDirection + 1] = knifeDirection
  if #g.run.knifeDirection > 2 then -- We want there to be a 3-frame window instead of a 1-frame window
    table.remove(g.run.knifeDirection, 1)
  end

  --[[
  Isaac.DebugString("         L R U D")
  for i, directionTable in ipairs(g.run.knifeDirection) do
    local frame = #g.run.knifeDirection - i
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
function PostRender:CheckCursedEye()
  -- Local variables
  local playerSprite = g.p:GetSprite()
  local hearts = g.p:GetHearts()
  local soulHearts = g.p:GetSoulHearts()

  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE) and -- 316
     playerSprite:IsPlaying("TeleportUp") and
     not g.run.naturalTeleport then -- Only catch Cursed Eye teleports

    -- Account for the Cursed Skull trinket
    if g.p:HasTrinket(TrinketType.TRINKET_CURSED_SKULL) and -- 43
       ((hearts == 1 and soulHearts == 0) or
        (hearts == 0 and soulHearts == 1)) then -- 1/2 of a heart remaining

      Isaac.DebugString("Cursed Skull teleport detected.")
    else
      -- Account for Devil Room teleports from Red Chests
      local touchingRedChest = false
      local openedRedChests = Isaac.FindByType(EntityType.ENTITY_PICKUP, -- 5
                                               PickupVariant.PICKUP_REDCHEST, 0, false, false) -- 360
      -- (a subtype of 0 indicates that it is opened, a 1 indicates that it is unopened)
      for _, chest in ipairs(openedRedChests) do
        if g.p.Position.X >= chest.Position.X - 24 and -- 25 is a touch too big
           g.p.Position.X <= chest.Position.X + 24 and
           g.p.Position.Y >= chest.Position.Y - 24 and
           g.p.Position.Y <= chest.Position.Y + 24 then

          touchingRedChest = true
        end
      end
      if touchingRedChest then
        Isaac.DebugString("Red Chest teleport detected.")
      else
        Isaac.DebugString("Cursed Eye teleport detected.")
        UseItem:Item44()
      end
    end
  end
end

-- Check to see if we are subverting a teleport from Gurdy, Mom, Mom's Heart, or It Lives
function PostRender:CheckSubvertTeleport()
  -- Local variables
  local stage = g.l:GetStage()

  if not g.run.teleportSubverted then
    return
  end
  g.run.teleportSubverted = false

  -- Find the correct position to teleport to, depending on which door we entered from
  local pos
  if stage == 6 then
    -- We can't use "level.EnterDoor" for Mom because it gives a random result every time,
    -- but "level.LeaveDoor" seems to be consistent
    Isaac.DebugString("Entering the Mom fight. LeaveDoor is \"" .. tostring(g.l.LeaveDoor) .. "\".")
    if g.l.LeaveDoor == Direction.LEFT then -- 0 (2x2 left top)
      pos = Vector(560, 280) -- (the default position if you enter the room from the right door)
    elseif g.l.LeaveDoor == Direction.UP then -- 1 (2x2 top left)
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    elseif g.l.LeaveDoor == Direction.RIGHT then -- 2 (2x2 right top)
      pos = Vector(80, 280) -- (the default position if you enter the room from the left door)
    elseif g.l.LeaveDoor == Direction.DOWN then -- 3 (2x2 bottom left)
      pos = Vector(320, 160) -- (the default position if you enter the room from the top door)
    elseif g.l.LeaveDoor == 4 then -- 2x2 left bottom
      pos = Vector(560, 280) -- (the default position if you enter the room from the right door)
    elseif g.l.LeaveDoor == 5 then -- 2x2 top right
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    elseif g.l.LeaveDoor == 6 then -- 2x2 right bottom
      pos = Vector(80, 280) -- (the default position if you enter the room from the left door)
    elseif g.l.LeaveDoor == 7 then -- 2x2 bottom right
      pos = Vector(320, 160) -- (the default position if you enter the room from the top door)
    else
       -- If we teleported into the room, use the default position
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    end
  else
    -- This will work for Gurdy / Mom's Heart / It Lives!
    if g.l.EnterDoor == Direction.LEFT then -- 0
      pos = Vector(80, 280) -- (the default position if you enter the room from the left door)
    elseif g.l.EnterDoor == Direction.UP then -- 1
      pos = Vector(320, 160) -- (the default position if you enter the room from the top door)
    elseif g.l.EnterDoor == Direction.RIGHT then -- 2
      pos = Vector(560, 280) -- (the default position if you enter the room from the right door)
    elseif g.l.EnterDoor == Direction.DOWN then -- 3
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    else
      -- If we teleported into the room, use the default position
      pos = Vector(320, 400) -- (the default position if you enter the room from the bottom door)
    end
  end

  -- Teleport them and make them visible again
  g.p.Position = pos
  g.p.SpriteScale = g.run.teleportSubvertScale

  -- Also, teleport all of the familiars (and make them visible again)
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    familiar.Position = pos
    familiar.Visible = true
  end
end

function PostRender:DisplayTopLeftText()
  -- Local variables
  local seedString = g.seeds:GetStartSeedString()

  -- We want to place informational text for the player to the right of the heart containers
  -- (which will depend on how many heart containers we have)
  local x = 55 + SoulJar:GetHeartXOffset()
  local y = 10
  local lineLength = 15

  if g.raceVars.victoryLaps > 0 then
    -- Display the number of victory laps
    -- (this should have priority over showing the seed)
    Isaac.RenderText("Victory Lap #" .. tostring(g.raceVars.victoryLaps), x, y, 2, 2, 2, 2)

  elseif g.run.endOfRunText then
    -- Show some run summary information
    -- (it will be removed if they exit the room)
    Isaac.RenderText("Seed: " .. seedString, x, y, 2, 2, 2, 2)
    y = y + lineLength
    local text = "Total rooms: " .. g.run.roomsEntered
    if Speedrun:InSpeedrun() then
      -- We can't put average time on a 3rd line because it will be blocked by the Checkpoint item text
      text = text .. ", avg. time per char: " .. Speedrun:GetAverageTimePerCharacter()
    end
    Isaac.RenderText(text, x, y, 2, 2, 2, 2)

    -- Draw a 3rd line to show the total frames
    if not Speedrun:InSpeedrun() or
       Speedrun:IsOnFinalCharacter() then
       local frames
      if Speedrun:InSpeedrun() then
        frames = Speedrun.finishedFrames
      else
        frames = g.raceVars.finishedFrames
      end
      local seconds = g:Round(frames / 60, 3)
       y = y + lineLength
      text = "Total frames: " .. tostring(frames) .. " (" .. tostring(seconds) .. "s)"
      Isaac.RenderText(text, x, y, 2, 2, 2, 2)
    end

  elseif g.race.status == "in progress" and
         g.run.roomsEntered <= 1 and
         Isaac.GetTime() - g.raceVars.startedTime <= 2000 then

    -- Only show it in the first two seconds of the race
    Isaac.RenderText("Race ID: " .. g.race.id, x, y, 2, 2, 2, 2)
  end
end

-- Do race specific stuff
function PostRender:Race()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- If we are not in a race, do nothing
  if g.race.status == "none" then
    -- Remove graphics as soon as the race is over
    Sprites:Init("top", 0)
    Sprites:ClearStartingRoomGraphicsTop()
    Sprites:ClearStartingRoomGraphicsBottom()
    Sprites:ClearPostRaceStartGraphics()
    if not g.raceVars.finished then
      Sprites:Init("place", 0) -- Keep the place there at the end of a race
    end
    return
  end

  --
  -- Race validation stuff
  --

  -- Show warning messages
  if g.race.hard and
     g.g.Difficulty ~= Difficulty.DIFFICULTY_HARD then -- 1

    Sprites:Init("top", "error-hard-mode") -- Error: You are on hard mode.
    return

  elseif not g.race.hard and
         g.g.Difficulty ~= Difficulty.DIFFICULTY_NORMAL and -- 0
         g.race.rFormat ~= "custom" then

    Sprites:Init("top", "error-hard-mode") -- Error: You are on hard mode.
    return

  elseif Sprites.sprites.top ~= nil and
         Sprites.sprites.top.spriteName == "error-hard-mode" then

    Sprites:Init("top", 0)
  end

  --
  -- Grahpics for the "Race Start" room
  --

  -- Show the graphics for the "Race Start" room (the top half)
  if g.race.status == "open" and
     roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3

    Sprites:Init("top", "wait") -- "Wait for the race to begin!"
    Sprites:Init("myStatus", g.race.myStatus)
    Sprites:Init("ready", tostring(g.race.placeMid))
    -- We use "placeMid" to hold this variable, since it isn't used before a race starts
    Sprites:Init("slash", "slash")
    Sprites:Init("readyTotal", tostring(g.race.numEntrants))
  else
    if Sprites.sprites.top ~= nil and Sprites.sprites.top.spriteName == "wait" then
      -- There can be other things on the "top" sprite location and we don't want to have to reload it on every frame
      Sprites:Init("top", 0)
    end
    Sprites:ClearStartingRoomGraphicsTop()
  end

  -- Show the graphics for the "Race Start" room (the bottom half)
  if (g.race.status == "open" or
      g.race.status == "starting") and
     roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3

    if g.race.ranked or
       not g.race.solo then

      Sprites:Init("raceRanked", "ranked")
      Sprites:Init("raceRankedIcon", "ranked-icon")
    else
      Sprites:Init("raceRanked", "unranked")
      Sprites:Init("raceRankedIcon", "unranked-icon")
    end
    Sprites:Init("raceFormat", g.race.rFormat)
    Sprites:Init("raceFormatIcon", g.race.rFormat .. "-icon")
    Sprites:Init("goal", "goal")
    Sprites:Init("raceGoal", g.race.goal)
  else
    Sprites:ClearStartingRoomGraphicsBottom()
  end

  --
  -- Countdown graphics
  --

  -- Show the appropriate countdown graphic/text
  if g.race.status == "starting" then
    if g.race.countdown == 10 then
      Sprites:Init("top", "10")

    elseif g.race.countdown == 5 then
      Sprites:Init("top", "5")

    elseif g.race.countdown == 4 then
      Sprites:Init("top", "4")

    elseif g.race.countdown == 3 then
      Sprites:Init("top", "3")

    elseif g.race.countdown == 2 then
      Sprites:Init("top", "2")

    elseif g.race.countdown == 1 then
      Sprites:Init("top", "1")
    end
  end

  --
  -- Race active
  --

  if g.race.status == "in progress" then
    -- The client will set countdown equal to 0 and the status equal to "in progress" at the same time
    if not g.raceVars.started then
      -- Reset some race-related variables
      g.raceVars.started = true
      -- We don't want to show the place graphic until we get to the 2nd floor
      g.raceVars.startedTime = Isaac.GetTime() -- Mark when the race started
      g.raceVars.startedFrame = Isaac.GetFrameCount() -- Also mark the frame the race started
      Isaac.DebugString("Starting the race! (" .. tostring(g.race.rFormat) .. ")")
    end

    -- Find out how much time has passed since the race started
    local elapsedTime = (Isaac.GetTime() - g.raceVars.startedTime) / 1000
    -- "Isaac.GetTime()" is analogous to Lua's "os.clock()"
    -- This will be in milliseconds, so we divide by 1000 to get seconds

    -- Draw the "Go!" graphic
    if elapsedTime < 3 then
      Sprites:Init("top", "go")
    else
      Sprites:Init("top", 0)
    end

    -- Draw the graphic that shows what place we are in
    if stage >= 2 and -- Our place is irrelevant on the first floor, so don't bother showing it
       not g.race.solo then -- Its irrelevant to show "1st" when there is only one person in the race

      Sprites:Init("place", tostring(g.race.placeMid))
    else
      Sprites:Init("place", 0)
    end
  end

  -- Remove graphics as soon as we enter another room
  -- (this is done separately from the above if block in case the client and mod become desynchronized)
  if g.raceVars.started == true and g.run.roomsEntered > 1 then
    Sprites:ClearPostRaceStartGraphics()
  end

  -- Hold the player in place when in the Race Room (to emulate the Gaping Maws effect)
  -- (this looks glitchy and jittery if is done in the PostUpdate callback, so do it here instead)
  if roomIndex == GridRooms.ROOM_DEBUG_IDX and -- -3
     not g.raceVars.started then

    -- The starting position is 320, 380
    g.p.Position = Vector(320, 380)
  end
end

function PostRender:DrawInvalidSaveFile()
  if g.saveFile.fullyUnlocked then
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

return PostRender
