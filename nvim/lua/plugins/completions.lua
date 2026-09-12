return {
	"hrsh7th/nvim-cmp", -- The completion plugin
	dependencies = {
		"hrsh7th/cmp-nvim-lsp", -- LSP completion source
		"hrsh7th/cmp-buffer", -- Buffer completion source
		"hrsh7th/cmp-path", -- Path completion source
	},
	config = function()
		local cmp = require("cmp")

		cmp.setup({
			window = {
				completion = {
					border = "rounded",
				},
				documentation = {
					border = "rounded",
				},
			},

			-- Keymaps
			mapping = cmp.mapping.preset.insert({
				["<C-Space>"] = cmp.mapping.complete(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<Tab>"] = cmp.mapping.select_next_item(),
				["<S-Tab>"] = cmp.mapping.select_prev_item(),
			}),

			sources = {
				{ name = "nvim_lsp" }, -- Enable LSP completions
				{ name = "buffer" }, -- Enable buffer completions
				{ name = "path" }, -- Enable file path completions
			},
		})

		cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
			sources = {
				{ name = "bigquery_schema" },
				{ name = "vim-dadbod-completion" },
				{ name = "buffer" },
			},
		})

		-- Register custom BigQuery completion source
		cmp.register_source("bigquery_schema", require("utils.bigquery").new_cmp_source())
	end,
}
