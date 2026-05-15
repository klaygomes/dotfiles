local M = {}

M.colorscheme = "tokyonight-night"
M.lightline   = "tokyonight"

function M.apply()
  vim.cmd("colorscheme " .. M.colorscheme)
  vim.api.nvim_set_hl(0, "ColorColumn", { link = "CursorLine" })
end

return M
