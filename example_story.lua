--[[
  Example Story for Ink-Inspired Dialogue Framework
  
  This demonstrates the key features of the framework:
    - Linear dialogue progression
    - Branching choices
    - Knot navigation with diverts
    - Basic variable usage
    - Speaker names and tags
    - Conditional content
  
  This story can be used as a template for creating your own stories.
]]

local helpers = require("story_helpers")
local text = helpers.text
local choice = helpers.choice
local divert = helpers.divert
local set = helpers.set
local condition = helpers.condition

--[[
  Story Structure:
  
  Each key is a "knot" (named section of the story).
  Each knot contains an array of content items:
    - Strings (simple dialogue)
    - text() objects (dialogue with speaker/tags)
    - choice() objects (player decisions)
    - divert() objects (jump to another knot)
    - set() objects (variable assignment)
    - condition() objects (conditional content)
]]

local story = {
  -- Starting knot
  start = {
    text("You wake up in a mysterious room.", "Narrator"),
    text("The walls are covered in strange symbols."),
    text("There's a door ahead and a window to your left."),
    
    choice("What do you do?", {
      {"Examine the symbols", divert = "examine_symbols"},
      {"Try the door", divert = "try_door"},
      {"Look out the window", divert = "window"}
    })
  },
  
  -- Examine symbols path
  examine_symbols = {
    text("You step closer to the wall, studying the intricate patterns."),
    text("They seem to glow faintly in the dim light."),
    text("As you trace your finger along one symbol, you feel a surge of knowledge.", "Narrator"),
    
    set("learned_symbols", true),
    
    text("You now understand the ancient language!", "Narrator"),
    text("The symbols spell out a warning: 'Beware the locked door.'"),
    
    divert("symbols_learned")
  },
  
  symbols_learned = {
    text("Armed with this new knowledge, you consider your options."),
    
    choice("What do you do next?", {
      {"Try the door (despite the warning)", divert = "try_door"},
      {"Look out the window", divert = "window"}
    })
  },
  
  -- Try door path
  try_door = {
    -- Conditional text based on whether player learned symbols
    condition("learned_symbols", true, 
      text("You remember the warning, but curiosity gets the better of you.")),
    
    text("You approach the heavy wooden door."),
    text("The handle is cold to the touch."),
    
    choice(nil, {
      {"Turn the handle", divert = "door_locked"},
      {"Knock on the door", divert = "door_knock"}
    })
  },
  
  door_locked = {
    text("You try to turn the handle, but it won't budge."),
    text("The door is firmly locked."),
    
    divert("after_door")
  },
  
  door_knock = {
    text("You knock three times."),
    text("*KNOCK KNOCK KNOCK*", "Sound"),
    text("Silence."),
    text("No response."),
    
    divert("after_door")
  },
  
  after_door = {
    text("It seems the door is not an option right now."),
    
    choice("What now?", {
      {"Look out the window", divert = "window"}
    })
  },
  
  -- Window path
  window = {
    text("You walk over to the window and peer outside."),
    text("Below, you see a beautiful garden bathed in moonlight."),
    text("A figure stands in the garden, looking up at you.", "Narrator"),
    
    choice("The figure gestures. What do you do?", {
      {"Wave back", divert = "wave"},
      {"Step away from the window", divert = "ignore_figure"}
    })
  },
  
  wave = {
    text("You wave at the mysterious figure."),
    text("They smile and point to something at their feet."),
    text("It's a key, glinting in the moonlight!", "Narrator"),
    text("The figure picks it up and tosses it toward your window."),
    text("*CLINK*", "Sound"),
    text("The key lands on your windowsill."),
    
    set("has_key", true),
    
    divert("got_key")
  },
  
  ignore_figure = {
    text("You step back from the window, uneasy."),
    text("When you look again, the figure is gone."),
    text("A lost opportunity...", "Narrator"),
    
    divert("ending_trapped")
  },
  
  got_key = {
    text("You pick up the key. It feels warm in your hand."),
    text("Looking down, you see the figure has vanished."),
    
    choice("What do you do with the key?", {
      {"Try it on the door", divert = "unlock_door"},
      {"Keep examining the room", divert = "examine_more"}
    })
  },
  
  examine_more = {
    text("You decide to explore a bit more before using the key."),
    text("But there's really nothing else of interest here."),
    text("The door awaits."),
    
    divert("got_key")
  },
  
  unlock_door = {
    text("You insert the key into the lock."),
    text("*CLICK*", "Sound"),
    text("The door unlocks smoothly."),
    text("You push it open and step through into blinding light...", "Narrator"),
    
    divert("ending_escape")
  },
  
  -- Endings
  ending_escape = {
    text("You find yourself standing in the beautiful garden.", "Narrator"),
    text("The mysterious figure is nowhere to be seen."),
    text("But you're free."),
    text("You've escaped the mysterious room!", "Narrator", {"achievement"}),
    
    divert("the_end")
  },
  
  ending_trapped = {
    text("Time passes.", "Narrator"),
    text("The room grows darker."),
    text("You never find a way out."),
    text("Perhaps you should have trusted the mysterious figure...", "Narrator"),
    
    divert("the_end")
  },
  
  the_end = {
    text("THE END", "Narrator"),
    
    choice("Would you like to play again?", {
      {"Yes, restart", divert = "start"},
      {"No, end here", divert = "final_end"}
    })
  },
  
  final_end = {
    text("Thank you for experiencing this demo!", "Narrator"),
    text("This framework supports many more features and can be extended further."),
    -- Story naturally ends here
  }
}

--[[
  Notes for Story Authors:
  
  1. Simple dialogue:
     - Use plain strings for basic narrator text
     - Use text("content", "Speaker") for dialogue with speaker names
  
  2. Choices:
     - Inline choices continue to next line
     - Use {text, divert = "knot_name"} to jump to different sections
  
  3. Variables:
     - set("var_name", value) to store state
     - condition("var_name", value, content) to show conditional content
  
  4. Flow control:
     - divert("knot_name") to jump between sections
     - Knots end automatically when they run out of content
  
  5. Organization tips:
     - Group related content in knots
     - Use descriptive knot names
     - Add comments to explain complex branching
  
  EXTENSION IDEAS:
     - Add more endings based on player choices
     - Track multiple variables (player name, inventory, stats)
     - Use conditions to unlock special dialogue
     - Add character portraits and emotions via tags
     - Include sound effects and music cues via tags
]]

return story

