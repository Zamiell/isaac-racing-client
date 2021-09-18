-- Racing+ enables --luadebug, so it also provides this sandbox to prevent other mods from doing
-- evil things

-- Constants
local HOSTNAME = "localhost"

-- Import the socket module for our own usage before we gimp the "require()" function
local socket = nil
local ok, requiredSocket = pcall(require, "socket")
if ok then
  socket = requiredSocket
end

-- Make a copy of some objects
local localDebug = debug

local sandbox = {}

function sandbox.init()
  sandbox.init = nil
  if socket == nil then
    Isaac.DebugString("The sandbox could not initialize because the \"--luadebug\" flag was not enabled.")
    return
  end

  sandbox.removeDangerousGlobals()
  sandbox.removeDangerousPackageFields()
  sandbox.sanitizeRequireFunction()
  sandbox.fixPrintFunction()
end

function sandbox.removeDangerousGlobals()
  debug = nil -- luacheck: ignore
  dump = nil -- luacheck: ignore
  io = nil -- luacheck: ignore
  loadfile = nil -- luacheck: ignore
  os = nil -- luacheck: ignore
end

function sandbox.removeDangerousPackageFields()
  -- Setting the entire package variable to nil will make Isaac crash on load,
  -- so we have to be more granular with what we remove
  package.loadlib = nil  -- luacheck: ignore
end

function sandbox.sanitizeRequireFunction()
  -- We can sanitize the "require()" function by removing searcher functions
  -- https://www.lua.org/manual/5.3/manual.html#pdf-package.searchers
  package.searchers[3] = nil -- Remove the loader function that is intended for C libraries
  package.searchers[4] = nil -- Remove the loader function that is the all-in-one loader
end

function sandbox.fixPrintFunction()
  -- When "--luadebug" is enabled,
  -- the "print()" function will no longer map to "Isaac.ConsoleOutput()"
  -- Manually fix this
  print = function(...) -- luacheck: ignore
    local msg = sandbox.getPrintMsg(...)

    -- First, write it to the log.txt
    Isaac.DebugString(msg)

    -- Second, write it to the console
    -- (this needs to be terminated by a newline or else it won't display properly)
    local msgWithNewline = msg .. "\n"
    Isaac.ConsoleOutput(msgWithNewline)
  end
end

function sandbox.getPrintMsg(...)
  -- Base case
  if ... == nil then
    return tostring(nil)
  end

  local args = {...}
  local msg = ""
  for _, arg in ipairs(args) do
    -- Separate multiple arguments with a space
    -- (a tab character appears as a circle, which is unsightly)
    if msg ~= "" then
      msg = msg .. " "
    end

    local valueToPrint
    local metatable = getmetatable(arg)
    local isVector = metatable ~= nil and metatable.__type == "Vector"
    if isVector then
      -- Provide special formatting for Vectors
      valueToPrint = "Vector(" .. tostring(arg.X) .. ", " .. tostring(arg.Y) .. ")"
    else
      -- By default, simply coerce the argument to a string, whatever it is
      valueToPrint = tostring(arg)
    end

    msg = msg .. valueToPrint
  end

  return msg
end

--
-- Exports
--

function sandbox.isSocketInitialized()
  return socket ~= nil
end

function sandbox.connectLocalhost(port, useTCP)
  if port == nil then
    Isaac.DebugString(
      "Error: The \"connectLocalhost()\" function requires a port as the first argument."
    )
    return nil
  end

  local protocol = "UDP";
  if useTCP == true then
    protocol = "TCP"
  end

  if socket == nil then
    Isaac.DebugString("Error: Failed to connect because the socket library is not initialized.")
    return nil
  end

  local socketClient
  if protocol == "TCP" then
    socketClient = socket.tcp()
    socketClient:settimeout(0.0001) -- 100 microseconds
    local err, errMsg = socketClient:connect(HOSTNAME, port)
    if err ~= 1 then
      if errMsg == "timeout" then
        Isaac.DebugString(protocol .. " socket server was not present on port: " .. tostring(port))
      else
        Isaac.DebugString(
          "Error: Failed to connect via " .. protocol .. " for \"" .. HOSTNAME .. "\" "
          .. "on port " .. tostring(port) .. ": " .. errMsg
        )
      end

      return nil
    end
  elseif protocol == "UDP" then
    socketClient = socket.udp()
    local err, errMsg = socketClient:setpeername(HOSTNAME, port)
    if err ~= 1 then
      Isaac.DebugString(
        "Error: Failed to connect via " .. protocol .. " for \"" .. HOSTNAME .. "\" "
        .. "on port " .. tostring(port) .. ": " .. errMsg
      )

      return nil
    end
  end

  local isaacFrameCount = Isaac.GetFrameCount()
  Isaac.DebugString(
    "Connected via " .. protocol .. " for \"" .. HOSTNAME .. "\" on port " .. tostring(port) ..
    " (on Isaac frame " .. tostring(isaacFrameCount) .. ")."
  )
  return socketClient
end

function sandbox.traceback()
  if localDebug == nil then
    Isaac.DebugString("traceback was called but the \"--luadebug\" flag was not enabled.")
  end

  local traceback = localDebug.traceback()
  Isaac.DebugString(traceback)
end

-- Also make it a global variable
traceback = sandbox.traceback -- luacheck: ignore

function sandbox.getParentFunctionDescription(levels)
  if levels == nil then
    error("The getParentFunctionDescription function requires the amount of levels to look backwards.")
  end

  if localDebug == nil then
    return ""
  end

  local debugTable = localDebug.getinfo(levels)
  if debugTable == nil then
    return ""
  end
  if debugTable.name == nil then
    debugTable.name = "unknown"
  end

  return debugTable.name .. ":" .. tostring(debugTable.linedefined)
end

-- Also make it a global variable
getParentFunctionDescription = sandbox.getParentFunctionDescription -- luacheck: ignore

return sandbox
