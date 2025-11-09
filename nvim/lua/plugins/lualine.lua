return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local custom_theme = require("lualine.themes.ayu_mirage")
		-- Change the background of lualine_c section for normal mode
		custom_theme.normal.c.bg = "#1F1F1F"
		require("lualine").setup({

			options = {
				theme = custom_theme,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = { "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		})
	end,
}
