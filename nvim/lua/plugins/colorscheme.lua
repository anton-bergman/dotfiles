return {
	"Mofiqul/vscode.nvim",
	config = function()
		local vscode = require("vscode")
		vscode.setup({
			style = "dark", -- Choose 'dark' for "Dark Modern", or 'light' for the light theme
			transparent = true, -- Set to true if you want a transparent background
			italic_comments = true, -- Enable italic comments
			disable_nvimtree_bg = true, -- Prevents nvim-tree from using a different background
		})

		-- Set the colorscheme
		vim.cmd("colorscheme vscode")

		-- Make StatusLine transparent - Colors not visible while using lualine
		vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = "#D4D4D4" }) -- Active window
		vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", fg = "#808080" }) -- Inactive windows
	end,
}
