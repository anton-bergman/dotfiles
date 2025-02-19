return {
	"hrsh7th/nvim-cmp",   -- The completion plugin
	dependencies = {
		"hrsh7th/cmp-nvim-lsp", -- LSP completion source
		"hrsh7th/cmp-buffer", -- Buffer completion source
		"hrsh7th/cmp-path", -- Path completion source
	},
	config = function()
		local cmp = require("cmp")
		cmp.setup({

			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
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
	end,
}
