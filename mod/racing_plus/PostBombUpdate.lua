local PostBombUpdate = {}

-- Includes
local Season6 = require("racing_plus/season6")

-- ModCallbacks.MC_POST_BOMB_UPDATE (58)
function PostBombUpdate:Main(bomb)
  Season6:PostBombUpdate(bomb)
end

return PostBombUpdate