local ChangeKeybindings = {}

-- Includes
local g       = require("racing_plus/globals")
local SaveDat = require("racing_plus/savedat")

ChangeKeybindings.challengeState = 1
ChangeKeybindings.challengeFramePressed = 0
ChangeKeybindings.states = {
  FAST_DROP = 1,
  FAST_DROP_TRINKET = 2,
  FAST_DROP_POCKET = 3,
  SCHOOLBAG_SWITCH = 4,
  START_TO_FADE_OUT = 5,
  FINISHED = 6,
}

--
-- The "Change Keybindings" custom challenge
--

function ChangeKeybindings:PostNewRoom()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("Change Keybindings") then
    return
  end

  if g.run.roomsEntered == 1 then
    Isaac.ExecuteCommand("stage 1a") -- The Cellar is the cleanest floor
    g.run.goingToDebugRoom = true
    Isaac.ExecuteCommand("goto d.0") -- We do more things in the next "PostNewRoom" callback
    return
  end
  if g.run.roomsEntered ~= 2 then
    return
  end

  -- Remove all enemies
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    local npc = entity:ToNPC()
    if npc ~= nil then
      entity:Remove()
    end
  end
  g.r:SetClear(true)

  -- We want to trap the player in the room, so delete all 4 doors
  for i = 0, 3 do
    g.r:RemoveDoor(i)
  end

  -- Put the player next to the bottom door
  g.p.Position = Vector(320, 400)

  -- Get rid of the HUD
  g.seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD) -- 10

  -- Make the player invisible
  g.p.Position = g.r:GetCenterPos()
  g.p.SpriteScale = g.zeroVector

  -- Reset variables used in the challenge
  ChangeKeybindings.challengeState = ChangeKeybindings.states.FAST_DROP
  ChangeKeybindings.challengeFramePressed = -100
  Isaac.DebugString("Entered the \"Change Keybindings\" custom challenge.")
end

function ChangeKeybindings:PostRender()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("Change Keybindings") then
    return
  end

  -- Wait a moment just in case they were mashing stuff while it was loading
  if g.g:GetFrameCount() < 1 then
    return
  end

  if ChangeKeybindings.challengeState == ChangeKeybindings.states.START_TO_FADE_OUT then
    ChangeKeybindings.challengeState = ChangeKeybindings.states.FINISHED
    g.g:Fadeout(0.05, g.FadeoutTarget.FADEOUT_MAIN_MENU)
  elseif ChangeKeybindings.challengeState == ChangeKeybindings.states.FINISHED then
    return
  end

  -- Wait a moment if they just set a hotkey
  if ChangeKeybindings.challengeFramePressed + 15 >= gameFrameCount then
    return
  end

  local text = {}
  if ChangeKeybindings.challengeState == ChangeKeybindings.states.FAST_DROP then
    if g.race.hotkeyDrop == 0 then
      text[1] = "The fast-drop hotkey is not bound."
    else
      text[1] = "The fast-drop hotkey is currently bound to:"
      text[2] = ChangeKeybindings:GetKeyName(g.race.hotkeyDrop) ..
                " (code: " .. tostring(g.race.hotkeyDrop) .. ")"
    end

  elseif ChangeKeybindings.challengeState == ChangeKeybindings.states.FAST_DROP_TRINKET then
    if g.race.hotkeyDropTrinket == 0 then
      text[1] = "The fast-drop (trinket-only) hotkey is not bound."
    else
      text[1] = "The fast-drop (trinket-only) hotkey is currently bound to:"
      text[2] = ChangeKeybindings:GetKeyName(g.race.hotkeyDropTrinket) ..
                " (code: " .. tostring(g.race.hotkeyDropTrinket) .. ")"
    end

  elseif ChangeKeybindings.challengeState == ChangeKeybindings.states.FAST_DROP_POCKET then
    if g.race.hotkeyDropPocket == 0 then
      text[1] = "The fast-drop (pocket-item-only) hotkey is not bound."
    else
      text[1] = "The fast-drop (pocket-item-only) hotkey is currently bound to:"
      text[2] = ChangeKeybindings:GetKeyName(g.race.hotkeyDropPocket) ..
                " (code: " .. tostring(g.race.hotkeyDropPocket) .. ")"
    end

  elseif ChangeKeybindings.challengeState == ChangeKeybindings.states.SCHOOLBAG_SWITCH then
    if g.race.hotkeySwitch == 0 then
      text[1] = "The Schoolbag-switch hotkey is not bound."
    else
      text[1] = "The Schoolbag-switch hotkey is currently bound to:"
      text[2] = ChangeKeybindings:GetKeyName(g.race.hotkeySwitch) ..
                " (code: " .. tostring(g.race.hotkeySwitch) .. ")"
    end
  end
  if text[2] == nil then
    text[2] = ""
  end
  text[3] = ""
  text[4] = "Press the desired key now."
  text[5] = "Or press F12 to keep the vanilla behavior."
  text[6] = "(For controller players, you must bind these"
  text[7] = "to a keyboard key and then use Joy2Key.)"
  for i, line in ipairs(text) do
    local y = 50 + (20 * i)
    g.font:DrawString(line, 100, y, g.kcolor, 0, true)
  end

  for k, v in pairs(Keyboard) do
    if Input.IsButtonPressed(v, 0) then
      if ChangeKeybindings.challengeState == ChangeKeybindings.states.FAST_DROP then
        g.race.hotkeyDrop = v
        if v == Keyboard.KEY_F12 then -- 301
          g.race.hotkeyDrop = 0
        end
        Isaac.DebugString("New drop hotkey: " .. tostring(g.race.hotkeyDrop))
        ChangeKeybindings.challengeState = ChangeKeybindings.states.FAST_DROP_TRINKET
        SaveDat:Save()
        ChangeKeybindings.challengeFramePressed = gameFrameCount

      elseif ChangeKeybindings.challengeState == ChangeKeybindings.states.FAST_DROP_TRINKET then
        g.race.hotkeyDropTrinket = v
        if v == Keyboard.KEY_F12 then -- 301
          g.race.hotkeyDropTrinket = 0
        end
        Isaac.DebugString("New drop trinket hotkey: " .. tostring(g.race.hotkeyDropTrinket))
        ChangeKeybindings.challengeState = ChangeKeybindings.states.FAST_DROP_POCKET
        SaveDat:Save()
        ChangeKeybindings.challengeFramePressed = gameFrameCount

      elseif ChangeKeybindings.challengeState == ChangeKeybindings.states.FAST_DROP_POCKET then
        g.race.hotkeyDropPocket = v
        if v == Keyboard.KEY_F12 then -- 301
          g.race.hotkeyDropPocket = 0
        end
        Isaac.DebugString("New drop pocket hotkey: " .. tostring(g.race.hotkeyDropPocket))
        ChangeKeybindings.challengeState = ChangeKeybindings.states.SCHOOLBAG_SWITCH
        SaveDat:Save()
        ChangeKeybindings.challengeFramePressed = gameFrameCount

      elseif ChangeKeybindings.challengeState == ChangeKeybindings.states.SCHOOLBAG_SWITCH then
        g.race.hotkeySwitch = v
        if v == Keyboard.KEY_F12 then -- 301
          g.race.hotkeySwitch = 0
        end
        Isaac.DebugString("New switch hotkey: " .. tostring(g.race.hotkeySwitch))
        ChangeKeybindings.challengeState = ChangeKeybindings.states.START_TO_FADE_OUT
        SaveDat:Save()
        ChangeKeybindings.challengeFramePressed = gameFrameCount
      end
    end
  end
end

function ChangeKeybindings:GetKeyName(keyCode)
  for k, v in pairs(Keyboard) do
    if v == keyCode then
      return k:sub(5)
    end
  end

  return "not found"
end

return ChangeKeybindings