return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	---@module "ibl"
	---@type ibl.config
	opts = {
		indent = { char = "│" },
		scope = { enabled = false },
	},
	config = function(_, opts)
		require("ibl").setup(opts)
	end,
}
