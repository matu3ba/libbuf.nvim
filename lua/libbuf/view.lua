--! Helpers to store and load tab window settings.

local M = {}
local api = vim.api

--@class WindowView
--@field width
--@field height

---@class TabView
---@field arg1 number
---@field arg2 string

-- Intended storage for window settings and visiable buffers.
---@TabView[]
M._tabviews = {}

-- yoinked from https://stackoverflow.com/a/73931737
M.printAllWinOptions = function()
  local win_number = api.nvim_get_current_win()
  local v = vim.wo[win_number]
  local all_options = api.nvim_get_all_options_info()
  local result = ''
  for key, val in pairs(all_options) do
    if val.global_local == false and val.scope == 'win' then
      result = result .. '|' .. key .. '=' .. tostring(v[key] or '<not set>')
    end
  end
  print(result)
end

-- Prints view data for regular windows with default settings and variables.
M.printAllTabInfos = function()
  local reg_wins = M.TabView()
  print(vim.inspect(reg_wins))
end

-- Returns view data for regular windows with default settings and variables.
---@return table reg_win_info
M.getTabView = function()
  local windows = api.nvim_tabpage_list_wins(0)
  local reg_wins = {}
  local i = 1
  for _, win in pairs(windows) do
    local cfg = vim.api.nvim_win_get_config(win) -- see nvim_open_win()
    -- check for absence of floating window
    if cfg.relative == '' then
      reg_wins[i] = {}
      local curwin_infos = vim.fn.getwininfo(win)
      -- reg_wins[i]["loclist"] = curwin_infos[1]["loclist"] -- unused
      -- reg_wins[i]["quickfix"] = curwin_infos[1]["quickfix"] -- unused
      -- reg_wins[i]["terminal"] = curwin_infos[1]["terminal"] --unused
      -- reg_wins[i]["topline"] = curwin_infos[1]["topline"] --unused
      -- reg_wins[i]["winbar"] = curwin_infos[1]["winbar"] -- unused
      reg_wins[i]['botline'] = curwin_infos[1]['botline'] -- botmost screen line
      reg_wins[i]['bufnr'] = curwin_infos[1]['bufnr'] -- buffer number
      reg_wins[i]['height'] = curwin_infos[1]['height'] -- window height excluding winbar
      reg_wins[i]['tabnr'] = curwin_infos[1]['tabnr']
      reg_wins[i]['textoff'] = curwin_infos[1]['textoff'] -- foldcolumn, signcolumn etc width
      reg_wins[i]['variables'] = curwin_infos[1]['variables'] --unused
      reg_wins[i]['width'] = curwin_infos[1]['width'] -- width (textoff to derive rightmost screen column)
      reg_wins[i]['wincol'] = curwin_infos[1]['wincol'] -- leftmost screen column of window
      reg_wins[i]['winid'] = curwin_infos[1]['winid']
      reg_wins[i]['winnr'] = curwin_infos[1]['winnr']
      reg_wins[i]['winrow'] = curwin_infos[1]['winrow'] -- topmost screen line

      local winpos = api.nvim_win_get_position(win) -- top left corner of window
      reg_wins[i]['row'] = winpos[1]
      reg_wins[i]['col'] = winpos[2]
      i = i + 1
    end
  end
  return reg_wins
end

-- Simplified version only taking into account idenically sized splits
-- along a full rectangle:
-- Windows can be grouped by following the direction of window numbers.
-- 1.                2.                      3.
--    1 | 2 |   |      |1 |2 |   |   | 6        | 1 | 2 | 3 | 4|
--   ---|---| 5 |      |-----| 4 | 5 |----      |--------------|
--    3 | 4 |   |      |  3  |   |   | 7        |       5      |
-- 1. allowed, because even though 5 has no split, it has full height
-- 2. not allowed, because 3 has no vsplit
-- 4. not allowed, because splits in 1,2 are not identical in 3.
-- 1 |   | 4 |   |
-- --| 3 |---| 6 | 7
-- 2 |   | 5 |   |            alternate for 1:
-- -----------------            1 | 3 |   |
--        8                    ---|---| 5 |
-- -----------------            2 | 4 |   |
--        9
-- -----------------
--        10
-- Then: Split order of alter for 1 can be recombined via grouping together
-- {1 spl 2} vspl {3 spl 4} vspl 5
-- Note: Reason is
--  |2|3| | |
--  |---|5| |
-- 1| 4 | |7| which makes things very convoluted.
--  |-----| |
--  |  6  | |
--  |--------
--  |     8 |
-- 2 cases: 1. is full width or full height or 2. has internal splits countable
-- as series (complex one 1, series(2..8).
-- for series: while(not (full width or full height)):
--   {op:item->next_item, 1:item, 2:next_item}
--   with item = curr_index, if next(next(curr_index)).winsize
-- Does not hold true unless introspection or backtracking!
---@param reg_wins table Regular windows info of a tab.
---@return integer status Status code with 0 as success and 1 as failure.
M.setTabView = function(reg_wins)
  -- clear current view except for last window.
  local windows = api.nvim_tabpage_list_wins(0)
  for _, win in pairs(windows) do
    local cfg = vim.api.nvim_win_get_config(win) -- see nvim_open_win()
    -- close floating windows (not to be restored)
    if cfg.relative == '' then
      vim.api.nvim_win_close(win, false)
      goto continue -- lua has no continue statement
    end
    if win['winnr'] == 1 then vim.api.nvim_win_close(win, false) end
    ::continue::
  end
  -- set supported simplified grid view 1,2,3
  local completed = {}
  completed.row = 1
  completed.col = 0
  while completed.row < vim.o.lines or completed.col < vim.o.columns do
    local direction = M.greedySetWinPositions(reg_wins, completed)
  end

  -- set new view.
  api.nvim_win_set_buf(1, reg_wins[1]['bufnr'])

  -- nvim_win_set_config, nvim_open_win

  -- for _, win in ipairs(reg_wins) do
  -- win["botline"] -- botmost screen line
  -- win["bufnr"] -- buffer number
  -- win["height"] -- window height excluding winbar
  -- win["tabnr"]
  -- win["textoff"] -- foldcolumn, signcolumn etc width
  -- win["variables"] --unused
  -- win["width"] -- width (textoff to derive rightmost screen column)
  -- win["wincol"] -- leftmost screen column of window
  -- win["winid"]
  -- win["winnr"]
  -- win["winrow"] -- topmost screen line
  -- end

  return 0
end

-- Returns whether rightwards or downwards split will fill page faster.
---@param reg_wins table Table of regular window info.
---@param completed table Table of winnr with completion status of xpos, ypos (width)
---@return integer direction 0 doesn't matter, 1 downwards, 2 rightwards, 3 is error.
M.setTabViewSimple = function(reg_wins, completed)
  local direction = 0
  -- table describing as rectangle from top left point, which parts have been redrawn.
  completed.row = 1
  completed.col = 0
  --downwards
  --rightwards

  return direction
end

return M
