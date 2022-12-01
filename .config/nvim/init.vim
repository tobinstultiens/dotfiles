call plug#begin('~/.vim/plugged')

" Prettier
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
Plug 'morhetz/gruvbox'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'itchyny/lightline.vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" LaTeX
Plug 'lervag/vimtex'
Plug 'KeitaNakamura/tex-conceal.vim'
" Disables search higlighting when you are done searching
Plug 'romainl/vim-cool'
" Python
Plug 'heavenshell/vim-pydocstring', { 'do': 'make install' }
Plug 'vim-scripts/indentpython.vim'
" Test runner
Plug 'vim-test/vim-test'
" Swagger
Plug 'xavierchow/vim-swagger-preview'
" Integrates lf
Plug 'ptzz/lf.vim'
" Color higlighter
Plug 'norcalli/nvim-colorizer.lua'
" Start menu
Plug 'mhinz/vim-startify'

call plug#end()

lua require('plug')

" Lf
let g:lf_map_keys = 0

" Move between splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Vim wiki
set nocompatible
filetype plugin on
syntax on
let mapleader = " "

" General Settings
set relativenumber
set tabstop=2 shiftwidth=2 noet
colorscheme gruvbox
set background=dark
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ }

" fzf file finder mapping
nnoremap <C-p> :GFiles<CR>

" Remappings using leader
nnoremap <Leader>g :G<CR>
nnoremap <Leader>m :Mason<CR>

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" LaTeX
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

" Make startify use NERDTreeBookmarks
let g:startify_bookmarks = systemlist("cut -sd' ' -f 2- ~/.NERDTreeBookmarks")

" Vim which key
set timeoutlen=500

lua require('config')
lua require('opts')
lua require('keys')
