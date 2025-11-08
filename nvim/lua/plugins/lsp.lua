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
			local function format_and_save()
				local bufnr = vim.api.nvim_get_current_buf()
				local ft = vim.bo[bufnr].filetype

				-- Helper: organize imports first (async)
				local function organize_imports(callback)
					if ft ~= "python" then
						callback()
						return
					end

					vim.lsp.buf.code_action({
						context = { only = { "source.organizeImports" } },
						apply = true,
					})

					-- Give LSP a short moment to apply changes before next step
					vim.defer_fn(callback, 300)
				end

				-- Helper: format buffer (sync)
				local function format_buffer(callback)
					vim.lsp.buf.format({
						bufnr = bufnr,
						async = false, -- blocking ensures no overlap
					})
					callback()
				end

				-- Step 1 → organize imports
				-- Step 2 → format buffer
				-- Step 3 → save buffer
				organize_imports(function()
					format_buffer(function()
						vim.cmd("write")
					end)
				end)
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
			vim.keymap.set("n", "<leader>fs", format_and_save, { desc = "Organize imports, format, and save document" })
			vim.keymap.set("n", "<leader>E", function()
				vim.diagnostic.open_float(nil, { scope = "buffer" })
			end, { desc = "Show all buffer diagnostics in floating window" })
		end,
	},
}
