# blame.nvim

A lightweight Neovim plugin for toggling git blame annotations. Two display modes: inline virtual text and a scroll-synced side window.

Requires Neovim 0.10+.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "wshivers93/blame.nvim",
  opts = {},
}
```

## Commands

| Command              | Description                                       |
| -------------------- | ------------------------------------------------- |
| `:BlameToggle`       | Toggle inline blame as right-aligned virtual text |
| `:BlameToggleWindow` | Toggle a scroll-synced blame side window          |
| `:BlameShowCommit`   | Show commit details for the current line          |

## Configuration

All options are optional. Below are the defaults:

```lua
{
  "wshivers93/blame.nvim",
  opts = {
    -- strftime format for dates
    date_format = "%Y-%m-%d",

    -- Highlight group for inline virtual text
    virtual_text_hl = "Comment",

    -- Formatter function for blame text
    -- Receives an entry with: hash, author, date, summary
    format = function(entry)
      return string.format("%s %s %s %s", entry.hash, entry.author, entry.date, entry.summary)
    end,
  },
}
```

### `format`

The `format` function controls how each blame line is displayed in both inline and window modes. It receives a table with the following fields:

| Field     | Type   | Example            |
| --------- | ------ | ------------------ |
| `hash`    | string | `"abc1234"`        |
| `author`  | string | `"Jane Doe"`       |
| `date`    | string | `"2024-01-15"`     |
| `summary` | string | `"Initial commit"` |

Example — show only author and summary:

```lua
opts = {
  format = function(entry)
    return string.format("%s: %s", entry.author, entry.summary)
  end,
}
```

## Keymaps

The plugin does not set any keymaps. Add them via the `keys` field in your lazy.nvim spec:

```lua
{
  "wshivers93/blame.nvim",
  opts = {},
  keys = {
    { "<leader>gb", "<cmd>BlameToggle<cr>", desc = "Toggle git blame" },
    { "<leader>gB", "<cmd>BlameToggleWindow<cr>", desc = "Toggle git blame window" },
    { "<leader>gc", "<cmd>BlameShowCommit<cr>", desc = "Show commit details" },
  },
}
```
