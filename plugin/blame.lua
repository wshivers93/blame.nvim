if vim.g.loaded_blame then
	return
end
vim.g.loaded_blame = true

-- Default highlight groups that link to theme colors so they adapt automatically
vim.api.nvim_set_hl(0, "BlameNvimCommit1", { link = "DiagnosticInfo", default = true })
vim.api.nvim_set_hl(0, "BlameNvimCommit2", { link = "DiagnosticHint", default = true })
vim.api.nvim_set_hl(0, "BlameNvimCommitDim", { link = "Comment", default = true })

require("blame").setup()
