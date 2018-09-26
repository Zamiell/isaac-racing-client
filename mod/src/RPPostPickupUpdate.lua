local RPPostPickupUpdate = {}

-- Includes
local RPPostPickupInit = require("src/rppostpickupinit")

-- ModCallbacks.MC_POST_PICKUP_UPDATE (35)
function RPPostPickupUpdate:Main(pickup)
  -- We only care about cards and runes
  if pickup.Variant ~= PickupVariant.PICKUP_TAROTCARD then -- 300
    return
  end

  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()

   -- We only care about cards in a shop
   if roomType ~= RoomType.ROOM_SHOP then -- 2
     return
   end

   -- We only care about cards that are already initialized
   -- (checking on frame 0 does not work, so it has to be frame 1)
   if pickup.FrameCount ~= 1 then
     return
   end

   -- Turn cards face up that are not for sale
   if pickup.Price == 0 then
     Isaac.DebugString("Set a card to be face up in a shop.")
     RPPostPickupInit:CardFaceUp(pickup)
   else
     Isaac.DebugString("Ignored a card in a shop.")
   end
end

return RPPostPickupUpdate
