local EntityTakeDmg = {}

-- Includes
local g       = require("src/globals")
local SoulJar = require("src/souljar")

-- ModCallbacks.MC_ENTITY_TAKE_DMG (11)
-- (this must return nil or false)
function EntityTakeDmg:Main(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  -- local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = tookDamage:ToPlayer()

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

  -- Betrayal (custom)
  if player:HasCollectible(Isaac.GetItemIdByName("Betrayal")) then
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      local npc = entity:ToNPC()
      if npc ~= nil and
         npc:IsVulnerableEnemy() then -- Returns true for enemies that can be damaged

        npc:AddCharmed(150) -- 5 seconds
      end
    end
  end
end

return EntityTakeDmg
