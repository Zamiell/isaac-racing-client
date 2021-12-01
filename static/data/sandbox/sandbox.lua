-- Racing+ enables --luadebug, so it also provides this sandbox to prevent other mods from doing
-- evil things

-- Constants
local LOCALHOST = "127.0.0.1" -- A string of "localhost" does not work
local TIMEOUT_SECONDS = 0.001 -- 1 millisecond
local UNSAFE_IMPORTS = {
  "debug",
  "dump",
  "io",
  "loadfile",
  "os",
  "socket",
}

-- Import the socket module for our own usage before we modify the "require()" function
local socket = nil
local ok, requiredSocket = pcall(require, "socket")
if ok then
  socket = requiredSocket
end

-- Make a copy of some globals
local originalDebug = debug
local originalDofile = dofile
local originalInclude = include
local originalRequire = require

--
-- Local functions
--

local function includes(array, value)
  for _, element in ipairs(array) do
    if element == value then
      return true
    end
  end

  return false
end

-- From TypeScriptToLua
local function stringTrim(str)
  local result = string.gsub(str, "^[%s ﻿]*(.-)[%s ﻿]*$", "%1")
  return result
end

-- From: https://stackoverflow.com/questions/1426954/split-string-in-lua
local function stringSplit(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end

  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end

  return t
end

local function validatePath(path)
  path = stringTrim(path)
  local splitWithPeriods = stringSplit(path, ".")
  local finalPartOfPathWithPeriods = splitWithPeriods[#splitWithPeriods]
  local splitWithSlashes = stringSplit(path, "/")
  local finalPartOfPathWithSlashes = splitWithSlashes[#splitWithSlashes]

  return not (
    includes(UNSAFE_IMPORTS, path)
    or includes(UNSAFE_IMPORTS, finalPartOfPathWithPeriods)
    or includes(UNSAFE_IMPORTS, finalPartOfPathWithSlashes)
  )
end

local function safeDofile(path)
  if not validatePath(path) then
    error("dofiling " .. path .. " is not allowed")
  end

  return originalDofile(path)
end

local function safeInclude(path)
  if not validatePath(path) then
    error("including " .. path .. " is not allowed")
  end

  return originalInclude(path)
end

local function safeRequire(path)
  if not validatePath(path) then
    error("requiring " .. path .. " is not allowed")
  end

  return originalRequire(path)
end

--
-- Sandbox
--

local sandbox = {}

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

  -- Prevent requiring some of the standard library
  dofile = safeDofile
  include = safeInclude
  require = safeRequire
end

function sandbox.setSomeSandboxFunctionsGlobal()
  sandboxTraceback = sandbox.traceback -- luacheck: ignore
  sandboxGetTraceback = sandbox.getTraceback -- luacheck: ignore
  getParentFunctionDescription = sandbox.getParentFunctionDescription -- luacheck: ignore
end

--
-- Exports
--

function sandbox.init()
  sandbox.init = nil
  if socket == nil then
    Isaac.DebugString(
      "The sandbox could not initialize because the \"--luadebug\" flag was not enabled."
    )
    return
  end

  sandbox.removeDangerousGlobals()
  sandbox.removeDangerousPackageFields()
  sandbox.sanitizeRequireFunction()
  sandbox.setSomeSandboxFunctionsGlobal()
end

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
    socketClient:settimeout(TIMEOUT_SECONDS)
    local err, errMsg = socketClient:connect(LOCALHOST, port)
    if err ~= 1 then
      if errMsg == "timeout" then
        Isaac.DebugString(protocol .. " socket server was not present on port: " .. tostring(port))
      else
        Isaac.DebugString(
          "Error: Failed to connect via " .. protocol .. " for \"" .. LOCALHOST .. "\" "
          .. "on port " .. tostring(port) .. ": " .. errMsg
        )
      end

      return nil
    end
  elseif protocol == "UDP" then
    socketClient = socket.udp()
    local err, errMsg = socketClient:setpeername(LOCALHOST, port)
    if err ~= 1 then
      Isaac.DebugString(
        "Error: Failed to connect via " .. protocol .. " for \"" .. LOCALHOST .. "\" "
        .. "on port " .. tostring(port) .. ": " .. errMsg
      )

      return nil
    end
  end

  local isaacFrameCount = Isaac.GetFrameCount()
  local localAddress, localPort = socketClient:getsockname()
  Isaac.DebugString(
    "Connected via " .. protocol .. " "
    .. "on local address " .. tostring(localAddress) .. ":" .. tostring(localPort) .. " "
    .. "and remote address " .. LOCALHOST .. ":" .. tostring(port) .. " "
    .. "(on Isaac frame " .. tostring(isaacFrameCount) .. ")."
  )
  return socketClient
end

function sandbox.traceback()
  local traceback = sandbox.getTraceback();
  if traceback ~= "" then
    Isaac.DebugString(tracebackMsg)
  end
end

function sandbox.getTraceback()
  if originalDebug == nil then
    Isaac.DebugString("Error: getTraceback was called but the \"--luadebug\" flag was not enabled.")
    return ""
  end

  return originalDebug.traceback()
end

function sandbox.getParentFunctionDescription(levels)
  if levels == nil then
    error("The getParentFunctionDescription function requires the amount of levels to look backwards.")
  end

  if originalDebug == nil then
    return ""
  end

  local debugTable = originalDebug.getinfo(levels)
  if debugTable == nil then
    return ""
  end
  if debugTable.name == nil then
    debugTable.name = "unknown"
  end

  return debugTable.name .. ":" .. tostring(debugTable.linedefined)
end

return {
  init = sandbox.init,
  isSocketInitialized = sandbox.isSocketInitialized,
  connectLocalhost = sandbox.connectLocalhost,
  traceback = sandbox.traceback,
  getTraceback = sandbox.getTraceback,
  getParentFunctionDescription = sandbox.getParentFunctionDescription,
}
