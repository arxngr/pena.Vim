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
- [Project tools](#project-tools)
- [Markdown and diagrams](#markdown-and-diagrams)
- [Keybindings](#keybindings)
  - [General](#general)
  - [Window and terminal navigation](#window-and-terminal-navigation)
  - [Buffer management](#buffer-management)
  - [Native text search](#native-text-search)
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
- **Debugging** via nvim-dap with project-selected adapters
- **Testing** via vim-test with a reusable terminal strategy
- **Fuzzy finding and picking** via Snacks.nvim (files, buffers, git, diagnostics, and more)
- **Text search** via native result splits and ripgrep, including unsaved buffer contents
- **LSP navigation** via native jumps and searchable quickfix splits with reversible source-window previews
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
- **Project detection** selects language servers, formatters, debuggers, and syntax parsers automatically

Feature behavior lives in domain modules; keymaps and plugin specifications only
wire entry points:

| Module | Responsibility |
|---|---|
| `lua/core/git.lua` | Native Git status, file previews, and native/Fugitive diff sessions (`status`, `diff`) |
| `lua/core/search.lua` | Buffer/project search and shared LSP reference/symbol result sessions (`current_buffer`, `project`, `handler`) |
| `lua/core/buffers.lua` | Safe closing and idle-buffer lifecycle (`close`, `setup`, `sweep`) |

Git status and Fugitive retain independent session state. Text search and LSP
navigation share the same result session implementation. Buffer cleanup remains
independent of both features.

---

## Prerequisites

Install Neovim and Git first. Other tools support search, display, parser
compilation, or the editor tools selected for your projects.

| Dependency | Purpose |
|---|---|
| [Neovim](https://neovim.io/) >= 0.12 | Runtime |
| [Git](https://git-scm.com/) | Plugin management and version control |
| C compiler (`gcc` or `clang`) | Compiling treesitter parsers |
| [Node.js](https://nodejs.org/) and npm | Required by some project-selected editor tools |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Native project text search and grug-far |
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

# Launch Neovim â€” lazy.nvim will install all plugins on first run
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

## Project tools

Language tools are selected automatically from the source files and manifests in
open projects. Mixed projects receive the tools they need. Dependency folders and
build outputs are excluded from detection. Servers activate only for matching
projects; installed tools stay cached for reuse.

Use `:ProjectLanguages` to inspect detection, `:ProjectTools` to inspect selected
tools and missing runtimes, and `:ProjectToolsRefresh` to rescan and retry installs.
Mason installs editor tools; required system runtimes and compilers must already
be available. Use `:MasonLog` for installation errors.

For .NET, use `:DotnetProject` (`<leader>np`) to select a startup project, then
`:DotnetRun` (`<leader>nr`), `:DotnetWatch` (`<leader>nw`), or `:DotnetDebug`.
Run, watch, and debug offer the project's `Project` launch profiles. Once an
ASP.NET Core server starts listening, Neovim opens the profile's `launchUrl`
once it responds successfully. Without a launch URL, it checks for Swagger UI,
then opens the homepage for a web project (including MVC, Razor Pages, and Blazor).
This also works with debug output in the integrated terminal. Console projects
run and debug without opening a browser unless their profile requests it.

Detection uses curl and checks the profile's `launchUrl`, `/swagger/index.html`,
and `/swagger`, with `/` as the final web-page fallback. Custom documentation paths can be set in `init.lua` with
`vim.g.dotnet_swagger_paths = { "/api/docs", "/swagger/index.html", "/" }`.
Set `vim.g.dotnet_auto_open_swagger = false` to disable all automatic browser opening;
`launchBrowser = false` in the chosen launch profile also disables it. Detection
uses the `Now listening on:` startup log when available and falls back to the
project's standard `appsettings.json`, environment-specific appsettings, Kestrel
endpoints, launch profile, and URL/port environment variables when logs are silent.
It waits up to two minutes for a launch page, Swagger UI, or homepage to respond successfully. For bindings set
only in application code or custom configuration, set
`vim.g.dotnet_swagger_urls = { "http://localhost:12345" }`; adjust the wait with
`vim.g.dotnet_swagger_timeout_ms`. It never changes the application's ports.
The same detection also applies to ordinary `coreclr` launch configurations:
Neovim locates the project from the output DLL or launch working directory and
uses that launch's environment. No service-specific names or ports are required.
On Windows, the .NET adapter launches the native `netcoredbg.exe` directly,
bypassing Mason's `.CMD` wrapper so DAP initialization can complete.

## Markdown and diagrams

Markdown files render automatically inside Neovim with `render-markdown.nvim`.
Headings, tables, lists, checkboxes, and code blocks are easier to read; source
text remains editable. Mermaid fences remain code inside the terminal preview.
Use the browser preview to draw Mermaid diagrams and display images and math.
The browser view updates as you edit and uses a locally running bundled server.

| Key (in a Markdown buffer) | Action |
|---|---|
| `<leader>mr` | Toggle in-editor rendering for the current buffer |
| `<leader>ms` | Open a rendered Markdown split inside Neovim |
| `<leader>mp` | Toggle live browser preview, including Mermaid diagrams |
| `<leader>mP` | Stop the browser preview |

Try [the Markdown example](examples/markdown-preview.md). `:MarkdownPreview`
also opens the browser preview directly. If the preview server needs reinstalling,
run `:Lazy build markdown-preview.nvim`. If in-editor rendering is missing, check
`:checkhealth render-markdown` and install the `markdown` and `markdown_inline`
Treesitter parsers. The browser preview uses its bundled Mermaid version, so some
syntax from newer Mermaid releases may not work.

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
| `n` | `<leader>bd` | Close current buffer; confirm save/discard/cancel for unsaved changes |
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
| `<leader>bd` | Close current buffer; confirm save/discard/cancel for unsaved changes |

Hidden, unmodified file buffers are closed after five minutes of inactivity,
checked once per minute. Visible buffers in any tab, unsaved changes, pinned
buffers, unnamed/special/terminal buffers, and active preview/diff source
buffers are protected. Cleanup never force-deletes a buffer or removes a file
from disk.

---

### Native text search

| Key in a code buffer | Description |
|---|---|
| `/` | Search the current buffer, including unsaved edits |
| `?` (Shift+/) | Global Search: search project files on disk with ripgrep |

Queries use a command-line prompt, not a floating picker. They are literal and
case-sensitive; Enter submits and Ctrl-C cancels. Project search uses the same
project-root detection as the project tools and honors ripgrep's ignore rules.
Text search and LSP results share the preview controls documented below.
Successful text searches preserve their literal query in native search state,
so `n` / `N` continue forward/backward after opening a result. Redundant leader
text-search shortcuts (`<leader>/`, `<leader>sb`, `<leader>sB`, `<leader>sw`,
`<leader>sg`, and `<leader>sG`) are no longer configured.
In quickfix, help, terminals, and other special buffers, `/` and `?` retain
their native forward/backward search behavior.

---

### Picker (Snacks)

#### Quick access

| Key | Description |
|---|---|
| `<leader><space>` | Smart find files |
| `<leader>,` | Buffers |
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
| `n` | `gr` | References in a bottom quickfix split |
| `n` | `gi` / `gI` | Go to implementation |
| `n` | `gy` | Go to type definition |
| `n` | `<leader>ss` | Document symbols in a bottom quickfix split |
| `n` | `<leader>sS` | Prompt for a workspace symbol query, then open quickfix |
| `n` | `<leader>rn` | Rename symbol |
| `n` / `x` | `<leader>ca` | Code action |
| `n` | `<leader>cr` | Rename (core keymap) |
| `n` | `<leader>k` | Toggle signature help |
| `n` | `<leader>uh` | Toggle inlay hints (all buffers) |

LSP navigation does not use Snacks. Definitions, declarations, implementations,
and type definitions jump directly when there is one result; multiple results
open a quickfix split. References, symbols, and text searches use a bottom
quickfix split sized to 35% of the editor height, with the total result count in
its header. Each result shows its path and location on a separate, muted display
line above the searchable code, including the first result, with a horizontal
separator between them. Code rows use theme-linked language syntax,
not quickfix filename coloring. Only the exact searched text uses the active
theme's `Search` colors, alongside a `>` gutter sign; surrounding code keeps its
syntax colors. Full-row quickfix and cursor-line coloring is disabled in result
windows. Opening a result clears the preview's word highlight and gutter sign.
Installed Treesitter parsers are reused; native syntax handles previews without
an available parser. Workspace symbols first use a command-line query
(Enter to submit, Ctrl-C to cancel).

Result rendering resolves filetypes and formats paths once per buffer in each
list, rather than once per reference, and reuses its separator text. This reduces
UI work for large reference lists without loading every target file. The first
reference request can still wait for the language server to index the project;
renderer optimizations do not remove that server-side delay.

In a fresh reference, symbol, or text-search list:

| Key | Action |
|---|---|
| `j` / `k`, arrow keys | Select a result and preview it in the source window without leaving the list |
| `/` / `?` | Native forward/backward search within the displayed code rows; results are not filtered |
| `n` / `N` | Move between native search matches |
| Enter / double-click in the result list | Commit the selected location and close the list |
| Click the source preview | Commit that preview and clear its search markers |
| `q` / Escape | Cancel, close the list, and restore the original buffer and cursor |

Switching windows with the keyboard without committing restores the main buffer and view, but keeps
the result session alive. Returning to the result window resumes the selected
preview and subsequent movement. Unsaved edits are preserved. `:cclose` cancels
the session; `:copen` reopens the results as a normal quickfix list. Native
`:cnext` / `:cprevious` remain available after committing.

Run the feature regressions below. Search includes navigation and actual UI-grid
rendering; Git covers native status and the installed Fugitive plugin. Search and
buffer checks run without plugins.

```sh
nvim --headless -u NONE -n -l tests/search.lua
nvim --headless -u NONE -n -l tests/git.lua
nvim --headless -u NONE -n -l tests/buffers.lua
```

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

Debug adapters are installed for the languages detected in your open projects.

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

Tests run in a reusable split terminal.

| Key | Description |
|---|---|
| `<leader>tn` | Run nearest test |
| `<leader>tf` | Run current file |
| `<leader>ts` | Run test suite |
| `<leader>tl` | Run last test |
| `<leader>tv` | Visit last test file |

---

### Git

#### Native Git status

`<leader>gs` opens a native 35%-height status split without loading Fugitive.
Move among files to preview them in the original source window. Keyboard window
switching restores the source; returning to status resumes previews.

| Control | Action |
|---|---|
| Enter / double-click a status entry | Open its native side-by-side diff |
| Click the source preview | Open the selected file's diff |
| `q` / Escape in status | Cancel and restore the original buffer/view |
| Ctrl-O in either diff pane | Close the session's diff panes and restore the original buffer, focus, and layout |

Staged entries compare HEAD with the index; unstaged entries compare the index
with the working file. Untracked files compare against an empty baseline.
Deleted files and renamed paths are supported. Ctrl-O removes only clean,
hidden buffers created by that session: pre-existing buffers/windows and
unsaved working-file edits are preserved. Starting with one file window returns
to that one window, without temporary diff buffers left open.

Use `:Git` for Fugitive's full staging interface.

#### vim-fugitive

| Key | Description |
|---|---|
| `<leader>gc` | Git commit |
| `<leader>gp` | Git push |
| `<leader>gb` | Git blame |
| `<leader>gd` | Git diff split; Ctrl-O in either pane closes the diff and restores the source |

The `<leader>gd` session preserves the original buffer, cursor, window layout,
and unsaved edits. Its temporary Ctrl-O mappings are removed on return, and clean,
hidden buffers created for the diff are deleted. Pre-existing windows and buffers
are retained. Direct `:Gvdiffsplit` commands keep Fugitive's native behavior;
use `<leader>gd` for the return shortcut.

The `tests/git.lua` command above exercises both native status and this path with
the installed Fugitive plugin (not a mock).

The fixture uses `stdpath("data")/lazy/vim-fugitive`; set `FUGITIVE_PATH` if the
plugin is installed elsewhere.

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

MIT â€” see [LICENSE](LICENSE).
