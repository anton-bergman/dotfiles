return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false, -- Requirement for v1.0
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")

		-- Setup plugin (optional, using defaults here)
		ts.setup({})

		-- Install core parsers
		ts.install({
			"c",
			"lua",
			"python",
			"javascript",
			"typescript",
			"vim",
			"vimdoc",
			"markdown",
			"markdown_inline",
		})

		-- Enable Treesitter highlighting globally for all supported filetypes
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ft = vim.bo[args.buf].filetype
				-- Ignore common special filetypes that shouldn't have TS
				if ft == "TelescopePrompt" or ft == "NvimTree" or ft == "lazy" or ft == "mason" then
					return
				end

				local lang = vim.treesitter.language.get_lang(ft)
				if lang then
					-- Wrap in pcall to prevent crashes if parser is missing
					pcall(vim.treesitter.start, args.buf, lang)
				end
			end,
		})

		-- Custom Markdown heading highlights
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
		})
	end,
}
