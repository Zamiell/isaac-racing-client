local PostRender = {}

-- Includes
local g = require("racing_plus/globals")
local SaveDat = require("racing_plus/savedat")
local Errors = require("racing_plus/errors")
local Sprites = require("racing_plus/sprites")
local Schoolbag = require("racing_plus/schoolbag")
local SoulJar = require("racing_plus/souljar")
local UseItem = require("racing_plus/useitem")
local Pills = require("racing_plus/pills")
local FastTravel = require("racing_plus/fasttravel")
local ChallengeRooms = require("racing_plus/challengerooms")
local ChangeKeybindings = require("racing_plus/changekeybindings")
local Timer = require("racing_plus/timer")
local Speedrun = require("racing_plus/speedrun")
local SpeedrunPostRender = require("racing_plus/speedrunpostrender")
local ChangeCharOrder = require("racing_plus/changecharorder")
local SeededDeath = require("racing_plus/seededdeath")
local Shadow = require("racing_plus/shadow")

-- Check various things once per draw frame (60 times a second)
-- (this will fire while the floor/room is loading)
-- ModCallbacks.MC_POST_RENDER (2)
function PostRender:Main()
  -- Update some cached API functions to avoid crashing
  g.l = g.g:GetLevel()
  g.r = g.g:GetRoom()
  g.p = g.g:GetPlayer(0)
  g.seeds = g.g:GetSeeds()
  g.itemPool = g.g:GetItemPool()

  -- Read the "save.dat" file
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
    g.g:Fadein(0.15) -- This is fine tuned from trial and error to be a good speed
    return
  end

  -- Draw any error messages
  -- If there are any errors, we can skip the remainder of this function
  if Errors:Draw() then
    return
  end

  -- Draw graphics
  Sprites:Display()
  PostRender:DrawStreakText()
  Schoolbag:SpriteDisplay()
  SoulJar:SpriteDisplay()
  PostRender:TheLostHealth()
  PostRender:HolyMantle()
  PostRender:LeadPencilChargeBar()
  PostRender:SchoolbagGlowingHourGlass()
  Timer:Display()
  Timer:DisplayRun()
  Timer:DisplaySeededDeath()
  PostRender:DisplayFloorName()
  Pills:PostRender()
  ChangeCharOrder:PostRender()
  ChangeKeybindings:PostRender()
  PostRender:DrawNumSacRoom()
  PostRender:DisplayTopLeftText()
  PostRender:DrawVersion()

  -- Check for inputs
  PostRender:CheckConsoleInput()
  PostRender:CheckResetInput()
  PostRender:CheckDirection()

  -- Make Cursed Eye seeded
  PostRender:CheckCursedEye()

  -- Speed up teleport animations
  PostRender:SpeedUpTeleport()

  -- Check for trapdoor related things
  FastTravel:CheckTrapdoor()

  -- Check to see if we are subverting a teleport from Gurdy, Mom, Mom's Heart, or It Lives
  PostRender:CheckSubvertTeleport()

  -- Check for the seeded death mechanic
  -- (this is not in the "PostRender:Race()" function because it also applies to speedruns)
  SeededDeath:PostRender()

  -- Do race specific stuff
  PostRender:Race()
  Shadow:Draw()

  -- Handle things for multi-character speedruns
  SpeedrunPostRender:Main()
end

-- We replace the vanilla streak text because it blocks the map occasionally
function PostRender:DrawStreakText()
  if g.run.streakFrame == 0 then
    -- Only draw the secondary streak text if there is no normal streak text showing
    if g.run.streakText2 ~= "" then
      -- Draw the string
      local posGame = g:GridToPos(6, 0) -- Below the top door
      local pos = Isaac.WorldToRenderPosition(posGame)
      local color = KColor(1, 1, 1, 1)
      local scale = 1
      local length = g.font:GetStringWidthUTF8(g.run.streakText2) * scale
      g.font:DrawStringScaled(
        g.run.streakText2,
        pos.X - (length / 2),
        pos.Y,
        scale,
        scale,
        color,
        0,
        true
      )
    end
    return
  end

  -- Players who prefer the vanilla streak text will have a separate mod enabled
  if VanillaStreakText ~= nil and not g.run.streakForce then
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
    g.run.streakForce = false
    return
  end

  -- Draw the string
  local posGame = g:GridToPos(6, 0) -- Below the top door
  local pos = Isaac.WorldToRenderPosition(posGame)
  local color = KColor(1, 1, 1, fade)
  local scale = 1
  local length = g.font:GetStringWidthUTF8(g.run.streakText) * scale
  g.font:DrawStringScaled(
    g.run.streakText,
    pos.X - (length / 2),
    pos.Y,
    scale,
    scale,
    color,
    0,
    true
  )
end

function PostRender:TheLostHealth()
  local character = g.p:GetPlayerType()
  if character ~= PlayerType.PLAYER_THELOST then
    return
  end

  if Sprites.sprites.lostHealth == nil then
    Sprites.sprites.lostHealth = Sprite()
    Sprites.sprites.lostHealth:Load("gfx/ui/p20_lost_health.anm2", true)
  end

  local hudOffsetX = 0
  local hudOffsetY = 0

  local offsetX = hudOffsetX + 41
  if g.p:GetExtraLives() > 0 then
    offsetX = offsetX + 24
  end

  local offsetY = hudOffsetY + 2

  local animationToPlay = "Empty_Heart"
  if g.p:GetSoulHearts() >= 1 then
    animationToPlay = "Lost_Heart_Half"
  end
  Sprites.sprites.lostHealth:Play(animationToPlay, true)
  Sprites.sprites.lostHealth:Render(Vector(offsetX,offsetY), g.zeroVector, g.zeroVector)
end

function PostRender:HolyMantle()
  local effects = g.p:GetEffects()
  local numMantles = effects:GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE) -- 313
  if numMantles < 1 then
    return
  end

  if Sprites.sprites.holyMantle == nil then
    Sprites.sprites.holyMantle = Sprite()
    Sprites.sprites.holyMantle:Load("gfx/ui/p20_holy_mantle.anm2", true)
  end

  local hudOffset1Heart = 41
  local hudOffset2Heart = hudOffset1Heart + 12
  local hudOffset3Heart = hudOffset2Heart + 12
  local hudOffset4Heart = hudOffset3Heart + 12
  local hudOffset5Heart = hudOffset4Heart + 12
  local hudOffset6Heart = hudOffset5Heart + 12

  local hudOffset1Row = 2
  local hudOffset2Row = hudOffset1Row + 10

  local Yoffset
  local Xoffset = hudOffset6Heart

  local visibleHearts = g:GetPlayerVisibleHearts()
  if visibleHearts > 6 then
    Yoffset = hudOffset2Row
  else
    Yoffset = hudOffset1Row
  end

  local Xheart = visibleHearts % 6
  if Xheart == 0 then
    Xheart = 6
  end

  if Xheart <= 1 then
    Xoffset = hudOffset1Heart
  elseif Xheart == 2 then
    Xoffset = hudOffset2Heart
  elseif Xheart == 3 then
    Xoffset = hudOffset3Heart
  elseif Xheart == 4 then
    Xoffset = hudOffset4Heart
  elseif Xheart == 5 then
    Xoffset = hudOffset5Heart
  elseif Xheart >= 6 then
    Xoffset = hudOffset6Heart
  end

  if g.l:GetCurses() == LevelCurse.CURSE_OF_THE_UNKNOWN then -- 1 << 3
    Xoffset = hudOffset1Heart
  end

  local character = g.p:GetPlayerType()
  if character == PlayerType.PLAYER_THELOST then -- 10
    if g.p:GetExtraLives() > 0 then
      Xoffset = Xoffset + 24
    end
  end

  local animationToPlay
  if character == PlayerType.PLAYER_KEEPER then -- 14
    animationToPlay = "Keeper_Mantle"
  else
    animationToPlay = "Mantle"
  end

  Sprites.sprites.holyMantle:Play(animationToPlay, true)
  Sprites.sprites.holyMantle:Render(Vector(Xoffset, Yoffset), g.zeroVector, g.zeroVector)
end

-- Make an additional charge bar for the Lead Pencil
function PostRender:LeadPencilChargeBar()
  local character = g.p:GetPlayerType()
  local flyingOffset = g.p:GetFlyingOffset()

  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_LEAD_PENCIL) -- 444
    or character == PlayerType.PLAYER_AZAZEL -- 7
    or character == PlayerType.PLAYER_LILITH -- 13
    or character == PlayerType.PLAYER_THEFORGOTTEN -- 16
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) -- 52
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) -- 68
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) -- 118
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) -- 395
  ) then
   return
  end

  -- Initialize the sprite
  if PostRender.pencilSprite == nil then
    PostRender.pencilSprite = Sprite()
    PostRender.pencilSprite:Load("gfx/chargebar_pencil.anm2", true)
  end

  -- Adjust the position slightly so that it appears properly centered on the player,
  -- taking into account the size of the player sprite and if there are any existing charge bars
  local adjustX = 18.5 * g.p.SpriteScale.X
  local adjustY = 15 + (54 * g.p.SpriteScale.Y) - flyingOffset.Y
  local chargeBarHeight = 4.5
  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) -- 69
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) -- 229
    or g.p:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE) -- 316
  ) then
    adjustY = adjustY + chargeBarHeight
    if flyingOffset.Y ~= 0 then
      -- When the character has flying, the charge bar will overlap, so manually adjust for this
      adjustY = adjustY - 6 -- 5 is too small and 6 is just right
    end
  end
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_MAW_OF_VOID) then -- 399
    adjustY = adjustY + chargeBarHeight
  end
  local adjustedPosition = Vector(g.p.Position.X + adjustX, g.p.Position.Y - adjustY)

  -- Render it
  -- (there are 101 frames in the "Charging animation" and it takes 15 shots to fire a pencil
  -- barrage)
  local barFrame = g.run.pencilCounter * (101 / 15)
  barFrame = g:Round(barFrame, 0)
  PostRender.pencilSprite:SetFrame("Charging", barFrame)
  PostRender.pencilSprite:Render(
    g.r:WorldToScreenPosition(adjustedPosition),
    g.zeroVector,
    g.zeroVector
  )
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
  if g.race.rFormat == "seeded" and g.race.status == "in progress" then
    intendedSeed = g.race.seed
  end
  if intendedSeed ~= nil and startSeedString ~= intendedSeed then
    -- Change the seed of the run and restart the game
    g:ExecuteCommand("seed " .. intendedSeed)
    -- (we can perform another restart immediately afterwards to change the character and nothing
    -- will go wrong)
  end

  -- The "restart" command takes an optional argument to specify the character;
  -- we might want to specify this
  local command = "restart"
  if Speedrun:InSpeedrun() then
    local currentChar = Speedrun:GetCurrentChar()
    if currentChar == nil or not Speedrun:CheckValidCharOrder() then
      -- The character order is not set properly; we will display an error to the user later on
      return
    end
    command = command .. " " .. currentChar
  elseif g.race.status ~= "none" and g.race.rFormat ~= "custom" then
    -- Custom races might switch between characters
    command = command .. " " .. g.race.character
  end

  g:ExecuteCommand(command)
end

-- Keep track that we opened the console on this run so that we can disable the fast-resetting
-- feature
-- (so that typing an "r" into the console does not cause a fast-reset)
function PostRender:CheckConsoleInput()
  -- We don't need to perform any additional checks if we have already opened the console on this
  -- run
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
  -- Disable the fast-reset feature if we have opened the console on this run
  -- (so that typing an "r" into the console does not cause a fast-reset)
  if g.run.consoleOpened then
    return
  end

  -- Don't fast-reset if any modifiers are pressed
  -- (with the exception of shift, since the speedrunner MasterofPotato uses shift)
  if (
    Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL, 0) -- 341
    or Input.IsButtonPressed(Keyboard.KEY_LEFT_ALT, 0) -- 342
    or Input.IsButtonPressed(Keyboard.KEY_LEFT_SUPER, 0) -- 343
    or Input.IsButtonPressed(Keyboard.KEY_RIGHT_CONTROL, 0) -- 345
    or Input.IsButtonPressed(Keyboard.KEY_RIGHT_ALT, 0) -- 346
    or Input.IsButtonPressed(Keyboard.KEY_RIGHT_SUPER, 0) -- 347
  ) then
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

  local isaacFrameCount = Isaac.GetFrameCount()
  if g.run.roomsEntered <= 3 or isaacFrameCount <= g.run.fastResetFrame + 60 then
    Speedrun.fastReset = true
    -- A fast reset means to reset the current character,
    -- a slow/normal reset means to go back to the first character
    g:ExecuteCommand("restart")
  else
    -- In speedruns, we want to double tap R to return reset to the same character
    g.run.fastResetFrame = isaacFrameCount
  end
end

-- Fix the bug where diagonal knife throws have a 1-frame window when playing on keyboard (1/2)
function PostRender:CheckDirection()
  local directions = {}
  for i = 1, 4 do -- This corresponds to the "ButtonAction.ACTION_SHOOTX" enum
    directions[i] = Input.IsActionPressed(i + 3, 0) -- e.g. ButtonAction.ACTION_SHOOTLEFT is 4
  end
  g.run.directions[#g.run.directions + 1] = directions
  if #g.run.directions > 2 then -- We want there to be a 3-frame window instead of a 1-frame window
    table.remove(g.run.directions, 1) -- Remove the first element in the array
  end

  --[[
  Isaac.DebugString("         L R U D")
  for i, directionTable in ipairs(g.run.directions) do
    local frame = #g.run.directions - i
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
  local gameFrameCount = g.g:GetFrameCount()
  local playerSprite = g.p:GetSprite()
  local hearts = g.p:GetHearts()
  local soulHearts = g.p:GetSoulHearts()

  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE) -- 316
    or not playerSprite:IsPlaying("TeleportUp")
    or g.run.lastDamageFrame == 0
    -- If we were not damaged on this frame, we can assume it is not a Cursed Eye teleport
    or gameFrameCount ~= g.run.lastDamageFrame
    or g.run.usedTeleport
  ) then
    return
  end

  -- Account for the Cursed Skull trinket
  if (
    g.p:HasTrinket(TrinketType.TRINKET_CURSED_SKULL) -- 43
    -- 1/2 of a heart remaining
    and (
      (hearts == 1 and soulHearts == 0)
      or (hearts == 0 and soulHearts == 1)
    )
  ) then
    Isaac.DebugString("Cursed Skull teleport detected.")
    return
  end

  Isaac.DebugString("Cursed Eye teleport detected.")
  UseItem:Teleport()
end

function PostRender:SpeedUpTeleport()
  -- Local variables
  local playerSprite = g.p:GetSprite()

  -- Replace the "item raising" animation after using Telepills with a "TeleportUp" animation
  -- (this has to be in the PostRender callback because game frames do not tick when the use
  -- animation is happening)
  if g.run.usedTelepills then
    g.run.usedTelepills = false
    playerSprite:Play("TeleportUp", true)
    Isaac.DebugString(
      "Replaced the \"use\" animation for Telepills with a \"TeleportUp\" animation."
    )
  end

  -- Replace the "item raising" animation after using Blank Card with a "TeleportUp" animation
  -- (this has to be in the PostRender callback because game frames do not tick when the use
  -- animation is happening)
  if g.run.usedBlankCard then
    g.run.usedBlankCard = false
    -- Using "playerSprite:Play("TeleportUp", true)" does not work here for some reason
    g.p:AnimateTeleport(true)
    Isaac.DebugString(
      "Replaced the \"use\" animation for Blank Card with a \"TeleportUp\" animation."
    )
  end

  -- The vanilla teleport animations are annoyingly slow, so speed them up by a factor of 2
  if (
    (playerSprite:IsPlaying("TeleportUp") or playerSprite:IsPlaying("TeleportDown"))
    and playerSprite.PlaybackSpeed == 1
  ) then
    playerSprite.PlaybackSpeed = 2
    Isaac.DebugString("Increased the playback speed of a teleport animation.")

    -- Furthermore, cancel any ongoing Challenge Rooms
    ChallengeRooms:Teleport()
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

  Isaac.DebugString("Subverted a position teleport (2/2).")
end

function PostRender:DrawNumSacRoom()
  local roomType = g.r:GetType()
  if roomType ~= RoomType.ROOM_SACRIFICE then -- 13
    return
  end

  local roomFrameCount = g.r:GetFrameCount()
  if roomFrameCount == 0 then
    return
  end

  -- We want to place informational text for the player to the right of the heart containers
  -- (which will depend on how many heart containers we have)
  -- (this code is copied from the "DisplayTopLeftText()" function)
  local x = 55 + g:GetHeartXOffset()
  local y = 10
  local text = "Sacrifices: " .. tostring(g.run.numSacrifices)
  Isaac.RenderText(text, x, y, 2, 2, 2, 2)
end

function PostRender:DisplayTopLeftText()
  -- Local variables
  local seedString = g.seeds:GetStartSeedString()

  -- We want to place informational text for the player to the right of the heart containers
  -- (which will depend on how many heart containers we have)
  local x = 55 + g:GetHeartXOffset()
  local y = 10
  local lineLength = 15

  if g.raceVars.victoryLaps > 0 then
    -- Display the number of victory laps
    -- (this should have priority over showing the seed)
    Isaac.RenderText("Victory Lap #" .. tostring(g.raceVars.victoryLaps), x, y, 2, 2, 2, 2)
  elseif g.run.endOfRunText then
    -- Show some run summary information
    -- (it will be removed if they exit the room)
    local firstLine = "R+ " .. g.version .. " - " .. seedString
    Isaac.RenderText(firstLine, x, y, 2, 2, 2, 2)
    y = y + lineLength
    local secondLine
    if Speedrun:InSpeedrun() then
      -- We can't put average time on a 3rd line because it will be blocked by the Checkpoint item
      -- text
      secondLine = "Avg. time per char: " .. Speedrun:GetAverageTimePerCharacter()
    else
      secondLine = "Rooms entered: " .. tostring(g.run.roomsEntered)
    end
    Isaac.RenderText(secondLine, x, y, 2, 2, 2, 2)

    -- Draw a 3rd line to show the total frames
    if not Speedrun:InSpeedrun() or Speedrun:IsOnFinalCharacter() then
      local frames
      if Speedrun:InSpeedrun() then
        frames = Speedrun.finishedFrames
      else
        frames = g.raceVars.finishedFrames
      end
      local seconds = g:Round(frames / 60, 1)
      y = y + lineLength
      local thirdLine = tostring(frames) .. " frames (" .. tostring(seconds) .. "s)"
      Isaac.RenderText(thirdLine, x, y, 2, 2, 2, 2)
    end
  elseif (
    g.race.raceID ~= nil
    and g.race.status == "in progress"
    and g.run.roomsEntered <= 1
    and Isaac.GetTime() - g.raceVars.startedTime <= 2000
  ) then
    -- Only show it in the first two seconds of the race
    Isaac.RenderText("Race ID: " .. g.race.raceID, x, y, 2, 2, 2, 2)
  end
end

-- Do race specific stuff
function PostRender:Race()
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()
  local challenge = Isaac.GetChallenge()

  -- If we are not in a race, do nothing
  if (
    g.race.status == "none"
    and challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)")
  ) then
    Sprites:ClearPostRaceStartGraphics()
  end
  if g.race.status == "none" then
    -- Remove graphics as soon as the race is over
    Sprites:Init("top", 0)
    Sprites:ClearStartingRoomGraphicsTop()
    Sprites:ClearStartingRoomGraphicsBottom()
    if not g.raceVars.finished then
      Sprites:Init("place", 0) -- Keep the place there at the end of a race
    end
    return
  end

  --
  -- Race validation / show warning messages
  --

  if (
    g.race.difficulty == "hard"
    and g.g.Difficulty ~= Difficulty.DIFFICULTY_HARD -- 1
    and g.race.rFormat ~= "custom"
  ) then
    Sprites:Init("top", "error-not-hard-mode") -- Error: You are not on hard mode.
    return
  elseif Sprites.sprites.top ~= nil and Sprites.sprites.top.spriteName == "error-not-hard-mode" then
    Sprites:Init("top", 0)
  end

  if (
    g.race.difficulty == "normal"
    and g.g.Difficulty ~= Difficulty.DIFFICULTY_NORMAL -- 0
    and g.race.rFormat ~= "custom"
  ) then
    Sprites:Init("top", "error-hard-mode") -- Error: You are on hard mode.
    return
  elseif Sprites.sprites.top ~= nil and Sprites.sprites.top.spriteName == "error-hard-mode" then
    Sprites:Init("top", 0)
  end

  --
  -- Grahpics for the "Race Start" room
  --

  -- Show the graphics for the "Race Start" room (the top half)
  if g.race.status == "open" and roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3
    Sprites:Init("top", "wait") -- "Wait for the race to begin!"
    Sprites:Init("myStatus", g.race.myStatus)
    Sprites:Init("ready", tostring(g.race.placeMid))
    -- We use "placeMid" to hold this variable, since it isn't used before a race starts
    Sprites:Init("slash", "slash")
    Sprites:Init("readyTotal", tostring(g.race.numEntrants))
  else
    if Sprites.sprites.top ~= nil and Sprites.sprites.top.spriteName == "wait" then
      -- There can be other things on the "top" sprite location and we don't want to have to reload
      -- it on every frame
      Sprites:Init("top", 0)
    end
    Sprites:ClearStartingRoomGraphicsTop()
  end

  -- Show the graphics for the "Race Start" room (the bottom half)
  if (
    (g.race.status == "open" or g.race.status == "starting")
    and roomIndex == GridRooms.ROOM_DEBUG_IDX -- -3
  ) then
    if g.race.ranked or not g.race.solo then
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
    -- The client will set countdown equal to 0 and the status equal to "in progress" at the same
    -- time
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
    if (
      stage >= 2 -- Our place is irrelevant on the first floor, so don't bother showing it
      -- It is irrelevant to show "1st" when there is only one person in the race
      and not g.race.solo
    ) then
      Sprites:Init("place", tostring(g.race.placeMid))
    else
      Sprites:Init("place", 0)
    end
  end

  -- Remove graphics as soon as we enter another room
  -- (this is done separately from the above if block in case the client and mod become
  -- desynchronized)
  if g.raceVars.started == true and g.run.roomsEntered > 1 then
    Sprites:ClearPostRaceStartGraphics()
  end

  -- Hold the player in place when in the Race Room (to emulate the Gaping Maws effect)
  -- (this looks glitchy and jittery if is done in the PostUpdate callback, so do it here instead)
  if (
    roomIndex == GridRooms.ROOM_DEBUG_IDX -- -3
    and not g.raceVars.started
  ) then
    -- The starting position is 320, 380
    g.p.Position = Vector(320, 380)
  end
end

function PostRender:DrawVersion()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Make the version persist for at least 2 seconds after the player presses "v"
  if Input.IsButtonPressed(Keyboard.KEY_V, 0) then -- 86
    g.run.showVersionFrame = gameFrameCount + 60
  end

  if g.run.showVersionFrame == 0 or gameFrameCount > g.run.showVersionFrame then
    return
  end

  local center = PostRender:GetScreenCenterPosition()
  local text, x, y

  -- Render the version of the mod
  text = "Racing+"
  x = center.X - 3 * #text
  y = center.Y + 40
  Isaac.RenderText(text, x, y, 2, 2, 2, 2)

  text = g.version
  y = y + 15
  Isaac.RenderText(text, x, y, 2, 2, 2, 2)
end

-- Make the Schoolbag work properly with the Glowing Hour Glass
-- (this has to be in the POST_RENDER callback instead of the POST_NEW_ROOM callback since
-- the game decrements the charge from the Glowing Hour Glass on the first render frame after the
-- room is loaded)
function PostRender:SchoolbagGlowingHourGlass()
  if g.run.schoolbag.usedGlowingHourGlass ~= 2 then
    return
  end

  -- Local variables
  local last = g.run.schoolbag.last

  -- Decrement the charges on the Glowing Hour Glass
  if last.active.item == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then -- 422
    last.active.charge = last.active.charge - 2
  end
  if last.schoolbag.item == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then -- 422
    last.schoolbag.charge = last.schoolbag.chargeBattery
  end

  -- Rewind the charges on the active item and the Schoolbag item
  g.run.schoolbag.usedGlowingHourGlass = 0
  local totalActiveCharge = last.active.charge + last.active.chargeBattery
  g.p:AddCollectible(last.active.item, totalActiveCharge, true)
  Schoolbag:Put(last.schoolbag.item, last.schoolbag.charge)
  g.run.schoolbag.chargeBattery = last.schoolbag.chargeBattery
  Isaac.DebugString(
    "Glowing Hour Glass used - manually restored the active item: "
    .. tostring(last.active.item) .. " - "
    .. tostring(last.active.charge) .. " - "
    .. tostring(last.active.chargeBattery)
  )
  Isaac.DebugString(
    "Glowing Hour Glass used - manually restored the Schoolbag item: "
    .. tostring(last.schoolbag.item) .. " - "
    .. tostring(last.schoolbag.charge) .. " - "
    .. tostring(last.schoolbag.chargeBattery)
  )
end

function PostRender:DisplayFloorName()
  -- Players who prefer the vanilla streak text will have a separate mod enabled
  if VanillaStreakText ~= nil then
   return
 end

  -- Only show the floor name if the user is pressing tab
  local tabPressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_MAP, i) then -- 13
      tabPressed = true
      break
    end
  end
  if not tabPressed then
    g.run.streakText2 = ""
    return
  end

  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  g.run.streakText2 = g.l:GetName(stage, stageType, 0, false)
end

-- Taken from Alphabirth: https://steamcommunity.com/sharedfiles/filedetails/?id=848056541
function PostRender:GetScreenCenterPosition()
  -- Local variables
  local shape = g.r:GetRoomShape()
  local centerOffset = (g.r:GetCenterPos()) - g.r:GetTopLeftPos()
  local pos = g.r:GetCenterPos()

  if centerOffset.X > 260 then
    pos.X = pos.X - 260
  end
  if shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LTL then
    pos.X = pos.X - 260
  end
  if centerOffset.Y > 140 then
    pos.Y = pos.Y - 140
  end
  if shape == RoomShape.ROOMSHAPE_LTR or shape == RoomShape.ROOMSHAPE_LTL then
    pos.Y = pos.Y - 140
  end

  return Isaac.WorldToRenderPosition(pos, false)
end

return PostRender
