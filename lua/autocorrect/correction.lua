local config = require("autocorrect.config")
local history = require("autocorrect.history")

local M = {}

local ns_id = vim.api.nvim_create_namespace("autocorrect")

-- Iterate words with proper UTF-8 support using vim's \w pattern
local function iter_words_utf8(text)
  local words = {}
  local pos = 1
  while pos <= #text do
    -- Find start of word (skip non-word characters)
    local start_byte = pos
    while start_byte <= #text do
      local char = text:sub(start_byte, start_byte)
      -- Use vim.fn.match to check if it's a word character
      if vim.fn.match(char, [[\w]]) >= 0 then
        break
      end
      start_byte = start_byte + 1
    end
    if start_byte > #text then
      break
    end

    -- Find end of word
    local end_byte = start_byte
    while end_byte <= #text do
      -- Get the complete UTF-8 character
      local byte = text:byte(end_byte)
      local char_len = 1
      if byte >= 0xC0 and byte < 0xE0 then char_len = 2
      elseif byte >= 0xE0 and byte < 0xF0 then char_len = 3
      elseif byte >= 0xF0 then char_len = 4
      end
      local char = text:sub(end_byte, end_byte + char_len - 1)
      if vim.fn.match(char, [[\w]]) < 0 then
        break
      end
      end_byte = end_byte + char_len
    end

    local word = text:sub(start_byte, end_byte - 1)
    if #word > 0 then
      table.insert(words, { start = start_byte - 1, word = word })  -- 0-indexed
    end
    pos = end_byte
  end
  return words
end

local function is_ignored(word)
  local lower = word:lower()
  for _, ignored in ipairs(config.options.ignore_words) do
    if ignored:lower() == lower then
      return true
    end
  end
  return false
end

local function preserve_case(original, corrected)
  if original:match("^%u+$") then
    return corrected:upper()
  elseif original:match("^%u") then
    return corrected:sub(1, 1):upper() .. corrected:sub(2)
  end
  return corrected
end

function M.get_correction(word)
  if #word < config.options.min_word_length then
    return nil
  end

  if is_ignored(word) then
    return nil
  end

  local spell_result = vim.spell.check(word)
  if not spell_result or #spell_result == 0 then
    return nil
  end

  local first = spell_result[1]
  if first[2] ~= "bad" then
    return nil
  end

  local suggestions = vim.fn.spellsuggest(word, 1)
  if not suggestions or #suggestions == 0 then
    return nil
  end

  return preserve_case(word, suggestions[1])
end

function M.scan_line_for_errors(bufnr, lnum, col_limit)
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
  if not line then
    return {}
  end

  local text_before_cursor = line:sub(1, col_limit)
  local corrections = {}

  for _, match in ipairs(iter_words_utf8(text_before_cursor)) do
    local col_start = match.start
    local word = match.word
    local col_end = col_start + #word

    -- Only correct a word once it has actually been "finished" — i.e. the
    -- cursor has moved past it (a space, punctuation, newline, etc. was
    -- typed). If col_end == col_limit, the cursor is sitting right at the
    -- end of this word, which means it's still being typed and must be
    -- skipped to avoid correcting it mid-word.
    if col_end < col_limit then
      local corrected = M.get_correction(word)
      if corrected and corrected ~= word then
        table.insert(corrections, {
          word = word,
          corrected = corrected,
          col_start = col_start,
          col_end = col_end,
        })
      end
    end
  end

  return corrections
end

function M.highlight_correction(bufnr, lnum, col_start, col_end)
  vim.api.nvim_buf_add_highlight(bufnr, ns_id, "AutocorrectHighlight", lnum, col_start, col_end)

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, lnum, lnum + 1)
    end
  end, config.options.highlight_ms)
end

function M.apply_corrections(bufnr, lnum, corrections, cursor_col)
  if #corrections == 0 then
    return cursor_col
  end

  table.sort(corrections, function(a, b)
    return a.col_start > b.col_start
  end)

  local offset = 0

  for _, corr in ipairs(corrections) do
    vim.api.nvim_buf_set_text(
      bufnr,
      lnum,
      corr.col_start,
      lnum,
      corr.col_end,
      { corr.corrected }
    )

    history.push({
      bufnr = bufnr,
      lnum = lnum,
      col_start = corr.col_start,
      col_end = corr.col_start + #corr.corrected,
      original = corr.word,
      corrected = corr.corrected,
    })

    M.highlight_correction(bufnr, lnum, corr.col_start, corr.col_start + #corr.corrected)

    local diff = #corr.corrected - #corr.word
    if corr.col_end <= cursor_col then
      offset = offset + diff
    end
  end

  return cursor_col + offset
end

return M
