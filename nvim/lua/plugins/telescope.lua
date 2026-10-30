return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")

			-- Set the grep command to use `grep` instead of `ripgrep`
			vim.g.telescope_grep_command = { "grep", "--color=never", "-r", "--exclude-dir={.git,node_modules}", "." }

			-- Shared arguments for ripgrep (Single Source of Truth for Telescope search scope)
			-- Includes dotfiles (.github/, configs), follows symlinks (-L), and includes *.local files,
			-- while strictly excluding caches, virtualenvs, dependencies, and git history.
			local rg_base_args = {
				"--hidden",
				"-L",
				"--no-ignore-vcs",
				"-g", "!.git/*",
				"-g", "!node_modules/*",
				"-g", "!.venv*",
				"-g", "!venv*",
				"-g", "!.secrets/*",
				"-g", "!dist/*",
				"-g", "!build/*",
				"-g", "!__pycache__/*",
				"-g", "!.pytest_cache/*",
				"-g", "!.ruff_cache/*",
				"-g", "!.mypy_cache/*",
				"-g", "!.DS_Store",
			}

			-- Keymap to open Telescope's file finder and search for files in the current project
			-- Uses shared rg_base_args (100% symmetric with live_grep)
			vim.keymap.set("n", "<leader>ff", function()
				local find_args = { "rg", "--files" }
				vim.list_extend(find_args, rg_base_args)
				builtin.find_files({
					find_command = find_args,
				})
			end, { desc = "Telescope find files" })

			-- Keymap to search ALL files including untracked/ignored files
			-- This bypasses git filtering completely
			vim.keymap.set("n", "<leader>fa", function()
				builtin.find_files({
					no_ignore = true,
					hidden = true,
					file_ignore_patterns = {
						-- Python virtual environments (all naming patterns)
						"%.venv[^/]*/", -- .venv, .venv-dev, .venv-prod, etc.
						"venv[^/]*/", -- venv, venv-dev, venv-app, etc.
						"env[^/]*/", -- env, env-dev, env-local, etc.
						"%.virtualenv[^/]*/", -- .virtualenv and variants

						-- Python caches and build artifacts
						"__pycache__/",
						".pytest_cache/",
						".ruff_cache/",
						".mypy_cache/",
						"%.egg%-info/",
						"%.pyc$",
						"%.pyo$",
						"%.coverage$",
						"htmlcov/",

						-- JavaScript/Node
						"node_modules/",
						"build/",
						"dist/",

						-- Version control
						"%.git/",

						-- OS files
						"%.DS_Store",
					},
				})
			end, { desc = "Telescope find all files" })

			-- Keymap to open Telescope's live grep and search for text across the project files
			-- Uses shared rg_base_args (100% symmetric with find_files)
			vim.keymap.set("n", "<leader>fg", function()
				builtin.live_grep({
					additional_args = function()
						return rg_base_args
					end,
				})
			end, { desc = "Telescope live grep" })

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
