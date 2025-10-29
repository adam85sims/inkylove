# Ink-Inspired Dialogue Framework for LÖVE2D

A flexible, modular dialogue system for LÖVE2D games, inspired by Ink's narrative design principles but implemented as a Lua-native solution. Perfect for visual novels, RPGs, adventure games, and any game that needs branching narratives.

## Features

- ✅ **Lua-Native Format**: No external compilers needed - write stories directly in Lua
- ✅ **Core Narrative Features**: Knots, choices, diverts, and variables
- ✅ **Modular UI System**: Swappable components that can be enabled/disabled per scene
- ✅ **Typewriter Effect**: Smooth character-by-character text display
- ✅ **Choice System**: Branching narratives with conditional options
- ✅ **State Management**: Track variables, visited knots, and player choices
- ✅ **Well Documented**: Extensive inline documentation and examples
- ✅ **Extensible**: Clear extension points for adding advanced features

## Quick Start

### 1. Basic Usage

```lua
local Dialogue = require("dialogue")
local DialogueUI = require("dialogue_ui")
local helpers = require("story_helpers")

-- Create your story
local my_story = {
  start = {
    helpers.text("Welcome to my game!", "Narrator"),
    helpers.choice("Ready to begin?", {
      {"Yes!", divert = "chapter_one"},
      {"Not yet", divert = "wait"}
    })
  },
  chapter_one = {
    "And so the adventure begins...",
    helpers.divert("the_end")
  },
  wait = {
    "Take your time!",
    helpers.divert("start")
  },
  the_end = {}
}

-- Initialize systems
local dialogue = Dialogue.new(my_story)
local ui = DialogueUI.new()

-- Show content
local content = dialogue:getNext()
ui:showContent(content)

-- Handle choices
ui.on_choice_made = function(index)
  content = dialogue:choose(index)
  ui:showContent(content)
end
```

### 2. Run the Demo

```bash
love .
```

The included demo showcases all framework features with a complete interactive story.

## Architecture

### Three-Layer Design

1. **Dialogue Engine** (`dialogue.lua`)
   - State management and narrative logic
   - UI-agnostic - can be used without the UI system
   - Handles variables, choices, diverts, and conditionals

2. **UI System** (`dialogue_ui.lua`)
   - Modular component-based rendering
   - Components can be enabled/disabled as needed
   - Easy to customize or replace entirely

3. **Story Helpers** (`story_helpers.lua`)
   - Utility functions for cleaner story authoring
   - Creates structured data the engine understands

### File Structure

```
dialogue.lua          - Core dialogue engine
dialogue_ui.lua       - Modular UI system
story_helpers.lua     - Story authoring utilities
example_story.lua     - Complete example story
main.lua              - Demo implementation
README.md             - This file
```

## Story Format

### Knots

Knots are named sections of your story (like chapters or scenes):

```lua
story = {
  start = {
    -- Content goes here
  },
  chapter_two = {
    -- More content
  }
}
```

### Content Types

#### Simple Text

```lua
"This is narrator text."
```

#### Text with Speaker

```lua
helpers.text("Hello there!", "Alice")
helpers.text("Welcome!", "Bob", {"happy", "wave"})  -- With tags
```

#### Choices

```lua
helpers.choice("What do you say?", {
  {"Hello!", divert = "greeting"},
  {"Goodbye", divert = "farewell"},
  "I don't know"  -- Continues to next line
})
```

#### Diverts (Jumps)

```lua
helpers.divert("next_scene")
```

#### Variables

```lua
-- Set a variable
helpers.set("player_name", "Alice")
helpers.set("score", 100)
helpers.set("has_key", true)

-- Use in conditionals
helpers.condition("has_key", true, 
  helpers.text("You unlock the door with your key."))
```

### Complete Example

```lua
local helpers = require("story_helpers")

local story = {
  start = {
    helpers.text("You enter a mysterious cave.", "Narrator"),
    helpers.set("visited_cave", true),
    
    helpers.choice("What do you do?", {
      {"Go deeper", divert = "deeper"},
      {"Turn back", divert = "turn_back"}
    })
  },
  
  deeper = {
    helpers.text("You venture into the darkness..."),
    helpers.condition("has_torch", true,
      helpers.text("Your torch lights the way.")),
    helpers.divert("cave_end")
  },
  
  turn_back = {
    "You decide it's too dangerous.",
    helpers.divert("outside")
  },
  
  cave_end = {},
  outside = {}
}
```

## API Reference

### Dialogue Engine

#### `Dialogue.new(story_data, start_knot)`
Create a new dialogue instance.

```lua
local dialogue = Dialogue.new(my_story, "start")
```

#### `dialogue:getNext()`
Get the next content. Returns a content object or `{type = "end"}`.

```lua
local content = dialogue:getNext()
-- content.type can be: "text", "choice", "end"
```

#### `dialogue:choose(choice_index)`
Make a choice and get next content.

```lua
local next_content = dialogue:choose(1)
```

#### `dialogue:setVariable(name, value)` / `dialogue:getVariable(name)`
Manage story variables.

```lua
dialogue:setVariable("score", 100)
local score = dialogue:getVariable("score")
```

#### `dialogue:hasEnded()`
Check if story has reached the end.

```lua
if dialogue:hasEnded() then
  print("Story complete!")
end
```

#### `dialogue:getCurrentKnot()`
Get the current knot name.

```lua
local knot = dialogue:getCurrentKnot()
```

### DialogueUI

#### `DialogueUI.new(config)`
Create a new UI instance with optional configuration.

```lua
local ui = DialogueUI.new({
  textbox = {
    x = 50, y = 400,
    width = 700, height = 150,
    typewriter_speed = 30
  },
  choicelist = {
    x = 100, y = 200,
    width = 600
  }
})
```

#### `ui:showContent(content)`
Display content from the dialogue engine.

```lua
ui:showContent(content)
```

#### `ui:update(dt)` / `ui:draw()` / `ui:mousepressed(x, y, button)`
Standard LÖVE callbacks.

```lua
function love.update(dt)
  ui:update(dt)
end

function love.draw()
  ui:draw()
end

function love.mousepressed(x, y, button)
  ui:mousepressed(x, y, button)
end
```

#### `ui.on_choice_made`
Callback function when player selects a choice.

```lua
ui.on_choice_made = function(choice_index)
  local next = dialogue:choose(choice_index)
  ui:showContent(next)
end
```

### Story Helpers

#### `helpers.text(content, speaker, tags)`
Create a dialogue line.

```lua
helpers.text("Hello!", "Alice", {"happy"})
```

#### `helpers.choice(prompt, options)`
Create a choice.

```lua
helpers.choice("What now?", {
  {"Option A", divert = "path_a"},
  {"Option B", divert = "path_b"}
})
```

#### `helpers.divert(target)`
Jump to another knot.

```lua
helpers.divert("next_scene")
```

#### `helpers.set(var, value)`
Set a variable.

```lua
helpers.set("player_name", "Alice")
```

#### `helpers.condition(var, value, content, operator)`
Conditional content.

```lua
helpers.condition("score", 100, 
  helpers.text("Perfect score!"), ">=")
```

Supported operators: `==`, `!=`, `>`, `<`, `>=`, `<=`

## Customization

### Custom UI Configuration

```lua
local ui = DialogueUI.new({
  textbox = {
    x = 50,
    y = 500,
    width = 700,
    height = 120,
    padding = 15,
    background_color = {0.1, 0.1, 0.2, 0.95},
    text_color = {1, 1, 1, 1},
    typewriter_speed = 50,  -- chars per second (0 = instant)
    font = love.graphics.newFont(20)
  },
  choicelist = {
    x = 100,
    y = 150,
    width = 600,
    button_height = 45,
    spacing = 12,
    normal_color = {0.2, 0.3, 0.4, 0.9},
    hover_color = {0.3, 0.5, 0.6, 0.9},
    font = love.graphics.newFont(18)
  }
})
```

### Disabling UI Components

For scenes where you don't want certain UI elements:

```lua
-- Hide the textbox for a menu scene
ui.textbox.visible = false

-- Disable choice interactions temporarily
ui.choicelist.enabled = false
```

### Using Without UI

The dialogue engine can be used independently:

```lua
local Dialogue = require("dialogue")
local dialogue = Dialogue.new(my_story)

while not dialogue:hasEnded() do
  local content = dialogue:getNext()
  
  if content.type == "text" then
    -- Render with your own system
    myCustomRenderer:showText(content.content)
  elseif content.type == "choice" then
    -- Show choices your way
    local index = myCustomMenu:showChoices(content.options)
    dialogue:choose(index)
  end
end
```

## Extension Points

The framework is designed to be extended. Key extension points are marked in the code with `EXTENSION POINT` comments.

### Future Features You Can Add

#### In `dialogue.lua`:
- Save/Load system
- Function calls (execute custom Lua from story)
- Tag processing (trigger events, sound effects, etc.)
- Threading (parallel storylines)
- Tunnels (temporary diverts that return)
- Sequences (cycle content on repeat visits)

#### In `dialogue_ui.lua`:
- Portrait component (character images)
- Backlog viewer (scrollable history)
- Auto-play mode
- Save/Load menu
- Settings panel

#### In `story_helpers.lua`:
- `sequence()` - Cycle through options on repeat visits
- `shuffle()` - Randomize content
- `include()` - Include knots inline
- `function_call()` - Execute Lua functions

### Adding Custom Components

```lua
-- Create a new component
local Portrait = setmetatable({}, {__index = Component})
Portrait.__index = Portrait

function Portrait:new(config)
  local obj = Component.new(self)
  obj.image = nil
  obj.x = config.x or 50
  obj.y = config.y or 50
  return obj
end

function Portrait:setImage(image)
  self.image = image
end

function Portrait:draw()
  if self.visible and self.image then
    love.graphics.draw(self.image, self.x, self.y)
  end
end

-- Add to UI
table.insert(ui.components, Portrait:new({x = 50, y = 100}))
```

## Use Cases

### Visual Novels
Use the full UI system with textbox, choices, and add portrait components for character images.

### RPG Dialogue
Disable the textbox background, position it differently, and integrate with your game's UI style.

### Adventure Games
Use minimal UI, process tags to trigger game events, integrate with inventory system via variables.

### Interactive Fiction
Focus on the dialogue engine, build custom rendering that fits your aesthetic.

## Tips for Story Authors

1. **Organize with Knots**: Group related content together
2. **Use Descriptive Names**: `forest_encounter` not `scene_3`
3. **Track Important State**: Use variables for key decisions
4. **Test Branches**: Make sure all paths lead somewhere
5. **Add Comments**: Explain complex branching logic
6. **Use Diverts Wisely**: Don't create circular loops unintentionally

## License

This framework is provided as-is for use in your LÖVE2D projects. Feel free to modify and extend it to suit your needs.

## Credits

Inspired by [Ink](https://github.com/inkle/ink) by Inkle Studios.

---

**Happy storytelling!** 🎮📖

