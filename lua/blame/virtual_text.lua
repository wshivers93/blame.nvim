local M = {}

local ns = vim.api.nvim_create_namespace("blame_virtual_text")

--- Show virtual text blame on every line of a buffer.
--- @param bufnr number
--- @param blame_data table[]
--- @param config table
function M.enable(bufnr, blame_data, config)
	M.disable(bufnr)

	local highlight_groups = config.highlight_groups or { "BlameNvimCommit1", "BlameNvimCommit2" }
	local merge_consecutive = config.merge_consecutive ~= false
	local format = config.format
	local max_length = config.max_length

	-- Build a sorted list of entries by line number
	local sorted = {}
	for _, entry in ipairs(blame_data) do
		sorted[entry.lnum] = entry
	end

	-- Assign a color index to each unique commit, in order of first appearance
	local commit_color = {}
	local color_count = 0
	local prev_hash = nil

	for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
		local entry = sorted[lnum]
		if not entry then
			prev_hash = nil
		else
			local hash = entry.hash
			if not commit_color[hash] then
				color_count = color_count + 1
				commit_color[hash] = ((color_count - 1) % #highlight_groups) + 1
			end

			local line = lnum - 1 -- 0-indexed
			local is_continuation = merge_consecutive and hash == prev_hash

			if is_continuation then
				vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
					virt_text = { { " │", "BlameNvimCommitDim" } },
					virt_text_pos = "right_align",
				})
			else
				local text = format(entry)
				if max_length and #text > max_length then
					text = text:sub(1, max_length) .. "…"
				end
				local hl = highlight_groups[commit_color[hash]]
				vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
					virt_text = { { " " .. text, hl } },
					virt_text_pos = "right_align",
				})
			end

			prev_hash = hash
		end
	end
end

--- Clear all blame virtual text from a buffer.
--- @param bufnr number
function M.disable(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
