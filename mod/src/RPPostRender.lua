local RPPostRender = {}

--
-- Includes
--

local RPGlobals         = require("src/rpglobals")
local RPSprites         = require("src/rpsprites")
local RPSchoolbag       = require("src/rpschoolbag")
local RPSoulJar         = require("src/rpsouljar")
local RPPostUpdate      = require("src/rppostupdate")
local RPItems           = require("src/rpitems")
local RPFastTravel      = require("src/rpfasttravel")

--
-- PostRender functions
--

-- Check various things once per draw frame (60 times a second)
-- (this will fire while the floor/room is loading)
-- ModCallbacks.MC_POST_RENDER (2)
function RPPostRender:Main()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Read the "save.dat" file and do nothing else on this frame if reading failed
  RPPostRender:LoadSaveDat()

  -- Keep track of whether the race is finished or not
  -- (we need to check for "open" because it is possible to quit at the main menu and
  -- then join another race before starting the game)
  if RPGlobals.race.status == "none" or RPGlobals.race.status == "open" then
    RPGlobals.raceVars.started = false
  end

  -- Restart the game if Easter Egg (or race) validation failed
  -- (we can't do this in the "PostGameStarted" callback because
  -- the "restart" command will fail when the game is first loading)
  if RPGlobals.run.restartFrame ~= 0 and RPGlobals.run.restartFrame <= Isaac.GetFrameCount() then
    RPGlobals.run.restartFrame = 0
    Isaac.ExecuteCommand("restart")
    Isaac.DebugString("Issued a \"restart\" command.")
    return
  end

  -- Draw graphics
  RPSprites:Display()
  RPSchoolbag:SpriteDisplay()
  RPSoulJar:SpriteDisplay()

  -- Update the timer that shows on the bottom-left hand corner of the screen when the player is in a race
  RPSprites:TimerUpdate()

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

  -- Check for trapdoor related things
  RPFastTravel:CheckTrapdoor()

  -- Check for reset inputs
  RPPostRender:CheckResetInput()

  -- Do race specific stuff
  RPPostRender:Race()
end

-- Read the "save.dat" file for updates from the Racing+ client
function RPPostRender:LoadSaveDat()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local isaacFrameCount = Isaac.GetFrameCount()

  if RPGlobals.raceVars.loadOnNextFrame or -- We need to check on the first frame of the run
     (RPGlobals.race.status == "starting" and isaacFrameCount & 1 == 0) or
     -- (this is the same as "isaacFrameCount % 2 == 0", but runs 20% faster)
     -- We want to check for updates on every other frame if the race is starting so that the countdown is smooth
     isaacFrameCount % 30 == 0 then
     -- Otherwise, only check for updates every half second, since file reads are expensive

    -- Mark that we have loaded on this frame
    RPGlobals.raceVars.loadOnNextFrame = false

    -- Make a backup in case loading fails
    local oldRace = RPGlobals.race

    -- The server will write data for us to the "save.dat" file in the mod subdirectory
    -- From: https://www.reddit.com/r/themoddingofisaac/comments/5q3ml0/tutorial_saving_different_moddata_for_each_run/
    RPGlobals.race = load("return " .. Isaac.LoadModData(RPGlobals.RacingPlus))() -- This loads the "save.dat" file

    -- Sometimes loading can fail, I'm not sure why; give up for now and try again on the next frame
    if RPGlobals.race == nil then
      RPGlobals.raceVars.loadOnNextFrame = true
      RPGlobals.race = oldRace -- Restore the backup
      Isaac.DebugString("Loading the \"save.dat\" file failed. Trying again on the next frame...")
      return
    end

    -- If anything changed, write it to the log
    if oldRace.status ~= RPGlobals.race.status then
      Isaac.DebugString("ModData status changed: " .. RPGlobals.race.status)

      if RPGlobals.race.status == "open" then
        if stage == 1 and roomIndex == level:GetStartingRoomIndex() then
          -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
          RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
        else
          -- We are in the middle of a run, so don't go to the Race Room until a reset occurs
          RPGlobals.raceVars.started = false
          RPGlobals.raceVars.startedTime = 0
          RPSprites:Init("place", "pre")
          RPGlobals.showPlaceGraphic = true
        end
      elseif RPGlobals.race.status == "in progress" or
             (RPGlobals.race.status == "none" and
              roomIndex == GridRooms.ROOM_DEBUG_IDX) then -- -3

        -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
        RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
      end
    end
    if oldRace.myStatus ~= RPGlobals.race.myStatus then
      Isaac.DebugString("ModData myStatus changed: " .. RPGlobals.race.myStatus)
    end
    if oldRace.rType ~= RPGlobals.race.rType then
      Isaac.DebugString("ModData rType changed: " .. RPGlobals.race.rType)
    end
    if oldRace.rFormat ~= RPGlobals.race.rFormat then
      Isaac.DebugString("ModData rFormat changed: " .. RPGlobals.race.rFormat)
      if RPGlobals.race.rFormat == "pageant" then
        -- For Pageant Boy, fix the bug where it is not loaded on the first run
        -- Doing a "restart" won't work since we are just starting a run, so mark to reset on the next frame
        RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
      end
    end
    if oldRace.character ~= RPGlobals.race.character then
      Isaac.DebugString("ModData character changed: " .. RPGlobals.race.character)
    end
    if oldRace.goal ~= RPGlobals.race.goal then
      Isaac.DebugString("ModData goal changed: " .. RPGlobals.race.goal)
    end
    if oldRace.seed ~= RPGlobals.race.seed then
      Isaac.DebugString("ModData seed changed: " .. RPGlobals.race.seed)
    end
    if #oldRace.startingItems ~= #RPGlobals.race.startingItems then
      Isaac.DebugString("ModData startingItems amount changed: " .. tostring(#RPGlobals.race.startingItems))
    end
    if oldRace.countdown ~= RPGlobals.race.countdown then
      Isaac.DebugString("ModData countdown changed: " .. tostring(RPGlobals.race.countdown))
    end
    if oldRace.placeMid ~= RPGlobals.race.placeMid then
      Isaac.DebugString("ModData placeMid changed: " .. tostring(RPGlobals.race.placeMid))
    end
    if oldRace.place ~= RPGlobals.race.place then
      Isaac.DebugString("ModData place changed: " .. tostring(RPGlobals.race.place))
    end
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
        RPItems:Teleport()
      end
    end
  end
end

-- Check for reset inputs
function RPPostRender:CheckResetInput()
  -- If we have opened the console at least once this run, disable fast-resetting
  if RPGlobals.run.consoleWindowOpen then
    return
  end

  -- Check to see if we are opening the console window
  if Input.IsButtonTriggered(Keyboard.KEY_GRAVE_ACCENT, 0) then -- 96
    RPGlobals.run.consoleWindowOpen = true
    return
  end

  -- Don't fast-reset if any modifiers are pressed
  -- (with the exception of shift, since MasterofPotato uses shift)
  if Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL, 0) or -- 341
     Input.IsButtonPressed(Keyboard.KEY_LEFT_ALT, 0) or -- 342
     Input.IsButtonPressed(Keyboard.KEY_LEFT_SUPER, 0) or -- 343
     Input.IsButtonPressed(Keyboard.KEY_RIGHT_CONTROL, 0) or -- 345
     Input.IsButtonPressed(Keyboard.KEY_RIGHT_ALT, 0) or -- 346
     Input.IsButtonPressed(Keyboard.KEY_RIGHT_SUPER, 0) then -- 347

    return
  end

  -- Check for the "R" input
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    -- (we check all inputs instead of "player.ControllerIndex" because
    -- a controller player might be using the keyboard to reset)
    if Input.IsActionTriggered(ButtonAction.ACTION_RESTART, i) then -- 16
      Isaac.ExecuteCommand("restart")
      return
    end
  end
end

-- Do race specific stuff
function RPPostRender:Race()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
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
  if RPGlobals.raceVars.difficulty ~= 0 and
     RPGlobals.raceVars.startedTime == 0 then

    -- Check to see if we are on hard mode
    RPSprites:Init("top", "error-hard-mode") -- Error: You are on hard mode.
    return

  elseif RPGlobals.raceVars.challenge ~= 0 and
         RPGlobals.raceVars.startedTime == 0 then

    -- Check to see if we are on a challenge
    RPSprites:Init("top", "error-challenge") -- Error: You are on a challenge.
    return

  elseif RPGlobals.race.character ~= RPGlobals.raceVars.character and
         RPGlobals.raceVars.startedTime == 0 then

    -- Check to see if we are on the right character
    RPSprites:Init("top", "error-character") -- Error: You are on the wrong character.
    return

  elseif RPGlobals.spriteTable.top ~= nil and
         (RPGlobals.spriteTable.top.spriteName == "error-hard-mode" or
          RPGlobals.spriteTable.top.spriteName == "error-challenge" or
          RPGlobals.spriteTable.top.spriteName == "error-character") then

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
    RPSprites:Init("readyTotal", tostring(RPGlobals.race.place))
    -- We use "place" to hold this variable, since it isn't used before a race starts
  else
    if RPGlobals.spriteTable.top ~= nil and RPGlobals.spriteTable.top.spriteName == "wait" then
      -- There can be other things on the "top" sprite location and we don't want to have to reload it on every frame
      RPSprites:Init("top", 0)
    end
    RPSprites:ClearStartingRoomGraphicsTop()
  end

  -- Show the graphics for the "Race Start" room (the bottom half)
  if (RPGlobals.race.status == "open" or RPGlobals.race.status == "starting") and
     roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3

    RPSprites:Init("raceType", RPGlobals.race.rType)
    RPSprites:Init("raceTypeIcon", RPGlobals.race.rType .. "Icon")
    RPSprites:Init("raceFormat", RPGlobals.race.rFormat)
    RPSprites:Init("raceFormatIcon", RPGlobals.race.rFormat .. "Icon")
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

      -- Disable resetting to prevent the user from resetting at the same time that we do later on
      RPGlobals.raceVars.resetEnabled = false

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
      RPGlobals.raceVars.resetEnabled = true -- Re-enable holding R to reset
      RPGlobals.raceVars.showPlaceGraphic = false
      -- We don't want to show the place graphic until we get to the 2nd floor
      RPGlobals.raceVars.startedTime = Isaac.GetTime() -- Mark when the race started
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
    if RPGlobals.raceVars.showPlaceGraphic and -- Don't show it on the first floor
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

return RPPostRender
