local M = {}

local ns = vim.api.nvim_create_namespace("blame_window")

function M.handleEntry(entry, prev_hash, config)
	local merge_consecutive = config.merge_consecutive ~= false
	if merge_consecutive and entry.hash == prev_hash then
		return "│"
	end
	return config.format(entry)
end

--- Build display lines, per-commit color map, and final clamped max width.
--- @return string[], table<string, string>, number
function M.build_display(blame_data, line_count, config)
	local highlight_groups = config.highlight_groups or { "BlameNvimCommit1", "BlameNvimCommit2" }
	local width_cfg = config.window_width or { min = 25, max = 40 }

	local commit_color = require("blame.highlights").assign_commit_colors(blame_data, line_count, highlight_groups)

	local lines = {}
	local max_width = 0
	local prev_hash = nil

	for i = 1, line_count do
		local entry = blame_data[i]
		local line
		if entry then
			line = M.handleEntry(entry, prev_hash, config)
			prev_hash = entry.hash
		else
			line = ""
			prev_hash = nil
		end
		lines[i] = line
		if #line > max_width then
			max_width = #line
		end
	end
	max_width = math.min(math.max(max_width, width_cfg.min), width_cfg.max)

	return lines, commit_color, max_width
end

--- Create a scratch buffer populated with the blame lines.
--- @return number bufnr
function M.create_buffer(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "blame"
	return buf
end

--- Apply per-line commit highlights to the blame buffer.
function M.apply_highlights(buf, blame_data, line_count, commit_color)
	for i = 1, line_count do
		local entry = blame_data[i]
		if entry then
			vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
				line_hl_group = commit_color[entry.hash],
			})
		end
	end
end

--- Open the blame side split and configure its window options.
--- @return number winid
function M.open_window(buf, width)
	local win = vim.api.nvim_open_win(buf, true, {
		split = "left",
		win = -1,
	})
	vim.api.nvim_win_set_width(win, width)

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].wrap = false
	vim.wo[win].cursorbind = true
	vim.wo[win].scrollbind = true

	return win
end

--- Enable scrollbind on the source window and sync positions.
function M.bind_scroll(source_win)
	vim.api.nvim_set_current_win(source_win)
	vim.wo[source_win].cursorbind = true
	vim.wo[source_win].scrollbind = true
	vim.cmd("syncbind")
end

--- Open a blame side window for the given buffer.
--- @param source_bufnr number
--- @param blame_data table[]
--- @param config table
--- @return { win: number, buf: number }
function M.enable(source_bufnr, blame_data, config)
	local line_count = vim.api.nvim_buf_line_count(source_bufnr)
	local source_win = vim.api.nvim_get_current_win()

	local lines, commit_color, max_width = M.build_display(blame_data, line_count, config)
	local blame_buf = M.create_buffer(lines)
	M.apply_highlights(blame_buf, blame_data, line_count, commit_color)
	local blame_win = M.open_window(blame_buf, max_width)
	M.bind_scroll(source_win)

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
	if source_win and vim.api.nvim_win_is_valid(source_win) then
		vim.wo[source_win].cursorbind = false
		vim.wo[source_win].scrollbind = false
	end
end

return M
