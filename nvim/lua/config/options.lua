---------- Vim options ----------

-- Enable line numbers
vim.opt.number = true

-- Enable relative line numbers
vim.opt.relativenumber = true

-- Define tab as 4 spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- Enables smart indentation based on code structure
vim.opt.smartindent = true

-- Disable line wrapping, long lines will extend horizontally
vim.opt.wrap = false

-- Enable incremental search, updating search results as while typing
vim.opt.incsearch = true

-- Enable true color support (24-bit colors)
vim.opt.termguicolors = true

-- Set number of visible lines above/below the cursor while scrolling
vim.opt.scrolloff = 8

-- Show a vertical line at the 80th column
vim.opt.colorcolumn = "80"

-- Enable system clipboard for all yank/paste operations
vim.opt.clipboard = "unnamedplus"


---------- Keymaps ----------

-- Set space as leader key
vim.g.mapleader = " "

-- Map <leader>e to the :Explore command to open the file explorer
vim.keymap.set("n", "<leader>e", ":Explore<CR>", { desc = "Open file explorer" })

-- Move selected lines up (K) or down (J) without losing the selection
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Scroll up/down half a screen while keeping the cursor centered
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- In Visual Mode, delete the selected text without overwriting the clipboard
-- register, effectively preserving the clipboard's contents while still
-- performing the delete operation
vim.keymap.set("x", "<leader>p", [["_dP]])
