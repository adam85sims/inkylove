# Quick Reference Guide

A cheat sheet for writing stories with the Ink-inspired dialogue framework.

## Basic Setup

```lua
local helpers = require("story_helpers")
local text = helpers.text
local choice = helpers.choice
local divert = helpers.divert
local set = helpers.set
local condition = helpers.condition
```

## Story Structure

```lua
local story = {
  knot_name = {
    -- Content array
  }
}
```

## Content Types

### Simple Text (Narrator)

```lua
"This is simple narrator text."
```

### Text with Speaker

```lua
text("Hello!", "Alice")
```

### Text with Speaker and Tags

```lua
text("I'm excited!", "Bob", {"happy", "jump"})
```

### Choice - Simple

```lua
choice("What do you say?", {
  "Hello",      -- Continues to next line
  "Goodbye",    -- Continues to next line
  "Nothing"     -- Continues to next line
})
```

### Choice - With Diverts

```lua
choice("Where do you go?", {
  {"Go left", divert = "left_path"},
  {"Go right", divert = "right_path"},
  {"Stay here", divert = "stay"}
})
```

### Choice - Without Prompt

```lua
choice(nil, {
  {"Option A", divert = "path_a"},
  {"Option B", divert = "path_b"}
})
```

### Divert (Jump to Knot)

```lua
divert("next_scene")
```

### Set Variable

```lua
set("player_name", "Alice")
set("score", 100)
set("has_key", true)
```

### Conditional Content

```lua
-- Show if condition is true
condition("has_key", true,
  text("You unlock the door."))

-- With operator
condition("score", 50, 
  text("Your score is high enough!"), ">=")
```

**Operators:** `==`, `!=`, `>`, `<`, `>=`, `<=`

## Complete Examples

### Linear Story

```lua
story = {
  start = {
    text("Chapter One: The Beginning", "Narrator"),
    "You wake up in a strange place.",
    "What will you do?",
    divert("chapter_two")
  },
  
  chapter_two = {
    "The story continues...",
    divert("the_end")
  },
  
  the_end = {}
}
```

### Branching Story

```lua
story = {
  start = {
    text("You see two paths.", "Narrator"),
    choice("Which way?", {
      {"Left path", divert = "left"},
      {"Right path", divert = "right"}
    })
  },
  
  left = {
    "You go left and find treasure!",
    divert("ending")
  },
  
  right = {
    "You go right and find danger!",
    divert("ending")
  },
  
  ending = {
    "THE END"
  }
}
```

### Using Variables

```lua
story = {
  start = {
    text("What is your name?"),
    choice(nil, {
      {"Alice", divert = "set_alice"},
      {"Bob", divert = "set_bob"}
    })
  },
  
  set_alice = {
    set("name", "Alice"),
    divert("greeting")
  },
  
  set_bob = {
    set("name", "Bob"),
    divert("greeting")
  },
  
  greeting = {
    -- Note: Variable interpolation not built-in yet
    -- Use conditionals instead
    condition("name", "Alice",
      text("Welcome, Alice!")),
    condition("name", "Bob",
      text("Welcome, Bob!")),
    divert("continue")
  },
  
  continue = {
    "Your adventure begins..."
  }
}
```

### Conditional Branching

```lua
story = {
  find_key = {
    "You found a key!",
    set("has_key", true),
    divert("door")
  },
  
  door = {
    "You approach the locked door.",
    
    condition("has_key", true,
      text("You unlock the door with your key.")),
    
    condition("has_key", true,
      divert("inside")),
    
    -- If no key (has_key != true)
    condition("has_key", nil,
      text("The door is locked.")),
    
    condition("has_key", nil,
      divert("stuck"))
  },
  
  inside = {
    "You enter the room..."
  },
  
  stuck = {
    "You're stuck outside..."
  }
}
```

## Common Patterns

### Hub System (Central Location)

```lua
story = {
  hub = {
    text("You're in the town square.", "Narrator"),
    choice("Where do you go?", {
      {"Visit the shop", divert = "shop"},
      {"Go to tavern", divert = "tavern"},
      {"Leave town", divert = "leave"}
    })
  },
  
  shop = {
    "You visit the shop.",
    choice("Done shopping?", {
      {"Return to square", divert = "hub"}
    })
  },
  
  tavern = {
    "You visit the tavern.",
    choice("Done drinking?", {
      {"Return to square", divert = "hub"}
    })
  },
  
  leave = {
    "You leave the town. Goodbye!"
  }
}
```

### Flag-Based Unlocking

```lua
story = {
  start = {
    choice("What do you do?", {
      {"Search the room", divert = "search"},
      {"Try the door", divert = "door"}
    })
  },
  
  search = {
    "You find a key!",
    set("found_key", true),
    divert("start")
  },
  
  door = {
    condition("found_key", true,
      text("You unlock the door!")),
    condition("found_key", true,
      divert("escape")),
    
    -- If not found_key
    text("The door is locked."),
    divert("start")
  },
  
  escape = {
    "You escaped! THE END"
  }
}
```

### Counting/Scoring

```lua
story = {
  start = {
    set("score", 0),
    divert("question1")
  },
  
  question1 = {
    choice("What is 2+2?", {
      {"4", divert = "correct1"},
      {"5", divert = "wrong1"}
    })
  },
  
  correct1 = {
    "Correct!",
    set("score", 1),  -- Note: score = score + 1 not built-in yet
    divert("results")
  },
  
  wrong1 = {
    "Wrong!",
    divert("results")
  },
  
  results = {
    condition("score", 0,
      text("You got 0 correct.")),
    condition("score", 1,
      text("You got 1 correct!")),
    "Thanks for playing!"
  }
}
```

## Dialogue Engine API

```lua
local Dialogue = require("dialogue")
local dialogue = Dialogue.new(story, "start")

-- Get next content
local content = dialogue:getNext()
-- Returns: {type = "text"|"choice"|"end", ...}

-- Make a choice
local next = dialogue:choose(choice_index)

-- Variables
dialogue:setVariable("name", "Alice")
local name = dialogue:getVariable("name")

-- Check if ended
if dialogue:hasEnded() then
  print("Story complete!")
end

-- Get current location
local knot = dialogue:getCurrentKnot()
```

## UI API

```lua
local DialogueUI = require("dialogue_ui")
local ui = DialogueUI.new(config)

-- Show content
ui:showContent(content)

-- Handle choice selection
ui.on_choice_made = function(index)
  local next = dialogue:choose(index)
  ui:showContent(next)
end

-- Update and draw
ui:update(dt)
ui:draw()

-- Handle input
ui:mousepressed(x, y, button)

-- Check state
if ui:isTextComplete() then
  -- Ready for next
end

-- Skip typewriter
ui:skipTypewriter()
```

## Configuration Examples

### Fast Text, No Typewriter

```lua
local ui = DialogueUI.new({
  textbox = {
    typewriter_speed = 0  -- Instant
  }
})
```

### Slow, Dramatic Text

```lua
local ui = DialogueUI.new({
  textbox = {
    typewriter_speed = 15  -- 15 chars/second
  }
})
```

### Custom Colors

```lua
local ui = DialogueUI.new({
  textbox = {
    background_color = {0.1, 0.1, 0.2, 1},
    text_color = {1, 0.9, 0.8, 1},
    border_color = {0.5, 0.4, 0.3, 1}
  },
  choicelist = {
    normal_color = {0.2, 0.2, 0.3, 1},
    hover_color = {0.4, 0.4, 0.6, 1}
  }
})
```

### Custom Position

```lua
local ui = DialogueUI.new({
  textbox = {
    x = 100,
    y = 500,
    width = 600,
    height = 120
  },
  choicelist = {
    x = 150,
    y = 200,
    width = 500
  }
})
```

## Tips & Tricks

### End a Story Gracefully

```lua
the_end = {
  text("THE END", "Narrator"),
  choice("Play again?", {
    {"Yes", divert = "start"},
    {"No", divert = "goodbye"}
  })
}

goodbye = {
  "Thanks for playing!"
  -- Story ends naturally here
}
```

### Debug Current State

In `love.keypressed()`:

```lua
if key == "d" then
  print("=== Debug Info ===")
  print("Knot:", dialogue:getCurrentKnot())
  print("Variables:")
  for k, v in pairs(dialogue.variables) do
    print("  " .. k .. " = " .. tostring(v))
  end
end
```

### Prevent Dead Ends

Always provide a way forward:

```lua
-- BAD: Could get stuck
stuck = {
  "You're stuck!"
  -- No way to continue!
}

-- GOOD: Always have an option
stuck = {
  "You're stuck!",
  choice("What now?", {
    {"Try again", divert = "start"},
    {"Give up", divert = "bad_ending"}
  })
}
```

### Organize Large Stories

```lua
-- Separate knots by chapter/area
local story = {
  -- Chapter 1
  ch1_start = {},
  ch1_battle = {},
  ch1_end = {},
  
  -- Chapter 2
  ch2_start = {},
  ch2_puzzle = {},
  ch2_end = {},
  
  -- Common
  game_over = {},
  victory = {}
}
```

---

## Need More?

- See **README.md** for full documentation
- See **EXTENDING.md** for advanced features
- See **example_story.lua** for complete example

**Happy writing!** ✍️

