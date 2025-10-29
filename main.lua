--[[
  Ink-Inspired Dialogue Framework Demo
  
  This demonstrates the complete dialogue system with:
    - Dialogue engine (state management)
    - Modular UI system
    - Example story with branching narrative
  
  Controls:
    - Click on text to advance
    - Click on choices to select
    - Space bar to advance text (when complete)
]]

-- Load the dialogue framework
local Dialogue = require("dialogue")
local DialogueUI = require("dialogue_ui")
local example_story = require("example_story")

-- Global state
local dialogue
local dialogue_ui
local current_content

function love.load()
  -- Set up window
  love.window.setTitle("Ink-Inspired Dialogue Framework Demo")
  
  -- Create dialogue engine with example story
  dialogue = Dialogue.new(example_story, "start")
  
  -- Create UI with custom configuration
  dialogue_ui = DialogueUI.new({
    textbox = {
      x = 50,
      y = love.graphics.getHeight() - 180,
      width = love.graphics.getWidth() - 100,
      height = 150,
      typewriter_speed = 40, -- Characters per second
      font = love.graphics.newFont(18)
    },
    choicelist = {
      x = 100,
      y = 200,
      width = love.graphics.getWidth() - 200,
      button_height = 50,
      font = love.graphics.newFont(16)
    }
  })
  
  -- Set up callback for when player makes a choice
  dialogue_ui.on_choice_made = function(choice_index)
    -- Tell dialogue engine about the choice
    current_content = dialogue:choose(choice_index)
    -- Show the next content
    dialogue_ui:showContent(current_content)
  end
  
  -- Get and show the first piece of content
  current_content = dialogue:getNext()
  dialogue_ui:showContent(current_content)
end

function love.update(dt)
  -- Update UI (handles typewriter effect, hover states, etc.)
  dialogue_ui:update(dt)
end

function love.draw()
  -- Clear background to a dark color
  love.graphics.clear(0.15, 0.15, 0.2)
  
  -- Draw title at top
  love.graphics.setColor(0.7, 0.8, 0.9, 0.5)
  love.graphics.print("Ink-Inspired Dialogue Framework Demo", 20, 20)
  
  -- Draw current knot name (for debugging)
  if dialogue and not dialogue:hasEnded() then
    love.graphics.setColor(0.5, 0.6, 0.7, 0.5)
    love.graphics.print("Current: " .. dialogue:getCurrentKnot(), 20, 40)
  end
  
  -- Draw the dialogue UI
  dialogue_ui:draw()
  
  -- Draw instructions
  if current_content and current_content.type == "text" then
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print("Click or press SPACE to continue", 20, love.graphics.getHeight() - 20)
  elseif current_content and current_content.type == "choice" then
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print("Click a choice to select", 20, love.graphics.getHeight() - 20)
  elseif dialogue:hasEnded() then
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Story complete. Press R to restart or ESC to quit.", 
      love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2)
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then
    -- First, try to handle UI interactions (choice clicks, etc.)
    if dialogue_ui:mousepressed(x, y, button) then
      return
    end
    
    -- If no UI element was clicked, advance dialogue (if text is complete)
    if current_content and current_content.type == "text" then
      if dialogue_ui:isTextComplete() then
        -- Get next content
        current_content = dialogue:getNext()
        dialogue_ui:showContent(current_content)
      else
        -- Skip typewriter effect
        dialogue_ui:skipTypewriter()
      end
    end
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "r" then
    -- Restart the story
    love.load()
  elseif key == "space" then
    -- Advance dialogue with spacebar
    if current_content and current_content.type == "text" then
      if dialogue_ui:isTextComplete() then
        current_content = dialogue:getNext()
        dialogue_ui:showContent(current_content)
      else
        dialogue_ui:skipTypewriter()
      end
    end
  elseif key == "d" then
    -- Debug: print current variables
    print("=== Current Variables ===")
    for k, v in pairs(dialogue.variables) do
      print(k .. " = " .. tostring(v))
    end
    print("=========================")
  end
end

--[[
  Integration Guide:
  
  To use this framework in your own game:
  
  1. Create your story:
     ```lua
     local helpers = require("story_helpers")
     local my_story = {
       start = {
         helpers.text("Your story begins here!", "Narrator"),
         helpers.choice("What do you do?", {
           {"Option A", divert = "path_a"},
           {"Option B", divert = "path_b"}
         })
       },
       -- Add more knots...
     }
     ```
  
  2. Initialize the dialogue system:
     ```lua
     local Dialogue = require("dialogue")
     local dialogue = Dialogue.new(my_story)
     ```
  
  3. Create the UI (optional - you can build your own):
     ```lua
     local DialogueUI = require("dialogue_ui")
     local ui = DialogueUI.new(config)
     ```
  
  4. Show content:
     ```lua
     local content = dialogue:getNext()
     ui:showContent(content)
     ```
  
  5. Handle choices:
     ```lua
     ui.on_choice_made = function(index)
       local next_content = dialogue:choose(index)
       ui:showContent(next_content)
     end
     ```
  
  Customization:
    - Disable components: ui.textbox.visible = false
    - Add custom components: Inherit from Component base class
    - Style the UI: Pass config options to DialogueUI.new()
    - Extend dialogue features: See EXTENSION POINTS in dialogue.lua
  
  For games that aren't visual novels:
    - You might only use the dialogue engine without the UI
    - Build custom rendering that fits your game's style
    - Use tags to trigger game events (combat, cutscenes, etc.)
    - Integrate with your existing game state system
]]
