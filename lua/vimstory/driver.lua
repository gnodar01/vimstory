local Path = require('plenary.path')

local function normalize_path(buf_name, root)
  return Path:new(buf_name):make_relative(root)
end

---@alias VimstoryListFileItem {value: string, context: {row: integer, col: integer}}
---@alias VimstoryListFileOptions {split: boolean, vsplit: boolean, tabedit: boolean}

---@class VimstoryPartialDriver
---@field select_with_nil? boolean defaults to false
---@field display? (fun(list_item: VimstoryListItem): string)
---@field equals? (fun(list_line_a: any, list_line_b: VimstoryListItem): boolean)
---@field get_root_dir? fun(): string
---@field create_list_item? fun(name: string?, driver_override: VimstoryDriverOverride?): VimstoryListItem
---@field select? (fun(list_item?: VimstoryListItem, options: any?): nil)
---@field encode? (fun(list_item: VimstoryListItem): string) | boolean
---@field decode? (fun(obj: string): any)

---@class VimstoryDriver
---@field select_with_nil boolean defaults to false
---@field display (fun(list_item: VimstoryListItem): string)
---@field equals (fun(list_line_a: any, list_line_b: VimstoryListItem): boolean)
---@field get_root_dir fun(): string
---@field create_list_item fun(name: string?, driver_override: VimstoryDriverOverride?): VimstoryListItem
---@field select (fun(list_item?: VimstoryListItem, options: any?): nil)
---@field encode (fun(list_item: VimstoryListItem): string) | boolean
---@field decode (fun(obj: string): any)

---@alias VimstoryDriverOverride (VimstoryPartialDriver | VimstoryDriver)

local M = {}

---@return VimstoryDriver
function M.get_default_driver()
  return {
    --- select_with_nill allows for a list to call select even if the provided item is nil
    select_with_nil = false,

    ---@param list_item VimstoryListItem
    display = function(list_item)
      return list_item.value
    end,

    ---@param list_item_a VimstoryListItem
    ---@param list_item_b VimstoryListItem
    ---@return boolean
    equals = function(list_item_a, list_item_b)
      if list_item_a == nil and list_item_b == nil then
        return true
      elseif list_item_a == nil or list_item_b == nil then
        return false
      end

      return list_item_a.value == list_item_b.value
    end,

    get_root_dir = function()
      return vim.uv.cwd()
    end,

    ---@param name? string
    ---@param driver_override? VimstoryDriverOverride
    ---@return VimstoryListItem
    create_list_item = function(name, driver_override)
      local driver = driver_override and M.merge_driver(driver_override) or M.get_default_driver()
      name = name or normalize_path(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), driver.get_root_dir())

      local bufnr = vim.fn.bufnr(name, false)

      local pos = { 1, 0 }
      if bufnr ~= -1 then
        pos = vim.api.nvim_win_get_cursor(0)
      end

      return {
        value = name,
        context = {
          row = pos[1],
          col = pos[2],
        },
      }
    end,

    --- the select function is called when a user selects an item from
    --- the corresponding list and can be nil if select_with_nil is true
    ---@param list_item? VimstoryListFileItem
    ---@param options VimstoryListFileOptions
    select = function(list_item, options)
      if list_item == nil then
        return
      end

      options = options or {}

      -- use exact name
      local bufnr = vim.fn.bufnr('^' .. list_item.value .. '$')
      local set_position = false
      if bufnr == -1 then -- must create a buffer!
        set_position = true
        -- bufnr = vim.fn.bufnr(list_item.value, true)
        bufnr = vim.fn.bufadd(list_item.value)
      end
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_option_value('buflisted', true, {
          buf = bufnr,
        })
      end

      if options.vsplit then
        vim.cmd('vsplit')
      elseif options.split then
        vim.cmd('split')
      elseif options.tabedit then
        vim.cmd('tabedit')
      end

      vim.api.nvim_set_current_buf(bufnr)

      if set_position then
        local lines = vim.api.nvim_buf_line_count(bufnr)

        --local edited = false
        if list_item.context.row > lines then
          list_item.context.row = lines
          --edited = true
        end

        local row = list_item.context.row
        local row_text = vim.api.nvim_buf_get_lines(0, row - 1, row, false)
        local col = #row_text[1]

        if list_item.context.col > col then
          list_item.context.col = col
          --edited = true
        end

        vim.api.nvim_win_set_cursor(0, {
          list_item.context.row or 1,
          list_item.context.col or 0,
        })
      end
    end,

    ---@param obj VimstoryListItem
    ---@return string
    encode = function(obj)
      return vim.json.encode(obj)
    end,

    ---@param str string
    ---@return VimstoryListItem
    decode = function(str)
      return vim.json.decode(str)
    end,
  }
end

---@param partial_driver VimstoryDriverOverride?
---@param full_driver VimstoryDriver?
---@return VimstoryDriver
function M.merge_driver(partial_driver, full_driver)
  partial_driver = partial_driver or {}
  local driver = full_driver or M.get_default_driver()
  vim.tbl_extend('force', driver, partial_driver)
  return driver
end

return M
