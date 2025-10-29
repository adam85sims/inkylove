--[[
  Story Helpers for Ink-Inspired Dialogue Framework
  
  These helper functions make story authoring cleaner and more readable.
  They create structured data that the dialogue engine can process.
  
  Example usage:
    story = {
      start = {
        text("Hello there!", "Narrator"),
        choice("How do you respond?", {
          {"Hello!", divert = "friendly"},
          {"...", divert = "silent"}
        })
      }
    }
]]

local StoryHelpers = {}

--[[
  Create a dialogue line with optional speaker and tags
  
  @param content string - The dialogue text to display
  @param speaker string|nil - Optional speaker name
  @param tags table|nil - Optional tags for metadata (e.g., emotions, commands)
  @return table - Structured dialogue line
  
  Example:
    text("I'm happy to see you!", "Alice", {"happy", "wave"})
]]
function StoryHelpers.text(content, speaker, tags)
  return {
    type = "text",
    content = content,
    speaker = speaker,
    tags = tags or {}
  }
end

--[[
  Create a choice structure for player decisions
  
  @param prompt string|nil - Optional prompt text before choices
  @param options table - Array of choice options
  
  Each option can be:
    - Simple string: "Choice text" (continues to next line)
    - Table with divert: {"Choice text", divert = "knot_name"}
    - Table with condition: {"Choice text", condition = {var = "name", value = "Alice"}}
  
  Example:
    choice("What do you say?", {
      {"I agree", divert = "agree_path"},
      {"I disagree", divert = "disagree_path"}
    })
]]
function StoryHelpers.choice(prompt, options)
  return {
    type = "choice",
    prompt = prompt,
    options = options
  }
end

--[[
  Create a divert (jump) to another knot
  
  @param target string - Name of the knot to jump to
  @return table - Divert instruction
  
  Example:
    divert("next_scene")
]]
function StoryHelpers.divert(target)
  return {
    type = "divert",
    target = target
  }
end

--[[
  Create a conditional content block
  
  @param var string - Variable name to check
  @param value any - Value to compare against
  @param content table - Content to show if condition is true
  @param operator string - Comparison operator (default: "==")
  @return table - Conditional structure
  
  EXTENSION POINT: This is a basic implementation. Future versions could support:
    - Multiple conditions (AND/OR)
    - Complex expressions
    - Else branches
  
  Example:
    condition("player_name", "Alice", text("Welcome back, Alice!"))
]]
function StoryHelpers.condition(var, value, content, operator)
  return {
    type = "condition",
    var = var,
    value = value,
    content = content,
    operator = operator or "=="
  }
end

--[[
  Create a variable assignment instruction
  
  @param var string - Variable name
  @param value any - Value to assign (string, number, boolean)
  @return table - Assignment instruction
  
  Example:
    set("player_name", "Alice")
    set("score", 100)
    set("has_key", true)
]]
function StoryHelpers.set(var, value)
  return {
    type = "set",
    var = var,
    value = value
  }
end

--[[
  EXTENSION POINT: Future helper functions could include:
  
  - function_call(name, args) - Call custom Lua functions
  - tag(name, ...) - Standalone tags for triggering events
  - sequence(...) - Cycle through content on repeated visits
  - shuffle(...) - Randomize content order
  - include(knot_name) - Include another knot inline
]]

return StoryHelpers

