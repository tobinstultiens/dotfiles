return require('packer').startup(function()
    -- other plugins...
    
    use 'williamboman/mason.nvim'    
    use 'williamboman/mason-lspconfig.nvim'

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

		-- Treesitter
    use 'nvim-treesitter/nvim-treesitter'

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

		use {
  		'phaazon/hop.nvim',
  		branch = 'v2', -- optional but strongly recommended
  		config = function()
    		-- you can configure Hop the way you like here; see :h hop-config
    		require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
  		end
		}
end)
