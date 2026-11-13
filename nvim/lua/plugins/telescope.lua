return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")

		-- Unified setup and extension loading
		telescope.setup({
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown({}),
				},
			},
		})
		telescope.load_extension("ui-select")

		-- Shared arguments for ripgrep (Single Source of Truth for search scope)
		-- Includes dotfiles (.github/, configs), follows symlinks (-L), and includes *.local files,
		-- while strictly excluding caches, virtualenvs, dependencies, and git history.
		local rg_base_args = {
			"--hidden",
			"-L",
			"--no-ignore-vcs",
			"-g",
			"!.git/*",
			"-g",
			"!.worktrees/*",
			"-g",
			"!node_modules/*",
			"-g",
			"!.venv*",
			"-g",
			"!venv*",
			"-g",
			"!.secrets/*",
			"-g",
			"!dist/*",
			"-g",
			"!build/*",
			"-g",
			"!__pycache__/*",
			"-g",
			"!.pytest_cache/*",
			"-g",
			"!.ruff_cache/*",
			"-g",
			"!.mypy_cache/*",
			"-g",
			"!.DS_Store",
		}

		-- Keymap: Find files in current project (symmetric with live_grep)
		vim.keymap.set("n", "<leader>ff", function()
			local find_args = { "rg", "--files" }
			vim.list_extend(find_args, rg_base_args)
			builtin.find_files({
				find_command = find_args,
			})
		end, { desc = "Telescope find files" })

		-- Keymap: Search ALL files bypassing git filtering
		vim.keymap.set("n", "<leader>fa", function()
			builtin.find_files({
				no_ignore = true,
				hidden = true,
				file_ignore_patterns = {
					"%.venv[^/]*/",
					"venv[^/]*/",
					"env[^/]*/",
					"%.virtualenv[^/]*/",
					"__pycache__/",
					".pytest_cache/",
					".ruff_cache/",
					".mypy_cache/",
					"%.egg%-info/",
					"%.pyc$",
					"%.pyo$",
					"%.coverage$",
					"htmlcov/",
					"node_modules/",
					"build/",
					"dist/",
					"%.git/",
					"%.worktrees/",
					"%.DS_Store",
				},
			})
		end, { desc = "Telescope find all files" })

		-- Keymap: Live grep text across project files (symmetric with find_files)
		vim.keymap.set("n", "<leader>fg", function()
			builtin.live_grep({
				additional_args = function()
					return rg_base_args
				end,
			})
		end, { desc = "Telescope live grep" })

		-- Keymap: Git status modified files
		vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Telescope git status" })
	end,
}
