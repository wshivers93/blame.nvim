local M = {}

local ns = vim.api.nvim_create_namespace("blame_virtual_text")

--- Format a blame entry into a display string.
--- @param entry table { hash, author, date, summary }
--- @return string
local function format_entry(entry)
  return string.format(" %s %s %s %s", entry.hash, entry.author, entry.date, entry.summary)
end

--- Show virtual text blame on every line of a buffer.
--- @param bufnr number
--- @param blame_data table[]
--- @param hl_group string Highlight group for the virtual text
function M.enable(bufnr, blame_data, hl_group)
  M.disable(bufnr)
  for _, entry in ipairs(blame_data) do
    local line = entry.lnum - 1 -- 0-indexed
    if line >= 0 and line < vim.api.nvim_buf_line_count(bufnr) then
      vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
        virt_text = { { format_entry(entry), hl_group } },
        virt_text_pos = "eol",
      })
    end
  end
end

--- Clear all blame virtual text from a buffer.
--- @param bufnr number
function M.disable(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
