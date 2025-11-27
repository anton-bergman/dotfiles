return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")

			-- Set the grep command to use `grep` instead of `ripgrep`
			vim.g.telescope_grep_command = { "grep", "--color=never", "-r", "--exclude-dir={.git,node_modules}", "." }

			-- Keymap to open Telescope's file finder and search for files in the current project
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })

			-- Keymap to open Telescope's live grep and search for text across the project files
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })

			-- Keymap to open Telescope's git status and show modified files
			vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Telescope git status" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
