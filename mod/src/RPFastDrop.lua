local RPFastDrop = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Fast drop functions
--

function RPFastDrop:PostRender()

  Isaac.DebugString("New drop hotkey: " .. tostring(RPGlobals.race.hotkeyDrop))
  Isaac.DebugString("New switch hotkey: " .. tostring(RPGlobals.race.hotkeySwitch))
end

return RPFastClear
