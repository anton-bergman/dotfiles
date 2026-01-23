return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local custom_theme = require("lualine.themes.ayu_mirage")

		-- Make section C transparent
		custom_theme.normal.c.bg = "NONE"

		require("lualine").setup({

			options = {
				theme = custom_theme,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { { "branch", icon = "" }, "diff", "diagnostics" },
				lualine_c = {
					{
						"filename",
						path = 1, -- 0: filename only, 1: relative path, 2: absolute path, 3: absolute with ~, 4: filename + parent
					},
				},
				lualine_x = { "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		})
	end,
}
