local PotatoDummy = {}

-- Includes
local g = require("racing_plus/globals")

local TargetEntity = Isaac.GetEntityTypeByName("Potato Dummy")

local PotatoEntity = nil -- la ou sera le mob
local	PotatoRoom         -- la piece ou se trouve la patate
local PotatoModel = 1    -- le visuel de la patate

local textAlpha = 1.0
local textHitAlpha = 1.0
local textDelay = 60
local textShow  = true

local textMaxAlpha = 1.0
local textMaxDelay = 60
local textMaxShow  = false

local hurtframe = 0
local currentDPS = 0
local maxDPS = 0
local dpstime = 0
local damagedone = 0
local hitdamage = 0
local hitpos = Vector(0,0)

local jackpot = false
local sfont = nil

function PotatoDummy:WriteText(text, px, py, center, colr, colv, colb, cola)
  local fontw = 6
  local ch

  if sfont == nil then
    sfont = Sprite()
    sfont:Load("gfx/potato/SinstharFonts.anm2", true)
    sfont:Play("Idle")
  end

  if center == true then
    px = px - ((string.len(text) * fontw) / 2) + (fontw/2)
  end

  sfont.Color = Color(colr, colv, colb, cola, 0, 0, 0)

  for i=1, string.len(text) do
    ch = string.byte(text,i) - 32
    sfont:SetLayerFrame(0,ch)
    sfont:Render(Vector(px + ((i-1)*fontw), py), Vector(0,0), Vector(0,0))
  end
end

function PotatoDummy:PostRender()
  if PotatoEntity == nil then
    return
  end

  local tpos
  local msg

  if textShow == true then
    tpos = Isaac.WorldToRenderPosition(PotatoEntity.Position, false)

    msg = string.format("%.1f", currentDPS).." DPS"

    if (dpstime == 0) then msg = ""
    elseif (dpstime == 1) then msg = "!"
    elseif (dpstime == 2) then msg = "!!"
    elseif (dpstime == 3) then msg = "!!!" end

    -- hit
    if hitdamage > 0 then
      PotatoDummy:WriteText(
        string.format("%.1f", hitdamage),
        tpos.X + hitpos.X,
        tpos.Y - 55 - hitpos.Y,
        true,
        1,
        0.6,
        0.6,
        textHitAlpha
      )
      textHitAlpha = textHitAlpha - 0.033
    end

    PotatoDummy:WriteText(msg, tpos.X, tpos.Y-45, true, 1, 1, 1, textAlpha)
    -- apres un delai on le fait disparaitre
    textDelay = textDelay - 1

    if (textDelay <= 0) then -- fade le texte
      textAlpha = textAlpha - 0.033
    end
  end

  if (textAlpha <= 0) then -- le texte du DPS a disparut
    textAlpha = 1.0
    textShow = false
    textDelay = 60
    textMaxShow = true
    damagedone = 0
  end

  -- ICI : affiche le dps max
  if (textMaxShow == true) then
    tpos = Isaac.WorldToRenderPosition(PotatoEntity.Position, false)

    if (maxDPS > 0) then
      msg = string.format("%.1f",maxDPS).." Dps"

      PotatoDummy:WriteText("BEST", tpos.X, tpos.Y-55, true, 1, 1, 0.1, textMaxAlpha)
      PotatoDummy:WriteText(msg, tpos.X, tpos.Y-45, true, 1, 1, 0.1, textMaxAlpha)
    end

    textMaxDelay = textMaxDelay - 1

    if textMaxDelay <= 0 then -- fade le texte
      textMaxAlpha = textMaxAlpha - 0.01
    end
  end

  if textMaxAlpha <= 0 then -- le texte du DPS a disparut
    textMaxAlpha = 1.0
    textMaxShow = false
    textMaxDelay = 60
  end
end

function PotatoDummy:PotatoChange()
  local sprite = PotatoEntity:GetSprite()

  -- change le visu de la patate si on a atteint le seuil de dps
  if (PotatoModel < 7) and (maxDPS > 100000) then
    sprite:ReplaceSpritesheet(0,"gfx/potato/potato7.png")
    sprite:LoadGraphics()
    PotatoModel = 7
    PotatoEntity.HitPoints = (PotatoEntity.MaxHitPoints / 7) * 7
    if jackpot == false then
      Isaac.Spawn(1000, 104, 0, PotatoEntity.Position, Vector(0, 0), Isaac.GetPlayer(0))
      jackpot = true
    end
  elseif (PotatoModel < 6) and (maxDPS > 20000) then
    sprite:ReplaceSpritesheet(0,"gfx/potato/potato6.png")
    sprite:LoadGraphics()
    PotatoModel = 6
    PotatoEntity.HitPoints = (PotatoEntity.MaxHitPoints / 7) * 6
  elseif (PotatoModel < 5) and (maxDPS > 4000) then
    sprite:ReplaceSpritesheet(0,"gfx/potato/potato5.png")
    sprite:LoadGraphics()
    PotatoModel = 5
    PotatoEntity.HitPoints = (PotatoEntity.MaxHitPoints / 7) * 5
  elseif (PotatoModel < 4) and (maxDPS > 400) then
    sprite:ReplaceSpritesheet(0,"gfx/potato/potato4.png")
    sprite:LoadGraphics()
    PotatoModel = 4
    PotatoEntity.HitPoints = (PotatoEntity.MaxHitPoints / 7) * 4
  elseif (PotatoModel < 3) and (maxDPS > 100) then
    sprite:ReplaceSpritesheet(0,"gfx/potato/potato3.png")
    sprite:LoadGraphics()
    PotatoModel = 3
    PotatoEntity.HitPoints = (PotatoEntity.MaxHitPoints / 7) * 3
  elseif (PotatoModel < 2) and (maxDPS > 30) then
    sprite:ReplaceSpritesheet(0,"gfx/potato/potato2.png")
    sprite:LoadGraphics()
    PotatoModel = 2
    PotatoEntity.HitPoints = (PotatoEntity.MaxHitPoints / 7) * 2
  end
end

function PotatoDummy:EntityTakeDmg(ent, dmg, flags, source, countdown)
  if ent.Variant ~= 2 then
    return
  end

  local sprite = ent:GetSprite()
  -- change la couleur
  ent.Color = Color(1,1,1,1,200,1,1)
  hurtframe = ent.FrameCount

  if sprite:IsPlaying("Hurt") == false then
    ent:ToNPC():PlaySound(60, 0.5, 60, false, 1)
  end
  sprite:SetAnimation ("Hurt")
  sprite:Play("Hurt", true)
  textDelay = 60
  textAlpha = 1.0
  textHitAlpha = 1.0
  textMaxAlpha = 0 -- efface le meilleur
  textShow = true
  damagedone = damagedone + dmg -- ajoute les degats
  hitdamage = dmg
  hitpos = Vector(math.random(0,10) - 5, math.random(0, 10))
  PotatoDummy:PotatoChange()
  return false
end

function PotatoDummy:PostUpdate()
  local player = Isaac.GetPlayer(0)

  if (player.FrameCount <= 3) then -- après init
    return
  end

  if (PotatoEntity ~= nil) then -- si on a une patate
    -- detruit la patate si pas dans la bonne piece, ou bien si la patate est moisie
    if (g.l:GetCurrentRoomIndex() ~= PotatoRoom) then
      PotatoEntity:Remove()
      PotatoEntity = nil;
      return
    end

    -- remet la couleur de base
    if (PotatoEntity.FrameCount > hurtframe+1) then
      PotatoEntity.Color = Color(1,1,1,1,1,1,1)
    end

    -- calcul les degats subis en 1 sec
    if (player.FrameCount % 30 == 0) then
      if (damagedone > 0) then
        dpstime = dpstime + 1
        currentDPS = (damagedone / dpstime)
        if (dpstime > 3) then maxDPS = math.max(maxDPS, currentDPS) end
      else -- aucun dommage
        dpstime = 0
      end
    end

    -- supprime les loots qui peuvent apparaitre
    local entities = Isaac.GetRoomEntities()
    local dist

    for i = 1, #entities do
      dist = entities[i].Position:Distance(PotatoEntity.Position)

      if (dist < 80) and (entities[i].Type == 5) and (entities[i].Variant == 20) and (entities[i].FrameCount < 2) then
        entities[i]:Remove()
      end
    end
  end
end

function PotatoDummy:PostGameStarted()
  PotatoEntity = nil
  PotatoModel = 1
  textShow = false
  textMaxShow = false
  maxDPS = 0
end

function PotatoDummy:Spawn()
  -- la variante déconne plus avec ca flags
  PotatoEntity = g.g:Spawn(TargetEntity,2, g.r:GetCenterPos(), Vector(0,0), g.p, 1, 1)
  PotatoEntity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS) -- aucun statuts negatif
  PotatoEntity.HitPoints = (PotatoEntity.MaxHitPoints / 7)
  PotatoRoom = g.l:GetCurrentRoomIndex()
  PotatoModel = math.max(1,PotatoModel-1) -- force le changement
  PotatoDummy:PotatoChange()
  dpstime = 0
  currentDPS = 0
  textMaxAlpha = 1.0
  textMaxDelay = 60
  textShow = true -- montre le dps max (en cas de retour dans la salle)
end

function PotatoDummy:PostNewRoom()
  textShow = false
  textMaxShow = false
end

return PotatoDummy
