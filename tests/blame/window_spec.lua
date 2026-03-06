local window = require("blame.window")

describe("window", function()
  local source_bufnr
  local blame_data = {
    { hash = "abc1234", author = "Jane", date = "2024-01-01", summary = "init", lnum = 1 },
    { hash = "def5678", author = "John", date = "2024-01-02", summary = "fix", lnum = 2 },
  }

  before_each(function()
    -- Close all windows except the current one
    vim.cmd("only")
    source_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(source_bufnr, 0, -1, false, { "line one", "line two" })
    vim.api.nvim_set_current_buf(source_bufnr)
  end)

  after_each(function()
    -- Clean up all windows and buffers
    vim.cmd("only")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end)

  it("creates a new window and buffer", function()
    local info = window.enable(source_bufnr, blame_data)

    assert.is_truthy(vim.api.nvim_win_is_valid(info.win))
    assert.is_truthy(vim.api.nvim_buf_is_valid(info.buf))

    -- Clean up
    window.disable(info, vim.api.nvim_get_current_win())
  end)

  it("blame window has correct properties", function()
    local info = window.enable(source_bufnr, blame_data)

    assert.are.equal("nofile", vim.bo[info.buf].buftype)
    assert.is_false(vim.bo[info.buf].modifiable)
    assert.are.equal("blame", vim.bo[info.buf].filetype)
    assert.is_true(vim.wo[info.win].scrollbind)
    assert.is_true(vim.wo[info.win].cursorbind)

    window.disable(info, vim.api.nvim_get_current_win())
  end)

  it("disable closes window and removes scrollbind from source", function()
    local source_win = vim.api.nvim_get_current_win()
    local info = window.enable(source_bufnr, blame_data)

    window.disable(info, source_win)

    assert.is_false(vim.api.nvim_win_is_valid(info.win))
    assert.is_false(vim.wo[source_win].scrollbind)
    assert.is_false(vim.wo[source_win].cursorbind)
  end)
end)
