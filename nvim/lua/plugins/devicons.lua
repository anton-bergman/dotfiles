return {
	"nvim-tree/nvim-web-devicons",
	lazy = true,
	opts = {},
	config = function(_, opts)
		local devicons = require("nvim-web-devicons")
		devicons.setup(opts)

		-- Dynamic pattern catch-all: any file starting with "Dockerfile." or "dockerfile."
		local orig_get_icon = devicons.get_icon
		devicons.get_icon = function(name, ext, opt)
			if type(name) == "string" and name:lower():match("^dockerfile%.") then
				return orig_get_icon("Dockerfile", nil, opt)
			end
			return orig_get_icon(name, ext, opt)
		end

		local orig_get_icon_color = devicons.get_icon_color
		devicons.get_icon_color = function(name, ext, opt)
			if type(name) == "string" and name:lower():match("^dockerfile%.") then
				return orig_get_icon_color("Dockerfile", nil, opt)
			end
			return orig_get_icon_color(name, ext, opt)
		end
	end,
}
