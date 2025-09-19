-- This plugin configuration is currently disabled.
-- It’s kept here for reference and can be re-enabled by setting `enabled = true`.

return {
	"olimorris/codecompanion.nvim",
	enabled = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		strategies = {
			chat = {
				adapter = "gemini",
			},
			inline = {
				adapter = "gemini",
			},
		},
		adapters = {
			http = {
				gemini = function()
					return require("codecompanion.adapters").extend("gemini", {
						schema = {
							model = {
								default = "gemini-2.5-flash",
							},
						},
						env = {
							api_key = vim.env.GEMINI_API_KEY,
						},
					})
				end,
			},
		},
		display = {
			chat = {
				window = {
					position = "right",
					width = 0.4,
				},
			},
		},
	},
	keys = {
		{ "<leader>cc", "<cmd>lua require('codecompanion').toggle()<cr>", desc = "Toggle Chat", mode = "n" },
	},
}
