# pena.Vim

Keymaps and everyday workflows.

**Leader:** `Space`. Shortcuts use Normal mode unless noted; press `Esc` to leave Insert mode.
`<C-x>` means Ctrl+x, `<M-x>` means Alt+x, and `<S-x>` means Shift+x.

## Contents

- [Dashboard](#dashboard)
- [Files and buffers](#files-and-buffers)
- [Windows and terminal](#windows-and-terminal)
- [Search and replace](#search-and-replace)
- [Code navigation and actions](#code-navigation-and-actions)
- [Diagnostics](#diagnostics)
- [Folding](#folding)
- [Git](#git)
- [Debugging](#debugging)
- [.NET projects](#net-projects)
- [Tasks](#tasks)
- [Testing](#testing)
- [Editing](#editing)
- [Markdown](#markdown)
- [Other pickers](#other-pickers)
- [Appearance and logging](#appearance-and-logging)

## Dashboard

Open the dashboard with `<leader>dd`.

| Key | Action |
|---|---|
| `f` | Find a file |
| `n` | Create a file |
| `g` | Search project text |
| `r` | Browse recent files |
| `c` | Find a configuration file |
| `s` | Restore the project session |
| `L` | Open the plugin manager |
| `q` | Quit |

## Files and buffers

| Key | Action |
|---|---|
| `<leader><space>` | Smart file finder |
| `<leader>ff` | Find files |
| `<leader>fg` | Find Git-tracked files |
| `<leader>fr` | Browse recent files |
| `<leader>fp` | Choose a project |
| `<leader>fc` | Find a configuration file |
| `<leader>e` | Open the file explorer |
| `<leader>,` / `<leader>fb` | Choose an open buffer |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<leader>bp` | Pin or unpin the current buffer |
| `<leader>bP` | Close unpinned buffers |
| `<leader>br` / `<leader>bl` | Close buffers to the right / left |
| `<leader>bd` | Close the current buffer; choose save, discard, or cancel for unsaved changes |

## Windows and terminal

| Key | Action |
|---|---|
| `<leader>wv` | Create a vertical split |
| `<leader>hv` | Create a horizontal split |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Move left / down / up / right between windows |
| `<C-q>` | Close the current window |
| `<leader>dt` | Toggle the floating terminal |
| `<C-x>` in Terminal mode | Leave Terminal mode |

Window-navigation shortcuts also work in Terminal mode. Touchpad and mouse-wheel
scrolling work over the hovered window, including search results.

## Search and replace

| Key | Action |
|---|---|
| `<leader>sg` | Search project text |
| `<leader>sG` | Search text in the current working directory |
| `<leader>sb` | Search the current buffer, including unsaved edits |
| `<leader>sw` | Search the word under the cursor, or selected text in Visual mode |
| `<leader>sr` | Open search and replace; starts with the current file type |
| `/` / `?` in a file | Search forward / backward |
| `n` / `N` in a file | Repeat the search in the same / opposite direction |

For text queries, type your search and press `Enter`. Press `Ctrl-C` to cancel.
`<leader>sw` searches immediately. Search and replace also opens from Visual mode.

### Search-result controls

These controls apply to text-search results, references, and symbol lists.

| Key | Action |
|---|---|
| `j` / `k`, arrow keys | Select a result and preview it in the original window |
| `/` / `?` | Search result text forward / backward without filtering the list |
| `n` / `N` | Repeat that result search in the same / opposite direction |
| `Enter` / double-click | Open the selected result and close the list |
| `q` / `Esc` | Close the list and restore the previous buffer and cursor |

Results show file icons, paths, and matching code. Unsaved edits are preserved
when previewing or cancelling.

## Code navigation and actions

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` / `gI` | Go to implementation |
| `gy` | Go to type definition |
| `<leader>ss` | Browse symbols in the current file |
| `<leader>sS` | Search workspace symbols |
| `<leader>rn` / `<leader>cr` | Rename a symbol |
| `<leader>ca` | Code actions; also works in Visual mode |
| `<leader>k` | Show signature help |
| `<leader>uh` | Toggle inlay hints |

A single definition jumps directly; multiple matches open the result list.

### Code selection and movement

Use text objects in Visual mode or after an editing command, such as `daf`.

| Key | Action |
|---|---|
| `af` / `if` | Select around / inside a function |
| `ac` / `ic` | Select around / inside a class |
| `]f` / `[f` | Next / previous function |
| `]c` / `[c` | Next / previous class |

## Diagnostics

| Key | Action |
|---|---|
| `<leader>cd` | Show diagnostics for the current line |
| `]d` / `[d` | Next / previous diagnostic |
| `]e` / `[e` | Next / previous error |
| `]w` / `[w` | Next / previous warning |
| `<leader>sd` | Browse project diagnostics |
| `<leader>sD` | Browse current-buffer diagnostics |
| `<leader>xx` | Toggle the diagnostics panel |
| `<leader>xX` | Toggle current-buffer diagnostics |
| `<leader>cs` | Toggle the code-navigation panel |
| `<leader>xL` / `<leader>xQ` | Toggle the location / quickfix list |
| `[q` / `]q` | Previous / next panel or quickfix item |

## Folding

Files start expanded.

| Key | Action |
|---|---|
| `za` | Toggle the fold under the cursor |
| `zc` / `zo` | Close / open the current fold |
| `zM` / `zR` | Close / open all folds |

## Git

| Key | Action |
|---|---|
| `<leader>gs` | Open Git status and preview changed files |
| `<leader>gd` | Open a diff for the current file |
| `<leader>gc` | Commit changes |
| `<leader>gp` | Push changes |
| `<leader>gb` | Show blame |
| `<leader>gl` | Browse Git history |
| `<leader>gL` | Browse history for the current line |
| `<leader>gf` | Browse history for the current file |

### Git status and diff controls

| Control | Action |
|---|---|
| Move through status entries | Preview the selected file |
| `Enter` / double-click a status entry | Open its diff |
| Click the source preview | Open that file's diff |
| `q` / `Esc` in status | Return to the previous buffer and cursor |
| `q` / `Ctrl-O` in either diff pane | Close the diff and restore the previous buffer, cursor, and layout |

Use `<leader>gd` or the status list to open diffs with these return controls.
Unsaved edits and unrelated windows are kept. `:Git` opens the full Git interface.

## Debugging

| Key | Action |
|---|---|
| `<leader>da` / `<leader>dc` | Start or continue debugging |
| `<leader>db` | Toggle a breakpoint |
| `<leader>dq` | Clear all breakpoints |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dw` | Inspect the variable under the cursor |
| `<leader>de` | Evaluate an expression; also works in Visual mode |
| `<leader>ds` | Show the call stack |
| `<leader>dr` | Toggle the debug console |
| `<leader>dlb` | Show breakpoints |
| `<leader>dh` | Show watches |
| `<leader>dv` | Show scopes |
| `<leader>dT` | Stop debugging |
| `<leader>dR` | Toggle automatic reload on save |

## .NET projects

Choose a startup project, then build, run, watch, or debug it.

| Key | Action |
|---|---|
| `<leader>np` | Choose the startup project |
| `<leader>nb` | Build |
| `<leader>nr` | Run |
| `<leader>nw` | Run with watch |
| `<leader>nt` | Run tests |
| `<leader>na` | Attach the debugger |

| Command | Action |
|---|---|
| `:DotnetDebug` | Debug the selected project |
| `:DotnetRestore` | Restore project packages |
| `:DotnetFormat` | Format the project |

## Tasks

| Key | Action |
|---|---|
| `<leader>ow` | Toggle the task list |
| `<leader>oo` | Run a task |
| `<leader>ot` | Open task actions |

Tasks and their consoles share the bottom 30% of the screen. In the task list,
use `<C-s>` to open output in a split.

## Testing

| Key | Action |
|---|---|
| `<leader>tn` | Run the nearest test |
| `<leader>tf` | Run tests in the current file |
| `<leader>ts` | Run the test suite |
| `<leader>tl` | Repeat the last test run |
| `<leader>tv` | Return to the last test file |

## Editing

| Key | Action |
|---|---|
| `<C-c>` in Visual mode | Copy selected text to the clipboard |
| `<C-v>` | Paste from the clipboard; also works in Visual mode |
| `d` | Delete without replacing the copied text |
| `<leader>p` in Visual mode | Paste without replacing the copied text |
| `<` / `>` in Visual mode | Indent left / right and keep the selection |
| `<C-d>` | Search for the word under the cursor |
| `<M-h>` / `<M-j>` / `<M-k>` / `<M-l>` | Move a line or selection left / down / up / right |
| `gsa` | Add surrounding quotes or brackets |
| `gsd` | Delete surrounding quotes or brackets |
| `gsr` | Replace surrounding quotes or brackets |
| `gsf` / `gsF` | Find the next / previous surrounding pair |
| `gsh` | Highlight the surrounding pair |

## Markdown

| Key | Action |
|---|---|
| `<leader>mr` | Toggle rendered Markdown in the editor |
| `<leader>ms` | Open a Markdown preview split |
| `<leader>mp` | Toggle browser preview |
| `<leader>mP` | Stop browser preview |

Browser preview displays diagrams and math. See the [Markdown example](examples/markdown-preview.md).

## Other pickers

| Key | Action |
|---|---|
| `<leader>:` / `<leader>sc` | Command history |
| `<leader>n` | Notification history |
| `<leader>s"` | Registers |
| `<leader>s/` | Search history |
| `<leader>sa` | Autocommands |
| `<leader>sC` | Available commands |
| `<leader>sh` | Help pages |
| `<leader>sH` | Highlight groups |
| `<leader>si` | Icons |
| `<leader>sj` | Jump history |
| `<leader>sk` | Keymaps |
| `<leader>sl` | Location list |
| `<leader>sm` | Marks |
| `<leader>sM` | Manual pages |
| `<leader>sp` | Plugins |
| `<leader>sq` | Quickfix list |
| `<leader>sR` | Resume the last picker |
| `<leader>su` | Undo history |

## Appearance and logging

| Key | Action |
|---|---|
| `<leader>uc` | Switch colorscheme |
| `<leader>ut` | Toggle transparency |
| `<leader>ll` | Log the variable under the cursor |
| `<leader>lt` | Log its type |
| `<leader>lm` | Insert a log message |
| `<leader>lr` | Remove log statements |

Choose OneDark, Tinta, Bluloco Dark, or Bluloco Light with `<leader>uc`.
