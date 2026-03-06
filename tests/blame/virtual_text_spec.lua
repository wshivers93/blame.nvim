local virtual_text = require("blame.virtual_text")

describe("virtual_text", function()
  local bufnr
  local ns = vim.api.nvim_create_namespace("blame_virtual_text")
  local blame_data = {
    { hash = "abc1234", author = "Jane", date = "2024-01-01", summary = "init", lnum = 1 },
    { hash = "def5678", author = "John", date = "2024-01-02", summary = "fix", lnum = 2 },
  }

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "line one", "line two" })
  end)

  after_each(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end)

  it("creates extmarks when enabled", function()
    virtual_text.enable(bufnr, blame_data, "Comment")

    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
    assert.are.equal(2, #marks)
  end)

  it("clears extmarks when disabled", function()
    virtual_text.enable(bufnr, blame_data, "Comment")
    virtual_text.disable(bufnr)

    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
    assert.are.equal(0, #marks)
  end)

  it("round-trip enable/disable leaves buffer clean", function()
    local marks_before = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
    virtual_text.enable(bufnr, blame_data, "Comment")
    virtual_text.disable(bufnr)
    local marks_after = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})

    assert.are.same(marks_before, marks_after)
  end)
end)
