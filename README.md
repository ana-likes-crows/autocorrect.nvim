# autocorrect.nvim

Real-time autocorrection plugin for Neovim using the native spell checker.

*[Leia em Português](#português)*

## Features

- Automatic spelling correction while typing in insert mode
- Uses Neovim's native `spell` checker
- Visual feedback with temporary highlighting on corrections
- Undo corrections with a single keystroke (`Alt+u`)
- Preserves letter case (lowercase, Capitalized, UPPERCASE)
- Cooldown system to prevent repeated corrections
- Full UTF-8 support
- Configurable per filetype

## Requirements

- Neovim >= 0.8.0
- Spell files for your language (`:set spell spelllang=en`)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "LuccaRomanelli/autocorrect.nvim",
  ft = "markdown",
  config = function()
    require("autocorrect").setup()
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "LuccaRomanelli/autocorrect.nvim",
  ft = "markdown",
  config = function()
    require("autocorrect").setup()
  end,
}
```

## Configuration

```lua
require("autocorrect").setup({
  enabled = true,           -- Enable autocorrection
  idle_ms = 500,            -- Delay before correction (ms)
  min_word_length = 3,      -- Minimum word length to correct
  filetypes = { "markdown" }, -- Filetypes to enable
  highlight_ms = 300,       -- Highlight duration (ms)
  undo_history_size = 10,   -- Max undo history entries
  undo_keymap = "<M-u>",    -- Keymap to undo last correction
  ignore_words = {},        -- Words to ignore (case insensitive)
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:AutocorrectEnable` | Enable autocorrection |
| `:AutocorrectDisable` | Disable autocorrection |
| `:AutocorrectToggle` | Toggle autocorrection |
| `:AutocorrectUndo` | Undo last correction |

## Keymaps

| Keymap | Mode | Description |
|--------|------|-------------|
| `<M-u>` (Alt+u) | Insert | Undo last correction |

## API

```lua
local autocorrect = require("autocorrect")

autocorrect.enable()   -- Enable autocorrection
autocorrect.disable()  -- Disable autocorrection
autocorrect.toggle()   -- Toggle autocorrection
autocorrect.undo()     -- Undo last correction
```

## Tips

### Setting up spell check

Make sure spell checking is enabled for your language:

```lua
vim.opt.spell = true
vim.opt.spelllang = { "en", "pt_br" }  -- English and Brazilian Portuguese
```

### Ignoring specific words

```lua
require("autocorrect").setup({
  ignore_words = { "neovim", "lua", "api" },
})
```

---

# Português

Plugin de autocorreção em tempo real para Neovim usando o verificador ortográfico nativo.

## Funcionalidades

- Correção ortográfica automática enquanto digita no modo insert
- Usa o verificador `spell` nativo do Neovim
- Feedback visual com destaque temporário nas correções
- Desfazer correções com uma única tecla (`Alt+u`)
- Preserva capitalização (minúsculas, Capitalizado, MAIÚSCULAS)
- Sistema de cooldown para evitar correções repetidas
- Suporte completo a UTF-8
- Configurável por tipo de arquivo

## Requisitos

- Neovim >= 0.8.0
- Arquivos de spell para seu idioma (`:set spell spelllang=pt_br`)

## Instalação

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "LuccaRomanelli/autocorrect.nvim",
  ft = "markdown",
  config = function()
    require("autocorrect").setup()
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "LuccaRomanelli/autocorrect.nvim",
  ft = "markdown",
  ft = "markdown",
  config = function()
    require("autocorrect").setup()
  end,
}
```

## Configuração

```lua
require("autocorrect").setup({
  enabled = true,           -- Habilitar autocorreção
  idle_ms = 500,            -- Delay antes de corrigir (ms)
  min_word_length = 3,      -- Tamanho mínimo da palavra
  filetypes = { "markdown" }, -- Tipos de arquivo habilitados
  highlight_ms = 300,       -- Duração do destaque (ms)
  undo_history_size = 10,   -- Máximo de entradas no histórico
  undo_keymap = "<M-u>",    -- Tecla para desfazer
  ignore_words = {},        -- Palavras a ignorar
})
```

## Comandos

| Comando | Descrição |
|---------|-----------|
| `:AutocorrectEnable` | Habilitar autocorreção |
| `:AutocorrectDisable` | Desabilitar autocorreção |
| `:AutocorrectToggle` | Alternar autocorreção |
| `:AutocorrectUndo` | Desfazer última correção |

## Atalhos

| Atalho | Modo | Descrição |
|--------|------|-----------|
| `<M-u>` (Alt+u) | Insert | Desfazer última correção |

## Dicas

### Configurando verificação ortográfica

Certifique-se de que a verificação ortográfica está habilitada:

```lua
vim.opt.spell = true
vim.opt.spelllang = { "pt_br", "en" }  -- Português e Inglês
```

### Ignorando palavras específicas

```lua
require("autocorrect").setup({
  ignore_words = { "neovim", "lua", "api" },
})
```

## License

MIT
