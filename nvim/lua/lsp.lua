local lsp_zero = require("lsp-zero")

lsp_zero.extend_lspconfig({
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  sign_text = true,
  lsp_attach = function(client, bufnr)
    lsp_zero.default_keymaps({ buffer = bufnr })
    -- keymaps not covered by lsp-zero defaults
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
    map("<leader>e", vim.diagnostic.open_float, "Show diagnostic float")
  end,
})

vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  signs = true,
  update_in_insert = false,
  float = { border = "rounded", source = true },
})

require("mason").setup({ ui = { border = "rounded" } })

require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "bashls",
    "ts_ls",
    "pyright",
    "clangd",
    "cssls",
    "html",
    "jsonls",
    "yamlls",
  },
  handlers = {
    lsp_zero.default_setup,

    lua_ls = function()
      require("lspconfig").lua_ls.setup(lsp_zero.nvim_lua_ls())
    end,

    pyright = function()
      require("lspconfig").pyright.setup({
        settings = {
          python = { analysis = { typeCheckingMode = "basic" } },
        },
      })
    end,
  },
})
