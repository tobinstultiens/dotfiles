-- Which key group names
local wk = require("which-key")

wk.register({
	f = {
		name = "Files",
		f = "Find files",
		g = "Find greps",
		b = "Find buffers",
		h = "Find help tags",
		-- t = {"<cmd>NvimTreeToggle<cr>", "Toggle Tree"},
		o = {"<cmd>NvimTreeFocus<cr>", "Focus Tree"},
		l = {"<cmd>NvimTreeFindFile<cr>", "Find file in Tree"},
		-- c = {"<cmd>NvimTreeCollapse<cr>", "Collapse"},
	},
	w = {
		name = "Windows",
		h = {"<C-W><C-H>","Move to the left window"},
		j = {"<C-W><C-J>","Move down the window"},
		k = {"<C-W><C-K>","Move up the window"},
		l = {"<C-W><C-L>","Move to the right window"},
		w = {"<C-W><C-W>","Switch windows"},
		t = {"<C-W>T","New Tab"},
	},
	l = {
		name = "Lsp actions",
	},
	d = {
		name = "Debugger",
	},
	g = {"<cmd>G<cr>","Git"},
	m = {"<cmd>Mason<cr>","Mason"},
	t = {
		name = "File Explorer"
	},
	p = {
		name = "Projects",
		p = {"<cmd>SearchSession<cr>","Search Sessions"},
		s = {"<cmd>SaveSession<cr>", "Save Session"},
		r = {"<cmd>RestoreSession<cr>", "Restore Session"},
		d = {"<cmd>DeleteSession<cr>", "Delete Session"},
	},
	b = {
		name = "Buffers",
		c = {"<cmd>bd"},
		s = {"<cmd>w"},
	},
}, {prefix = "<leader>"})

-- Vimspector
vim.cmd([[
nmap <leader>dl <cmd>call vimspector#Launch()<cr>
nmap <leader>dc <cmd>call vimspector#StepOver()<cr>
nmap <leader>dr <cmd>call vimspector#Reset()<cr>
nmap <leader>ds <cmd>call vimspector#StepOver()<cr>
nmap <leader>do <cmd>call vimspector#StepOut()<cr>
nmap <leader>di <cmd>call vimspector#StepInto()<cr>
nmap <leader>db <cmd>call vimspector#ToggleBreakpoint()<cr>
nmap <leader>dw <cmd>call vimspector#AddWatch()<cr>
nmap <leader>de <cmd>call vimspector#Evaluate()<cr>
]])

-- Move between windows
vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")

-- Telescope keys
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {desc = "Find files"})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {desc = "Find in greps"})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {desc = "Find in buffers"})
vim.keymap.set('n', '<C-p>', builtin.buffers, {desc = "Find in buffers"})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {desc = "Find in tags"})

-- FloaTerm configuration
vim.keymap.set('n', "<leader>ft", ":FloatermNew --name=myfloat --height=0.8 --width=0.7 --autoclose=2 fish <CR> ", {desc = "Reset Floating window session"})
vim.keymap.set('n', "t", ":FloatermToggle myfloat<CR>")
vim.keymap.set('t', "<Esc>", "<C-\\><C-n>:q<CR>")
