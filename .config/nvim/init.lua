-- File Explorer related
-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require('plug')
-- Rust tools
-- Mason Setup
require("mason").setup()
-- Null ls setup (Formatter)
require("mason-null-ls").setup({
    ensure_installed = {
        -- Opt to list sources here, when available in mason.
    },
    automatic_installation = false,
    automatic_setup = true, -- Recommended, but optional
})
require("null-ls").setup({
    sources = {
        -- Anything not supported by mason.
    }
})

require("mason-null-ls").setup({
    automatic_setup = true,
})

local rt = require("rust-tools")

rt.setup({
  server = {
    on_attach = function(_, bufnr)
      -- Hover actions
      vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- Code action groups
      vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
    end,
		settings = {
			["rust-analyzer"] = {
				lens = {
					enable = true,
				},
				checkonsave = {
					command = "clippy",
				},
			},
		},
  },
}) 

-- LSP Diagnostics Options Setup 
local sign = function(opts)
  vim.fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = ''
  })
end

sign({name = 'DiagnosticSignError', text = ''})
sign({name = 'DiagnosticSignWarn', text = ''})
sign({name = 'DiagnosticSignHint', text = ''})
sign({name = 'DiagnosticSignInfo', text = ''})

vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    update_in_insert = true,
    underline = true,
    severity_sort = false,
    float = {
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
    },
})

-- Completion Plugin Setup
local cmp = require'cmp'
cmp.setup({
  -- Enable LSP snippets
  snippet = {
    expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    -- Add tab support
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<C-S-f>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    })
  },
  -- Installed sources:
  sources = {
    { name = 'path' },                              -- file paths
    { name = 'nvim_lsp', keyword_length = 3 },      -- from language server
    { name = 'nvim_lsp_signature_help'},            -- display function signatures with current parameter emphasized
    { name = 'nvim_lua', keyword_length = 2},       -- complete neovim's Lua runtime API such vim.lsp.*
    { name = 'buffer', keyword_length = 2 },        -- source current buffer
    { name = 'vsnip', keyword_length = 2 },         -- nvim-cmp source for vim-vsnip 
    { name = 'calc'},                               -- source for math calculation
  },
  window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
  },
  formatting = {
      fields = {'menu', 'abbr', 'kind'},
      format = function(entry, item)
          local menu_icon ={
              nvim_lsp = 'λ',
              vsnip = '⋗',
              buffer = 'Ω',
              path = '🖫',
          }
          item.menu = menu_icon[entry.source.name]
          return item
      end,
  },
})

-- Treesitter Plugin Setup 
require('nvim-treesitter.configs').setup {
  ensure_installed = { "lua", "rust", "toml" },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting=false,
  },
  ident = { enable = true }, 
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = nil,
  }
}
vim.opt.foldenable = false 

-- Telescope
local actions = require "telescope.actions"
require("telescope").setup{ 
	defaults = { 
		mappings = { 
			i = { 
				["<Esc>"] = actions.close, 
			}, 
		}, 
	}, 
}
require("which-key").setup {
	-- your configuration comes here
	-- or leave it empty to use the default settings
	-- refer to the configuration section below
}

require('lualine').setup{
	options = { theme = 'gruvbox_dark' }
}

-- Bufferline setup
vim.opt.termguicolors = true
require("bufferline").setup{}

-- File Explorer
require("nvim-tree").setup()

-- Load opts and keys
require('opts')
require('keys')

-- Theme
vim.o.background = "dark"
vim.cmd([[
colorscheme gruvbox
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ }
]])

-- Set defaults
vim.g.mapleader= " "
vim.wo.number=true
vim.cmd("set tabstop=2 shiftwidth=2 noet")

-- Vim which key
vim.o.timeoutlen = 500
