# Extending the Dialogue Framework

This guide covers how to add advanced features to the Ink-inspired dialogue framework. All the features listed here are designed as natural extensions of the existing architecture.

## Table of Contents

1. [Adding Advanced Ink Features](#adding-advanced-ink-features)
2. [Custom UI Components](#custom-ui-components)
3. [Tag System Implementation](#tag-system-implementation)
4. [Save/Load System](#saveload-system)
5. [Function Calls from Stories](#function-calls-from-stories)
6. [Threading and Tunnels](#threading-and-tunnels)

---

## Adding Advanced Ink Features

### Sequences (Cycling Content)

Sequences let content change on repeated visits. Add to `story_helpers.lua`:

```lua
function StoryHelpers.sequence(...)
  local items = {...}
  return {
    type = "sequence",
    items = items,
    mode = "cycle"  -- or "once", "stopping", "shuffle"
  }
end
```

Then in `dialogue.lua`, add handling in `getNext()`:

```lua
elseif content_type == "sequence" then
  local visit_count = self:getKnotVisitCount(self.current_knot)
  local index = (visit_count % #content.items) + 1
  
  if content.mode == "stopping" then
    index = math.min(visit_count + 1, #content.items)
  elseif content.mode == "once" then
    if visit_count > 0 then
      self.current_index = self.current_index + 1
      return self:getNext()
    end
    index = 1
  elseif content.mode == "shuffle" then
    -- Implement random selection with tracking
  end
  
  self.current_index = self.current_index + 1
  return {type = "text", content = content.items[index]}
```

Usage in stories:

```lua
{
  helpers.sequence(
    "First time here.",
    "Second time.",
    "Third and subsequent times."
  )
}
```

### Tunnels (Temporary Diverts)

Tunnels jump to content then return. Add to `dialogue.lua`:

```lua
function Dialogue:tunnel(target_knot)
  -- Save return position
  table.insert(self.tunnel_stack, {
    knot = self.current_knot,
    index = self.current_index
  })
  
  self:divertTo(target_knot)
end

function Dialogue:returnFromTunnel()
  if #self.tunnel_stack > 0 then
    local return_pos = table.remove(self.tunnel_stack)
    self.current_knot = return_pos.knot
    self.current_index = return_pos.index
  end
end
```

Add `tunnel_stack = {}` to `Dialogue.new()`.

Add helper:

```lua
function StoryHelpers.tunnel(target)
  return {type = "tunnel", target = target}
end

function StoryHelpers.return_from_tunnel()
  return {type = "return"}
end
```

Handle in `getNext()`:

```lua
elseif content_type == "tunnel" then
  self:tunnel(content.target)
  return self:getNext()
  
elseif content_type == "return" then
  self:returnFromTunnel()
  return self:getNext()
```

---

## Custom UI Components

### Portrait Component

Display character images alongside dialogue.

Create in `dialogue_ui.lua`:

```lua
local Portrait = setmetatable({}, {__index = Component})
Portrait.__index = Portrait

function Portrait:new(config)
  local obj = Component.new(self)
  
  obj.x = config.x or 50
  obj.y = config.y or 50
  obj.width = config.width or 200
  obj.height = config.height or 200
  
  obj.current_image = nil
  obj.images = config.images or {}  -- {character_name = image}
  obj.fade_speed = config.fade_speed or 2
  obj.alpha = 0
  
  return obj
end

function Portrait:setCharacter(name)
  if self.images[name] then
    self.current_image = self.images[name]
    self.alpha = 0  -- Fade in
  else
    self.current_image = nil
  end
end

function Portrait:update(dt)
  if self.current_image and self.alpha < 1 then
    self.alpha = math.min(1, self.alpha + self.fade_speed * dt)
  elseif not self.current_image and self.alpha > 0 then
    self.alpha = math.max(0, self.alpha - self.fade_speed * dt)
  end
end

function Portrait:draw()
  if self.visible and self.current_image and self.alpha > 0 then
    love.graphics.setColor(1, 1, 1, self.alpha)
    love.graphics.draw(self.current_image, self.x, self.y, 0,
      self.width / self.current_image:getWidth(),
      self.height / self.current_image:getHeight())
  end
end
```

Add to DialogueUI:

```lua
-- In DialogueUI.new()
self.portrait = Portrait:new(config.portrait or {})
table.insert(self.components, self.portrait)

-- In showContent(), update portrait based on speaker
if content.type == "text" and content.speaker then
  self.portrait:setCharacter(content.speaker)
end
```

### Backlog (History Viewer)

Create a scrollable dialogue history:

```lua
local Backlog = setmetatable({}, {__index = Component})
Backlog.__index = Backlog

function Backlog:new(config)
  local obj = Component.new(self)
  
  obj.x = config.x or 0
  obj.y = config.y or 0
  obj.width = config.width or love.graphics.getWidth()
  obj.height = config.height or love.graphics.getHeight()
  
  obj.history = {}  -- {speaker, text} pairs
  obj.scroll_offset = 0
  obj.line_height = 25
  obj.visible = false  -- Hidden by default
  
  return obj
end

function Backlog:addEntry(text, speaker)
  table.insert(self.history, {
    speaker = speaker,
    text = text,
    timestamp = love.timer.getTime()
  })
end

function Backlog:draw()
  if not self.visible then return end
  
  -- Semi-transparent background
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
  
  -- Draw history entries
  local y = self.y + 20 - self.scroll_offset
  for i = #self.history, 1, -1 do
    local entry = self.history[i]
    
    if entry.speaker then
      love.graphics.setColor(0.7, 0.9, 1)
      love.graphics.print(entry.speaker, self.x + 20, y)
      y = y + self.line_height
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(entry.text, self.x + 40, y)
    y = y + self.line_height + 5
  end
  
  -- Instructions
  love.graphics.setColor(0.5, 0.5, 0.5)
  love.graphics.print("Press H to close | Mouse wheel to scroll", 
    self.x + 20, self.y + self.height - 30)
end

function Backlog:wheelmoved(x, y)
  if self.visible then
    self.scroll_offset = math.max(0, self.scroll_offset - y * 30)
    return true
  end
  return false
end
```

---

## Tag System Implementation

Tags allow stories to trigger game events, play sounds, show emotions, etc.

### In Story

```lua
helpers.text("I'm so happy!", "Alice", {"emotion:happy", "sound:laugh"})
```

### Processing Tags

Add to `dialogue.lua`:

```lua
function Dialogue:processTags(tags, content)
  if not self.tag_handlers then return end
  
  for _, tag in ipairs(tags) do
    -- Parse tag format: "category:value" or just "tag"
    local category, value = tag:match("([^:]+):([^:]+)")
    
    if not category then
      category = tag
      value = nil
    end
    
    if self.tag_handlers[category] then
      self.tag_handlers[category](value, content)
    end
  end
end

-- In getNext(), after getting text content:
if content.tags and #content.tags > 0 then
  self:processTags(content.tags, content)
end
```

### Register Tag Handlers

```lua
-- In your game code
dialogue.tag_handlers = {
  sound = function(sound_name)
    -- Play sound effect
    if sounds[sound_name] then
      sounds[sound_name]:play()
    end
  end,
  
  emotion = function(emotion)
    -- Update character portrait
    ui.portrait:setEmotion(emotion)
  end,
  
  camera = function(action)
    -- Camera shake, zoom, etc.
    if action == "shake" then
      camera:shake(0.5, 10)
    end
  end,
  
  music = function(track)
    -- Change background music
    playMusic(track)
  end
}
```

---

## Save/Load System

### Serializing Dialogue State

Add to `dialogue.lua`:

```lua
function Dialogue:saveState()
  return {
    current_knot = self.current_knot,
    current_index = self.current_index,
    variables = self.variables,
    history = self.history,
    tunnel_stack = self.tunnel_stack,
    version = "1.0"
  }
end

function Dialogue:loadState(state)
  if state.version ~= "1.0" then
    error("Incompatible save version")
  end
  
  self.current_knot = state.current_knot
  self.current_index = state.current_index
  self.variables = state.variables
  self.history = state.history
  self.tunnel_stack = state.tunnel_stack or {}
end
```

### Save to File

```lua
function saveDialogueState(dialogue, filename)
  local state = dialogue:saveState()
  local serialized = require("json").encode(state)  -- Or use Lua serialize
  love.filesystem.write(filename, serialized)
end

function loadDialogueState(dialogue, filename)
  local serialized = love.filesystem.read(filename)
  if serialized then
    local state = require("json").decode(serialized)
    dialogue:loadState(state)
    return true
  end
  return false
end
```

---

## Function Calls from Stories

Execute custom Lua functions from story content.

### Add Helper

```lua
function StoryHelpers.call(func_name, ...)
  return {
    type = "function_call",
    func_name = func_name,
    args = {...}
  }
end
```

### Handle in Dialogue

```lua
-- In Dialogue.new()
self.functions = {}

-- Register functions
function Dialogue:registerFunction(name, func)
  self.functions[name] = func
end

-- In getNext()
elseif content_type == "function_call" then
  if self.functions[content.func_name] then
    self.functions[content.func_name](unpack(content.args))
  else
    print("Warning: Function '" .. content.func_name .. "' not registered")
  end
  self.current_index = self.current_index + 1
  return self:getNext()
```

### Usage

```lua
-- Register game functions
dialogue:registerFunction("give_item", function(item_name)
  player.inventory:add(item_name)
end)

dialogue:registerFunction("start_battle", function(enemy_name)
  game:startBattle(enemy_name)
end)

-- In story
{
  helpers.text("Here, take this sword."),
  helpers.call("give_item", "iron_sword"),
  helpers.text("You obtained: Iron Sword!")
}
```

---

## Threading and Tunnels

### Parallel Storylines

For managing multiple concurrent storylines (e.g., different characters):

```lua
function Dialogue:createThread(name, start_knot)
  self.threads = self.threads or {}
  self.threads[name] = {
    knot = start_knot,
    index = 1,
    paused = false
  }
end

function Dialogue:switchThread(name)
  if not self.threads[name] then
    error("Thread '" .. name .. "' does not exist")
  end
  
  -- Save current thread
  self.threads[self.current_thread] = {
    knot = self.current_knot,
    index = self.current_index
  }
  
  -- Switch to new thread
  local thread = self.threads[name]
  self.current_knot = thread.knot
  self.current_index = thread.index
  self.current_thread = name
end
```

---

## Performance Optimizations

### Content Caching

For large stories, cache processed content:

```lua
function Dialogue:cacheKnot(knot_name)
  if not self.content_cache then
    self.content_cache = {}
  end
  
  local knot = self.story_data[knot_name]
  local cached = {}
  
  for i, content in ipairs(knot) do
    -- Pre-process content
    if type(content) == "string" then
      cached[i] = {
        type = "text",
        content = content,
        speaker = nil,
        tags = {}
      }
    else
      cached[i] = content
    end
  end
  
  self.content_cache[knot_name] = cached
end
```

---

## Integration Examples

### RPG Battle Integration

```lua
-- In story
{
  helpers.text("A wild slime appears!"),
  helpers.call("start_battle", "slime"),
  helpers.condition("battle_won", true,
    helpers.text("You defeated the slime!")),
  helpers.condition("battle_won", false,
    helpers.text("You fled from the slime."))
}

-- In game
dialogue:registerFunction("start_battle", function(enemy)
  local won = battle:start(enemy)
  dialogue:setVariable("battle_won", won)
end)
```

### Inventory System

```lua
-- Check if player has item
helpers.condition("has_key", true,
  helpers.text("You use the key to unlock the door."))

-- Give item
helpers.call("add_item", "health_potion")
```

---

## Testing Extensions

Create a test story for each new feature:

```lua
local test_story = {
  test_sequences = {
    helpers.sequence(
      "First visit",
      "Second visit",
      "Third visit"
    ),
    helpers.divert("test_sequences")  -- Loop to test cycling
  },
  
  test_functions = {
    helpers.text("Testing function calls..."),
    helpers.call("test_func", "param1", "param2"),
    helpers.text("Function executed!")
  }
}

-- Test it
dialogue:registerFunction("test_func", function(a, b)
  print("Called with:", a, b)
end)
```

---

## Best Practices

1. **Keep Extensions Modular**: Each feature should be independent
2. **Document New Features**: Add comments and examples
3. **Maintain Backward Compatibility**: Don't break existing stories
4. **Test Thoroughly**: Create test stories for new features
5. **Follow Patterns**: Use existing code structure as a guide
6. **Mark Extension Points**: Help future developers with clear comments

---

**Happy extending!** 🚀

