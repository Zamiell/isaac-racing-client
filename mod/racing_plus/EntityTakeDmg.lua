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

-- EntityType.ENTITY_HUSH (407)
function EntityTakeDmg:Hush(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  if g.run.dealingExtraDamage then
    return
  end

  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then
    return
  end

  -- Adjust his HP directly to avoid the damage scaling (armor)
  tookDamage.HitPoints = tookDamage.HitPoints - damageAmount

  -- Make him flash
  g.run.dealingExtraDamage = true
  tookDamage:TakeDamage(0, 0, damageSource, damageCountdownFrames)
  g.run.dealingExtraDamage = false
end

return EntityTakeDmg
