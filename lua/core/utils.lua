local M = {}

-- Open config
M.open_config = function()
    vim.cmd("edit $MYVIMRC")
end

-- Restore last session
M.restore_last_session = function()
    local session_file = vim.fn.stdpath("data") .. "/session.vim"
    if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("silent! source " .. session_file)
        vim.cmd("silent! tabfirst") -- optional: go to the first tab
        print("Session restored.")
    else
        print("No session found.")
    end
end

-- Save session manually
M.save_session = function()
    local session_file = vim.fn.stdpath("data") .. "/session.vim"
    vim.opt.sessionoptions = {
        "buffers",
        "curdir",
        "tabpages",
        "winsize",
        "help",
        "globals",
        "localoptions",
        "folds"
    }
    vim.cmd("mksession! " .. session_file)
    print("Session saved.")
end


return M
