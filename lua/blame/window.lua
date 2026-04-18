local M = {}

local ns = vim.api.nvim_create_namespace("blame_window")

--- Open a blame side window for the given buffer.
--- @param source_bufnr number
--- @param blame_data table[]
--- @param config table
--- @return { win: number, buf: number }
function M.enable(source_bufnr, blame_data, config)
	local format = config.format
	local highlight_groups = config.highlight_groups or { "BlameNvimCommit1", "BlameNvimCommit2" }
	local width_cfg = config.window_width or { min = 25, max = 40 }

	local line_count = vim.api.nvim_buf_line_count(source_bufnr)
	local lines = {}
	local blame_by_line = {}

	for _, entry in ipairs(blame_data) do
		blame_by_line[entry.lnum] = entry
	end

	for i = 1, line_count do
		local entry = blame_by_line[i]
		if entry then
			table.insert(lines, format(entry))
		else
			table.insert(lines, "")
		end
	end

	-- Find max width for the blame window
	local max_width = 0
	for _, line in ipairs(lines) do
		if #line > max_width then
			max_width = #line
		end
	end
	max_width = math.min(math.max(max_width, width_cfg.min), width_cfg.max)

	local source_win = vim.api.nvim_get_current_win()

	-- Create blame buffer
	local blame_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(blame_buf, 0, -1, false, lines)
	vim.bo[blame_buf].buftype = "nofile"
	vim.bo[blame_buf].modifiable = false
	vim.bo[blame_buf].filetype = "blame"

	-- Apply per-commit highlight groups
	local commit_color = require("blame.highlights").assign_commit_colors(blame_by_line, line_count, highlight_groups)
	for i = 1, line_count do
		local entry = blame_by_line[i]
		if entry then
			vim.api.nvim_buf_add_highlight(blame_buf, ns, commit_color[entry.hash], i - 1, 0, -1)
		end
	end

	-- Open split to the left
	vim.cmd("topleft vsplit")
	local blame_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(blame_win, blame_buf)
	vim.api.nvim_win_set_width(blame_win, max_width)

	-- Configure blame window
	vim.wo[blame_win].number = false
	vim.wo[blame_win].relativenumber = false
	vim.wo[blame_win].signcolumn = "no"
	vim.wo[blame_win].foldcolumn = "0"
	vim.wo[blame_win].wrap = false
	vim.wo[blame_win].cursorbind = true
	vim.wo[blame_win].scrollbind = true

	-- Enable scrollbind on source window
	vim.api.nvim_set_current_win(source_win)
	vim.wo[source_win].cursorbind = true
	vim.wo[source_win].scrollbind = true

	-- Sync scroll positions
	vim.cmd("syncbind")

	return { win = blame_win, buf = blame_buf }
end

--- Close the blame side window and clean up.
--- @param info { win: number, buf: number }
--- @param source_win number|nil
function M.disable(info, source_win)
	if info.win and vim.api.nvim_win_is_valid(info.win) then
		vim.api.nvim_win_close(info.win, true)
	end
	if info.buf and vim.api.nvim_buf_is_valid(info.buf) then
		vim.api.nvim_buf_delete(info.buf, { force = true })
	end
	-- Remove scrollbind from source window
	if source_win and vim.api.nvim_win_is_valid(source_win) then
		vim.wo[source_win].cursorbind = false
		vim.wo[source_win].scrollbind = false
	end
end

return M
