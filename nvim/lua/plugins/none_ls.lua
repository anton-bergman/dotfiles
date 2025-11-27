return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		local mason_null_ls = require("mason-null-ls")

		-- Ensure CLI tools are installed
		mason_null_ls.setup({
			ensure_installed = {
				"stylua",
				"prettier",
				"shfmt",
				"sqlfluff", -- BigQuery-compatible SQL formatter & linter
			},
			automatic_installation = true,
		})

		-- Configure null-ls to use CLI tools as LSP-like sources for formatting
		null_ls.setup({
			sources = {

				-- Lua
				null_ls.builtins.formatting.stylua,

				-- Prettier for web/config files
				null_ls.builtins.formatting.prettier.with({
					filetypes = {
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
						"css",
						"scss",
						"html",
						"json",
						"jsonc",
						"yaml",
						"markdown",
						"markdown.mdx",
						"graphql",
					},
				}),

				-- Shell scripts
				null_ls.builtins.formatting.shfmt,

				-- SQL files (BigQuery)
				null_ls.builtins.formatting.sqlfluff.with({
					extra_args = { "--dialect", "bigquery" },
				}),
			},
		})
	end,
}
