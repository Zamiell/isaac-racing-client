local PostCurseEval = {}

-- ModCallbacks.MC_POST_CURSE_EVAL (12)
function PostCurseEval:Main(curses)
  -- Disable all curses
  Isaac.DebugString("Disabling curse: " .. tostring(curses))
  return 0
end

return PostCurseEval
