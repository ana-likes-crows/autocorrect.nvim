local config = require("autocorrect.config")
local correction = require("autocorrect.correction")
local history = require("autocorrect.history")

local M = {}

local timer = nil
local augroup = nil
local is_correcting = false
local last_correction = nil  -- { lnum, col_start, word }
local correction_cooldown = {}  -- { [bufnr] = { [lnum] = expire_time } }
local COOLDOWN_MS = 1000

local function is_filetype_enabled()
  local ft = vim.bo.filetype
  for _, enabled_ft in ipairs(config.options.filetypes) do
    if ft == enabled_ft then
      return true
    end
  end
  return false
end

local function is_in_cooldown(bufnr, lnum)
  local buf = correction_cooldown[bufnr]
  if not buf or not buf[lnum] then
    return false
  end
  if vim.loop.now() < buf[lnum] then
    return true
  end
  buf[lnum] = nil
  return false
end

local function set_cooldown(bufnr, lnum)
  if not correction_cooldown[bufnr] then
    correction_cooldown[bufnr] = {}
  end
  correction_cooldown[bufnr][lnum] = vim.loop.now() + COOLDOWN_MS
end

local function is_same_correction(lnum, corrections)
  if not last_correction then
    return false
  end
  if last_correction.lnum ~= lnum then
    return false
  end
  for _, corr in ipairs(corrections) do
    if corr.col_start == last_correction.col_start and
       corr.corrected == last_correction.word then
      return true
    end
  end
  return false
end

local function do_correction()
  if is_correcting then
    return
  end

  if not config.options.enabled then
    return
  end

  if not is_filetype_enabled() then
    return
  end

  is_correcting = true

  -- Cancel pending timer
  if timer then
    timer:stop()
    timer = nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1] - 1
  local col = cursor[2]

  -- Check cooldown BEFORE scanning
  if is_in_cooldown(bufnr, lnum) then
    is_correcting = false
    return
  end

  local corrections = correction.scan_line_for_errors(bufnr, lnum, col)

  -- Evitar re-corrigir a mesma palavra
  if #corrections > 0 and not is_same_correction(lnum, corrections) then
    local old_eventignore = vim.o.eventignore
    vim.o.eventignore = "TextChangedI"

    local new_col = correction.apply_corrections(bufnr, lnum, corrections, col)
    vim.api.nvim_win_set_cursor(0, { lnum + 1, new_col })

    -- Guardar última correção
    last_correction = {
      lnum = lnum,
      col_start = corrections[1].col_start,
      word = corrections[1].corrected
    }

    -- Set cooldown after correction
    set_cooldown(bufnr, lnum)

    vim.o.eventignore = old_eventignore
  end

  is_correcting = false
end

local function schedule_correction()
  if timer then
    timer:stop()
  end

  timer = vim.defer_fn(function()
    timer = nil
    do_correction()
  end, config.options.idle_ms)
end

local function setup_autocmds()
  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
  end

  augroup = vim.api.nvim_create_augroup("Autocorrect", { clear = true })

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup,
    callback = function()
      if config.options.enabled and is_filetype_enabled() then
        schedule_correction()
      end
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    callback = function()
      if timer then
        timer:stop()
        timer = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = augroup,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      if last_correction and last_correction.lnum ~= cursor[1] - 1 then
        last_correction = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(args)
      correction_cooldown[args.buf] = nil
    end,
  })
end

local function setup_highlight()
  vim.api.nvim_set_hl(0, "AutocorrectHighlight", { link = "IncSearch", default = true })
end

local function setup_keymap()
  if config.options.undo_keymap then
    vim.keymap.set("i", config.options.undo_keymap, function()
      history.undo_last()
    end, { desc = "Desfazer última autocorreção" })
  end
end

local function setup_commands()
  vim.api.nvim_create_user_command("AutocorrectEnable", function()
    M.enable()
  end, { desc = "Habilitar autocorreção" })

  vim.api.nvim_create_user_command("AutocorrectDisable", function()
    M.disable()
  end, { desc = "Desabilitar autocorreção" })

  vim.api.nvim_create_user_command("AutocorrectToggle", function()
    M.toggle()
  end, { desc = "Alternar autocorreção" })

  vim.api.nvim_create_user_command("AutocorrectUndo", function()
    history.undo_last()
  end, { desc = "Desfazer última autocorreção" })
end

function M.enable()
  config.options.enabled = true
  vim.notify("Autocorrect: habilitado", vim.log.levels.INFO)
end

function M.disable()
  config.options.enabled = false
  if timer then
    timer:stop()
    timer = nil
  end
  vim.notify("Autocorrect: desabilitado", vim.log.levels.INFO)
end

function M.toggle()
  if config.options.enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.undo()
  history.undo_last()
end

function M.setup(opts)
  config.setup(opts)
  history.set_max_size(config.options.undo_history_size)

  setup_highlight()
  setup_autocmds()
  setup_keymap()
  setup_commands()
end

return M
