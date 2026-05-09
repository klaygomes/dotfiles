-- Keymaps set whenever an LSP client attaches (Neovim 0.10+ pattern)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Go to implementation")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
    map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
    map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
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

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "bashls",
    "ts_ls",      -- JavaScript / TypeScript / JSX / TSX
    "pyright",    -- Python
    "clangd",     -- C / C++
    "cssls",      -- CSS
    "html",       -- HTML
    "jsonls",
    "yamlls",
  },
  handlers = {
    -- Default: apply shared capabilities to every server
    function(server_name)
      require("lspconfig")[server_name].setup({ capabilities = capabilities })
    end,

    -- lua_ls: teach it about the Neovim runtime
    lua_ls = function()
      require("lspconfig").lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
          },
        },
      })
    end,

    -- pyright: disable type-checking in favour of diagnostics only
    pyright = function()
      require("lspconfig").pyright.setup({
        capabilities = capabilities,
        settings = {
          python = { analysis = { typeCheckingMode = "basic" } },
        },
      })
    end,
  },
})
