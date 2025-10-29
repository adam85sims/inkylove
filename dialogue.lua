--[[
  Dialogue Engine for Ink-Inspired Framework
  
  This is the core state machine that manages:
    - Story progression through knots
    - Variable storage and retrieval
    - Choice handling
    - Content iteration
  
  The engine is UI-agnostic; it only manages narrative logic.
  
  Architecture:
    story_data: Table of knots (named sections)
    current_knot: Name of active knot
    current_index: Position within current knot
    variables: Story state storage
    history: Record of visited knots and choices (for future features)
]]

local Dialogue = {}
Dialogue.__index = Dialogue

--[[
  Create a new dialogue instance
  
  @param story_data table - The story structure (knots and content)
  @param start_knot string - Name of starting knot (default: "start")
  @return Dialogue - New dialogue instance
  
  Example:
    local dialogue = Dialogue.new(my_story, "opening_scene")
]]
function Dialogue.new(story_data, start_knot)
  local self = setmetatable({}, Dialogue)
  
  self.story_data = story_data or {}
  self.current_knot = start_knot or "start"
  self.current_index = 1
  self.variables = {}
  self.history = {
    knots_visited = {},
    choices_made = {}
  }
  
  -- Validate that start knot exists
  if not self.story_data[self.current_knot] then
    error("Start knot '" .. self.current_knot .. "' not found in story data")
  end
  
  return self
end

--[[
  Get the next piece of content from the story
  
  @return table|nil - Content object or nil if story ended
  
  Return types:
    {type = "text", content = "...", speaker = "...", tags = {...}}
    {type = "choice", prompt = "...", options = {...}}
    {type = "end"} - Story has ended
    nil - No more content (same as end)
  
  This function automatically handles:
    - Variable assignments (set)
    - Diverts (jumps)
    - Conditionals (skips content if condition false)
]]
function Dialogue:getNext()
  -- Check if we've reached the end
  if not self.current_knot or not self.story_data[self.current_knot] then
    return {type = "end"}
  end
  
  local knot = self.story_data[self.current_knot]
  
  -- Check if we've exhausted this knot
  if self.current_index > #knot then
    return {type = "end"}
  end
  
  local content = knot[self.current_index]
  
  -- Handle different content types
  if type(content) == "string" then
    -- Simple string - convert to text object
    self.current_index = self.current_index + 1
    return {
      type = "text",
      content = content,
      speaker = nil,
      tags = {}
    }
    
  elseif type(content) == "table" then
    local content_type = content.type
    
    -- Handle variable assignment
    if content_type == "set" then
      self:setVariable(content.var, content.value)
      self.current_index = self.current_index + 1
      return self:getNext() -- Skip to next content
      
    -- Handle divert
    elseif content_type == "divert" then
      self:divertTo(content.target)
      return self:getNext() -- Continue from new location
      
    -- Handle conditional
    elseif content_type == "condition" then
      if self:evaluateCondition(content) then
        -- Condition true - return the content
        self.current_index = self.current_index + 1
        if type(content.content) == "table" then
          return content.content
        else
          return {type = "text", content = content.content}
        end
      else
        -- Condition false - skip this content
        self.current_index = self.current_index + 1
        return self:getNext()
      end
      
    -- Handle text
    elseif content_type == "text" then
      self.current_index = self.current_index + 1
      return content
      
    -- Handle choice
    elseif content_type == "choice" then
      -- Don't increment index yet - wait for player to choose
      return content
      
    else
      -- Unknown type - skip it
      print("Warning: Unknown content type '" .. tostring(content_type) .. "'")
      self.current_index = self.current_index + 1
      return self:getNext()
    end
  end
  
  -- Shouldn't reach here, but just in case
  return {type = "end"}
end

--[[
  Make a choice and continue the story
  
  @param choice_index number - Index of the chosen option (1-based)
  @return table|nil - Next content after the choice
  
  This function handles the choice, processes any diverts or effects,
  and returns the next content.
]]
function Dialogue:choose(choice_index)
  local knot = self.story_data[self.current_knot]
  local content = knot[self.current_index]
  
  if not content or content.type ~= "choice" then
    error("Current content is not a choice")
  end
  
  local choice = content.options[choice_index]
  if not choice then
    error("Invalid choice index: " .. choice_index)
  end
  
  -- Record choice in history
  table.insert(self.history.choices_made, {
    knot = self.current_knot,
    index = self.current_index,
    choice = choice_index
  })
  
  -- Move past the choice
  self.current_index = self.current_index + 1
  
  -- Handle choice effects
  if type(choice) == "table" then
    -- Check for divert
    if choice.divert then
      self:divertTo(choice.divert)
    end
    
    -- Check for variable assignment
    if choice.set then
      for var, value in pairs(choice.set) do
        self:setVariable(var, value)
      end
    end
  end
  
  -- Return next content
  return self:getNext()
end

--[[
  Jump to a different knot
  
  @param target_knot string - Name of knot to jump to
]]
function Dialogue:divertTo(target_knot)
  if not self.story_data[target_knot] then
    error("Divert target '" .. target_knot .. "' not found")
  end
  
  -- Record knot visit
  if not self.history.knots_visited[target_knot] then
    self.history.knots_visited[target_knot] = 0
  end
  self.history.knots_visited[target_knot] = self.history.knots_visited[target_knot] + 1
  
  self.current_knot = target_knot
  self.current_index = 1
end

--[[
  Evaluate a conditional expression
  
  @param condition table - Condition object with var, value, operator
  @return boolean - True if condition passes
  
  EXTENSION POINT: Currently supports basic comparison operators.
  Future versions could support:
    - Complex expressions
    - Multiple conditions with AND/OR
    - Custom comparison functions
]]
function Dialogue:evaluateCondition(condition)
  local var_value = self:getVariable(condition.var)
  local target_value = condition.value
  local operator = condition.operator or "=="
  
  if operator == "==" then
    return var_value == target_value
  elseif operator == "!=" then
    return var_value ~= target_value
  elseif operator == ">" then
    return var_value > target_value
  elseif operator == "<" then
    return var_value < target_value
  elseif operator == ">=" then
    return var_value >= target_value
  elseif operator == "<=" then
    return var_value <= target_value
  else
    print("Warning: Unknown operator '" .. operator .. "'")
    return false
  end
end

--[[
  Get a story variable
  
  @param name string - Variable name
  @return any - Variable value or nil
]]
function Dialogue:getVariable(name)
  return self.variables[name]
end

--[[
  Set a story variable
  
  @param name string - Variable name
  @param value any - Value to store
]]
function Dialogue:setVariable(name, value)
  self.variables[name] = value
end

--[[
  Check if the story has ended
  
  @return boolean - True if no more content available
]]
function Dialogue:hasEnded()
  if not self.current_knot or not self.story_data[self.current_knot] then
    return true
  end
  
  local knot = self.story_data[self.current_knot]
  return self.current_index > #knot
end

--[[
  Get the current knot name
  
  @return string - Current knot name
]]
function Dialogue:getCurrentKnot()
  return self.current_knot
end

--[[
  Get visit count for a knot
  
  @param knot_name string - Name of knot to check
  @return number - Number of times visited (0 if never)
  
  EXTENSION POINT: This can be used for:
    - "Once" content (only show on first visit)
    - Different dialogue on repeat visits
    - Unlock conditions
]]
function Dialogue:getKnotVisitCount(knot_name)
  return self.history.knots_visited[knot_name] or 0
end

--[[
  EXTENSION POINTS for future development:
  
  - Save/Load system: Serialize/deserialize dialogue state
  - Function calls: Execute custom Lua functions from story
  - Tags: Process metadata tags (emotions, sound effects, etc.)
  - Threading: Multiple parallel storylines
  - Tunnels: Jump to knot then return
  - Sequences: Cycle content on repeated visits
]]

return Dialogue

