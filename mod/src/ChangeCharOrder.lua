local ChangeCharOrder = {}

-- Includes
local g       = require("src/globals")
local SaveDat = require("src/savedat")

--
-- Constants
--

-- The format of "charPosition" is character number, X, Y
ChangeCharOrder.seasons = {
  R9S1 = {
    X = 2,
    Y = 1,
    charPosition = {
      {2, 2, 1},  -- Cain
      {3, 4, 1},  -- Judas
      {4, 6, 1},  -- Blue Baby
      {5, 8, 1},  -- Eve
      {6, 10, 1}, -- Samson
      {7, 3, 3},  -- Azazel
      {8, 5, 3},  -- Lazarus
      {10, 7, 3}, -- The Lost
      {14, 9, 3}, -- Keeper
    },
  },
  R14S1 = {
    X = 6,
    Y = 1,
    charPosition = {
      {0, 1, 1},   -- Isaac
      {1, 3, 1},   -- Magdalene
      {2, 5, 1},   -- Cain
      {3, 7, 1},   -- Judas
      {4, 9, 1},   -- Blue Baby
      {5, 11, 1},  -- Eve
      {6, 1, 3},   -- Samson
      {7, 3, 3},   -- Azazel
      {8, 5, 3},   -- Lazarus
      {9, 7, 3},   -- Eden
      {10, 9, 3},  -- The Lost
      {13, 11, 3}, -- Lilith
      {14, 2, 5},  -- Keeper
      {15, 10, 5}, -- Apollyon

    },
  },
  R7S2 = {
    X = 10,
    Y = 1,
    charPosition = {
      {0, 2, 1},  -- Isaac
      {2, 4, 1},  -- Cain
      {3, 6, 1},  -- Judas
      {7, 8, 1},  -- Azazel
      {9, 10, 1}, -- Eden
      {15, 5, 3}, -- Apollyon
      {Isaac.GetPlayerTypeByName("Samael"), 7, 3}, -- Samael
    },
  },
  R7S3 = {
    X = 2,
    Y = 3,
    charPosition = {
      {0, 2, 1},  -- Isaac
      {1, 4, 1},  -- Magdalene
      {3, 6, 1},  -- Judas
      {5, 8, 1},  -- Eve
      {6, 10, 1}, -- Samson
      {8, 5, 3},  -- Lazarus
      {10, 7, 3}, -- The Lost
    },
  },
  R7S4 = {
    X = 6,
    Y = 3,
    charPosition = {
      {2, 2, 1},  -- Cain
      {3, 4, 1},  -- Judas
      {4, 6, 1},  -- Blue Baby
      {7, 8, 1},  -- Azazel
      {8, 10, 1}, -- Lazarus
      {13, 5, 3}, -- Lilith
      {15, 7, 3}, -- Apollyon
    },
    itemPosition = {
      {172, 1, 1},  -- Sacrificial Dagger
      {224, 3, 1},  -- Cricket's Body
      {373, 5, 1},  -- Dead Eye
      {52, 7, 1},   -- Dr. Fetus
      {229, 9, 1},  -- Monstro's Lung
      {311, 11, 1}, -- Judas' Shadow
      {1006, 1, 3},   -- Chocolate Milk + Steven
      {1005, 11, 3},  -- Jacob's Ladder + There's Options

      {1001, 9, 5},  -- Mutant Spider + The Inner Eye
      {1002, 10, 5},  -- Technology + A Lump of Coal
      {1003, 11, 5}, -- Fire Mind + Mysterious Liquid + 13 luck
      {1004, 12, 5},  -- Kamikaze! + Host Hat

      {114, 0, 5}, -- Mom's Knife
      {395, 1, 5}, -- Tech X
      {168, 2, 5}, -- Epic Fetus
      {149, 3, 5}, -- Ipecac
    },
    numSClass = 4,
  },
  R7S6 = {
    X = 10,
    Y = 3,
    charPosition = {
      {3, 2, 1},  -- Judas
      {4, 4, 1},  -- Blue Baby
      {5, 6, 1},  -- Eve
      {7, 8, 1},  -- Azazel
      {9, 10, 1}, -- Eden
      {10, 5, 3}, -- The Lost
      {16, 7, 3}, -- The Forgotten
    },
    itemPosition1 = {
      {114, 3, 5}, -- Mom's Knife
      {395, 5, 5}, -- Tech X
      {168, 7, 5}, -- Epic Fetus
      {149, 9, 5}, -- Ipecac
    },
    itemBans = 3,
    itemPosition2 = {
      {172, 1, 1},  -- Sacrificial Dagger
      {245, 2, 1},  -- 20/20
      {261, 3, 1},  -- Proptosis
      {275, 4, 1},  -- Lil Brimstone
      {12, 5, 1},   -- Magic Mushroom
      {244, 6, 1},  -- Tech.5
      {169, 7, 1},  -- Polyphemus
      {4, 8, 1},    -- Cricket's Head
      {237, 9, 1},  -- Death's Touch
      {373, 10, 1}, -- Dead Eye
      {224, 11, 1}, -- Cricket's Body
      {52, 1, 3},   -- Dr. Fetus
      {229, 2, 3},  -- Monstro's Lung
      {311, 3, 3},  -- Judas' Shadow

      {1006, 5, 3}, -- Chocolate Milk + Steven
      {1005, 6, 3}, -- Jacob's Ladder + There's Options

      {118, 8, 3},  -- Brimstone
      {360, 9, 3},  -- Incubus
      {415, 10, 3}, -- Crown of Light
      {182, 11, 3}, -- Sacred Heart

      {1001, 1, 5}, -- Mutant Spider + The Inner Eye
      {1002, 2, 5}, -- Technology + A Lump of Coal
      {1003, 3, 5}, -- Fire Mind + Mysterious Liquid + 13 luck
    },
  },
  --[[
  R7SS = { -- R+7 Seeded
    X = 2,
    Y = 5,
    charPosition = {
      {0, 2, 1},  -- Isaac
      {1, 4, 1},  -- Magdalene
      {8, 6, 1},  -- Lazarus
      {9, 8, 1},  -- Eden
      {10, 10, 1}, -- The Lost
      {15, 5, 3},  -- Apollyon
      {16, 7, 3}, -- The Forgotten
    },
  },
  --]]
  R15V = {
    X = 10,
    Y = 5,
    charPosition = {
      {0, 1, 1},   -- Isaac
      {1, 3, 1},   -- Magdalene
      {2, 5, 1},   -- Cain
      {3, 7, 1},   -- Judas
      {4, 9, 1},   -- Blue Baby
      {5, 11, 1},  -- Eve
      {6, 1, 3},   -- Samson
      {7, 3, 3},   -- Azazel
      {8, 5, 3},   -- Lazarus
      {9, 7, 3},   -- Eden
      {10, 9, 3},  -- The Lost
      {13, 11, 3}, -- Lilith
      {14, 1, 5},  -- Keeper
      {15, 3, 5},  -- Apollyon
      {16, 11, 5}, -- The Forgotton
    },
  },
}

--
-- Variables
--

ChangeCharOrder.phase = 1 -- Reset when we enter the room
ChangeCharOrder.seasonChosen = nil -- Reset when we enter the room
ChangeCharOrder.createButtonsFrame = 0 -- Reset when we enter the room
ChangeCharOrder.charOrder = {} -- Reset when we enter the room
ChangeCharOrder.itemOrder = {} -- Reset when we enter the room
ChangeCharOrder.sprites = {} -- Reset in the PostGameStarted callback

--
-- Functions
--

-- Called from the "Speedrun:PostGameStarted()" function
function ChangeCharOrder:PostGameStarted()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local itemConfig = Isaac.GetItemConfig()

  -- Remove the D6
  player:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 106

  -- Remove the bomb
  player:AddBombs(-1)

  -- Give Isaac's some speed
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  Isaac.DebugString("Removing collectible 28 (The Belt)")
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  Isaac.DebugString("Removing collectible 28 (The Belt)")
  player:RemoveCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_BELT)) -- 28

  -- Go to the "Change Char Order" room
  Isaac.ExecuteCommand("stage 1a") -- The Cellar is the cleanest floor
  Isaac.ExecuteCommand("goto s.boss.9999")
  -- We can't use an existing boss room because after the boss is removed, a pedestal will spawn
  Isaac.DebugString("Going to the \"Change Char Order\" room.")
  -- We do more things in the "PostNewRoom" callback
end

-- Called from the "PostNewRoom:Main()" function
function ChangeCharOrder:PostNewRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndexUnsafe = level:GetCurrentRoomIndex()
  local room = game:GetRoom()
  local sfx = SFXManager()
  local challenge = Isaac.GetChallenge()
  local player = game:GetPlayer(0)

  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") or
     roomIndexUnsafe ~= GridRooms.ROOM_DEBUG_IDX then -- -3

    return
  end

  -- Stop the boss room sound effect
  sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

  -- We want to trap the player in the room, so delete all 4 doors
  for i = 0, 3 do
    room:RemoveDoor(i)
  end

  -- Put the player next to the bottom door
  player.Position = Vector(320, 400)

  -- Reset variables relating to the room and the graphics
  ChangeCharOrder.phase = 1
  ChangeCharOrder.seasonChosen = nil
  ChangeCharOrder.createButtonsFrame = 0
  ChangeCharOrder.charOrder = {}
  ChangeCharOrder.itemOrder = {}
  ChangeCharOrder.sprites = {}

  -- Spawn buttons for each type of speedrun
  -- (and a graphic over each button)
  ChangeCharOrder.sprites.buttons = {}
  for k, v in pairs(ChangeCharOrder.seasons) do
    local pos = g:GridToPos(v.X, v.Y)
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20

    ChangeCharOrder.sprites.buttons[k] = Sprite()
    ChangeCharOrder.sprites.buttons[k]:Load("gfx/speedrun/button-" .. tostring(k) .. ".anm2", true)
    ChangeCharOrder.sprites.buttons[k]:SetFrame("Default", 0)
  end
end

-- Called from the "PostRender:Main()" function
function ChangeCharOrder:CheckChangeCharOrder()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)

  -- Disable the controls or else the player will be able to move around while the screen is still black
  if gameFrameCount < 1 then
    player.ControlsEnabled = false
  else
    player.ControlsEnabled = true
  end
end

-- Called from the "CheckEntities:Grid()" function
function ChangeCharOrder:CheckButtonPressed(gridEntity)
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  if ChangeCharOrder.phase == 1 then
    -- Check to see if the season buttons were pressed
    ChangeCharOrder:CheckButtonPressed1(gridEntity)
  elseif ChangeCharOrder.phase == 2 then
    -- Check to see if the character buttons were pressed
    ChangeCharOrder:CheckButtonPressed2(gridEntity)
  elseif ChangeCharOrder.phase == 3 then
    if ChangeCharOrder.seasonChosen == "R7S4" then
      -- Check to see if the item buttons were pressed
      ChangeCharOrder:CheckButtonPressed3(gridEntity)
    else
      -- Check to see if the first item ban buttons were pressed
      ChangeCharOrder:CheckButtonPressedBan1(gridEntity)
    end
  elseif ChangeCharOrder.phase == 4 then
    -- Check to see if the second item ban buttons were pressed
    ChangeCharOrder:CheckButtonPressedBan2(gridEntity)
  end
end

-- Phase 1 corresponds to when the season buttons are present
function ChangeCharOrder:CheckButtonPressed1(gridEntity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  for k, v in pairs(ChangeCharOrder.seasons) do
    local buttonPos = g:GridToPos(v.X, v.Y)
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.Position.X == buttonPos.X and
       gridEntity.Position.Y == buttonPos.Y then

      ChangeCharOrder.phase = 2
      ChangeCharOrder.seasonChosen = k
      ChangeCharOrder:RemoveAllRoomButtons()

      -- Delete all of the season sprites
      ChangeCharOrder.sprites.buttons = {}

      -- Mark to create new buttons (for the characters) on the next frame
      ChangeCharOrder.createButtonsFrame = gameFrameCount + 1
    end
  end
end

-- Phase 2 corresponds to when the character buttons are present
function ChangeCharOrder:CheckButtonPressed2(gridEntity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local season = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]

  for i = 1, #season.charPosition do
    local posButton = g:GridToPos(season.charPosition[i][2], season.charPosition[i][3])
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.VarData == 0 and
       gridEntity.Position.X == posButton.X and
       gridEntity.Position.Y == posButton.Y then

      -- Check to see if we chose Eden first on season 6
      if ChangeCharOrder.seasonChosen == "R7S6" and
         #ChangeCharOrder.charOrder == 0 then

        if season.charPosition[i][1] == PlayerType.PLAYER_EDEN then -- 9
          player:Kill()
          Isaac.DebugString("Killing the player since they chose Eden first.")
          return
        end

        -- Break the rocks so that they can choose Eden for the second character and beyond
        room:RemoveGridEntity(25, 0, false) -- gridEntity:Destroy() does not work
        room:RemoveGridEntity(26, 0, false) -- gridEntity:Destroy() does not work
        room:RemoveGridEntity(27, 0, false) -- gridEntity:Destroy() does not work
        room:RemoveGridEntity(40, 0, false) -- gridEntity:Destroy() does not work
        room:RemoveGridEntity(42, 0, false) -- gridEntity:Destroy() does not work
        room:RemoveGridEntity(55, 0, false) -- gridEntity:Destroy() does not work
        room:RemoveGridEntity(56, 0, false) -- gridEntity:Destroy() does not work
        room:RemoveGridEntity(57, 0, false) -- gridEntity:Destroy() does not work
      end

      -- Mark that we have pressed this button already
      gridEntity.VarData = 1
      ChangeCharOrder.charOrder[#ChangeCharOrder.charOrder + 1] = season.charPosition[i][1]

      -- Change the graphic to that of a number
      ChangeCharOrder.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
      ChangeCharOrder.sprites.characters[i]:SetFrame("Default", #ChangeCharOrder.charOrder)
      ChangeCharOrder.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade

      -- Check to see if this is our last character
      if #ChangeCharOrder.charOrder == #season.charPosition then
        if ChangeCharOrder.seasonChosen == "R7S4" or
           ChangeCharOrder.seasonChosen == "R7S6" then

          -- In R+7 Season 4/6, now we have to choose our items
          ChangeCharOrder.phase = 3
          ChangeCharOrder:RemoveAllRoomButtons()

          -- Mark to create new buttons (for the items) on the next frame
          ChangeCharOrder.createButtonsFrame = gameFrameCount + 1
        else
          -- Insert the type of speedrun as the first element in the table
          table.insert(ChangeCharOrder.charOrder, 1, ChangeCharOrder.seasonChosen)

          -- We are done, so write the changes to the "save.dat" file
          g.race.charOrder = ChangeCharOrder.charOrder
          SaveDat:Save()

          -- Let the client know about the new order so that it does not overwrite it later
          Isaac.DebugString("New charOrder: " .. g:TableToString(g.race.charOrder))

          game:Fadeout(0.05, g.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end
      end
    end
  end
end

-- Phase 3 corresponds to when the item buttons are present
function ChangeCharOrder:CheckButtonPressed3(gridEntity)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local season = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]

  for i = 1, #season.itemPosition do
    local posButton = g:GridToPos(season.itemPosition[i][2], season.itemPosition[i][3])
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.VarData == 0 and
       gridEntity.Position.X == posButton.X and
       gridEntity.Position.Y == posButton.Y then

      -- Mark that we have pressed this button already
      gridEntity.VarData = 1
      ChangeCharOrder.itemOrder[#ChangeCharOrder.itemOrder + 1] = season.itemPosition[i][1]

      if #ChangeCharOrder.itemOrder == #season.charPosition then
        -- They finished choosing all the items (one for each character)
        -- Check to see if they cheated
        -- (it is possible to push two buttons at once in order to get two "big 4" items)
        local numBig4Items = 0
        for j = 1, #ChangeCharOrder.itemOrder do
          local item = ChangeCharOrder.itemOrder[j]
          if item == 114 or
             item == 395 or
             item == 168 or
             item == 149 then

            numBig4Items = numBig4Items + 1
          end
        end
        if numBig4Items > 1 then
          player:Kill()
          Isaac.DebugString("Cheating detected; killing the player.")
          return
        end

        -- Concatentate the character order and the items chosen into one big table
        g.race.charOrder = g:TableConcat(ChangeCharOrder.charOrder, ChangeCharOrder.itemOrder)

        -- Insert the type of speedrun as the first element in the table
        table.insert(ChangeCharOrder.charOrder, 1, ChangeCharOrder.seasonChosen)

        -- We are done, so write the changes to the "save.dat" file
        g.race.charOrder = ChangeCharOrder.charOrder
        SaveDat:Save()

        -- Let the client know about the new order so that it does not overwrite it later
        Isaac.DebugString("New charOrder: " .. g:TableToString(g.race.charOrder))

        game:Fadeout(0.05, g.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
      end

      -- Change the graphic to that of a number
      ChangeCharOrder.sprites.items[i]:Load("gfx/timer/timer.anm2", true)
      ChangeCharOrder.sprites.items[i]:SetFrame("Default", #ChangeCharOrder.itemOrder)

      -- Change the player sprite
      local charNum = ChangeCharOrder.charOrder[#ChangeCharOrder.itemOrder + 1]
      ChangeCharOrder.sprites.characters[1]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
      ChangeCharOrder.sprites.characters[1]:SetFrame("Death", 5) -- The 5th frame is rather interesting
      ChangeCharOrder.sprites.characters[1].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      -- Fade the character so it looks like a ghost

      if i > #season.itemPosition - season.numSClass then -- Big 4
        -- They touched an S class item, and are only allowed to choose one of those
        ChangeCharOrder:RemoveSClassButtons(i)
      end
    end
  end
end

-- Phase 3 corresponds to when the big 4 ban buttons are present
function ChangeCharOrder:CheckButtonPressedBan1(gridEntity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local season = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]

  for i = 1, #season.itemPosition1 do
    local posButton = g:GridToPos(season.itemPosition1[i][2], season.itemPosition1[i][3])
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.VarData == 0 and
       gridEntity.Position.X == posButton.X and
       gridEntity.Position.Y == posButton.Y then

      -- Mark that we have pressed this button already
      gridEntity.VarData = 1
      ChangeCharOrder.itemOrder[#ChangeCharOrder.itemOrder + 1] = season.itemPosition1[i][1]

      if #ChangeCharOrder.itemOrder == 1 then
        -- They finished banning a big 4 item

        -- Concatentate the character order and the items chosen into one big table
        g.race.charOrder = g:TableConcat(ChangeCharOrder.charOrder, ChangeCharOrder.itemOrder)

        -- Reset the items chosen
        ChangeCharOrder.itemOrder = {}

        -- Now we have to ban other items
        ChangeCharOrder.phase = 4
        ChangeCharOrder:RemoveAllRoomButtons()

        -- Mark to create new buttons (for the items) on the next frame
        ChangeCharOrder.createButtonsFrame = gameFrameCount + 1
      end
    end
  end
end

-- Phase 4 corresponds to when the non-big 4 ban buttons are present
function ChangeCharOrder:CheckButtonPressedBan2(gridEntity)
  -- Local variables
  local game = Game()
  local season = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]

  for i = 1, #season.itemPosition2 do
    local posButton = g:GridToPos(season.itemPosition2[i][2], season.itemPosition2[i][3])
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.VarData == 0 and
       gridEntity.Position.X == posButton.X and
       gridEntity.Position.Y == posButton.Y then

      -- Mark that we have pressed this button already
      gridEntity.VarData = 1
      ChangeCharOrder.itemOrder[#ChangeCharOrder.itemOrder + 1] = season.itemPosition2[i][1]

      if #ChangeCharOrder.itemOrder == season.itemBans then
        -- Concatentate the previous data and the new items chosen into one big table
        g.race.charOrder = g:TableConcat(ChangeCharOrder.charOrder, ChangeCharOrder.itemOrder)

        -- Insert the type of speedrun as the first element in the table
        table.insert(ChangeCharOrder.charOrder, 1, ChangeCharOrder.seasonChosen)

        -- We are done, so write the changes to the "save.dat" file
        g.race.charOrder = ChangeCharOrder.charOrder
        SaveDat:Save()

        -- Let the client know about the new order so that it does not overwrite it later
        Isaac.DebugString("New charOrder: " .. g:TableToString(g.race.charOrder))

        game:Fadeout(0.05, g.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
      end

      -- Change the graphic to that of a number
      ChangeCharOrder.sprites.items[i]:Load("gfx/timer/timer.anm2", true)
      ChangeCharOrder.sprites.items[i]:SetFrame("Default", #ChangeCharOrder.itemOrder)
    end
  end
end

-- Called from the "PostUpdate:Main()" function
function ChangeCharOrder:PostUpdate()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  if ChangeCharOrder.createButtonsFrame ~= 0 and
     gameFrameCount >= ChangeCharOrder.createButtonsFrame then

    ChangeCharOrder.createButtonsFrame = 0

    -- Create the character buttons
    if ChangeCharOrder.phase == 2 then
      ChangeCharOrder:CreateCharacterButtons()
    elseif ChangeCharOrder.phase == 3 then
      if ChangeCharOrder.seasonChosen == "R7S4" then
        ChangeCharOrder:CreateItemButtons()
      else
        ChangeCharOrder:CreateItemBanButtons1()
      end
    elseif ChangeCharOrder.phase == 4 then
      ChangeCharOrder:CreateItemBanButtons2()
    else
      Isaac.DebugString("ERROR: The \"ChangeCharOrder:PostUpdate()\" function was entered with a phase of: " ..
                        tostring(ChangeCharOrder.phase))
    end
  end
end

function ChangeCharOrder:CreateCharacterButtons()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local season = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]

  ChangeCharOrder.sprites.characters = {}
  for i = 1, #season.charPosition  do
    -- Spawn buttons for each characters
    local pos = g:GridToPos(season.charPosition[i][2], season.charPosition[i][3])
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20

    -- Spawn the character selection graphic next to the button
    ChangeCharOrder.sprites.characters[i] = Sprite()
    local charNum = season.charPosition[i][1]
    ChangeCharOrder.sprites.characters[i]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
    ChangeCharOrder.sprites.characters[i]:SetFrame("Death", 5) -- The 5th frame is rather interesting
    ChangeCharOrder.sprites.characters[i].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
    -- Fade the character so it looks like a ghost
  end

  -- In Season 6, we are not allowed to choose Eden for the first character
  if ChangeCharOrder.seasonChosen == "R7S6" then
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(9, 0), true) -- 17
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(10, 0), true) -- 17
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(11, 0), true) -- 17
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(9, 1), true) -- 17
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(11, 1), true) -- 17
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(9, 2), true) -- 17
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(10, 2), true) -- 17
    Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, g:GridToPos(11, 2), true) -- 17
  end

  -- Put the player next to the bottom door
  player.Position = Vector(320, 400)
end

function ChangeCharOrder:CreateItemButtons()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local itemConfig = Isaac.GetItemConfig()

  -- Make the sprite that shows what character we are choosing for
  ChangeCharOrder.sprites.characters = {}
  ChangeCharOrder.sprites.characters[1] = Sprite()
  local charNum = ChangeCharOrder.charOrder[1]
  ChangeCharOrder.sprites.characters[1]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
  ChangeCharOrder.sprites.characters[1]:SetFrame("Death", 5) -- The 5th frame is rather interesting
  ChangeCharOrder.sprites.characters[1].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
  -- Fade the character so that it looks like a ghost

  local v = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]
  ChangeCharOrder.sprites.items = {}
  for i = 1, #v.itemPosition do
    -- Spawn buttons for the all the items
    local buttonPos = g:GridToPos(v.itemPosition[i][2], v.itemPosition[i][3])
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, buttonPos, true) -- 20
    if i > #v.itemPosition - v.numSClass then -- Big 4
      -- Spawn creep for the S-Class items
      room:SetClear(false) -- Or else the creep will instantly dissipate
      for j = 1, 10 do
        local creep = game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED,
                                 buttonPos, Vector(0, 0), nil, 0, 0)
        creep:ToEffect().Timeout = 1000000
      end
    end

    -- Spawn the item selection graphics next to the buttons
    local newIndex = #ChangeCharOrder.sprites.items + 1
    ChangeCharOrder.sprites.items[newIndex] = Sprite()
    ChangeCharOrder.sprites.items[newIndex]:Load("gfx/schoolbag_item.anm2", false)
    local itemNum = v.itemPosition[i][1]
    if itemNum < 1000 then
      -- This is a single item
      local fileName = itemConfig:GetCollectible(itemNum).GfxFileName
      ChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, fileName)
    else
      -- This is a build
      ChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, "gfx/builds/" .. tostring(itemNum) .. ".png")
    end
    ChangeCharOrder.sprites.items[newIndex]:LoadGraphics()
    ChangeCharOrder.sprites.items[newIndex]:SetFrame("Default", 1)
  end

  -- Move Isaac to the center of the room
  player.Position = room:GetCenterPos()
end

function ChangeCharOrder:CreateItemBanButtons1()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local itemConfig = Isaac.GetItemConfig()

  -- Delete the character sprites
  ChangeCharOrder.sprites.characters = {}

  local v = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]
  ChangeCharOrder.sprites.items = {}
  for i = 1, #v.itemPosition1 do
    -- Spawn buttons for the all the items
    local buttonPos = g:GridToPos(v.itemPosition1[i][2], v.itemPosition1[i][3])
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, buttonPos, true) -- 20

    -- Spawn the item selection graphics next to the buttons
    local newIndex = #ChangeCharOrder.sprites.items + 1
    ChangeCharOrder.sprites.items[newIndex] = Sprite()
    ChangeCharOrder.sprites.items[newIndex]:Load("gfx/schoolbag_item.anm2", false)
    local itemNum = v.itemPosition1[i][1]
    if itemNum < 1000 then
      -- This is a single item
      local fileName = itemConfig:GetCollectible(itemNum).GfxFileName
      ChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, fileName)
    else
      -- This is a build
      ChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, "gfx/builds/" .. tostring(itemNum) .. ".png")
    end
    ChangeCharOrder.sprites.items[newIndex]:LoadGraphics()
    ChangeCharOrder.sprites.items[newIndex]:SetFrame("Default", 1)
  end

  -- Move Isaac to the center of the room
  player.Position = room:GetCenterPos()
end

function ChangeCharOrder:CreateItemBanButtons2()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local itemConfig = Isaac.GetItemConfig()

  local v = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]
  ChangeCharOrder.sprites.items = {}
  for i = 1, #v.itemPosition2 do
    -- Spawn buttons for the all the items
    local buttonPos = g:GridToPos(v.itemPosition2[i][2], v.itemPosition2[i][3])
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, buttonPos, true) -- 20

    -- Spawn the item selection graphics next to the buttons
    local newIndex = #ChangeCharOrder.sprites.items + 1
    ChangeCharOrder.sprites.items[newIndex] = Sprite()
    ChangeCharOrder.sprites.items[newIndex]:Load("gfx/schoolbag_item.anm2", false)
    local itemNum = v.itemPosition2[i][1]
    if itemNum < 1000 then
      -- This is a single item
      local fileName = itemConfig:GetCollectible(itemNum).GfxFileName
      ChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, fileName)
    else
      -- This is a build
      ChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, "gfx/builds/" .. tostring(itemNum) .. ".png")
    end
    ChangeCharOrder.sprites.items[newIndex]:LoadGraphics()
    ChangeCharOrder.sprites.items[newIndex]:SetFrame("Default", 1)
  end

  -- Put the player next to the bottom door
  player.Position = Vector(320, 400)
end

function ChangeCharOrder:RemoveAllRoomButtons()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end
    end
  end
end

-- In R+7 Season 4, remove all the S class item buttons
function ChangeCharOrder:RemoveSClassButtons(itemNum)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local v = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]

  -- Remove all of the buttons in the room
  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        for j = #v.itemPosition - v.numSClass + 1, #v.itemPosition do -- Big 4
          local itemPos = g:GridToPos(v.itemPosition[j][2], v.itemPosition[j][3])
          if gridEntity.Position.X == itemPos.X and
             gridEntity.Position.Y == itemPos.Y then

            room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
          end
        end
      end
    end
  end

  -- Remove the sprites for the last 4 items
  -- (but leave the one we just chose so that it stays as a number)
  for i = #v.itemPosition - v.numSClass + 1, #v.itemPosition do -- Big 4
    if i ~= itemNum then
      ChangeCharOrder.sprites.items[i] = Sprite()
    end
  end
end

-- Called from the PostRender callback
function ChangeCharOrder:DisplayCharSelectRoom()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  -- Render the button sprites
  if ChangeCharOrder.sprites.buttons ~= nil then
    for k, v in pairs(ChangeCharOrder.sprites.buttons) do
      if v ~= nil then
        local posButton = g:GridToPos(ChangeCharOrder.seasons[k].X, ChangeCharOrder.seasons[k].Y - 1)
        local posRender = Isaac.WorldToRenderPosition(posButton, false)
        v:RenderLayer(0, posRender)
      end
    end
  end

  -- Render the character sprites
  if ChangeCharOrder.seasonChosen == nil then
    return
  end
  local v = ChangeCharOrder.seasons[ChangeCharOrder.seasonChosen]
  if ChangeCharOrder.sprites.characters ~= nil then
    for i = 1, #ChangeCharOrder.sprites.characters do
      local posGame
      if #ChangeCharOrder.sprites.characters == 1 then
        posGame = g:GridToPos(6, 5) -- The bottom-center of the room
      else
        posGame = g:GridToPos(v.charPosition[i][2], v.charPosition[i][3] - 1)
      end

      local posRender = Isaac.WorldToRenderPosition(posGame, false)
      posRender.Y = posRender.Y + 10
      ChangeCharOrder.sprites.characters[i]:Render(posRender, Vector(0, 0), Vector(0, 0))
    end
  end

  -- Render the item sprites
  if ChangeCharOrder.sprites.items ~= nil then
    for i = 1, #ChangeCharOrder.sprites.items do
      local x, y
      if ChangeCharOrder.seasonChosen == "R7S4" then
        x = v.itemPosition[i][2]
        y = v.itemPosition[i][3]
      else
        if ChangeCharOrder.phase == 3 then
          x = v.itemPosition1[i][2]
          y = v.itemPosition1[i][3]
        elseif ChangeCharOrder.phase == 4 then
          x = v.itemPosition2[i][2]
          y = v.itemPosition2[i][3]
        end
      end

      local posGame = g:GridToPos(x, y - 1)
      local posRender = Isaac.WorldToRenderPosition(posGame, false)
      posRender.Y = posRender.Y
      ChangeCharOrder.sprites.items[i]:Render(posRender, Vector(0, 0), Vector(0, 0))
    end
  end
end

return ChangeCharOrder
