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
	-- use { "ellisonleao/gruvbox.nvim" }
	use { "catppuccin/nvim", as = "catppuccin" }

	-- Treesitter
	use 'nvim-treesitter/nvim-treesitter'

	-- File Explorer
	use { 'nvim-tree/nvim-tree.lua' }

	-- Disables search higlighting when you are done searching
	use 'romainl/vim-cool'

	-- Color hightlighter
	use 'norcalli/nvim-colorizer.lua'

	-- Vimspector
	use 'puremourning/vimspector'

	-- Vim floating terminal
	use 'voldikss/vim-floaterm'

	-- Lualine
	use {
  	'nvim-lualine/lualine.nvim',
  	requires = { 'nvim-tree/nvim-web-devicons', opt = true }
	}
	-- Buffer line
	use {
		'akinsho/bufferline.nvim', 
		tag = "v3.*", requires = 'nvim-tree/nvim-web-devicons'
	}

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

	-- Tmux
	use 'christoomey/vim-tmux-navigator'
end)
