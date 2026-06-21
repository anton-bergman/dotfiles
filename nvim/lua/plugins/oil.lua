return {
	"stevearc/oil.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"refractalize/oil-git-status.nvim",
	},
	cmd = "Oil",
	keys = {
		-- The definitive power-user shortcut to open Oil in the current file's directory
		{ "-", "<CMD>Oil<CR>", desc = "Open parent directory in Oil" },
		{ "<leader>e", "<CMD>Oil<CR>", desc = "Open Oil" }, -- Muscle memory fallback
	},
	opts = {
		-- Uses default netrw-style file browser behavior
		default_file_explorer = true,

		-- ID of the window when oil opens a directory
		win_options = {
			signcolumn = "yes:2", -- Needed for oil-git-status.nvim dependency
			wrap = false,
			cursorcolumn = false,
			foldcolumn = "0",
			spell = false,
		},

		-- Power users prefer a clean, minimal interface over UI clutter
		columns = {
			"icon", -- Keeps icons for instant file-type recognition
			-- "permissions", "size", "mtime" are omitted to maximize code screen real estate
		},

		-- Buffer-level options
		buf_options = {
			buflisted = false,
			bufhidden = "hide",
		},

		-- Configuration for the floating window layout (if you prefer floats over full-screen)
		float = {
			padding = 2,
			max_width = 80,
			max_height = 20,
			border = "rounded", -- Options: "single", "double", "shadow", "rounded"
			win_options = {
				winblend = 0,
			},
		},

		-- Style popup windows
		confirmation = {
			border = "rounded",
		},
		keymaps_help = {
			border = "rounded",
		},
		progress = {
			border = "rounded",
			minimized_border = "rounded",
		},

		-- Core configuration to tweak behavior
		delete_to_trash = true, -- Safety net: items go to system trash instead of permanent deletion
		skip_confirm_for_simple_edits = true, -- 10x workflow bypasses confirmation prompts for quick edits
		prompt_save_on_select_new_entry = true, -- Forces a save prompt if you try to open a file with unsaved filesystem changes

		-- Watch the filesystem for external changes (git pulls, build scripts creating files)
		watch_for_changes = true,

		-- Keymaps specific to the Oil buffer
		keymaps = {
			["g?"] = "actions.show_help",
			["<CR>"] = "actions.select",

			-- Open files in splits/tabs
			["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
			["<C-x>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
			["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },

			-- Quick preview pane (highly efficient for reading files without opening them)
			["<C-p>"] = "actions.preview",
			["<C-c>"] = "actions.close",

			-- CRITICAL: Disable default mappings that hijack tmux/pane navigation (Ctrl + h/l)
			["<C-h>"] = false,
			["<C-l>"] = false,

			-- Micro-navigation mappings
			["-"] = "actions.parent", -- Go up one directory level
			["_"] = "actions.open_cwd", -- Go directly to project root directory
			["`"] = "actions.cd", -- Change Neovim's global CWD to this folder

			-- Copy paths directly to system clipboard
			["gy"] = {
				desc = "Copy relative path to clipboard",
				callback = function()
					local oil = require("oil")
					local entry = oil.get_cursor_entry()
					if not entry then
						vim.notify("No file under cursor", vim.log.levels.WARN)
						return
					end
					local dir = oil.get_current_dir()
					local abs_path = dir .. entry.name
					local rel_path = vim.fn.fnamemodify(abs_path, ":.")
					vim.fn.setreg("+", rel_path)
					vim.fn.setreg("*", rel_path)
					vim.notify("Copied relative path: " .. rel_path)
				end,
			},
			["gY"] = {
				desc = "Copy absolute path to clipboard",
				callback = function()
					local oil = require("oil")
					local entry = oil.get_cursor_entry()
					if not entry then
						vim.notify("No file under cursor", vim.log.levels.WARN)
						return
					end
					local dir = oil.get_current_dir()
					local abs_path = dir .. entry.name
					vim.fn.setreg("+", abs_path)
					vim.fn.setreg("*", abs_path)
					vim.notify("Copied absolute path: " .. abs_path)
				end,
			},

			-- Toggle visibility options instantly
			["g."] = "actions.toggle_hidden",
			["g\\"] = "actions.toggle_trash",
		},

		-- Hide dotfiles and build directories by default to avoid visual noise
		view_options = {
			show_hidden = false,
			is_hidden_file = function(name, bufnr)
				return vim.startswith(name, ".") or name == "node_modules" or name == "target"
			end,
			is_always_hidden = function(name, bufnr)
				return name == ".." or name == ".git"
			end,
		},
	},
	config = function(_, opts)
		require("oil").setup(opts)
		require("oil-git-status").setup()
	end,
}
