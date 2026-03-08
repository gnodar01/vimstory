local utils = require('vimstory.utils')

---@param arr any[]
---@return integer
local function guess_length(arr)
  local last_known = #arr
  for i = 1, 20 do
    if arr[i] ~= nil and last_known < i then
      last_known = i
    end
  end

  return last_known
end

---@param arr any[]
---@param previous_length integer
---@return integer
local function determine_length(arr, previous_length)
  local idx = 0
  for i = previous_length, 1, -1 do
    if arr[i] ~= nil then
      idx = i
      break
    end
  end
  return idx
end

--- @class VimstoryNavOptions
--- @field ui_nav_wrap? boolean

---@param arr any[]
---@param value any
---@return number
local function prepend_to_array(arr, value)
  local idx = 1
  local prev = value
  while true do
    local curr = arr[idx]
    arr[idx] = prev
    if curr == nil then
      break
    end
    prev = curr
    idx = idx + 1
  end
  return idx
end

--- @class VimstoryListItem
--- @field value string

--- @class VimstoryList
--- @field driver VimstoryPartialDriverItem
--- @field name string
--- @field _length number
--- @field _index number
--- @field items VimstoryListItem[]
local VimstoryList = {}

---@param items VimstoryListItem[]
---@param length integer
---@param element any
---@param driver? VimstoryPartialDriverItem
---@return integer
local function index_of(items, length, element, driver)
  local equals = driver and driver.equals or function(a, b)
    return a == b
  end
  local index = -1
  for i = 1, length do
    local item = items[i]
    if equals(element, item) then
      index = i
      break
    end
  end

  return index
end

VimstoryList.__index = VimstoryList
---@param driver VimstoryPartialDriverItem
---@param name string
---@param items VimstoryListItem[]
function VimstoryList:new(driver, name, items)
  items = items or {}
  return setmetatable({
    items = items,
    driver = driver,
    name = name,
    _length = guess_length(items),
    _index = 1,
  }, self)
end

---@return number
function VimstoryList:length()
  return self._length
end

function VimstoryList:clear()
  self.items = {}
  self._length = 0
end

---@param idx number
---@param item? VimstoryListItem
function VimstoryList:replace_at(idx, item)
  item = item or self.driver.create_list_item(self.driver)

  local current_idx = index_of(self.items, self._length, item, self.driver)

  self.items[idx] = item

  if current_idx ~= idx then
    self.items[current_idx] = nil
  end

  if idx > self._length then
    self._length = idx
  else
    self._length = determine_length(self.items, self._length)
  end
end

---@param item? VimstoryListItem
function VimstoryList:add(item)
  item = item or self.driver.create_list_item(self.driver)

  local index = index_of(self.items, self._length, item, self.driver)

  if index == -1 then
    local idx = self._length + 1
    for i = 1, self._length + 1 do
      if self.items[i] == nil then
        idx = i
        break
      end
    end

    self.items[idx] = item
    if idx > self._length then
      self._length = idx
    end
  end

  return self
end

---@param item? VimstoryListItem
---@return VimstoryList
function VimstoryList:prepend(item)
  item = item or self.driver.create_list_item(self.driver)

  local index = index_of(self.items, self._length, item, self.driver)

  if index == -1 then
    local stop_idx = prepend_to_array(self.items, item)
    if stop_idx > self._length then
      self._length = stop_idx
    end
  end

  return self
end

---@param item? VimstoryListItem
---@return VimstoryList
function VimstoryList:remove(item)
  item = item or self.driver.create_list_item(self.driver)

  for i = 1, self._length do
    local v = self.items[i]
    if self.driver.equals(v, item) then
      self.items[i] = nil
      if i == self._length then
        self._length = determine_length(self.items, self._length)
      end
      break
    end
  end
  return self
end

---@param index integer
---@return VimstoryList
function VimstoryList:remove_at(index)
  if self.items[index] then
    self.items[index] = nil
    if index == self._length then
      self._length = determine_length(self.items, self._length)
    end
  end
  return self
end

---@param index integer
---@return VimstoryListItem
function VimstoryList:get(index)
  return self.items[index]
end

---@param value string
function VimstoryList:get_by_value(value)
  local index = index_of(self.items, self._length, value, {
    equals = function(element, item)
      if item == nil then
        return false
      end
      return element == item.value
    end,
  })
  if index == -1 then
    return nil
  end
  return self.items[index], index
end

---@param displayed string[]
---@param length integer
function VimstoryList:resolve_displayed(displayed, length)
  local new_list = {}

  local list_displayed = self:display()

  --local change = 0
  --for i = 1, self._length do
  --  local v = self.items[i]
  --  local index = index_of(displayed, self._length, v)
  --  if index == -1 then
  --    change = change + 1
  --  end
  --end

  for i = 1, length do
    local v = displayed[i]
    local index = index_of(list_displayed, self._length, v)
    if utils.is_white_space(v) then
      new_list[i] = nil
    elseif index == -1 then
      new_list[i] = self.driver.create_list_item(self.driver, v)
      --change = change + 1
    else
      local index_in_new_list = index_of(new_list, length, self.items[index], self.driver)

      if index_in_new_list == -1 then
        new_list[i] = self.items[index]
      end

      --if index ~= i then
      --  change = change + 1
      --end
    end
  end

  self.items = new_list
  self._length = length
  --if change > 0 then
  --  -- do something with this info?
  --end
end

---@param index integer
---@param options any
function VimstoryList:select(index, options)
  local item = self.items[index]
  if item or self.driver.select_with_nil then
    self.driver.select(item, options)
  end
end

--- @param opts? VimstoryNavOptions
function VimstoryList:next(opts)
  opts = opts or {}

  self._index = self._index + 1
  if self._index > self._length then
    if opts.ui_nav_wrap then
      self._index = 1
    else
      self._index = self._length
    end
  end

  self:select(self._index)
end

--- @param opts? VimstoryNavOptions
function VimstoryList:prev(opts)
  opts = opts or {}

  self._index = self._index - 1
  if self._index < 1 then
    if opts.ui_nav_wrap then
      self._index = #self.items
    else
      self._index = 1
    end
  end

  self:select(self._index)
end

--- @return string[]
function VimstoryList:display()
  ---@type { [integer]: string }
  local out = {}

  for i = 1, self._length do
    local v = self.items[i]
    out[i] = v == nil and '' or self.driver.display(v)
  end

  return out
end

--- @return string[]
function VimstoryList:encode()
  local out = {}
  for k, v in pairs(self.items) do
    out[k] = self.driver.encode(v)
  end

  return out
end

--- @return VimstoryList
--- @param list_driver VimstoryPartialDriverItem
--- @param name string
--- @param items string[]
function VimstoryList.decode(list_driver, name, items)
  local list_items = {}
  for k, item in pairs(items) do
    list_items[k] = item ~= vim.NIL and list_driver.decode(item) or nil
  end

  return VimstoryList:new(list_driver, name, list_items)
end

return VimstoryList
