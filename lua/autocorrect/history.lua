local M = {}

local history = {}
local max_size = 10

function M.set_max_size(size)
  max_size = size
  while #history > max_size do
    table.remove(history, 1)
  end
end

function M.push(entry)
  table.insert(history, entry)
  if #history > max_size then
    table.remove(history, 1)
  end
end

function M.pop()
  if #history == 0 then
    return nil
  end
  return table.remove(history)
end

function M.undo_last()
  local entry = M.pop()
  if not entry then
    vim.notify("Autocorrect: nada para desfazer", vim.log.levels.INFO)
    return false
  end

  local bufnr = entry.bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("Autocorrect: buffer inválido", vim.log.levels.WARN)
    return false
  end

  local current_line = vim.api.nvim_buf_get_lines(bufnr, entry.lnum, entry.lnum + 1, false)[1]
  if not current_line then
    return false
  end

  local current_word = current_line:sub(entry.col_start + 1, entry.col_end)
  if current_word ~= entry.corrected then
    vim.notify("Autocorrect: texto foi modificado, não é possível desfazer", vim.log.levels.WARN)
    return false
  end

  vim.api.nvim_buf_set_text(
    bufnr,
    entry.lnum,
    entry.col_start,
    entry.lnum,
    entry.col_end,
    { entry.original }
  )

  return true
end

function M.clear()
  history = {}
end

return M
