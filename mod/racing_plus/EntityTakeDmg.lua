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

  EntityTakeDmg:SacrificeRoom(damageFlag)
  SoulJar:EntityTakeDmg(damageFlag)
  return SeededDeath:EntityTakeDmg(damageAmount, damageFlag)
end

function EntityTakeDmg:SacrificeRoom(damageFlag)
  local roomType = g.r:GetType()
  if roomType ~= RoomType.ROOM_SACRIFICE then -- 13
    return
  end

  local bit = (damageFlag & (1 << 7)) >> 7 -- DamageFlag.DAMAGE_SPIKES
  if bit == 1 then
    g.run.numSacrifices = g.run.numSacrifices + 1
  end
end

return EntityTakeDmg
