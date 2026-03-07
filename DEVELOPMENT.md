# Development

## Prerequisites

- Neovim 0.10+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for tests)
- [StyLua](https://github.com/JohnnyMorganz/StyLua) (for formatting)

## Local Setup

Clone the repo and ensure plenary.nvim is installed. The test runner expects it at the lazy.nvim default path (`~/.local/share/nvim/lazy/plenary.nvim`). Override by setting `PLENARY_PATH`:

```bash
export PLENARY_PATH=/path/to/plenary.nvim
```

To load the plugin from your local checkout, add it to your lazy.nvim config with `dir`:

```lua
{ dir = "~/projects/nvim_plugins/blame.nvim", opts = {} }
```

## Running Tests

```bash
# All tests
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Single file
nvim --headless -c "PlenaryBustedFile tests/blame/git_spec.lua"
```

## Formatting

```bash
# Format
stylua lua/ plugin/

# Check only
stylua --check lua/ plugin/
```

## How It Works

### Architecture

```
plugin/blame.lua           → entry point, guards double-load, calls setup()
lua/blame/init.lua         → public API: setup(opts), toggle_virtual_text(), toggle_window()
lua/blame/git.lua          → async git blame --porcelain runner + parser
lua/blame/virtual_text.lua → extmark-based inline blame display
lua/blame/window.lua       → side-split blame window with scrollbind
```

### Flow

1. `plugin/blame.lua` loads on startup, calls `require("blame").setup()` to register `:BlameToggle` and `:BlameToggleWindow` commands.
2. When a user runs a command, `init.lua` checks per-buffer state to determine if blame is currently active.
3. **Toggling on:** `git.blame()` runs `git blame --porcelain` asynchronously via `vim.system()`. On completion, the callback is scheduled back to the main loop with `vim.schedule()`, then the parsed blame data is passed to either `virtual_text.enable()` or `window.enable()`.
4. **Toggling off:** the display module's `disable()` is called immediately (no git call needed).

### Modules

**`git.lua`** — Runs `git blame --porcelain` and parses the output. `parse_porcelain()` is pure Lua with no Neovim dependencies, making it easy to unit test. Each entry produces `{ hash, author, date, summary, lnum }`.

**`virtual_text.lua`** — Uses `nvim_buf_set_extmark()` to place right-aligned virtual text on each line. All extmarks use a shared namespace so `disable()` can clear them in one call.

**`window.lua`** — Creates a scratch buffer with formatted blame lines and opens it in a left-side vertical split. Both the source and blame windows get `scrollbind` and `cursorbind` enabled. `disable()` closes the blame window and removes the bindings from the source.

### State Management

`init.lua` maintains a local `state` table keyed by buffer number, tracking whether virtual text or a blame window is active. A `BufDelete` autocmd cleans up entries when buffers are deleted to prevent stale state.

### Submodule Loading

Submodules (`git`, `virtual_text`, `window`) are lazy-required on first use rather than at module load time, so `require("blame")` itself is lightweight.
