return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {

				-- Lua
				null_ls.builtins.formatting.stylua,

				-- JavaScript/TypeScript
				require("none-ls.diagnostics.eslint_d"),
				require("none-ls.formatting.eslint_d"),
			},
		})
	end,
}
