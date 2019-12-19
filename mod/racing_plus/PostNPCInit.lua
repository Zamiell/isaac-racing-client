local PostNPCInit = {}

-- In this callback, an NPC's position will not be initialized yet

-- Includes
local g = require("racing_plus/globals")

-- EntityType.ENTITY_BABY (38)
function PostNPCInit:NPC38(npc)
  if g.run.spawningAngel then
    return
  end

  -- We only want to replace Babies on the Isaac fight
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  if stage ~= 10 or
     roomType ~= RoomType.ROOM_BOSS then -- 5

    return
  end

  -- Get the position of the boss
  local isaacs = Isaac.FindByType(EntityType.ENTITY_ISAAC, -1, -1, false, false) -- 102
  if #isaacs == 0 then
    return
  end
  local isaacPos = isaacs[1].Position

  local position
  while true do
    -- Get a random position on the edge of a circle around Isaac
    -- (2.5 grid squares = 100)
    position = isaacPos + (RandomVector():Normalized() * 100)

    -- We want to ensure that we do not spawn a Baby too close to the player
    if position:Distance(g.p.Position) > 80 then
      break
    end
  end

  g.run.spawningAngel = true
  g.g:Spawn(npc.Type, npc.Variant, position, g.zeroVector, nil, npc.SubType, npc.InitSeed)
  g.run.spawningAngel = false
  npc:Remove()
end

-- EntityType.ENTITY_THE_HAUNT (260)
function PostNPCInit:NPC260(npc)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Speed up the first Lil' Haunt attached to a Haunt (2/3)
  if npc.Variant == 10 and -- Lil' Haunt (260.10)
     npc.Parent ~= nil then
     -- This will only target Lil' Haunts that are attached to a Haunt
     -- If we change Lil' Haunts that are not attached to a Haunt to an idle state during their appear animation,
     -- they will turn into bosses for some reason and show the boss health bars at the bottom of the screen

    -- Change it from NpcState.STATE_INIT (0) to NpcState.STATE_IDLE (3)
    -- For Lil' Haunts attached to a Haunt, we still have to manually set them to NpcState.STATE_MOVE (4), but
    -- it produces cleaner results when you go from 3 to 4 rather than from 0 to 4
    npc.State = NpcState.STATE_IDLE -- 3
    Isaac.DebugString("Manually set a Lil' Haunt to an idle state (3) on frame: " .. tostring(gameFrameCount))

    -- Keeping Lil' Haunts in place is next handled in the "CheckEntities:Entity260()" function
    -- Speeding up the first Lil' Haunt is next handled in the "PostUpdate:CheckHauntSpeedup()" function
  end
end

-- EntityType.ENTITY_ISAAC (102)
function PostNPCInit:NPC102(npc)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- In season 7 speedruns, we want to go directly into the second phase of Hush
  if npc.Variant == 2 and
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then

    npc:Remove()
    g.g:Spawn(EntityType.ENTITY_HUSH, 0, Vector(580, 260), g.zeroVector, nil, 0, npc.InitSeed) -- 407
    -- (the position is copied from vanilla)
  end
end

return PostNPCInit
