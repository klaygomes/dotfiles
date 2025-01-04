vim.opt.number = true       -- Show line numbers
vim.opt.compatible = false  -- Be neovim, not vi
vim.opt.filetype = "on"     -- Enable filetype detection
vim.opt.syntax = "enable"   -- Enable syntax highlighting
vim.opt.path:append("**")   -- search recursively for files with :find
vim.opt.autoread = true     -- automatically read file when changed outside of vim

vim.opt.hidden = true       -- don't ask to save buffers before switching
vim.opt.number = true       -- Show line numbers
vim.opt.showbreak = "+++"   -- Wrap-broken line prefix
vim.opt.textwidth = 100     -- Line wrap (number of cols)
vim.opt.showmatch = true    -- Highlight matching brace
vim.opt.spell = true        -- Enable spell-checking
vim.opt.visualbell = true   -- Use visual bell (no beeping)

vim.opt.hlsearch = true     -- Highlight all search results
vim.opt.smartcase = true    -- Enable smart-case search
vim.opt.ignorecase = true   -- Always case-insensitive
vim.opt.incsearch = true    -- Searches for strings incrementally

vim.opt.autoindent = true   -- Auto-indent new lines
vim.opt.expandtab = true    -- Use spaces instead of tabs
vim.opt.shiftwidth = 2      -- Number of auto-indent spaces
vim.opt.smartindent = true  -- Enable smart-indent
vim.opt.smarttab = true     -- Enable smart-tabs
vim.opt.softtabstop = 2     -- Number of spaces per Tab
vim.opt.cursorline = true   -- Highlight current line
vim.opt.ruler = true        -- Show the cursor position
vim.opt.termguicolors = true  -- Color Schema
vim.opt.wildmenu = true       -- Enhance command-line completion
vim.opt.wrap = true           -- Wrap lines
vim.opt.wrapscan = true       -- Searches wrap around the end of the file

-- show all characters that aren't white-space. So spaces are the only thing that doesn't show up.
vim.opt.listchars = { eol = "$", tab = "→ ", trail = "~", extends = ">", precedes = "<", nbsp = "☠" }
vim.opt.list = true
vim.opt.updatetime = 100                  -- To be able to see gitgutter signs more quickly
vim.opt.completeopt = "menuone,noselect"  -- completion menu like an IDE
vim.opt.spelllang = "en_us,pt_br"         -- Set the spell language
vim.opt.swapfile = false                  -- no swap files, I like to live dangerously

-- Set the leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ignore files
vim.opt.wildignore:append({ "*.pyc", "*.o", "*.obj", "*.svn", "*.swp", "*.class", "*.hg", "*.DS_Store", "*.min.*", "node_files" })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  {
    'jacoborus/tender.vim',
    config = function() vim.cmd([[colorscheme tender]]) end
  },
  {
    'itchyny/lightline.vim',
    config = function()
      vim.g.lightline = {
        colorscheme = 'tender',
        active = {
          left = { { 'mode', 'paste' }, { 'gitbranch', 'readonly', 'filename', 'modified' } }
        },
        component_function = {
          gitbranch = 'gitbranch#name'
        },
      }
    end
  }
})
