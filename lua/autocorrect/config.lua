local M = {}

M.defaults = {
  enabled = true,
  idle_ms = 500,
  min_word_length = 3,
  filetypes = { "markdown" },
  highlight_ms = 300,
  undo_history_size = 10,
  undo_keymap = "<M-u>",
  ignore_words = {},
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
