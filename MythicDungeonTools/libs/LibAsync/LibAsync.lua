-- Legion-compatible coroutine scheduler (replaces retail LibAsync)
local _MAJOR = "LibAsync"
local _MINOR = 1

local LibAsync
if LibStub then
  LibAsync = LibStub:NewLibrary(_MAJOR, _MINOR)
else
  LibAsync = {}
end
if not LibAsync then return end

local handlers = {}
local handlerCount = 0

local function resumeCoroutine(co, errorHandler, name)
  local ok, err = coroutine.resume(co)
  if not ok then
    if errorHandler then
      errorHandler(tostring(err), debugstack(co), name)
    else
      geterrorhandler()(tostring(err))
    end
    return false
  end
  return coroutine.status(co) ~= "dead"
end

local function createHandler(config)
  handlerCount = handlerCount + 1
  local handler = {
    tasks = {},
    frame = CreateFrame("Frame", "LibAsyncFrame"..handlerCount),
    maxTime = (config and config.maxTime) or 40,
    errorHandler = config and config.errorHandler,
  }

  handler.frame:SetScript("OnUpdate", function()
    local startMs = GetTime() * 1000
    for name, task in pairs(handler.tasks) do
      while task.co and coroutine.status(task.co) ~= "dead" do
        if not resumeCoroutine(task.co, handler.errorHandler, name) then
          task.co = nil
          break
        end
        if (GetTime() * 1000) - startMs >= handler.maxTime then
          return
        end
      end
      if not task.co or coroutine.status(task.co) == "dead" then
        handler.tasks[name] = nil
      end
    end
  end)

  function handler:Async(func, name, singleton)
    if singleton and self.tasks[name] then return end
    local co = coroutine.create(func)
    self.tasks[name] = { co = co }
    if not resumeCoroutine(co, self.errorHandler, name) then
      self.tasks[name] = nil
    end
  end

  function handler:CancelAsync(name)
    if not name then return end
    self.tasks[name] = nil
  end

  return handler
end

function LibAsync:GetHandler(config)
  local key = tostring(config or "default")
  if not handlers[key] then
    handlers[key] = createHandler(config)
  end
  return handlers[key]
end
