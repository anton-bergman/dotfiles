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
				exclude = { ".env", "AGENTS.md", "efs" }, -- Don't hide these files in file explorer
			},
			renderer = {
				highlight_git = true,
				icons = {
					show = {
						git = false,
					},
					glyphs = {
						folder = {
							arrow_closed = "\u{f061}",
							arrow_open = "\u{f063}",
						},
					},
				},
				indent_markers = {
					enable = true,
					inline_arrows = false,
					icons = {
						corner = "└",
						edge = "│",
						item = "│",
						bottom = "─",
						none = " ",
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
