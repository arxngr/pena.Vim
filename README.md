---

# Pena.Vim

Modular Neovim configuration tailored for developers seeking a streamlined and efficient coding environment. Built with Lua, it leverages the power of `lazy.nvim` for plugin management, offering a clean and extensible setup out of the box.
<img width="2884" height="1920" alt="image" src="https://github.com/user-attachments/assets/910c83fd-d163-490e-8784-77a349a56e0e" />

---

## 📑 Table of Contents

* [📦 Features](#-features)
* [🚀 Installation](#-installation)
  * [🔧 Prerequisites](#prerequisites)
  * [📥 Steps](#steps)
* [📦 Installing LuaRocks](#-installing-luarocks)
  * [💻 For Unix/Linux/macOS](#for-unixlinuxmacos)
  * [🪟 For Windows](#for-windows)
* [🗝️ Keybindings](#-keybindings)
  * [🪄 General](#-general)
  * [🪟 Window & Terminal Navigation](#-window--terminal-navigation)
  * [� Buffer Management](#-buffer-management)
  * [�🔍 Picker (Snacks)](#-picker-snacks)
  * [🔎 Search & Replace](#-search--replace)
  * [🧪 Testing (vim-test)](#-testing-vim-test)
  * [🐞 Debugging (nvim-dap)](#-debugging-nvim-dap)
  * [🔧 Code / LSP](#-code--lsp)
  * [📋 Trouble.nvim](#-troublenvim)
  * [📂 Project Tasks (Overseer)](#-project-tasks-overseer)
  * [🌿 Git](#-git)
  * [🪵 Chainsaw (Logging)](#-chainsaw-logging)
  * [✏️ Editing (mini.nvim)](#-editing-mininvim)
  * [🧱 Misc Plugins](#-misc-plugins)
* [📄 License](#-license)
* [🙏 Acknowledgments](#-acknowledgments)

---

## 📦 Features

* 🔧 **LSP & Autocompletion** — powered by [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [Mason](https://github.com/williamboman/mason.nvim), and [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
* 🧪 **Testing** with [vim-test](https://github.com/vim-test/vim-test) (reusable terminal strategy)
* 🐞 **Debugging** with [nvim-dap](https://github.com/mfussenegger/nvim-dap) & [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)
* 🗂️ **Picker & Fuzzy Finder** with [Snacks.nvim](https://github.com/folke/snacks.nvim) (files, grep, buffers, LSP, git, diagnostics)
* 🧰 **Terminal management** with [ToggleTerm](https://github.com/akinsho/toggleterm.nvim)
* 🛠️ **Project tasks** via [Overseer](https://github.com/stevearc/overseer.nvim)
* 🌲 **Floating file explorer** using [Oil.nvim](https://github.com/stevearc/oil.nvim)
* 🎨 **Theme switching** with [Themery](https://github.com/zaldih/themery.nvim) (OneDark, Tinta)
* 🔍 **Search and Replace** with [grug-far](https://github.com/MagicDuck/grug-far.nvim)
* 🚨 **Diagnostics** with [Trouble](https://github.com/folke/trouble.nvim)
* 🌿 **Git integration** with [vim-fugitive](https://github.com/tpope/vim-fugitive), [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) & [LazyGit](https://github.com/folke/snacks.nvim)
* ✨ **Auto-formatting** with [conform.nvim](https://github.com/stevearc/conform.nvim) (format-on-save)
* � **Tabline & Buffers** with [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
* 🪵 **Smart logging** with [Chainsaw](https://github.com/chrisgrieser/nvim-chainsaw)
* ✏️ **Editing enhancements** with [mini.nvim](https://github.com/echasnovski/mini.nvim) (surround, move, pairs, diff)
* 🧭 **Breadcrumbs** with [nvim-navic](https://github.com/SmiteshP/nvim-navic)
* 💬 **Command UI** with [Noice](https://github.com/folke/noice.nvim)
* 🪗 **Code folding** with [nvim-ufo](https://github.com/kevinhwang91/nvim-ufo)
* 💾 **Session persistence** with [persistence.nvim](https://github.com/folke/persistence.nvim)
* ⏱️ **Coding metrics** with [WakaTime](https://github.com/wakatime/vim-wakatime)
* 🖊️ **Multi-cursor editing** with [vim-visual-multi](https://github.com/mg979/vim-visual-multi)
* 🌈 **Rainbow delimiters** with [rainbow-delimiters.nvim](https://github.com/HiPhish/rainbow-delimiters.nvim)
* 💡 **Which-key** popup for keybinding discovery

---

## 🚀 Installation

### Prerequisites

Ensure you have the following installed:

* [Neovim](https://neovim.io/) (version 0.9 or higher)
* [Git](https://git-scm.com/)
* [Lua 5.1](https://www.lua.org/) or [LuaJIT](https://luajit.org/)
* [LuaRocks](https://luarocks.org/)

### Steps

1. **Backup Existing Neovim Configuration**

   If you have an existing Neovim configuration, back it up:

   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   mv ~/.local/share/nvim ~/.local/share/nvim.backup
   mv ~/.local/state/nvim ~/.local/state/nvim.backup
   mv ~/.cache/nvim ~/.cache/nvim.backup
   ```

2. **Clone Repository**

   Clone the repository into your Neovim configuration directory:

   ```bash
   git clone https://github.com/arxngr/pena.Vim ~/.config/nvim
   ```

3. **Launch Neovim**

   Open Neovim to initiate the plugin installation process:

   ```bash
   nvim
   ```

   Upon first launch, `lazy.nvim` will automatically install the necessary plugins. Wait for the process to complete.

4. **Install LuaRocks (If Not Already Installed)**

   LuaRocks is essential for managing Lua dependencies. Follow the instructions below based on your operating system.

---

## 📦 Installing LuaRocks

### For Unix/Linux/macOS

1. **Install Lua**

   Use your package manager to install Lua 5.1 or LuaJIT:

   * **Ubuntu/Debian**:

     ```bash
     sudo apt update
     sudo apt install lua5.1 liblua5.1-0-dev
     ```

   * **Fedora**:

     ```bash
     sudo dnf install lua compat-lua-devel-5.1.5
     ```

   * **macOS (using Homebrew)**:

     ```bash
     brew install lua@5.1
     ```

2. **Download and Install LuaRocks**

   Download the latest LuaRocks version from the [official site](https://luarocks.org/releases/):

   ```bash
   wget https://luarocks.org/releases/luarocks-3.11.1.tar.gz
   tar zxpf luarocks-3.11.1.tar.gz
   cd luarocks-3.11.1
   ./configure && make && sudo make install
   ```

Verify the installation:

```bash
luarocks --version
```

### For Windows

1. **Install Lua**

   Download and install Lua for Windows from [LuaBinaries](https://luabinaries.sourceforge.net/) or use a package manager like [Chocolatey](https://chocolatey.org/) or [Scoop](https://scoop.sh/):

   * **Using Chocolatey**:

     ```powershell
     choco install lua
     ```

   * **Using Scoop**:

     ```powershell
     scoop install lua
     ```

2. **Install LuaRocks**

   Download the LuaRocks Windows installer from the [official site](https://luarocks.org/releases/):

   * Extract the contents and run the `install.bat` script. For example:

     ```cmd
     install.bat /P C:\LuaRocks /L
     ```

   Ensure that the installation path (e.g., `C:\LuaRocks`) is added to your system's `PATH` environment variable.

   Alternatively, using package managers:

   * **Using Chocolatey**:

     ```powershell
     choco install luarocks
     ```

   * **Using Scoop**:

     ```powershell
     scoop install luarocks
     ```

   After installation, verify:

   ```powershell
   luarocks --version
   ```

---

## 🛠️ Usage

Once installed, pena.Vim provides a robust Neovim environment with sensible defaults and powerful plugins. Explore and customize the configuration to suit your workflow.

---

## 🗝️ Keybindings

**Leader key** is set to `<Space>`. **Local leader** is `,`.

### 🪄 General

| Mode    | Key           | Description                      |
| ------- | ------------- | -------------------------------- |
| `n`     | `<C-q>`       | Quit file                        |
| `n`/`x` | `d`          | Delete (black hole, no yank)     |
| `x`     | `<leader>p`   | Paste without overwriting register |
| `n`/`v` | `<C-c>`       | Copy to system clipboard         |
| `n`/`v` | `<C-v>`       | Paste from system clipboard      |
| `n`     | `<C-d>`       | Search word under cursor         |
| `v`     | `<` / `>`     | Indent left/right (stays in visual) |
| `n`     | `<leader>bd`  | Close current buffer             |
| `n`     | `<leader>wv`  | Vertical split                   |
| `n`     | `<leader>hv`  | Horizontal split                 |
| `n`     | `<leader>?`   | Show buffer local keymaps (which-key) |
| `n`     | `<leader>dd`  | Open dashboard                   |

---

### 🪟 Window & Terminal Navigation

| Mode | Key             | Description                           |
| ---- | --------------- | ------------------------------------- |
| `n`  | `<C-h/j/k/l>`  | Move between windows                  |
| `t`  | `<C-h/j/k/l>`  | Move between windows (terminal mode)  |
| `t`  | `<C-x>`         | Escape terminal mode                  |

---

### � Buffer Management

| Key          | Description                   |
| ------------ | ----------------------------- |
| `<S-h>`      | Previous buffer               |
| `<S-l>`      | Next buffer                   |
| `<leader>bp` | Toggle pin                    |
| `<leader>bP` | Delete non-pinned buffers     |
| `<leader>br` | Delete buffers to the right   |
| `<leader>bl` | Delete buffers to the left    |
| `<leader>bd` | Close current buffer          |

---

### 🔍 Picker (Snacks)

#### Quick Access

| Key                    | Description             |
| ---------------------- | ----------------------- |
| `<leader><space>`      | Smart find files        |
| `<leader>,`            | Buffers                 |
| `<leader>/`            | Grep                    |
| `<leader>:`            | Command history         |
| `<leader>n`            | Notification history    |

#### Find

| Key          | Description         |
| ------------ | ------------------- |
| `<leader>ff` | Find files          |
| `<leader>fb` | Find buffers        |
| `<leader>fc` | Find config file    |
| `<leader>fg` | Find git files      |
| `<leader>fp` | Projects            |
| `<leader>fr` | Recent files        |

#### Grep / Search

| Key            | Description              |
| -------------- | ------------------------ |
| `<leader>sb`   | Buffer lines             |
| `<leader>sB`   | Grep open buffers        |
| `<leader>sg`   | Grep                     |
| `<leader>sw`   | Grep word (visual/normal) |
| `<leader>s"`   | Registers                |
| `<leader>s/`   | Search history           |
| `<leader>sa`   | Autocmds                 |
| `<leader>sc`   | Command history          |
| `<leader>sC`   | Commands                 |
| `<leader>sd`   | Diagnostics              |
| `<leader>sD`   | Buffer diagnostics       |
| `<leader>sh`   | Help pages               |
| `<leader>sH`   | Highlights               |
| `<leader>si`   | Icons                    |
| `<leader>sj`   | Jumps                    |
| `<leader>sk`   | Keymaps                  |
| `<leader>sl`   | Location list            |
| `<leader>sm`   | Marks                    |
| `<leader>sM`   | Man pages                |
| `<leader>sp`   | Plugin spec              |
| `<leader>sq`   | Quickfix list            |
| `<leader>sR`   | Resume last picker       |
| `<leader>su`   | Undo history             |
| `<leader>ss`   | LSP symbols              |
| `<leader>sS`   | LSP workspace symbols    |
| `<leader>sr`   | Search and replace (grug-far) |

---

### 🔎 Search & Replace

| Key          | Mode    | Description         |
| ------------ | ------- | ------------------- |
| `<leader>sr` | `n`/`v` | Open grug-far (search & replace, scoped to current file type) |

---

### 🧪 Testing (vim-test)

| Key          | Description          |
| ------------ | -------------------- |
| `<leader>tn` | Run nearest test     |
| `<leader>tf` | Run current file     |
| `<leader>ts` | Run test suite       |
| `<leader>tl` | Run last test        |
| `<leader>tv` | Visit last test file |

---

### 🐞 Debugging (nvim-dap)

| Key           | Description                |
| ------------- | -------------------------- |
| `<leader>da`  | Start / Continue debugging |
| `<leader>dc`  | Continue                   |
| `<leader>di`  | Step into                  |
| `<leader>do`  | Step over                  |
| `<leader>dO`  | Step out                   |
| `<leader>db`  | Toggle breakpoint          |
| `<leader>dq`  | Clear all breakpoints      |
| `<leader>dw`  | Hover variable             |
| `<leader>de`  | Evaluate expression (`n`/`v`) |
| `<leader>ds`  | View stacks (float)        |
| `<leader>dr`  | Toggle REPL                |
| `<leader>dlb` | View breakpoints (float)   |
| `<leader>dh`  | View watches (float)       |
| `<leader>dv`  | View scopes (float)        |
| `<leader>dT`  | Terminate debug session    |
| `<leader>dR`  | Toggle auto-reload on save |

---

### 🔧 Code / LSP

| Key          | Description                   |
| ------------ | ----------------------------- |
| `gd`         | Goto definition               |
| `gD`         | Goto declaration              |
| `gr`         | References                    |
| `gi`         | Goto implementation           |
| `gy`         | Goto type definition          |
| `<leader>rn` | LSP: Rename symbol            |
| `<leader>ca` | LSP: Code action (`n`/`x`)   |
| `<leader>cr` | Rename (core keymap)          |
| `<leader>k`  | Toggle signature help         |
| `<leader>cd` | Open float diagnostic         |
| `<leader>uh` | Toggle inlay hints (global)   |

#### Diagnostic Navigation

| Key   | Description        |
| ----- | ------------------ |
| `]d`  | Next diagnostic    |
| `[d`  | Prev diagnostic    |
| `]e`  | Next error         |
| `[e`  | Prev error         |
| `]w`  | Next warning       |
| `[w`  | Prev warning       |

---

### 📋 Trouble.nvim

| Key          | Description                        |
| ------------ | ---------------------------------- |
| `<leader>xx` | Toggle diagnostics (Trouble)       |
| `<leader>xX` | Buffer diagnostics (Trouble)       |
| `<leader>cs` | LSP references (Trouble)           |
| `<leader>xL` | Location list (Trouble)            |
| `<leader>xQ` | Quickfix list (Trouble)            |
| `[q` / `]q`  | Prev/Next Trouble or quickfix item |

---

### 📂 Project Tasks (Overseer)

| Key          | Description                 |
| ------------ | --------------------------- |
| `<leader>ow` | Toggle task list            |
| `<leader>oo` | Run task                    |
| `<leader>oq` | Quick action on recent task |
| `<leader>oi` | Overseer info               |
| `<leader>ob` | Open task builder           |
| `<leader>ot` | Task action menu            |
| `<leader>oc` | Clear task cache            |

---

### 🌿 Git

#### Fugitive

| Key          | Description      |
| ------------ | ---------------- |
| `<leader>gs` | Git status       |
| `<leader>gc` | Git commit       |
| `<leader>gp` | Git push         |
| `<leader>gb` | Git blame        |
| `<leader>gd` | Git diff split   |

#### Snacks Git Picker

| Key          | Description      |
| ------------ | ---------------- |
| `<leader>gl` | Git log          |
| `<leader>gL` | Git log (line)   |
| `<leader>gf` | Git log (file)   |

#### Mini.diff

| Key          | Description              |
| ------------ | ------------------------ |
| `<leader>go` | Toggle diff overlay      |

---

### 🪵 Chainsaw (Logging)

| Key          | Description      |
| ------------ | ---------------- |
| `<leader>ll` | Log variable     |
| `<leader>lt` | Log type         |
| `<leader>lm` | Log message      |
| `<leader>lr` | Remove all logs  |

---

### ✏️ Editing (mini.nvim)

#### mini.surround

| Key    | Description            |
| ------ | ---------------------- |
| `gsa`  | Add surrounding        |
| `gsd`  | Delete surrounding     |
| `gsf`  | Find surrounding right |
| `gsF`  | Find surrounding left  |
| `gsh`  | Highlight surrounding  |
| `gsr`  | Replace surrounding    |
| `gsn`  | Update `n_lines`       |

#### mini.move

| Key      | Description          |
| -------- | -------------------- |
| `<M-h>`  | Move selection left  |
| `<M-l>`  | Move selection right |
| `<M-j>`  | Move selection down  |
| `<M-k>`  | Move selection up    |

---

### 🧱 Misc Plugins

| Key          | Description                 |
| ------------ | --------------------------- |
| `<leader>dt` | Toggle floating terminal    |
| `<leader>e`  | Toggle Oil file explorer    |
| `<leader>ut` | Toggle transparency         |
| `<leader>uc` | Toggle Themery (colorscheme) |

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

* [Neovim](https://neovim.io/)
* [lazy.nvim](https://github.com/folke/lazy.nvim)
* [Snacks.nvim](https://github.com/folke/snacks.nvim)
* [LuaRocks](https://luarocks.org/)

---
