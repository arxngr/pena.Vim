# pena.Vim

Modular Neovim configuration written in Lua, managed by [lazy.nvim](https://github.com/folke/lazy.nvim). Aimed at a clean, fast editing experience with LSP, debugging, testing, and git workflows built in.

<img width="2884" height="1920" alt="image" src="https://github.com/user-attachments/assets/910c83fd-d163-490e-8784-77a349a56e0e" />

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [macOS](#macos)
  - [Linux](#linux)
  - [Windows](#windows)
- [Keeping versions in sync](#keeping-versions-in-sync)
- [Keybindings](#keybindings)
  - [General](#general)
  - [Window and terminal navigation](#window-and-terminal-navigation)
  - [Buffer management](#buffer-management)
  - [Picker (Snacks)](#picker-snacks)
  - [Search and replace](#search-and-replace)
  - [LSP](#lsp)
  - [Diagnostics](#diagnostics)
  - [Trouble](#trouble)
  - [Debugging (nvim-dap)](#debugging-nvim-dap)
  - [Testing (vim-test)](#testing-vim-test)
  - [Git](#git)
  - [Treesitter text objects](#treesitter-text-objects)
  - [Project tasks (Overseer)](#project-tasks-overseer)
  - [Logging (Chainsaw)](#logging-chainsaw)
  - [Editing (mini.nvim)](#editing-mininvim)
  - [Miscellaneous](#miscellaneous)
- [License](#license)

---

## Features

- **LSP and autocompletion** via nvim-lspconfig, Mason, and nvim-cmp
- **Debugging** via nvim-dap with adapters for JavaScript/TypeScript, Go, Python, and C/C++
- **Testing** via vim-test with a reusable terminal strategy
- **Fuzzy finding and picking** via Snacks.nvim (files, grep, buffers, LSP, git, diagnostics, and more)
- **Search and replace** via grug-far.nvim
- **File explorer** via Oil.nvim (floating)
- **Git** via vim-fugitive, gitsigns.nvim, and LazyGit (Snacks)
- **Diagnostics** via Trouble.nvim
- **Formatting** via conform.nvim (format on save)
- **Code folding** via nvim-ufo
- **Session persistence** via persistence.nvim
- **Breadcrumbs** via nvim-navic (winbar)
- **Terminal** via ToggleTerm
- **Project task runner** via Overseer.nvim
- **Multi-cursor** via vim-visual-multi
- **Surround, move, pairs, diff** via mini.nvim
- **Colorscheme switcher** via Themery (OneDark, Tinta)
- **Coding metrics** via WakaTime
- **Smart logging** via nvim-chainsaw

---

## Prerequisites

The following must be installed before setting up pena.Vim:

| Dependency | Purpose |
|---|---|
| [Neovim](https://neovim.io/) >= 0.10 | Runtime |
| [Git](https://git-scm.com/) | Plugin management and version control |
| C compiler (`gcc` or `clang`) | Compiling treesitter parsers |
| [Node.js](https://nodejs.org/) and npm | JavaScript/TypeScript debug adapter |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Grep-based search (Snacks, grug-far) |
| [fd](https://github.com/sharkdp/fd) | Fast file finding (optional but recommended) |
| A [Nerd Font](https://www.nerdfonts.com/) | Icons in the UI |

---

## Installation

### macOS

```bash
# Install dependencies via Homebrew
brew install neovim git ripgrep fd node

# Install Xcode command line tools (C compiler for treesitter)
xcode-select --install

# Back up any existing config
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

# Clone the repo
git clone https://github.com/arxngr/pena.Vim ~/.config/nvim

# Launch Neovim — lazy.nvim will install all plugins on first run
nvim
```

### Linux

**Ubuntu / Debian**

```bash
# Install Neovim (use the official unstable PPA for a recent version)
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update && sudo apt install neovim

# Install dependencies
sudo apt install git ripgrep fd-find nodejs npm build-essential
# Note: on Ubuntu, fd is installed as 'fdfind'. Create an alias if needed:
# echo 'alias fd=fdfind' >> ~/.bashrc

# Back up any existing config
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

# Clone the repo
git clone https://github.com/arxngr/pena.Vim ~/.config/nvim

nvim
```

**Arch / Manjaro**

```bash
sudo pacman -S neovim git ripgrep fd nodejs npm base-devel

mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

git clone https://github.com/arxngr/pena.Vim ~/.config/nvim
nvim
```

**Fedora**

```bash
sudo dnf install neovim git ripgrep fd-find nodejs npm gcc

mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

git clone https://github.com/arxngr/pena.Vim ~/.config/nvim
nvim
```

### Windows

Use either [Scoop](https://scoop.sh/) or [Chocolatey](https://chocolatey.org/). PowerShell is recommended.

**Using Scoop**

```powershell
scoop install neovim git ripgrep fd nodejs

# Back up any existing config
Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak -ErrorAction SilentlyContinue
Move-Item $env:LOCALAPPDATA\nvim-data $env:LOCALAPPDATA\nvim-data.bak -ErrorAction SilentlyContinue

# Clone the repo (Windows config dir is %LOCALAPPDATA%\nvim)
git clone https://github.com/arxngr/pena.Vim $env:LOCALAPPDATA\nvim

nvim
```

**Using Chocolatey**

```powershell
choco install neovim git ripgrep fd nodejs

Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak -ErrorAction SilentlyContinue

git clone https://github.com/arxngr/pena.Vim $env:LOCALAPPDATA\nvim

nvim
```

On Windows you also need a C compiler for treesitter. Install [LLVM](https://github.com/llvm/llvm-project/releases) and ensure `clang` is on your `PATH`, or install the [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) and select the C++ workload.

---

## Keeping versions in sync

`lazy-lock.json` records the exact commit of every plugin. Commit this file to git so all machines use the same versions.

```bash
git add lazy-lock.json
git commit -m "chore: lock plugin versions"
```

On another machine, after pulling the latest changes:

```
:Lazy restore
```

When you want to update plugins, run `:Lazy update` on one machine, commit the updated lock file, then pull and `:Lazy restore` on the others.

---

## Keybindings

**Leader key:** `Space`  
**Local leader:** `,`

### General

| Mode | Key | Description |
|---|---|---|
| `n` | `<C-q>` | Quit |
| `n` / `x` | `d` | Delete to black hole register (does not yank) |
| `x` | `<leader>p` | Paste without overwriting the register |
| `n` / `v` | `<C-c>` | Copy to system clipboard |
| `n` / `v` | `<C-v>` | Paste from system clipboard |
| `n` | `<C-d>` | Mark word under cursor and search for it |
| `v` | `<` / `>` | Indent left / right (stays in visual mode) |
| `n` | `<leader>wv` | Vertical split |
| `n` | `<leader>hv` | Horizontal split |
| `n` | `<leader>bd` | Close current buffer |
| `n` | `<leader>dd` | Open dashboard |

> Note: `d` is remapped to delete into the black hole register (`"_d`), so deleted text is never placed in the yank register. Use `"dd` or `"dw` if you need the default behaviour.

---

### Window and terminal navigation

| Mode | Key | Description |
|---|---|---|
| `n` | `<C-h/j/k/l>` | Move between windows |
| `t` | `<C-h/j/k/l>` | Move between windows from terminal mode |
| `t` | `<C-x>` | Exit terminal mode |

---

### Buffer management

| Key | Description |
|---|---|
| `<S-h>` | Previous buffer |
| `<S-l>` | Next buffer |
| `<leader>bp` | Toggle pin |
| `<leader>bP` | Delete all non-pinned buffers |
| `<leader>br` | Delete buffers to the right |
| `<leader>bl` | Delete buffers to the left |
| `<leader>bd` | Close current buffer |

---

### Picker (Snacks)

#### Quick access

| Key | Description |
|---|---|
| `<leader><space>` | Smart find files |
| `<leader>,` | Buffers |
| `<leader>/` | Grep |
| `<leader>:` | Command history |
| `<leader>n` | Notification history |

#### Find

| Key | Description |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fb` | Find buffers |
| `<leader>fc` | Find config file |
| `<leader>fg` | Find git files |
| `<leader>fp` | Projects |
| `<leader>fr` | Recent files |

#### Grep

| Key | Description |
|---|---|
| `<leader>sb` | Buffer lines |
| `<leader>sB` | Grep open buffers |
| `<leader>sg` | Grep |
| `<leader>sw` | Grep word under cursor or selection (`n` / `x`) |

#### Search

| Key | Description |
|---|---|
| `<leader>s"` | Registers |
| `<leader>s/` | Search history |
| `<leader>sa` | Autocmds |
| `<leader>sc` | Command history |
| `<leader>sC` | Commands |
| `<leader>sd` | Diagnostics |
| `<leader>sD` | Buffer diagnostics |
| `<leader>sh` | Help pages |
| `<leader>sH` | Highlights |
| `<leader>si` | Icons |
| `<leader>sj` | Jumps |
| `<leader>sk` | Keymaps |
| `<leader>sl` | Location list |
| `<leader>sm` | Marks |
| `<leader>sM` | Man pages |
| `<leader>sp` | Plugin spec |
| `<leader>sq` | Quickfix list |
| `<leader>sR` | Resume last picker |
| `<leader>su` | Undo history |
| `<leader>ss` | LSP symbols |
| `<leader>sS` | LSP workspace symbols |

---

### Search and replace

| Mode | Key | Description |
|---|---|---|
| `n` / `v` | `<leader>sr` | Open grug-far (scoped to current file type) |

---

### LSP

| Mode | Key | Description |
|---|---|---|
| `n` | `gd` | Go to definition |
| `n` | `gD` | Go to declaration |
| `n` | `gr` | References |
| `n` | `gI` | Go to implementation |
| `n` | `gy` | Go to type definition |
| `n` | `<leader>rn` | Rename symbol |
| `n` / `x` | `<leader>ca` | Code action |
| `n` | `<leader>cr` | Rename (core keymap) |
| `n` | `<leader>k` | Toggle signature help |
| `n` | `<leader>uh` | Toggle inlay hints (all buffers) |

---

### Diagnostics

| Key | Description |
|---|---|
| `<leader>cd` | Open floating diagnostic |
| `]d` | Next diagnostic |
| `[d` | Previous diagnostic |
| `]e` | Next error |
| `[e` | Previous error |
| `]w` | Next warning |
| `[w` | Previous warning |

---

### Trouble

| Key | Description |
|---|---|
| `<leader>xx` | Toggle diagnostics |
| `<leader>xX` | Buffer diagnostics |
| `<leader>cs` | LSP references |
| `<leader>xL` | Location list |
| `<leader>xQ` | Quickfix list |
| `[q` / `]q` | Previous / next Trouble or quickfix item |

---

### Debugging (nvim-dap)

Adapters are included for: JavaScript, TypeScript, Go (delve), Python (debugpy), and C/C++ (codelldb / cppdbg).

| Key | Description |
|---|---|
| `<leader>da` | Start / continue |
| `<leader>dc` | Continue |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>db` | Toggle breakpoint |
| `<leader>dq` | Clear all breakpoints |
| `<leader>dw` | Hover variable |
| `<leader>de` | Evaluate expression (`n` / `v`) |
| `<leader>ds` | Stacks (float) |
| `<leader>dr` | Toggle REPL |
| `<leader>dlb` | Breakpoints (float) |
| `<leader>dh` | Watches (float) |
| `<leader>dv` | Scopes (float) |
| `<leader>dT` | Terminate session |
| `<leader>dR` | Toggle auto-reload on save |

---

### Testing (vim-test)

Tests run in a reusable split terminal. Go projects use `gotest` as the runner.

| Key | Description |
|---|---|
| `<leader>tn` | Run nearest test |
| `<leader>tf` | Run current file |
| `<leader>ts` | Run test suite |
| `<leader>tl` | Run last test |
| `<leader>tv` | Visit last test file |

---

### Git

#### vim-fugitive

| Key | Description |
|---|---|
| `<leader>gs` | Git status |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git push |
| `<leader>gb` | Git blame |
| `<leader>gd` | Git diff split |

#### Snacks git log

| Key | Description |
|---|---|
| `<leader>gl` | Git log |
| `<leader>gL` | Git log (current line) |
| `<leader>gf` | Git log (current file) |

#### mini.diff

| Key | Description |
|---|---|
| `<leader>go` | Toggle diff overlay |

Gitsigns is also active and shows inline blame at end of line.

---

### Treesitter text objects

#### Select (visual / operator-pending)

| Key | Description |
|---|---|
| `af` | Around function |
| `if` | Inside function |

#### Move

| Key | Description |
|---|---|
| `]f` | Next function start |
| `]F` | Next function end |
| `]c` | Next class start |
| `]C` | Next class end |
| `]a` | Next parameter start |
| `]A` | Next parameter end |
| `[f` | Previous function start |
| `[F` | Previous function end |
| `[c` | Previous class start |
| `[C` | Previous class end |
| `[a` | Previous parameter start |
| `[A` | Previous parameter end |

---

### Project tasks (Overseer)

| Key | Description |
|---|---|
| `<leader>ow` | Toggle task list |
| `<leader>oo` | Run task |
| `<leader>oq` | Quick action on recent task |
| `<leader>oi` | Overseer info |
| `<leader>ob` | Task builder |
| `<leader>ot` | Task action menu |
| `<leader>oc` | Clear task cache |

---

### Logging (Chainsaw)

Inserts language-aware log statements for the variable or expression under the cursor.

| Key | Description |
|---|---|
| `<leader>ll` | Log variable |
| `<leader>lt` | Log type |
| `<leader>lm` | Log message |
| `<leader>lr` | Remove all log statements |

---

### Editing (mini.nvim)

#### mini.surround

| Key | Description |
|---|---|
| `gsa` | Add surrounding |
| `gsd` | Delete surrounding |
| `gsf` | Find surrounding (right) |
| `gsF` | Find surrounding (left) |
| `gsh` | Highlight surrounding |
| `gsr` | Replace surrounding |
| `gsn` | Update `n_lines` |

#### mini.move

| Key | Description |
|---|---|
| `<M-h>` | Move selection left |
| `<M-l>` | Move selection right |
| `<M-j>` | Move selection down |
| `<M-k>` | Move selection up |

---

### Miscellaneous

| Key | Description |
|---|---|
| `<leader>dt` | Toggle floating terminal |
| `<leader>e` | Toggle Oil file explorer (float) |
| `<leader>ut` | Toggle background transparency |
| `<leader>uc` | Switch colorscheme (Themery) |

---

## License

MIT — see [LICENSE](LICENSE).
