---@class VimstoryToggleOptions
---@field border? any this value is directly passed to nvim_open_win
---@field title_pos? any this value is directly passed to nvim_open_win
---@field title? string this value is directly passed to nvim_open_win
---@field ui_fallback_width? number used if we can't get the current window
---@field ui_width_ratio? number this is the ratio of the editor window to use
---@field ui_max_width? number this is the max width the window can be
---@field height_in_lines? number this is the max height in lines that the window can be

---@return VimstoryToggleOptions
local function toggle_config(config)
  return vim.tbl_extend('force', {
    ui_fallback_width = 69,
    ui_width_ratio = 0.62569,
  }, config or {})
end

---@class VimstoryUI
---@field win_id number
---@field bufnr number
---@field settings VimstorySettings
---@field active_list VimstoryList
local VimstoryUI = {}

---@param list VimstoryList
---@return string
local function list_name(list)
  return list and list.name or 'nil'
end
