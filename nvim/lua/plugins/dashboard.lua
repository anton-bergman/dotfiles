-- This plugin configuration is currently disabled.
-- It’s kept here for reference and can be re-enabled by setting `enabled = true`.

return {
	"nvimdev/dashboard-nvim",
	enabled = false,
	event = "VimEnter",
	config = function()
		require("dashboard").setup({
			-- config
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
