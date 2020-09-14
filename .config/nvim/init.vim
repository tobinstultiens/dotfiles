call plug#begin('~/.vim/plugged')

" Prettier
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
Plug 'morhetz/gruvbox'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'dense-analysis/ale'
Plug 'itchyny/lightline.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'rust-lang/rustfmt'
Plug 'rust-lang/rust.vim'
Plug 'vimwiki/vimwiki'
Plug 'lervag/vimtex'
Plug 'KeitaNakamura/tex-conceal.vim'
Plug 'romainl/vim-cool'
Plug 'heavenshell/vim-pydocstring', { 'do': 'make install' }
Plug 'vim-test/vim-test'
Plug 'vim-scripts/indentpython.vim'

call plug#end()

" Move between splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Clipboard
"set clipboard+=unnamedplus

" Vim wiki
set nocompatible
filetype plugin on
syntax on
let mapleader = ","

set relativenumber
set tabstop=2 shiftwidth=2 noet
colorscheme gruvbox
set background=dark
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ }

" Mappings
nmap <leader>gd <Plug>(coc-definition)
nmap <leader>gr <Plug>(coc-references)
nnoremap <C-p> :GFiles<CR>

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" Rust autoformat on save
let g:rustfmt_autosave = 1

" LaTeX
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

set conceallevel=1
let g:tex_conceal='abdmg'
hi Conceal ctermbg=none

setlocal spell
set spelllang=en_us,nl_nl
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u

" Python
let g:pydocstring_formatter = 'numpy'
nmap <silent> t<C-n> :TestNearest<CR>
