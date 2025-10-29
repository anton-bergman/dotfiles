return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup()

		vim.keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk_inline<CR>", { desc = "Gitsigns: Preview hunk" })
		vim.keymap.set(
			"n",
			"<leader>gb",
			":Gitsigns toggle_current_line_blame<CR>",
			{ desc = "Gitsigns: Toggle line blame" }
		)
		vim.keymap.set("n", "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "Gitsigns: Reset hunk" })

		vim.keymap.set("v", "<leader>gr", function()
			local start_line = vim.fn.line("v")
			local end_line = vim.fn.line(".")
			vim.cmd("normal! <Esc>") -- exit visual mode
			require("gitsigns").reset_hunk({ start_line, end_line })
		end, { desc = "Gitsigns: Reset selected hunks" })
	end,
}
