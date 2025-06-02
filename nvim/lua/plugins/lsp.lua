return {
	-- Mason plugin to manage LSP servers
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
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
				},
			})
		end,
	},
	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")

			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
			vim.lsp.handlers["textDocument/signatureHelp"] =
				vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

			-- Diagnostics
			vim.diagnostic.config({
				virtual_text = true, -- Inline error messages
				float = { border = "rounded" }, -- Floating popups
				severity_sort = true, -- Sort diagnostics by severity
			})

			-- LSP Setup --
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})
			lspconfig.pyright.setup({
				capabilities = capabilities,
			})
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})
			lspconfig.ruff.setup({
				capabilities = capabilities,
			})

			-- Keymaps --
			vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show hover documentation" })
			vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show function signature help" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			vim.keymap.set("n", "<leader>fs", function()
				-- Organize imports
				vim.lsp.buf.code_action({
					context = { only = { "source.organizeImports.ruff" } },
					apply = true,
				})

				-- Format the document
				-- vim.lsp.buf.format({ name = "ruff" })
				vim.lsp.buf.format()

				-- Save the file
				vim.cmd("write")
			end, { desc = "Organize imports, format, and save document" })
			vim.keymap.set("n", "<leader>E", function()
				vim.diagnostic.open_float(nil, { scope = "buffer" })
			end, { desc = "Show all buffer diagnostics in floating window" })
		end,
	},
}
