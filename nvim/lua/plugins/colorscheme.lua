return {
	"Mofiqul/vscode.nvim",
	config = function()
		local vscode = require("vscode")
		vscode.setup({
			style = "dark", -- Choose 'dark' for "Dark Modern", or 'light' for the light theme
			transparent = false, -- Set to true if you want a transparent background
			italic_comments = true, -- Enable italic comments
			disable_nvimtree_bg = true, -- Prevents nvim-tree from using a different background
		})

		-- Set the colorscheme
		vim.cmd("colorscheme vscode")
	end
}
