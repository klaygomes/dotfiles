local nvim_lsp = require('lspconfig')

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { "html", "bashls", "cssls", "vimls", "tsserver", "pyright"}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {
      debounce_text_changes = 150,
    }
  }
end
--
-- efm configuration
-- Below is a variable in wich you specify where you have prettier installed
-- make sure you update the formatCommand path to the location where you have installed prettier
local prettier = {
  formatCommand = 'prettier --stdin-filepath ${FILENAME}',
  formatStdin = true
}

-- Below is a variable in wich you specify where eslint_d is installed, you dont need to change this
-- as it should be the same for you.
local eslint = {
  lintCommand = "eslint_d -f unix --stdin --stdin-filename ${FILENAME}",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintIgnoreExitCode = true,
  formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename ${FILENAME}",
  formatStdin = true 
}

-- Below you can set some formatting options for prettier
-- Format options for prettier
local format_options_prettier = {
  tabWidth = 2,
  singleQuote = true,
  trailingComma = 'all',
  configPrecedence = 'prefer-file'
}

-- Below is a list of languages and a list of servers you want per language
-- so for typescript we have prettier and eslint for example
local languages = {
  typescript = {prettier, eslint},
  javascript = {prettier, eslint},
  typescriptreact = {prettier, eslint},
  javascriptreact = {prettier, eslint},
  yaml = {prettier},
  json = {prettier},
  html = {prettier},
  scss = {prettier},
  css = {prettier},
  markdown = {prettier}
}

-- Below is where you setup the efm language server and add the on_attach function
-- and add all the filetypes you want this server to be appended on.
nvim_lsp.efm.setup{
  on_attach = on_attach,

  -- Tell efm what filetypes to append to
  filetypes = vim.tbl_keys(languages),

  -- Set some extra settings
  init_options = {
    -- Enable document formatting
    documentFormatting = true,

    -- Enable hover information functionality
    hover = true,

    -- Enable the use of symbols
    documentSymbol = true,

    -- Enable the use of code actions
    codeAction = true,

    -- Enable autocompletion popup
    completion = true
  },

  settings = {
    -- This is the location where error messages wil be written to
    -- this is nice for debugging your language server
    log_file =  os.getenv('HOME') .. '/logfile.txt',

    -- These are the paths efm will look for eslint settings and prettier settings
    -- inside a project you are working on
    rootMarkers = {
      ".lua-format",
      ".eslintrc.cjs",
      ".eslintrc",
      ".eslintrc.json",
      ".eslintrc.js",
      ".prettierrc",
      ".prettierrc.js",
      ".prettierrc.json",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettier.config.js",
      ".prettier.config.cjs",
    },

    -- Setting the languages
    languages = languages,
  }
}

nvim_lsp.ccls.setup {
  cmd = { 'ccls', '--log-file=' .. os.getenv('HOME')  .. 'ccls-log.txt' },
  init_options = {
    cache = {
      directory = "/tmp/ccls-cache"
    },
    clang = {
      extraArgs = {'--gcc-toolchain=/Applications/ARM/arm-none-eabi' }
    }
  }
}

