local Errors = {}

-- Includes
local g = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")

Errors.startingX = 115
Errors.startingY = 70

function Errors:Draw()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- We only want to show one error to the user at a time
  -- Errors are checked for in order of precendence
  if g.corrupted then
    Errors:DrawCorrupted()
    return true
  elseif g.resumedOldRun then
    Errors:DrawResumedOldRun()
    return true
  elseif not g.saveFile.fullyUnlocked then
    Errors:DrawInvalidSaveFile()
    return true
  elseif g.invalidItemsXML then
    Errors:DrawInvalidItemsXML()
    return true
  elseif (
    not g.luaDebug
    and g.raceVars.shadowEnabled
  ) then
    Errors:DrawNoLuaDebug()
    return true
  elseif (
    (Speedrun:InSpeedrun() or challenge == Isaac.GetChallengeIdByName("Change Char Order"))
    and RacingPlusData == nil
  ) then
    Errors:DrawRacingPlusData1()
    return true
  elseif (
    challenge == Isaac.GetChallengeIdByName("Change Keybindings")
    and RacingPlusData == nil
  ) then
    Errors:DrawRacingPlusData2()
    return true
  elseif (
    challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)")
    and SinglePlayerCoopBabies == nil
  ) then
    Errors:DrawEnableBabiesMod()
    return true
  elseif (
    Speedrun:InSpeedrun()
    and challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5)")
    and SinglePlayerCoopBabies ~= nil
  ) then
    Errors:DrawDisableBabiesMod()
    return true
  elseif (
    challenge == Isaac.GetChallengeIdByName("R+7 (Season 9 Beta)")
    and RacingPlusRebalanced == nil
  ) then
    Errors:DrawEnableBalanceMod()
    return true
  elseif (
    Speedrun:InSpeedrun()
    and challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 9 Beta)")
    and RacingPlusRebalanced ~= nil
  ) then
    Errors:DrawDisableBalanceMod()
    return true
  elseif (
    Speedrun:InSpeedrun()
    and not Speedrun:CheckValidCharOrder()
  ) then
    Errors:DrawSetCharOrder()
    return true
  end
end

function Errors:DrawCorrupted()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must close and re-open the game after", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("enabling or disabling any mods.", x, y, 2, 2, 2, 2)
  y = y + 20
  Isaac.RenderText("If this error persists after re-opening the game,", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("then your Racing+ mod is corrupted and needs to be", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("redownloaded/reinstalled.", x, y, 2, 2, 2, 2)
end

function Errors:DrawResumedOldRun()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: Racing+ does not support continuing old", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("runs that were played prior to opening the", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("game. Please reset the run.", x, y, 2, 2, 2, 2)
end

function Errors:DrawInvalidSaveFile()
  local x = Errors.startingX
  local y = Errors.startingY
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
  y = y + 20
  Isaac.RenderText("For save file troubleshooting, please read the", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("following link:", x, y, 2, 2, 2, 2)
  y = y + 20
  Isaac.RenderText("https://pastebin.com/1YY4jb4P", x, y, 2, 2, 2, 2)
end

function Errors:DrawInvalidItemsXML()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You are using a mod that conflicts with", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("Racing+. Please disable all other mods, and then", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("completely close and re-open the game. See the", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("Discord server for more information about legal", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("mods:", x, y, 2, 2, 2, 2)
  x = x - 42
  y = y + 20
  Isaac.RenderText("https://www.speedrun.com/afterbirthplus/thread/pffgt", x, y, 2, 2, 2, 2)
end

function Errors:DrawNoLuaDebug()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: In order for Racing+ to draw the opponent's", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("shadows, you must set \"--luadebug\" in the Steam", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("launch options for the game. Before doing this,", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("it is imperative that you disable any mods that", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("you do not fully trust. For more information,", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("please read the following link:", x, y, 2, 2, 2, 2)
  y = y + 20
  Isaac.RenderText("https://pastebin.com/2ZnRxDba", x, y, 2, 2, 2, 2)
end

function Errors:DrawRacingPlusData1()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must subscribe to and enable", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("the \"Racing+ Data\" mod on the Steam", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("Workshop in order to play multi-character", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("custom challenges.", x, y, 2, 2, 2, 2)
  x = x - 42
  y = y + 20
  Isaac.RenderText("https://steamcommunity.com/sharedfiles/", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("filedetails/?id=2004774809", x, y, 2, 2, 2, 2)
end

function Errors:DrawRacingPlusData2()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must subscribe to and enable", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("the \"Racing+ Data\" mod on the Steam", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("Workshop in order to use the extra", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("keybindings provided by Racing+.", x, y, 2, 2, 2, 2)
  x = x - 42
  y = y + 20
  Isaac.RenderText("https://steamcommunity.com/sharedfiles/", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("filedetails/?id=2004774809", x, y, 2, 2, 2, 2)
end

function Errors:DrawEnableBabiesMod()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must subscribe to and enable", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("\"The Babies Mod\" on the Steam Workshop", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("in order for the Racing+ season 5 custom", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("challenge to work correctly.", x, y, 2, 2, 2, 2)
  x = x - 42
  y = y + 20
  Isaac.RenderText("https://steamcommunity.com/sharedfiles/", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("filedetails/?id=1545273881", x, y, 2, 2, 2, 2)
end

function Errors:DrawDisableBabiesMod()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must disable The Babies Mod", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("in order for this custom challenge to", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("work correctly.", x, y, 2, 2, 2, 2)
end

function Errors:DrawEnableBalanceMod()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must subscribe to and enable the", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("\"Racing+ Rebalanced\" mod on the Steam Workshop", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("in order for the Racing+ season 9 custom", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("challenge to work correctly.", x, y, 2, 2, 2, 2)
  x = x - 42
  y = y + 20
  Isaac.RenderText("https://steamcommunity.com/sharedfiles/", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("filedetails/?id=FILL_THIS_IN_LATER", x, y, 2, 2, 2, 2)
end

function Errors:DrawDisableBalanceMod()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must disable the Racing+ Rebalanced", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("mod in order for this custom challenge to", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("work correctly.", x, y, 2, 2, 2, 2)
end

function Errors:DrawSetCharOrder()
  local x = Errors.startingX
  local y = Errors.startingY
  Isaac.RenderText("Error: You must set a character order first", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("by using the \"Change Char Order\" custom", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("challenge.", x, y, 2, 2, 2, 2)
end

return Errors
