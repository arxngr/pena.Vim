

# pena.Vim 🚀

**pena.Vim** is a modular Neovim configuration built on [LazyVim](https://github.com/LazyVim/LazyVim) with custom overrides. Designed for developers who want a fast, elegant, and extensible coding environment.

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-green)](https://neovim.io/) [![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

![pena.Vim Screenshot](https://github.com/user-attachments/assets/910c83fd-d163-490e-8784-77a349a56e0e)

---

## ✨ Features

* 🔧 LSP & autocompletion
* 🧪 Testing with [Neotest](https://github.com/nvim-neotest/neotest)
* 🐞 Debugging via [nvim-dap](https://github.com/mfussenegger/nvim-dap)
* 🗂️ File navigation with [Telescope Picker](https://github.com/nvim-telescope/snacks.nvim)
* 🧰 Terminal management with [ToggleTerm](https://github.com/akinsho/toggleterm.nvim)
* 🛠️ Project tasks via [Overseer](https://github.com/stevearc/overseer.nvim)
* 🌲 Floating file explorer: [Oil.nvim](https://github.com/stevearc/oil.nvim)
* 🎨 Theme switching: [Themery](https://github.com/zaldih/themery.nvim)
* 🔍 Search & replace: [grug-far](https://github.com/jesseleite/grug-far.nvim)
* 🚨 Diagnostics with [Trouble.nvim](https://github.com/folke/trouble.nvim)

---

## ⚡ Quick Install

```bash
# Backup current config
mv ~/.config/nvim ~/.config/nvim.backup

# Clone pena.Vim
git clone https://github.com/arxngr/pena.Vim ~/.config/nvim

# Launch Neovim to install plugins
nvim
```

> `lazy.nvim` auto-installs plugins on first launch.

---

## 🖥️ Requirements

* Neovim ≥ 0.9
* Git
* Lua 5.1 / LuaJIT
* LuaRocks

---

## ⌨️ Keybindings

### 🪄 General

| Mode  | Key       | Action                      |
| ----- | --------- | --------------------------- |
| `n`   | `c`       | Open config                 |
| `n`   | `<C-q>`   | Quit file                   |
| `n`   | `<Tab>`   | Next buffer                 |
| `n`   | `<S-Tab>` | Previous buffer             |
| `v`   | `<` / `>` | Indent left/right           |
| `n`   | `<C-c>`   | Copy to system clipboard    |
| `n/v` | `<C-v>`   | Paste from system clipboard |

### 🪟 Window & Terminal Navigation

| Mode | Key           | Action                          |
| ---- | ------------- | ------------------------------- |
| `n`  | `<C-h/j/k/l>` | Move between windows            |
| `t`  | `<C-h/j/k/l>` | Move between windows (terminal) |
| `t`  | `<C-x>`       | Exit terminal mode              |

### 🔍 Picker

| Key                | Action            |
| ------------------ | ----------------- |
| `<leader>ff`       | Find files        |
| `<leader>sb`       | Search in buffer  |
| `<leader>sg`       | Live grep         |
| `<leader>sd`       | Show diagnostics  |
| `<leader><leader>` | List open buffers |

### 🧪 Neotest

| Key          | Action              |
| ------------ | ------------------- |
| `<leader>tt` | Run current file    |
| `<leader>tr` | Run nearest test    |
| `<leader>tl` | Run last test       |
| `<leader>ts` | Toggle summary      |
| `<leader>to` | Show output         |
| `<leader>tO` | Toggle output panel |
| `<leader>tS` | Stop tests          |
| `<leader>tw` | Toggle watch mode   |

### 🐞 Debugging (nvim-dap)

| Key           | Action                   |
| ------------- | ------------------------ |
| `<leader>da`  | Start debugging          |
| `<leader>dc`  | Continue                 |
| `<leader>db`  | Toggle breakpoint        |
| `<leader>dq`  | Clear breakpoints        |
| `<leader>do`  | Step over                |
| `<leader>dO`  | Step out                 |
| `<leader>dr`  | Toggle REPL              |
| `<leader>dv`  | View scopes              |
| `<leader>dw`  | Hover variable           |
| `<leader>ds`  | View stacks              |
| `<leader>dlb` | View breakpoints (float) |
| `<leader>dh`  | View watches             |
| `<leader>td`  | Debug nearest test       |

### 🔧 Code

| Key          | Action           |
| ------------ | ---------------- |
| `gd`         | Go to definition |
| `gr`         | References       |
| `gI`         | Implementations  |
| `gt`         | Type definitions |
| `<leader>rn` | Rename symbol    |
| `<leader>ca` | Code actions     |

### 🧱 Misc Plugins

| Key          | Action                   |
| ------------ | ------------------------ |
| `<leader>dt` | Toggle floating terminal |
| `<leader>wv` | Vertical split           |
| `<leader>hv` | Horizontal split         |
| `<leader>e`  | Toggle Oil file explorer |
| `<leader>ut` | Toggle transparency      |
| `<leader>gg` | LazyGit                  |

### 📋 Trouble.nvim

| Key          | Action                        |
| ------------ | ----------------------------- |
| `<leader>xx` | Toggle diagnostics            |
| `<leader>xX` | Buffer diagnostics            |
| `<leader>cs` | Toggle symbols                |
| `<leader>cS` | LSP references/definitions    |
| `<leader>xL` | Location list                 |
| `<leader>xQ` | Quickfix list                 |
| `[q` / `]q`  | Prev/next quickfix or Trouble |

---

## 📂 Project Tasks (Overseer)

| Key          | Action                      |
| ------------ | --------------------------- |
| `<leader>ow` | Toggle task list            |
| `<leader>oo` | Run task                    |
| `<leader>oq` | Quick action on recent task |
| `<leader>oi` | View task info              |
| `<leader>ob` | Open task builder           |
| `<leader>ot` | Task action menu            |
| `<leader>oc` | Clear task cache            |

---

## 📄 License

MIT License – see [LICENSE](LICENSE)

---

## 🙏 Acknowledgments

* [Neovim](https://neovim.io/)
* [lazy.nvim](https://github.com/folke/lazy.nvim)
* [LuaRocks](https://luarocks.org/)

---


