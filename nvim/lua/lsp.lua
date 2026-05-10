vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(ev)
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    map('gd',  vim.lsp.buf.definition,                                        'Go to definition')
    map('gD',  vim.lsp.buf.declaration,                                       'Go to declaration')
    map('gr',  vim.lsp.buf.references,                                        'References')
    map('gi',  vim.lsp.buf.implementation,                                    'Go to implementation')
    map('K',   vim.lsp.buf.hover,                                             'Hover docs')
    map('<leader>rn', vim.lsp.buf.rename,        'Rename symbol')
    map('<leader>ca', vim.lsp.buf.code_action,   'Code action')
    map('<leader>e',  vim.diagnostic.open_float, 'Show diagnostic')
  end,
})

vim.diagnostic.config({
  virtual_text = { prefix = '●' },
  signs = true,
  update_in_insert = false,
  float = { border = 'rounded', source = true },
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
})

vim.lsp.config('pyright', {
  settings = {
    python = { analysis = { typeCheckingMode = 'basic' } },
  },
})

require('mason').setup({ ui = { border = 'rounded' } })
require('mason-lspconfig').setup({
  ensure_installed = { 'lua_ls', 'clangd', 'marksman' },
})

-- npm-managed servers (via node/globals) — Mason does not manage these
vim.lsp.enable({
  'bashls',
  'ts_ls',
  'cssls',
  'html',
  'jsonls',
  'yamlls',
  'pyright',
})
