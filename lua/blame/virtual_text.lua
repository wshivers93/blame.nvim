local M = {}

local ns = vim.api.nvim_create_namespace("blame_virtual_text")

--- Show virtual text blame on every line of a buffer.
--- @param bufnr number
--- @param blame_data table[]
--- @param hl_group string Highlight group for the virtual text
--- @param format fun(entry: table): string
function M.enable(bufnr, blame_data, hl_group, format)
  M.disable(bufnr)
  for _, entry in ipairs(blame_data) do
    local line = entry.lnum - 1 -- 0-indexed
    if line >= 0 and line < vim.api.nvim_buf_line_count(bufnr) then
      vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
        virt_text = { { " " .. format(entry), hl_group } },
        virt_text_pos = "right_align",
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
