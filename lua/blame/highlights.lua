local M = {}

--- Assign highlight groups to commits in order of first appearance (top to bottom).
--- @param by_line table<number, table> Map of line number to blame entry
--- @param line_count number Total lines in the buffer
--- @param highlight_groups string[] Available highlight group names
--- @return table<string, string> Map of commit hash to highlight group name
function M.assign_commit_colors(by_line, line_count, highlight_groups)
	local colors = {}
	local count = 0
	for lnum = 1, line_count do
		local entry = by_line[lnum]
		if entry and not colors[entry.hash] then
			count = count + 1
			colors[entry.hash] = highlight_groups[((count - 1) % #highlight_groups) + 1]
		end
	end
	return colors
end

return M
