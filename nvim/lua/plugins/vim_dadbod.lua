return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	keys = {
		{ "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Toggle Dadbod UI" },
	},
	init = function()
		vim.g.db_ui_use_nerd_fonts = 1
		vim.g.db_adapter_bigquery_region = vim.env.BIGQUERY_REGION or "region-europe-west3"

		-- Ensure query results buffers are open and not folded by default
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "dbout",
			callback = function()
				vim.opt_local.foldenable = false
			end,
		})
	end,
}
