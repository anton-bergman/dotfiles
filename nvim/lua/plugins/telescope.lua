return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")

			-- Set the grep command to use `grep` instead of `ripgrep`
			vim.g.telescope_grep_command = { "grep", "--color=never", "-r", "--exclude-dir={.git,node_modules}", "." }

			-- Keymap to open Telescope's file finder and search for files in the current project
			-- Respects .gitignore, includes dotfiles (.gitignore, .dockerignore),
			-- un-ignores machine-local files (*.local, **/local/*), and excludes .git/
			vim.keymap.set("n", "<leader>ff", function()
				builtin.find_files({
					find_command = {
						"sh",
						"-c",
						'(rg --files --hidden -L -g "!.git/*"; rg --files --hidden -L --no-ignore -g "!.git/*" -g "!node_modules/*" -g "!.venv*" -g "!venv*" -g "!.secrets/*" -g "!dist/*" -g "!build/*" -g "*.local" -g "*.local.*" -g "**/local/**") | sort -u',
					},
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
