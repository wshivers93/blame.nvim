local git = require("blame.git")

describe("git.parse_porcelain", function()
	local date_format = "%Y-%m-%d"

	it("parses a single line blame entry", function()
		local output = table.concat({
			"abc1234567890abcdef1234567890abcdef12345678 1 1 1",
			"author Jane Doe",
			"author-mail <jane@example.com>",
			"author-time 1700000000",
			"author-tz +0000",
			"committer Jane Doe",
			"committer-mail <jane@example.com>",
			"committer-time 1700000000",
			"committer-tz +0000",
			"summary Initial commit",
			"filename test.lua",
			"\tlocal x = 1",
		}, "\n")

		local results = git.parse_porcelain(output, date_format)

		assert.are.equal(1, #results)
		assert.are.equal("abc1234", results[1].hash)
		assert.are.equal("Jane Doe", results[1].author)
		assert.are.equal("Initial commit", results[1].summary)
		assert.are.equal(1, results[1].lnum)
		assert.is_truthy(results[1].date:match("^%d%d%d%d%-%d%d%-%d%d$"))
	end)

	it("parses multiple lines from the same commit", function()
		local lines = {}
		for i = 1, 3 do
			-- Only the first line of a commit group has the count field;
			-- subsequent lines reuse the same hash header.
			local header = "abc1234567890abcdef1234567890abcdef12345678 " .. i .. " " .. i
			if i == 1 then
				header = header .. " 3"
			end
			vim.list_extend(lines, {
				header,
				"author Jane Doe",
				"author-time 1700000000",
				"summary Initial commit",
				"filename test.lua",
				"\tline " .. i,
			})
		end

		local results = git.parse_porcelain(table.concat(lines, "\n"), date_format)

		assert.are.equal(3, #results)
		for i = 1, 3 do
			assert.are.equal(i, results[i].lnum)
			assert.are.equal("abc1234", results[i].hash)
		end
	end)

	it("parses entries from multiple different commits", function()
		local output = table.concat({
			"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111 1 1 1",
			"author Alice",
			"author-time 1700000000",
			"summary First commit",
			"filename test.lua",
			"\tline 1",
			"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2222 2 2 1",
			"author Bob",
			"author-time 1700100000",
			"summary Second commit",
			"filename test.lua",
			"\tline 2",
		}, "\n")

		local results = git.parse_porcelain(output, date_format)

		assert.are.equal(2, #results)
		assert.are.equal("aaaaaaa", results[1].hash)
		assert.are.equal("Alice", results[1].author)
		assert.are.equal("First commit", results[1].summary)
		assert.are.equal("bbbbbbb", results[2].hash)
		assert.are.equal("Bob", results[2].author)
		assert.are.equal("Second commit", results[2].summary)
	end)

	it("propagates metadata to subsequent occurrences of the same commit", function()
		-- Simulates real porcelain output where a commit appears non-consecutively.
		-- Metadata is only present on the first occurrence; subsequent ones
		-- only have the header, filename, and content line.
		local output = table.concat({
			"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111 1 1 1",
			"author Alice",
			"author-time 1700000000",
			"summary First commit",
			"filename test.lua",
			"\tline 1",
			"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2222 2 2 1",
			"author Bob",
			"author-time 1700100000",
			"summary Second commit",
			"filename test.lua",
			"\tline 2",
			"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111 3 3",
			"filename test.lua",
			"\tline 3",
		}, "\n")

		local results = git.parse_porcelain(output, date_format)

		assert.are.equal(3, #results)
		-- Third line reuses commit aaa... — should have Alice's metadata
		assert.are.equal("aaaaaaa", results[3].hash)
		assert.are.equal("Alice", results[3].author)
		assert.are.equal("First commit", results[3].summary)
		assert.is_truthy(results[3].date:match("^%d%d%d%d%-%d%d%-%d%d$"))
	end)

	it("returns empty table for empty output", function()
		local results = git.parse_porcelain("", date_format)
		assert.are.same({}, results)
	end)
end)
