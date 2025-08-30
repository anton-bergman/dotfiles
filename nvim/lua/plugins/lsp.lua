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
					-- Language Servers
					"lua_ls",
					"pyright",
					"ts_ls",

					-- Linters
					"ruff",
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
			vim.keymap.set("n", "K", function()
				vim.lsp.buf.hover({ border = "rounded" })
			end, { desc = "Show hover documentation" })
			vim.keymap.set("i", "<C-k>", function()
				vim.lsp.buf.signature_help({ border = "rounded" })
			end, { desc = "Show function signature help" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			vim.keymap.set("n", "<leader>fs", function()
				-- Current buffer (e.i current open file)
				local bufnr = 0

				-- Run code actions if any attached LSP supports it
				for _, client in ipairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
					if client.supports_method("textDocument/codeAction") then
						-- Organize Python imports
						vim.lsp.buf.code_action({
							context = { only = { "source.organizeImports.ruff" } },
							apply = true,
						})
						break
					end
				end

				-- 2️⃣ Format the buffe
				vim.lsp.buf.format({ bufnr = bufnr })

				-- Save the buffer
				vim.cmd("write")
			end, { desc = "Organize imports, format, and save document" })
			vim.keymap.set("n", "<leader>E", function()
				vim.diagnostic.open_float(nil, { scope = "buffer" })
			end, { desc = "Show all buffer diagnostics in floating window" })
		end,
	},
}
