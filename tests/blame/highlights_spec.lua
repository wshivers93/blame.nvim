local highlights = require("blame.highlights")

describe("highlights.assign_commit_colors", function()
	local groups = { "BlameNvimCommit1", "BlameNvimCommit2" }

	it("assigns colors in order of first appearance", function()
		local by_line = {
			[1] = { hash = "aaaaaaa" },
			[2] = { hash = "bbbbbbb" },
			[3] = { hash = "aaaaaaa" },
		}

		local colors = highlights.assign_commit_colors(by_line, 3, groups)

		assert.are.equal("BlameNvimCommit1", colors["aaaaaaa"])
		assert.are.equal("BlameNvimCommit2", colors["bbbbbbb"])
	end)

	it("cycles through highlight groups", function()
		local by_line = {
			[1] = { hash = "aaaaaaa" },
			[2] = { hash = "bbbbbbb" },
			[3] = { hash = "ccccccc" },
		}

		local colors = highlights.assign_commit_colors(by_line, 3, groups)

		assert.are.equal("BlameNvimCommit1", colors["aaaaaaa"])
		assert.are.equal("BlameNvimCommit2", colors["bbbbbbb"])
		assert.are.equal("BlameNvimCommit1", colors["ccccccc"])
	end)

	it("skips lines with no blame entry", function()
		local by_line = {
			[1] = { hash = "aaaaaaa" },
			[3] = { hash = "bbbbbbb" },
		}

		local colors = highlights.assign_commit_colors(by_line, 3, groups)

		assert.are.equal("BlameNvimCommit1", colors["aaaaaaa"])
		assert.are.equal("BlameNvimCommit2", colors["bbbbbbb"])
	end)
end)
