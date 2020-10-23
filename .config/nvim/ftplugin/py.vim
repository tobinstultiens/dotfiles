" Python
let g:coc_global_extensions = [
	\ 'coc-snippets',
	\ 'coc-actions',
	\ 'coc-sh',
	\ 'coc-java-debug',
	\ 'coc-java',
	\ 'coc-lists',
	\ 'coc-emmet',
	\ 'coc-tasks',
	\ 'coc-pairs',
	\ 'coc-tsserver',
	\ 'coc-floaterm',
	\ 'coc-html',
	\ 'coc-css',
	\ 'coc-emoji',
	\ 'coc-cssmodules',
	\ 'coc-yaml',
	\ 'coc-python',
	\ 'coc-pyright',
	\ 'coc-explorer',
	\ 'coc-svg',
	\ 'coc-prettier',
	\ 'coc-vimlsp',
	\ 'coc-xml',
	\ 'coc-yank',
	\ 'coc-json',
	\ 'coc-marketplace',
	\ ]

let g:pydocstring_formatter = 'numpy'
let test#python#runner = 'pytest'
nmap <silent> t<C-n> :TestNearest<CR>

" Set tags
set autochdir
