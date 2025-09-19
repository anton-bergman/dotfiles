---------- Vim options ----------

-- Enable line numbers
vim.opt.number = true

-- Enable relative line numbers
vim.opt.relativenumber = true

-- Define a tab character as 4 spaces
vim.opt_local.expandtab = true -- convert tabs to spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		-- Code files (JS/TS/Web)
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
		"svelte",
		"css",
		"scss",
		"html",
		-- Config/data files
		"json",
		"jsonc",
		"json5",
		"yaml",
		"yml",
		"toml",
		"conf",
		"env",
		-- Scripts
		"sh",
		"bash",
		"zsh",
		-- Documentation / prose
		"markdown",
		"markdown.mdx",
		"mdx",
		"txt",
		"test",
		"gitcommit",
		-- Other
		"graphql",
		"dockerfile",
		"sql",
	},
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.shiftwidth = 2
	end,
})

-- Enables smart indentation based on code structure
vim.opt.smartindent = true

-- Disable line wrapping, long lines will extend horizontally
vim.opt.wrap = false
vim.opt.linebreak = false
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "markdown.mdx", "mdx", "txt", "gitcommit" },
	callback = function()
		vim.opt_local.wrap = true
		-- When 'wrap' is enabled, break lines at word boundaries instead of mid-word
		vim.opt_local.linebreak = true
		-- Indented wrapped lines align visually with the start of the text in the line
		vim.opt_local.breakindent = true
	end,
})

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

-- Map <leader>s to save the current file
vim.keymap.set("n", "<leader>s", ":w<CR>", { desc = "Save file" })

-- Move selected lines up (K) or down (J) without losing the selection
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Scroll up/down half a screen while keeping the cursor centered
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Enable navigation between Vim splits using Ctrl + h/j/k/l
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

-- In Visual Mode, delete the selected text without overwriting the clipboard
-- register, effectively preserving the clipboard's contents while still
-- performing the delete operation
vim.keymap.set("x", "<leader>p", [["_dP]])
