local M = {}

--- Parse git blame --porcelain output into a table of blame entries per line.
--- @param output string Raw porcelain output
--- @param date_format string strftime format for dates
--- @return table[] List of { hash, author, date, summary, lnum }
function M.parse_porcelain(output, date_format)
  local results = {}
  local current = {}

  for line in output:gmatch("[^\n]+") do
    -- Header line: <hash> <orig_line> <final_line> [<num_lines>]
    local hash, _, final_line = line:match("^(%x+) (%d+) (%d+)")
    if hash and #hash >= 40 then
      current = { hash = hash:sub(1, 7), lnum = tonumber(final_line) }
    elseif line:match("^author ") then
      current.author = line:sub(8)
    elseif line:match("^author%-time ") then
      local timestamp = tonumber(line:sub(13))
      current.date = os.date(date_format, timestamp)
    elseif line:match("^summary ") then
      current.summary = line:sub(9)
    elseif line:match("^\t") then
      -- Content line marks end of this entry
      if current.lnum then
        table.insert(results, {
          hash = current.hash or "",
          author = current.author or "",
          date = current.date or "",
          summary = current.summary or "",
          lnum = current.lnum,
        })
      end
    end
  end

  return results
end

--- Run git blame asynchronously on a file.
--- @param file string Absolute path to the file
--- @param date_format string strftime format for dates
--- @param callback fun(err: string|nil, data: table[]|nil)
function M.blame(file, date_format, callback)
  vim.system(
    { "git", "blame", "--porcelain", "--", file },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          callback(result.stderr or "git blame failed", nil)
          return
        end
        local data = M.parse_porcelain(result.stdout, date_format)
        callback(nil, data)
      end)
    end
  )
end

return M
