local M = {}

local ns = vim.api.nvim_create_namespace("blame_virtual_text")

--- Build the virtual-text string for a blame entry, applying continuation merging and truncation.
function M.format_entry(entry, prev_hash, config)
	local merge_consecutive = config.merge_consecutive ~= false
	if merge_consecutive and entry.hash == prev_hash then
		return " │"
	end
	local text = config.format(entry)
	local max_length = config.max_length
	if max_length and #text > max_length then
		text = text:sub(1, max_length) .. "…"
	end
	return " " .. text
end

--- Set per-line virtual-text extmarks for every blame entry.
function M.apply_virtual_text(bufnr, blame_data, line_count, commit_color, config)
	local prev_hash = nil
	for lnum = 1, line_count do
		local entry = blame_data[lnum]
		if entry then
			local text = M.format_entry(entry, prev_hash, config)
			vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, 0, {
				virt_text = { { text, commit_color[entry.hash] } },
				virt_text_pos = "right_align",
			})
			prev_hash = entry.hash
		else
			prev_hash = nil
		end
	end
end

--- Show virtual text blame on every line of a buffer.
--- @param bufnr number
--- @param blame_data table[]
--- @param config table
function M.enable(bufnr, blame_data, config)
	M.disable(bufnr)
	local highlight_groups = config.highlight_groups or { "BlameNvimCommit1", "BlameNvimCommit2" }
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local commit_color = require("blame.highlights").assign_commit_colors(blame_data, line_count, highlight_groups)
	M.apply_virtual_text(bufnr, blame_data, line_count, commit_color, config)
end

--- Clear all blame virtual text from a buffer.
--- @param bufnr number
function M.disable(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
