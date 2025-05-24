---

# Pena.Vim

Modular Neovim configuration tailored for developers seeking a streamlined and efficient coding environment. Built with Lua, it leverages the power of `lazy.nvim` for plugin management, offering a clean and extensible setup out of the box.([GitHub][1])

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
  * [🔍 Telescope](#-telescope)
  * [🧪 Neotest](#-neotest)
  * [🐞 Debugging (nvim-dap)](#-debugging-nvim-dap)
  * [🔧 Code](#-code)
  * [🧱 Misc Plugins](#-misc-plugins)
  * [📋 Trouble.nvim](#-troublenvim)
* [📂 Project Tasks (Overseer)](#-project-tasks-overseer)
* [📄 License](#-license)
* [🙏 Acknowledgments](#-acknowledgments)

---


## 📦 Features

* 🔧 LSP and autocompletion
* 🧪 Testing with [Neotest](https://github.com/nvim-neotest/neotest)
* 🐞 Debugging with [nvim-dap](https://github.com/mfussenegger/nvim-dap)
* 🗂️ File navigation with [Telescope](https://github.com/nvim-telescope/telescope.nvim)
* 🧰 Terminal management with [ToggleTerm](https://github.com/akinsho/toggleterm.nvim)
* 🛠️ Project tasks via [Overseer](https://github.com/stevearc/overseer.nvim)
* 🌲 Floating file explorer using [Oil.nvim](https://github.com/stevearc/oil.nvim)
* 🎨 Theme switching with [Themery](https://github.com/zaldih/themery.nvim)
* 🔍 Search and Replace with [grug-far](https://github.com/jesseleite/grug-far.nvim)
* 🚨 Diagnostics with [Trouble](https://github.com/folke/trouble.nvim)


---

## 🚀 Installation

### Prerequisites

Ensure you have the following installed:

* [Neovim](https://neovim.io/) (version 0.9 or higher)
* [Git](https://git-scm.com/)
* [Lua 5.1](https://www.lua.org/) or [LuaJIT](https://luajit.org/)
* [LuaRocks](https://luarocks.org/)([luarocks.org][4])

### Steps

1. **Backup Existing Neovim Configuration**

   If you have an existing Neovim configuration, back it up:

   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   mv ~/.local/share/nvim ~/.local/share/nvim.backup
   mv ~/.local/state/nvim ~/.local/state/nvim.backup
   mv ~/.cache/nvim ~/.cache/nvim.backup:contentReference[oaicite:39]{index=39}
   ```

2. **Clone Repository**

   Clone therepository into your Neovim configuration directory:

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

   * Extract the contents and run the `install.bat` script. For example:([ESOUI Code Collection][5], [luarocks.org][4])

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

Default & Custom Setting
By default, Vim uses \ (backslash) as the "leader" key, but most users redefine it to something easier to reach—commonly the spacebar for faster access:

### 🪄 General

| Mode  | Key       | Description              |
| ----- | --------- | ------------------------ |
| `n`   | `c`       | Open config              |
| `n`   | `<C-q>`   | Quit file                |
| `n`   | `<Tab>`   | Next buffer              |
| `n`   | `<S-Tab>` | Previous buffer          |
| `v`   | `<` / `>` | Indent left/right        |
| `n`   | `<C-c>`   | Copy to system clipboard |
| `n/v` | `<C-v>`   | Paste from clipboard     |

### 🪟 Window & Terminal Navigation

| Mode | Key           | Action                          |
| ---- | ------------- | ------------------------------- |
| `n`  | `<C-h/j/k/l>` | Move between windows            |
| `t`  | `<C-h/j/k/l>` | Move between windows (terminal) |
| `t`  | `<C-x>`       | Exit terminal mode              |

---

### 🔍 Telescope

| Key                | Description              |
| ------------------ | ------------------------ |
| `<leader>ff`       | Find files               |
| `<leader>sb`       | Search in current buffer |
| `<leader>sg`       | Live grep                |
| `<leader>ss`       | Telescope built-ins      |
| `<leader>sd`       | Diagnostics              |
| `<leader><leader>` | List open buffers        |

---

### 🧪 Neotest

| Key          | Description         |
| ------------ | ------------------- |
| `<leader>tt` | Run current file    |
| `<leader>tr` | Run nearest test    |
| `<leader>tl` | Run last test       |
| `<leader>ts` | Toggle summary      |
| `<leader>to` | Show output         |
| `<leader>tO` | Toggle output panel |
| `<leader>tS` | Stop tests          |
| `<leader>tw` | Toggle watch mode   |

---

### 🐞 Debugging (nvim-dap)

| Key           | Description             |
| ------------- | ----------------------- |
| `<leader>da`  | Start Debugging         |
| `<leader>dc`  | Continue                |
| `<leader>db`  | Toggle breakpoint       |
| `<leader>dq`  | Clear breakpoints       |
| `<leader>do`  | Step over               |
| `<leader>dO`  | Step out                |
| `<leader>dr`  | Toggle REPL             |
| `<leader>dv`  | View scopes             |
| `<leader>dw`  | Hover variable          |
| `<leader>ds`  | View stacks             |
| `<leader>dlb` | View breakpoints float  |
| `<leader>dh`  | View watches            |
| `<leader>td`  | Debug nearest (Neotest) |

---

### 🔧 Code

| Key          | Description      |
| ------------ | ---------------- |
| `gd`         | Goto definition  |
| `gr`         | References       |
| `gI`         | Implementations  |
| `gt`         | Type definitions |
| `<leader>rn` | Rename symbol    |
| `<leader>ca` | Code actions     |

---

### 🧱 Misc Plugins

| Key          | Description              |
| ------------ | ------------------------ |
| `<leader>ft` | Toggle floating terminal |
| `<leader>wv` | Vertical split           |
| `<leader>hv` | Horizontal split         |
| `<leader>e`  | Toggle Oil file explorer |
| `<leader>ut` | Toggle transparency      |
| `<leader>gg` | LazyGit                  |

---

### 📋 Trouble.nvim

| Key          | Description                   |
| ------------ | ----------------------------- |
| `<leader>xx` | Toggle diagnostics            |
| `<leader>xX` | Buffer diagnostics            |
| `<leader>cs` | Toggle symbols                |
| `<leader>cS` | LSP references/defs           |
| `<leader>xL` | Location list                 |
| `<leader>xQ` | Quickfix list                 |
| `[q` / `]q`  | Prev/next quickfix or Trouble |

---

## 📂 Project Tasks (Overseer)

| Key          | Description                 |
| ------------ | --------------------------- |
| `<leader>ow` | Toggle task list            |
| `<leader>oo` | Run task                    |
| `<leader>oq` | Quick action on recent task |
| `<leader>oi` | View task info              |
| `<leader>ob` | Open task builder           |
| `<leader>ot` | Task action menu            |
| `<leader>oc` | Clear task cache            |


## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

* [Neovim](https://neovim.io/)
* [lazy.nvim](https://github.com/folke/lazy.nvim)
* [LuaRocks](https://luarocks.org/)([GitHub][1], [luarocks.org][4])

---

[1]: https://github.com/vhyrro/luarocks.nvim?utm_source=chatgpt.com "Easily install luarocks with lazy.nvim - GitHub"
[2]: https://www.reddit.com/r/neovim/comments/1bd499s/how_to_use_a_lua_module_from_luarocks_in_my/?utm_source=chatgpt.com "How to use a lua module from luarocks in my neovim plugin - Reddit"
[3]: https://github.com/camspiers/luarocks?utm_source=chatgpt.com "Easily install luarocks with lazy.nvim - GitHub"
[4]: https://luarocks.org/?utm_source=chatgpt.com "LuaRocks - The Lua package manager"
[5]: https://esouimods.github.io/1-install_luarocks.html?utm_source=chatgpt.com "Installing LuaRocks | ESOUI Code Collection - GitHub Pages"


