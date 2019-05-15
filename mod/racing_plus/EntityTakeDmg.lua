local EntityTakeDmg = {}

-- Includes
local g       = require("racing_plus/globals")
local SoulJar = require("racing_plus/souljar")

-- ModCallbacks.MC_ENTITY_TAKE_DMG (11), EntityType.ENTITY_PLAYER (1)
-- (this must return nil or false)
function EntityTakeDmg:Player(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  -- local variables
  local stage = g.l:GetStage()

  -- Make us invincibile while interacting with a trapdoor
  if g.run.trapdoor.state > 0 then
    return false
  end

  -- Prevent unavoidable damage from Mushrooms (when walking over skulls with Leo / Thunder Thighs)
  if damageSource.Type == EntityType.ENTITY_MUSHROOM and -- 300
     stage ~= LevelStage.STAGE2_1 and -- 3
     stage ~= LevelStage.STAGE2_2 then -- 4

    return false
  end

  -- Handle the Soul Jar
  SoulJar:EntityTakeDmg(damageFlag)
end

return EntityTakeDmg
