return {
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	event = "VeryLazy",
	config = function()
		require("nvim-tree").setup({
			filters = {
				git_ignored = true, -- Hide git-ignored files
				dotfiles = false, -- Show dotfiles
				exclude = { ".env" }, -- Do not hide '.env'-files
			},
			renderer = {
				highlight_git = true,
				icons = {
					show = {
						git = false,
					},
				},
			},
		})

		-- Map <leader>e to toggle file tree
		vim.keymap.set(
			"n",
			"<leader>e",
			":NvimTreeToggle<CR>",
			{ noremap = true, silent = true, desc = "Toggle NvimTree" }
		)
	end,
}
