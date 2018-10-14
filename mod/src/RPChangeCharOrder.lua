local RPChangeCharOrder = {}

-- Includes
local RPGlobals = require("src/rpglobals")
local RPSaveDat = require("src/rpsavedat")

--
-- Constants
--

-- The format of "charPosition" is character number, X, Y
RPChangeCharOrder.seasons = {
  R9S1 = {
    X = 2,
    Y = 3,
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
    Y = 3,
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
    Y = 3,
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
    X = 4,
    Y = 5,
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
    X = 8,
    Y = 5,
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
  R15V = {
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
      {14, 1, 5},  -- Keeper
      {15, 3, 5},  -- Apollyon
      {16, 11, 5}, -- The Forgotton
    },
  },
}

--
-- Variables
--

RPChangeCharOrder.phase = 1 -- Reset when we enter the room
RPChangeCharOrder.seasonChosen = nil -- Reset when we enter the room
RPChangeCharOrder.createButtonsFrame = 0 -- Reset when we enter the room
RPChangeCharOrder.charOrder = {} -- Reset when we enter the room
RPChangeCharOrder.itemOrder = {} -- Reset when we enter the room
RPChangeCharOrder.sprites = {} -- Reset in the PostGameStarted callback

--
-- Functions
--

-- Called from the "RPSpeedrun:PostGameStarted()" function
function RPChangeCharOrder:PostGameStarted()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local itemConfig = Isaac.GetItemConfig()

  -- Remove the D6
  player:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 106

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

-- Called from the "RPPostNewRoom:Main()" function
function RPChangeCharOrder:PostNewRoom()
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
  RPChangeCharOrder.phase = 1
  RPChangeCharOrder.seasonChosen = nil
  RPChangeCharOrder.createButtonsFrame = 0
  RPChangeCharOrder.charOrder = {}
  RPChangeCharOrder.itemOrder = {}
  RPChangeCharOrder.sprites = {}

  -- Spawn buttons for each type of speedrun
  -- (and a graphic over each button)
  RPChangeCharOrder.sprites.buttons = {}
  for k, v in pairs(RPChangeCharOrder.seasons) do
    local pos = RPGlobals:GridToPos(v.X, v.Y)
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20

    RPChangeCharOrder.sprites.buttons[k] = Sprite()
    RPChangeCharOrder.sprites.buttons[k]:Load("gfx/speedrun/button-" .. tostring(k) .. ".anm2", true)
    RPChangeCharOrder.sprites.buttons[k]:SetFrame("Default", 0)
  end
end

-- Called from the "RPPostRender:Main()" function
function RPChangeCharOrder:CheckChangeCharOrder()
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

-- Called from the "RPCheckEntities:Grid()" function
function RPChangeCharOrder:CheckButtonPressed(gridEntity)
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  if RPChangeCharOrder.phase == 1 then
    -- Check to see if the season buttons were pressed
    RPChangeCharOrder:CheckButtonPressed1(gridEntity)
  elseif RPChangeCharOrder.phase == 2 then
    -- Check to see if the character buttons were pressed
    RPChangeCharOrder:CheckButtonPressed2(gridEntity)
  elseif RPChangeCharOrder.phase == 3 then
    -- Check to see if the item buttons were pressed
    RPChangeCharOrder:CheckButtonPressed3(gridEntity)
  end
end

-- Phase 1 corresponds to when the season buttons are present
function RPChangeCharOrder:CheckButtonPressed1(gridEntity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  for k, v in pairs(RPChangeCharOrder.seasons) do
    local buttonPos = RPGlobals:GridToPos(v.X, v.Y)
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.Position.X == buttonPos.X and
       gridEntity.Position.Y == buttonPos.Y then

      Isaac.DebugString("The " .. tostring(k) .. " button was pressed.")
      RPChangeCharOrder.phase = 2
      RPChangeCharOrder.seasonChosen = k
      RPChangeCharOrder:RemoveAllRoomButtons()

      -- Delete all of the season sprites
      RPChangeCharOrder.sprites.buttons = {}

      -- Mark to create new buttons (for the characters) on the next frame
      RPChangeCharOrder.createButtonsFrame = gameFrameCount + 1
    end
  end
end

-- Phase 2 corresponds to when the character buttons are present
function RPChangeCharOrder:CheckButtonPressed2(gridEntity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local season = RPChangeCharOrder.seasons[RPChangeCharOrder.seasonChosen]

  for i = 1, #season.charPosition do
    local posButton = RPGlobals:GridToPos(season.charPosition[i][2], season.charPosition[i][3])
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.VarData == 0 and
       gridEntity.Position.X == posButton.X and
       gridEntity.Position.Y == posButton.Y then

      Isaac.DebugString("The " .. tostring(season.charPosition[i][1]) .. " character button was pressed.")

      -- Mark that we have pressed this button already
      gridEntity.VarData = 1
      RPChangeCharOrder.charOrder[#RPChangeCharOrder.charOrder + 1] = season.charPosition[i][1]

      -- Change the graphic to that of a number
      RPChangeCharOrder.sprites.characters[i]:Load("gfx/timer/timer.anm2", true)
      RPChangeCharOrder.sprites.characters[i]:SetFrame("Default", #RPChangeCharOrder.charOrder)
      RPChangeCharOrder.sprites.characters[i].Color = Color(1, 1, 1, 1, 0, 0, 0) -- Remove the fade

      -- Check to see if this is our last character
      if #RPChangeCharOrder.charOrder == #season.charPosition then
        if RPChangeCharOrder.seasonChosen == "R7S4" then
          -- In R+7 Season 4, now we have to choose our items
          RPChangeCharOrder.phase = 3
          RPChangeCharOrder:RemoveAllRoomButtons()

          -- Mark to create new buttons (for the items) on the next frame
          RPChangeCharOrder.createButtonsFrame = gameFrameCount + 1
        else
          -- Insert the type of speedrun as the first element in the table
          table.insert(RPChangeCharOrder.charOrder, 1, RPChangeCharOrder.seasonChosen)

          -- We are done, so write the changes to the "save.dat" file
          RPGlobals.race.charOrder = RPChangeCharOrder.charOrder
          RPSaveDat:Save()

          -- Let the client know about the new order so that it does not overwrite it later
          Isaac.DebugString("New charOrder: " .. RPGlobals:TableToString(RPGlobals.race.charOrder))

          game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
        end
      end
    end
  end
end

-- Phase 3 corresponds to when the item buttons are present
function RPChangeCharOrder:CheckButtonPressed3(gridEntity)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local season = RPChangeCharOrder.seasons[RPChangeCharOrder.seasonChosen]

  for i = 1, #season.itemPosition do
    local posButton = RPGlobals:GridToPos(season.itemPosition[i][2], season.itemPosition[i][3])
    if gridEntity:GetSaveState().State == 3 and
       gridEntity.VarData == 0 and
       gridEntity.Position.X == posButton.X and
       gridEntity.Position.Y == posButton.Y then

      Isaac.DebugString("The " .. tostring(season.itemPosition[i][1]) .. " item button was pressed.")

      -- Mark that we have pressed this button already
      gridEntity.VarData = 1
      RPChangeCharOrder.itemOrder[#RPChangeCharOrder.itemOrder + 1] = season.itemPosition[i][1]

      if #RPChangeCharOrder.itemOrder == #season.charPosition then
        -- They finished choosing all the items (one for each character)
        -- Check to see if they cheated
        -- (it is possible to push two buttons at once in order to get two "big 4" items)
        local numBig4Items = 0
        for j = 1, #RPChangeCharOrder.itemOrder do
          local item = RPChangeCharOrder.itemOrder[j]
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
        RPGlobals.race.charOrder = RPGlobals:TableConcat(RPChangeCharOrder.charOrder, RPChangeCharOrder.itemOrder)

        -- Insert the type of speedrun as the first element in the table
        table.insert(RPChangeCharOrder.charOrder, 1, RPChangeCharOrder.seasonChosen)

        -- We are done, so write the changes to the "save.dat" file
        RPGlobals.race.charOrder = RPChangeCharOrder.charOrder
        RPSaveDat:Save()

        -- Let the client know about the new order so that it does not overwrite it later
        Isaac.DebugString("New charOrder: " .. RPGlobals:TableToString(RPGlobals.race.charOrder))

        game:Fadeout(0.05, RPGlobals.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
      end

      -- Change the graphic to that of a number
      RPChangeCharOrder.sprites.items[i]:Load("gfx/timer/timer.anm2", true)
      RPChangeCharOrder.sprites.items[i]:SetFrame("Default", #RPChangeCharOrder.itemOrder)

      -- Change the player sprite
      local charNum = RPChangeCharOrder.charOrder[#RPChangeCharOrder.itemOrder + 1]
      RPChangeCharOrder.sprites.characters[1]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
      RPChangeCharOrder.sprites.characters[1]:SetFrame("Death", 5) -- The 5th frame is rather interesting
      RPChangeCharOrder.sprites.characters[1].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
      -- Fade the character so it looks like a ghost

      if i > #season.itemPosition - season.numSClass then -- Big 4
        -- They touched an S class item, and are only allowed to choose one of those
        RPChangeCharOrder:RemoveSClassButtons(i)
      end
    end
  end
end

-- Called from the "RPPostUpdate:Main()" function
function RPChangeCharOrder:PostUpdate()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  if RPChangeCharOrder.createButtonsFrame ~= 0 and
     gameFrameCount >= RPChangeCharOrder.createButtonsFrame then

    RPChangeCharOrder.createButtonsFrame = 0

    -- Create the character buttons
    if RPChangeCharOrder.phase == 2 then
      RPChangeCharOrder:CreateCharacterButtons()
    elseif RPChangeCharOrder.phase == 3 then
      RPChangeCharOrder:CreateItemButtons()
    else
      Isaac.DebugString("ERROR: The \"RPChangeCharOrder:PostUpdate()\" function was entered with a phase of: " ..
                        tostring(RPChangeCharOrder.phase))
    end
  end
end

function RPChangeCharOrder:CreateCharacterButtons()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local season = RPChangeCharOrder.seasons[RPChangeCharOrder.seasonChosen]

  RPChangeCharOrder.sprites.characters = {}
  for i = 1, #season.charPosition  do
    -- Spawn buttons for each characters
    local pos = RPGlobals:GridToPos(season.charPosition[i][2], season.charPosition[i][3])
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20

    -- Spawn the character selection graphic next to the button
    local index = #RPChangeCharOrder.sprites.characters + 1
    RPChangeCharOrder.sprites.characters[index] = Sprite()
    local charNum = season.charPosition[i][1]
    RPChangeCharOrder.sprites.characters[index]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
    RPChangeCharOrder.sprites.characters[index]:SetFrame("Death", 5) -- The 5th frame is rather interesting
    RPChangeCharOrder.sprites.characters[index].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
    -- Fade the character so it looks like a ghost
  end

  -- Put the player next to the bottom door
  player.Position = Vector(320, 400)
end

function RPChangeCharOrder:CreateItemButtons()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local itemConfig = Isaac.GetItemConfig()

  -- Make the sprite that shows what character we are choosing for
  RPChangeCharOrder.sprites.characters = {}
  RPChangeCharOrder.sprites.characters[1] = Sprite()
  local charNum = RPChangeCharOrder.charOrder[1]
  RPChangeCharOrder.sprites.characters[1]:Load("gfx/custom/characters/" .. tostring(charNum) .. ".anm2", true)
  RPChangeCharOrder.sprites.characters[1]:SetFrame("Death", 5) -- The 5th frame is rather interesting
  RPChangeCharOrder.sprites.characters[1].Color = Color(1, 1, 1, 0.5, 0, 0, 0)
  -- Fade the character so that it looks like a ghost

  local v = RPChangeCharOrder.seasons[RPChangeCharOrder.seasonChosen]
  RPChangeCharOrder.sprites.items = {}
  for i = 1, #v.itemPosition do
    -- Spawn buttons for the all the items
    local buttonPos = RPGlobals:GridToPos(v.itemPosition[i][2], v.itemPosition[i][3])
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
    local newIndex = #RPChangeCharOrder.sprites.items + 1
    RPChangeCharOrder.sprites.items[newIndex] = Sprite()
    RPChangeCharOrder.sprites.items[newIndex]:Load("gfx/schoolbag_item.anm2", false)
    local itemNum = v.itemPosition[i][1]
    if itemNum < 1000 then
      -- This is a single item
      local fileName = itemConfig:GetCollectible(itemNum).GfxFileName
      RPChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, fileName)
    else
      -- This is a build
      RPChangeCharOrder.sprites.items[newIndex]:ReplaceSpritesheet(0, "gfx/builds/" .. tostring(itemNum) .. ".png")
    end
    RPChangeCharOrder.sprites.items[newIndex]:LoadGraphics()
    RPChangeCharOrder.sprites.items[newIndex]:SetFrame("Default", 1)
  end

  -- Move Isaac to the center of the room
  player.Position = room:GetCenterPos()
end

function RPChangeCharOrder:RemoveAllRoomButtons()
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
function RPChangeCharOrder:RemoveSClassButtons(itemNum)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local v = RPChangeCharOrder.seasons[RPChangeCharOrder.seasonChosen]

  -- Remove all of the buttons in the room
  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        for j = #v.itemPosition - v.numSClass + 1, #v.itemPosition do -- Big 4
          local itemPos = RPGlobals:GridToPos(v.itemPosition[j][2], v.itemPosition[j][3])
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
      RPChangeCharOrder.sprites.items[i] = Sprite()
    end
  end
end

-- Called from the PostRender callback
function RPChangeCharOrder:DisplayCharSelectRoom()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then
    return
  end

  -- Render the button sprites
  if RPChangeCharOrder.sprites.buttons ~= nil then
    for k, v in pairs(RPChangeCharOrder.sprites.buttons) do
      if v ~= nil then
        local posButton = RPGlobals:GridToPos(RPChangeCharOrder.seasons[k].X, RPChangeCharOrder.seasons[k].Y - 1)
        local posRender = Isaac.WorldToRenderPosition(posButton, false)
        v:RenderLayer(0, posRender)
      end
    end
  end

  -- Render the character sprites
  if RPChangeCharOrder.seasonChosen == nil then
    return
  end
  local v = RPChangeCharOrder.seasons[RPChangeCharOrder.seasonChosen]
  if RPChangeCharOrder.sprites.characters ~= nil then
    for i = 1, #RPChangeCharOrder.sprites.characters do
      local posGame
      if #RPChangeCharOrder.sprites.characters == 1 then
        posGame = RPGlobals:GridToPos(6, 5) -- The bottom-center of the room
      else
        posGame = RPGlobals:GridToPos(v.charPosition[i][2], v.charPosition[i][3] - 1)
      end

      local posRender = Isaac.WorldToRenderPosition(posGame, false)
      posRender.Y = posRender.Y + 10
      RPChangeCharOrder.sprites.characters[i]:Render(posRender, Vector(0, 0), Vector(0, 0))
    end
  end

  -- Render the item sprites
  if RPChangeCharOrder.sprites.items ~= nil then
    for i = 1, #RPChangeCharOrder.sprites.items do
      local posGame = RPGlobals:GridToPos(v.itemPosition[i][2], v.itemPosition[i][3] - 1)
      local posRender = Isaac.WorldToRenderPosition(posGame, false)
      posRender.Y = posRender.Y
      RPChangeCharOrder.sprites.items[i]:Render(posRender, Vector(0, 0), Vector(0, 0))
    end
  end
end

return RPChangeCharOrder
