local virtual_text = require("blame.virtual_text")

describe("virtual_text", function()
	local bufnr
	local ns = vim.api.nvim_create_namespace("blame_virtual_text")
	local blame_data = {
		{ hash = "abc1234", author = "Jane", date = "2024-01-01", summary = "init", lnum = 1 },
		{ hash = "def5678", author = "John", date = "2024-01-02", summary = "fix", lnum = 2 },
	}
	local format = function(entry)
		return string.format("%s %s %s %s", entry.hash, entry.author, entry.date, entry.summary)
	end
	local base_config = {
		format = format,
		merge_consecutive = false,
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
		virtual_text.enable(bufnr, blame_data, base_config)

		local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
		assert.are.equal(2, #marks)
	end)

	it("clears extmarks when disabled", function()
		virtual_text.enable(bufnr, blame_data, base_config)
		virtual_text.disable(bufnr)

		local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
		assert.are.equal(0, #marks)
	end)

	it("truncates text when max_length is set", function()
		local config = vim.tbl_extend("force", base_config, { max_length = 10 })
		virtual_text.enable(bufnr, blame_data, config)

		local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
		for _, mark in ipairs(marks) do
			local virt_text = mark[4].virt_text[1][1]
			-- leading space + 10 chars + "…" (3 bytes UTF-8) = 14
			assert.is_true(#virt_text <= 14)
		end
	end)

	it("does not truncate when max_length is nil", function()
		virtual_text.enable(bufnr, blame_data, base_config)

		local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
		local virt_text = marks[1][4].virt_text[1][1]
		-- full text: " abc1234 Jane 2024-01-01 init" = 30 chars
		assert.is_true(#virt_text > 12)
	end)

	it("round-trip enable/disable leaves buffer clean", function()
		local marks_before = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
		virtual_text.enable(bufnr, blame_data, base_config)
		virtual_text.disable(bufnr)
		local marks_after = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})

		assert.are.same(marks_before, marks_after)
	end)
end)
