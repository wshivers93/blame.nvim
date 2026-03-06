# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

blame.nvim is a Neovim plugin written in Lua that toggles git blame annotations. Two display modes: inline virtual text (`:BlameToggle`) and a scroll-synced side window (`:BlameToggleWindow`). Requires Neovim 0.10+ for `vim.system()`.

## Architecture

```
plugin/blame.lua          → entry point, guards double-load, calls setup()
lua/blame/init.lua        → public API: setup(opts), toggle_virtual_text(), toggle_window()
lua/blame/git.lua         → async git blame --porcelain runner + parser
lua/blame/virtual_text.lua → extmark-based inline blame display
lua/blame/window.lua      → side-split blame window with scrollbind
```

**Flow:** User command → `init.toggle_*()` → checks per-buffer state → if off, runs `git.blame()` async → callback enables display via `virtual_text` or `window` module. If already on, disables immediately.

**State:** Per-buffer table in `init.lua` tracks `{ virtual_text = bool, window = {win, buf} | nil, source_win }`.

## Development

### Formatting

```bash
stylua lua/ plugin/
stylua --check lua/ plugin/
```

## Conventions

- Public API in `lua/blame/init.lua`; internal modules are separate files under `lua/blame/`
- Use `vim.api`, `vim.fn`, `vim.system` for Neovim interaction; avoid legacy VimL
- User-facing commands and config go through `setup(opts)`
- Git interaction is async via `vim.system()` with `vim.schedule()` for callbacks
