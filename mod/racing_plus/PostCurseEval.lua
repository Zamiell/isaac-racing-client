local PostCurseEval = {}

-- ModCallbacks.MC_POST_CURSE_EVAL (12)
function PostCurseEval:Main(curses)
  -- Disable all curses
  return 0
end

return PostCurseEval
