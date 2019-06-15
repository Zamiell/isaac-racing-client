local CheckEntities = {}

-- Includes
local g                  = require("racing_plus/globals")
local FastTravel         = require("racing_plus/fasttravel")
local Race               = require("racing_plus/race")
local SeededDeath        = require("racing_plus/seededdeath")
local Speedrun           = require("racing_plus/speedrun")
local SpeedrunPostUpdate = require("racing_plus/speedrunpostupdate")
local ChangeCharOrder    = require("racing_plus/changecharorder")

-- Check all the grid entities in the room
-- (called from the PostUpdate callback)
function CheckEntities:Grid()
  -- Local variables
  local gridSize = g.r:GetGridSize()

  for i = 1, gridSize do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_TRAPDOOR and -- 17
         saveState.VarData == 1 then -- Void Portals have a VarData of 1

        -- Delete all Void Portals
        gridEntity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

      elseif saveState.Type == GridEntityType.GRID_TRAPDOOR then -- 17
        FastTravel:ReplaceTrapdoor(gridEntity, i)

      elseif saveState.Type == GridEntityType.GRID_STAIRS then -- 18
        FastTravel:ReplaceCrawlspace(gridEntity, i)

      elseif saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        ChangeCharOrder:CheckButtonPressed(gridEntity)
        SpeedrunPostUpdate:CheckVetoButton(gridEntity)
      end
    end
  end
end

-- Check all the non-grid entities in the room
-- (called from the PostUpdate callback)
function CheckEntities:NonGrid()
  -- Go through all the entities
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    local entityFunc = CheckEntities.functions[entity.Type]
    if entityFunc ~= nil then
      return entityFunc(entity)
    end
  end
end

-- The collection of functions for each entity
CheckEntities.functions = {}

-- EntityType.ENTITY_ATTACKFLY (18)
CheckEntities.functions[18] = function(entity)
  -- There is a weird bug where an Attack Fly will get set to a NaN position and
  -- will appear in the bottom-right hand corner of the room but will not be able to be damaged
  -- This might be a vanilla bug where the game runs out of memory and cannot create the fly properly
  -- This has mostly happened on the Blue Baby fight, although it can happen in other places as well
  -- Attempt to fix this bug in Racing+
  -- Just in case the bugged entity will not fire the NPC_UPDATE callback,
  -- check on every frame in the POST_UPDATE callback
  if entity.Position.X ~= entity.Position.X then -- Kilburn says that NaN isn't equal to itself
    entity:Remove()
    Isaac.DebugString("Error: Manually removed a null position fly.")
  end
end

-- EntityType.ENTITY_THE_HAUNT (260)
CheckEntities.functions[260] = function(entity)
  -- We only care about Lil' Haunts (260.10)
  if entity.Variant ~= 10 then
    return
  end
  local npc = entity:ToNPC()

  -- Add them to the table so that we can track them
  local index = GetPtrHash(npc)
  if g.run.currentLilHaunts[index] == nil then
    -- This can't be in the NPC_UPDATE callback because it does not fire during the "Appear" animation
    -- This can't be in the MC_POST_NPC_INIT callback because the position is always equal to (0, 0) there
    g.run.currentLilHaunts[index] = {
      index = npc.Index, -- We could have this just be table index instead, but it's safer to use the hash
      pos = npc.Position,
      ptr = EntityPtr(npc),
    }
    local string = "Added a Lil' Haunt with index " .. tostring(index) .. " to the table (with "
    if npc.Parent == nil then
      string = string .. "no"
    else
      string = string .. "a"
      g.run.currentLilHaunts[index].parentIndex = npc.Parent.Index
    end
    string = string .. " parent)."
    Isaac.DebugString(string)
  end

  -- Remove invulnerability frames from Lil' Haunts that are not attached to a Haunt
  -- (we can't do it any earlier than the 4th frame because it will introduce additional bugs,
  -- such as the Lil' Haunt becoming invisible)
  if npc.Parent == nil and
     npc.FrameCount == 4 then

     -- Changing the NPC's state triggers the invulnerability removal in the next frame
    npc.State = NpcState.STATE_MOVE -- 4

    -- Additionally, we also have to manually set the collision, because
    -- tears will pass through Lil' Haunts when they first spawn
    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4

    Isaac.DebugString("Removed invulnerability frames and set collision for a Lil' Haunt with index: " ..
                      tostring(npc.Index))
  end

  -- Lock newly spawned Lil' Haunts in place so that they don't immediately rush the player
  if npc.State == NpcState.STATE_MOVE and -- 4
     npc.FrameCount <= 16 then

    npc.Position = g.run.currentLilHaunts[index].pos
    npc.Velocity = g.zeroVector
  end
end

-- EntityType.ENTITY_RACE_TROPHY
CheckEntities.functions[EntityType.ENTITY_RACE_TROPHY] = function(entity)
  -- We can't check in the NPC_UPDATE callback since it will not fire during the "Appear" animation
  if g.raceVars.finished or Speedrun.finished then
    return
  end

  -- We should not be able to finish the race while we are in ghost form
  if g.run.seededDeath.state == SeededDeath.state.GHOST_FORM then
    return
  end

  -- Check to see if we are touching the trophy
  if g.p.Position:Distance(entity.Position) > 24 then -- 25 is a touch too big
    return
  end

  entity:Remove()
  g.p:AnimateCollectible(CollectibleType.COLLECTIBLE_TROPHY, "Pickup", "PlayerPickupSparkle2")

  if Isaac.GetChallenge() == Challenge.CHALLENGE_NULL and -- 0
     not Speedrun.inSeededSpeedrun then

    Race:Finish()

  else
    Speedrun:Finish()
  end
end

return CheckEntities
