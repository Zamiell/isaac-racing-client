local RPExecuteCmd = {}

--
-- Includes
--

local RPSpeedrun = require("src/rpspeedrun")

-- ModCallbacks.MC_EXECUTE_CMD (22)
function RPExecuteCmd:Main(cmd, params)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()
  local isaacFrameCount = Isaac.GetFrameCount()

  Isaac.DebugString("MC_EXECUTE_CMD - " .. tostring(cmd) .. " " .. tostring(params))

  if cmd == "getframe" then
    Isaac.DebugString("Isaac frame count is at: " .. tostring(isaacFrameCount))
    Isaac.DebugString("Game frame count is at: " .. tostring(gameFrameCount))
    Isaac.DebugString("Room frame count is at: " .. tostring(roomFrameCount))
  elseif cmd == "next" then
    RPSpeedrun.spawnedCheckpoint = true
    RPSpeedrun:CheckpointTouched()
  end
end

return RPExecuteCmd
