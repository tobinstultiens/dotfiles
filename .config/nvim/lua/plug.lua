return require('packer').startup(function()
	-- Which key
	use {
		"folke/which-key.nvim",
	}

	-- Mason
	use 'williamboman/mason.nvim'    
	use 'williamboman/mason-lspconfig.nvim'
	use "jose-elias-alvarez/null-ls.nvim"
  use "jay-babu/mason-null-ls.nvim"

	-- Rust tools 
	use 'neovim/nvim-lspconfig' 
	use 'simrat39/rust-tools.nvim'

	-- Completion framework:
	use 'hrsh7th/nvim-cmp' 

	-- LSP completion source:
	use 'hrsh7th/cmp-nvim-lsp'

	-- Useful completion sources:
	use 'hrsh7th/cmp-nvim-lua'
	use 'hrsh7th/cmp-nvim-lsp-signature-help'
	use 'hrsh7th/cmp-vsnip'                             
	use 'hrsh7th/cmp-path'                              
	use 'hrsh7th/cmp-buffer'                            
	use 'hrsh7th/vim-vsnip'

	-- Tpoe
	use 'tpope/vim-surround'
	use 'tpope/vim-commentary'
	use 'tpope/vim-fugitive'

	-- Theme
	use { "ellisonleao/gruvbox.nvim" }

	-- Treesitter
	use 'nvim-treesitter/nvim-treesitter'

	-- File Explorer
	use { 'nvim-tree/nvim-tree.lua' }

	-- Session manager
	use {
  	'rmagatti/auto-session',
  	config = function()
    	require("auto-session").setup {
      	log_level = "error",
      	auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/"},
    	}
  	end
	}
	use {
	  'rmagatti/session-lens',
	  requires = {'rmagatti/auto-session', 'nvim-telescope/telescope.nvim'},
	  config = function()
	    require('session-lens').setup({--[[your custom config--]]})
	  end
	}

	-- Disables search higlighting when you are done searching
	use 'romainl/vim-cool'

	-- Color hightlighter
	use 'norcalli/nvim-colorizer.lua'

	-- Vimspector
	use 'puremourning/vimspector'

	-- Vim floating terminal
	use 'voldikss/vim-floaterm'

	-- Telescope
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.0',
		-- or                            , branch = '0.1.x',
		requires = { {'nvim-lua/plenary.nvim'} }
	}

	-- Hop
	use {
		'phaazon/hop.nvim',
		branch = 'v2', -- optional but strongly recommended
		config = function()
			-- you can configure Hop the way you like here; see :h hop-config
			require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
		end
	}
end)
