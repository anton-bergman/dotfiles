return {
	"lewis6991/gitsigns.nvim",
	opts = {
		sign_priority = 20, -- Higher priority ensure gitsigns take precedence over LSP diagnostics in the gutter/sign column (default: 6)
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			map("n", "<leader>gh", gs.preview_hunk_inline, { desc = "Gitsigns: Preview hunk" })
			map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Gitsigns: Toggle line blame" })
			map("n", "<leader>gr", gs.reset_hunk, { desc = "Gitsigns: Reset hunk" })
			map("v", "<leader>gr", function()
				gs.reset_hunk({ vim.fn.line("v"), vim.fn.line(".") })
			end, { desc = "Gitsigns: Reset selected hunks" })
		end,
	},
}
