---

# Pena.Vim

Modular Neovim configuration tailored for developers seeking a streamlined and efficient coding environment. Built with Lua, it leverages the power of `lazy.nvim` for plugin management, offering a clean and extensible setup out of the box.([GitHub][1])

---

## ✨ Features

* **Lazy-loaded plugins** for optimal startup time
* **LSP (Language Server Protocol)** integration for enhanced code intelligence
* **Treesitter** for advanced syntax highlighting
* **Telescope** for fuzzy finding and navigation
* **Custom key mappings** for improved workflow
* **LuaRocks** integration for managing Lua dependencies([Reddit][2], [GitHub][3])

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

2. **Clone AnVim Repository**

   Clone the AnVim repository into your Neovim configuration directory:

   ```bash
   git clone https://github.com/ardi-nugraha/AnVim ~/.config/nvim
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

Once installed, AnVim provides a robust Neovim environment with sensible defaults and powerful plugins. Explore and customize the configuration to suit your workflow.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

* [Neovim](https://neovim.io/)
* [lazy.nvim](https://github.com/folke/lazy.nvim)
* [LuaRocks](https://luarocks.org/)([GitHub][1], [luarocks.org][4])

---

Feel free to customize this `README.md` further to match any specific details or preferences for your AnVim configuration.

[1]: https://github.com/vhyrro/luarocks.nvim?utm_source=chatgpt.com "Easily install luarocks with lazy.nvim - GitHub"
[2]: https://www.reddit.com/r/neovim/comments/1bd499s/how_to_use_a_lua_module_from_luarocks_in_my/?utm_source=chatgpt.com "How to use a lua module from luarocks in my neovim plugin - Reddit"
[3]: https://github.com/camspiers/luarocks?utm_source=chatgpt.com "Easily install luarocks with lazy.nvim - GitHub"
[4]: https://luarocks.org/?utm_source=chatgpt.com "LuaRocks - The Lua package manager"
[5]: https://esouimods.github.io/1-install_luarocks.html?utm_source=chatgpt.com "Installing LuaRocks | ESOUI Code Collection - GitHub Pages"
