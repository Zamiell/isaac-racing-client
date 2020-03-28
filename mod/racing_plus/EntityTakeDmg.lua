local EntityTakeDmg = {}

-- Includes
local g           = require("racing_plus/globals")
local SoulJar     = require("racing_plus/souljar")
local SeededDeath = require("racing_plus/seededdeath")

-- EntityType.ENTITY_PLAYER (1)
-- (this must return nil or false)
function EntityTakeDmg:Player(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  -- Make us invincibile while interacting with a trapdoor
  if g.run.trapdoor.state > 0 then
    return false
  end

  -- Handle the Soul Jar
  SoulJar:EntityTakeDmg(damageFlag)

  -- Handle seeded death
  return SeededDeath:EntityTakeDmg(damageAmount, damageFlag)
end

return EntityTakeDmg
