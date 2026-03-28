local blame = require("blame")

describe("setup", function()
	before_each(function()
		blame.setup()
	end)

	it("registers BufDelete autocmd for state cleanup", function()
		local autocmds = vim.api.nvim_get_autocmds({
			group = "blame_cleanup",
			event = "BufDelete",
		})

		assert.are.equal(1, #autocmds)
	end)

	it("creates BlameToggle command", function()
		local ok = pcall(vim.api.nvim_get_commands, {})
		assert.is_true(ok)
		assert.is_truthy(vim.fn.exists(":BlameToggle") == 2)
	end)

	it("creates BlameToggleWindow command", function()
		assert.is_truthy(vim.fn.exists(":BlameToggleWindow") == 2)
	end)
end)
