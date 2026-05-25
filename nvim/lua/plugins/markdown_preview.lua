return {
	{
		"iamcco/markdown-preview.nvim",
		ft = { "markdown" },
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },

		-- Post-install hook to automatically download the pre-compiled rendering binaries
		build = function()
			vim.fn["mkdp#util#install"]()
		end,

		config = function()
			-- Optional configuration settings
			-- Set to 1 if you want the browser window to open automatically
			vim.g.mkdp_auto_start = 0

			-- Set to 1 if you want the preview page to close automatically when switching buffers
			vim.g.mkdp_auto_close = 1

			-- Define the keymap to easily toggle the browser preview
			-- Pressing <leader>mp (usually Space + m + p) will open/close the browser window
			vim.keymap.set(
				"n",
				"<leader>mp",
				"<cmd>MarkdownPreviewToggle<cr>",
				{ desc = "Toggle Markdown Browser Preview", silent = true }
			)
		end,
	},
}
