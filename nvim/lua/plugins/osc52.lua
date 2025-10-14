-- Load the OSC52 clipboard plugin only when running inside a Docker container
return {
	{
		"ojroques/nvim-osc52",

		-- Only enable this plugin if Neovim is running inside Docker
		cond = function()
			-- Helper function to detect Docker environment
			local function in_docker()
				-- Check for /.dockerenv (exists in most Docker containers)
				if vim.fn.filereadable("/.dockerenv") == 1 then
					return true
				end

				-- Fallback: check if /proc/1/cgroup mentions "docker" or "kubepods"
				local ok, lines = pcall(vim.fn.readfile, "/proc/1/cgroup")
				if ok then
					for _, line in ipairs(lines) do
						if line:find("docker") or line:find("kubepods") then
							return true
						end
					end
				end

				-- Not running inside Docker
				return false
			end

			-- Return true/false for lazy.nvim's `cond` field
			return in_docker()
		end,

		-- Configure the plugin if it’s loaded
		-- NOTE:
		--   This plugin enables copying *from* Neovim inside Docker *to* your host clipboard
		--   using OSC52 escape sequences.
		--   To paste text *from your host machine into Neovim* running inside Docker:
		--     1. Enter INSERT mode in Neovim.
		--     2. Use your host system’s native paste shortcut.
		--        - On macOS (Apple Silicon): press ⌘ + V
		--   Neovim will then receive the pasted text directly from your terminal.
		config = function()
			-- Define how Neovim should copy text using OSC52 escape sequences
			local function copy(lines, _)
				require("osc52").copy(table.concat(lines, "\n"))
			end

			-- Define how Neovim should paste text
			local function paste()
				return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
			end

			-- Set Neovim's clipboard provider to use OSC52 for + and * registers
			vim.g.clipboard = {
				name = "osc52",
				copy = { ["+"] = copy, ["*"] = copy },
				paste = { ["+"] = paste, ["*"] = paste },
			}

			-- Use the system clipboard as the default register
			vim.opt.clipboard = "unnamedplus"
		end,
	},
}
