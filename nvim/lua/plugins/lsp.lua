return {
	-- Mason plugin to manage LSP servers
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
				},
			})
		end,
	},
	-- Mason-LSPconfig to simplify LSP server installation
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"pyright",
					"ts_ls",
					"ruff",
					"taplo",
					"dockerls",
				},
			})
		end,
	},
	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- Diagnostics
			vim.diagnostic.config({
				virtual_text = true, -- Inline error messages
				float = { border = "rounded" }, -- Floating popups
				severity_sort = true, -- Sort diagnostics by severity
			})

			-- Get the list of servers to install from mason-lspconfig
			local servers = require("mason-lspconfig").get_installed_servers()
			vim.lsp.enable(servers)

			-- Function to organize imports and format
			local function format_on_save(bufnr)
				-- Get all active LSP clients for the buffer
				local clients = vim.lsp.get_active_clients({ bufnr = bufnr })

				-- Check if ruff is one of the active clients
				for _, client in ipairs(clients) do
					if client.name == "ruff" then
						-- Run organize imports command
						vim.lsp.buf.code_action({
							context = { only = { "source.organizeImports" } },
							apply = true,
						})
					end
				end
				vim.lsp.buf.format({ bufnr = bufnr })
			end

			-- Keymaps --
			vim.keymap.set("n", "K", function()
				vim.lsp.buf.hover({ border = "rounded" })
			end, { desc = "Show hover documentation" })
			vim.keymap.set("i", "<C-k>", function()
				vim.lsp.buf.signature_help({ border = "rounded" })
			end, { desc = "Show function signature help" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			vim.keymap.set("n", "<leader>fs", function()
				pcall(format_on_save)
				pcall(vim.cmd, "write")
			end, { desc = "Organize imports, format, and save document" })
			vim.keymap.set("n", "<leader>E", function()
				vim.diagnostic.open_float(nil, { scope = "buffer" })
			end, { desc = "Show all buffer diagnostics in floating window" })
		end,
	},
}
