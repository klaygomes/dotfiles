local cmp = require("cmp")
local cmp_action = require("lsp-zero").cmp_action()
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
    ["<C-f>"]     = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"]     = cmp.mapping.abort(),
    ["<CR>"]      = cmp.mapping.confirm({ select = false }),
    ["<Tab>"]     = cmp_action.tab_complete(),
    ["<S-Tab>"]   = cmp_action.select_prev_or_fallback(),
  }),
  sources = cmp.config.sources(
    { { name = "nvim_lsp" }, { name = "luasnip" } },
    { { name = "buffer" }, { name = "path" } }
  ),
})
