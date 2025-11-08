return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate", -- Ensure parsers are updated on install
	config = function()
		require("nvim-treesitter.configs").setup({
			-- A list of parser names, or "all" (the listed parsers MUST always be installed)
			ensure_installed = {
				"c",
				"lua",
				"python",
				"javascript",
				"typescript",
				"markdown",
				"markdown_inline",
			},

			-- Install parsers synchronously (only applied to `ensure_installed`)
			sync_install = false,

			-- Automatically install missing parsers when entering buffer
			-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
			auto_install = true,

			highlight = {
				enable = true,
				-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
				-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
				-- Using this option may slow down your editor, and you may see some duplicate highlights.
				-- Instead of true it can also be a list of languages
				additional_vim_regex_highlighting = false,
			},
			-- Ensure consistent color for all Markdown headings
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.cmd([[
						highlight MarkdownHeadingBoldBlue guifg=#569cd6 gui=bold
						highlight! link @markup.heading.1.markdown MarkdownHeadingBoldBlue
						highlight! link @markup.heading.2.markdown MarkdownHeadingBoldBlue
						highlight! link @markup.heading.3.markdown MarkdownHeadingBoldBlue
						highlight! link @markup.heading.4.markdown MarkdownHeadingBoldBlue
						highlight! link @markup.heading.5.markdown MarkdownHeadingBoldBlue
						highlight! link @markup.heading.6.markdown MarkdownHeadingBoldBlue
					]])
				end,
			}),
		})
	end,
}
