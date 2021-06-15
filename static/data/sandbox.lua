-- Racing+ enables --luadebug, so it also provides this sandbox to prevent other mods from doing
-- evil things

-- Import the socket module for our own usage before we gimp the "require()" function
local socket = nil
local ok, requiredSocket = pcall(require, "socket")
if ok then
  socket = requiredSocket
end

local sandbox = {}

function sandbox.init()
  sandbox.removeDangerousPackageFields()
  sandbox.removeDangerousPackageFields()
  sandbox.sanitizeRequireFunction()
  sandbox.fixPrintFunction()
  sandbox.init = nil
end

function sandbox.removeDangerousGlobals()
  debug = nil -- luacheck: ignore
  dump = nil -- luacheck: ignore
  io = nil -- luacheck: ignore
  load = nil -- luacheck: ignore
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
  -- the "print()" function will no longer map to"Isaac.ConsoleOutput()"
  -- Manually fix this
  print = function(msg) -- luacheck: ignore
    Isaac.ConsoleOutput(tostring(msg))
  end
end

function sandbox.isSocketInitialized()
  return socket ~= nil
end

--
-- Exposed socket functionality
--

-- Constants
local HOSTNAME = "localhost"

function sandbox.connectLocalhost(port)
  if port == nil then
    Isaac.DebugString("Error: The \"connectLocalhost()\" function requires a port as the first argument.")
    return nil
  end

  if socket == nil then
    Isaac.DebugString("Error: Failed to connect because the socket library is not initialized.")
    return nil
  end

  local tcp = socket.tcp()
  tcp:settimeout(0.001) -- 1 millisecond
  local err, errMsg = tcp:connect(HOSTNAME, port)
  if err ~= 1 then
    Isaac.DebugString(
      "Error: Failed to connect to \"" .. HOSTNAME .. "\" on port " .. tostring(port) .. ": " .. errMsg
    )
    return nil
  end

  Isaac.DebugString("Connected to " .. HOSTNAME .. " on port " .. tostring(port) .. ".")
  return tcp
end

return sandbox
