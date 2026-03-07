if vim.g.loaded_blame then
	return
end
vim.g.loaded_blame = true

require("blame").setup()
