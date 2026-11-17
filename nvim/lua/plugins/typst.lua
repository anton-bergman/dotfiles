return {
	{
		"chomosuke/typst-preview.nvim",
		ft = { "typst" },
		version = "1.*",
		build = function()
			require("typst-preview").update()
		end,
		opts = {
			open_cmd = "open %s",
			invert_colors = "never",
		},
		config = function(_, opts)
			require("typst-preview").setup(opts)

			-- Toggle browser live preview with keystroke-level sync
			vim.keymap.set(
				"n",
				"<leader>tp",
				"<cmd>TypstPreviewToggle<cr>",
				{ desc = "Toggle Typst Live Preview", silent = true }
			)
		end,
	},
}
