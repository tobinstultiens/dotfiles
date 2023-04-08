--Set completeopt to have a better completion experience
-- :help completeopt
-- menuone: popup even when there's only one match
-- noinsert: Do not insert text until a selection is made
-- noselect: Do not select, force to select one from the menu
-- shortness: avoid showing extra messages when using completion
-- updatetime: set updatetime for CursorHold
vim.opt.completeopt = {'menuone', 'noselect', 'noinsert'}
vim.opt.shortmess = vim.opt.shortmess + { c = true}
vim.api.nvim_set_option('updatetime', 300) 

vim.cmd([[
set signcolumn=yes
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])

-- Treesitter folding 
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'

-- Vimspector options
vim.cmd([[
let g:vimspector_sidebar_width = 85
let g:vimspector_bottombar_height = 15
let g:vimspector_terminal_maxwidth = 70
]])

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, { desc = "Open floating diagnostic"})
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic"})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic"})
vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, { desc = "Set local diagnostic list"})

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = "Go to declaration"}, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "Go to definition" }, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Show description" }, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = "Go to implementation" }, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { desc = "Signature help" }, opts)
    vim.keymap.set('n', '<leader>lwa', vim.lsp.buf.add_workspace_folder, { desc = "Add workspace folder" }, opts)
    vim.keymap.set('n', '<leader>lwr', vim.lsp.buf.remove_workspace_folder, { desc = "Remove workspace folder" }, opts)
    vim.keymap.set('n', '<leader>lwl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, { desc = "List workspace folders" }, opts)
    vim.keymap.set('n', '<leader>ld', vim.lsp.buf.type_definition, { desc = "Type definition" }, opts)
    vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { desc = "Rename" }, opts)
    vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, { desc = "Code action" }, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = "References" }, opts)
    vim.keymap.set('n', '<leader>lf', function()
      vim.lsp.buf.format { async = true }
    end, { desc = "Format the buffer" }, opts)
  end,
})

-- File Explorer
-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true
