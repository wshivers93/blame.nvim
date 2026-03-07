local M = {}

M.config = {
  date_format = "%Y-%m-%d",
  virtual_text_hl = "Comment",
  format = function(entry)
    return string.format("%s %s %s %s", entry.hash, entry.author, entry.date, entry.summary)
  end,
}

-- Per-buffer state: { [bufnr] = { virtual_text = bool, window = { win, buf } | nil, source_win = number | nil } }
local state = {}

local function get_state(bufnr)
  if not state[bufnr] then
    state[bufnr] = { virtual_text = false, window = nil, source_win = nil }
  end
  return state[bufnr]
end

local function get_file(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return nil
  end
  return file
end

--- Toggle virtual text blame for the current buffer.
function M.toggle_virtual_text()
  local bufnr = vim.api.nvim_get_current_buf()
  local s = get_state(bufnr)

  if s.virtual_text then
    require("blame.virtual_text").disable(bufnr)
    s.virtual_text = false
    return
  end

  local file = get_file(bufnr)
  if not file then
    vim.notify("blame.nvim: buffer has no file", vim.log.levels.WARN)
    return
  end

  require("blame.git").blame(file, M.config.date_format, function(err, data)
    if err then
      vim.notify("blame.nvim: " .. err, vim.log.levels.ERROR)
      return
    end
    require("blame.virtual_text").enable(bufnr, data, M.config.virtual_text_hl, M.config.format)
    s.virtual_text = true
  end)
end

--- Toggle window blame for the current buffer.
function M.toggle_window()
  local bufnr = vim.api.nvim_get_current_buf()
  local s = get_state(bufnr)

  if s.window then
    require("blame.window").disable(s.window, s.source_win)
    s.window = nil
    s.source_win = nil
    return
  end

  local file = get_file(bufnr)
  if not file then
    vim.notify("blame.nvim: buffer has no file", vim.log.levels.WARN)
    return
  end

  require("blame.git").blame(file, M.config.date_format, function(err, data)
    if err then
      vim.notify("blame.nvim: " .. err, vim.log.levels.ERROR)
      return
    end
    local source_win = vim.api.nvim_get_current_win()
    local info = require("blame.window").enable(bufnr, data, M.config.format)
    s.window = info
    s.source_win = source_win
  end)
end

--- Setup the plugin with user options.
--- @param opts table|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("BlameToggle", function()
    M.toggle_virtual_text()
  end, { desc = "Toggle git blame virtual text" })

  vim.api.nvim_create_user_command("BlameToggleWindow", function()
    M.toggle_window()
  end, { desc = "Toggle git blame side window" })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = vim.api.nvim_create_augroup("blame_cleanup", { clear = true }),
    callback = function(args)
      state[args.buf] = nil
    end,
  })
end

return M
