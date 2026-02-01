if vim.g.loaded_autocorrect then
  return
end
vim.g.loaded_autocorrect = true

-- Keymap para desfazer última autocorreção no insert mode
vim.keymap.set("i", "<M-u>", function()
  require("autocorrect.history").undo_last()
end, { desc = "Desfazer última autocorreção" })
