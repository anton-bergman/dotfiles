local M = {}

local schema_cache = nil

-- Standard SQL keywords to avoid false-positive alias detection
local SQL_KEYWORDS = {
	["all"] = true,
	["and"] = true,
	["as"] = true,
	["by"] = true,
	["cross"] = true,
	["from"] = true,
	["group"] = true,
	["having"] = true,
	["in"] = true,
	["inner"] = true,
	["into"] = true,
	["is"] = true,
	["join"] = true,
	["left"] = true,
	["like"] = true,
	["limit"] = true,
	["not"] = true,
	["null"] = true,
	["on"] = true,
	["or"] = true,
	["order"] = true,
	["outer"] = true,
	["right"] = true,
	["select"] = true,
	["set"] = true,
	["union"] = true,
	["update"] = true,
	["using"] = true,
	["values"] = true,
	["where"] = true,
	["with"] = true,
}

--- Cleans raw SQL identifier string by stripping backticks, quotes, and whitespace.
--- @param raw string?
--- @return string
function M.clean_identifier(raw)
	if not raw then
		return ""
	end
	return string.gsub(raw, "[`'\"%s]", "")
end

--- Checks whether a given token is a reserved SQL keyword.
--- @param word string?
--- @return boolean
function M.is_sql_keyword(word)
	if not word then
		return false
	end
	local clean = string.lower(M.clean_identifier(word))
	return SQL_KEYWORDS[clean] == true
end

--- Lazily loads BigQuery schema JSON cache from disk.
--- @param force_reload boolean?
--- @return table<string, string[]>?
function M.get_schema(force_reload)
	if schema_cache and not force_reload then
		return schema_cache
	end

	local schema_path = vim.fn.expand("~/.cache/nvim/bq_schema.json")
	if vim.fn.filereadable(schema_path) ~= 1 then
		return nil
	end

	local file = io.open(schema_path, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.json.decode, content)
	if ok and type(decoded) == "table" then
		schema_cache = decoded
		return schema_cache
	end

	return nil
end

--- Resolves column array and canonical table name from a raw table reference.
--- Handles backticks, project-qualified, dataset-qualified, and short table names.
--- @param tbl_raw string?
--- @return string[]? columns, string? canonical_table_name
function M.get_columns_for_table(tbl_raw)
	local schema = M.get_schema()
	if not schema or not tbl_raw then
		return nil, nil
	end

	local clean = M.clean_identifier(tbl_raw)
	if clean == "" then
		return nil, nil
	end

	-- 1. Exact match (e.g., "my_table" or "my_dataset.my_table")
	if schema[clean] then
		return schema[clean], clean
	end

	-- 2. Strip project prefix (e.g., "my-project.my_dataset.my_table" -> "my_dataset.my_table")
	local without_project = string.match(clean, "%.([%w_%.]+)$")
	if without_project and schema[without_project] then
		return schema[without_project], without_project
	end

	-- 3. Strip dataset prefix (e.g., "my_dataset.my_table" -> "my_table")
	local short_name = string.match(clean, "([%w_]+)$")
	if short_name and schema[short_name] then
		return schema[short_name], short_name
	end

	return nil, nil
end

--- Returns a list of all available BigQuery table names.
--- @return string[]
function M.get_all_tables()
	local schema = M.get_schema()
	if not schema then
		return {}
	end

	local tables = {}
	for tbl_name, _ in pairs(schema) do
		table.insert(tables, tbl_name)
	end
	return tables
end

--- Scans buffer lines for table alias declarations and resolves the associated columns.
--- Supports "FROM/JOIN table AS alias" and "FROM/JOIN table alias".
--- @param lines string[]
--- @param target_alias string
--- @return string[]? columns, string? table_name
function M.find_table_by_alias(lines, target_alias)
	local clean_target = M.clean_identifier(target_alias)
	if clean_target == "" then
		return nil, nil
	end

	for _, buf_line in ipairs(lines) do
		local lower_line = string.lower(buf_line)
		if string.find(lower_line, "from") or string.find(lower_line, "join") then
			-- 1. FROM/JOIN tbl AS alias
			for tbl, alias in string.gmatch(buf_line, "[Ff][Rr][Oo][Mm]%s+([`%w_%-%.]+)%s+[Aa][Ss]%s+([`%w_]+)") do
				if M.clean_identifier(alias) == clean_target then
					local cols, r_tbl = M.get_columns_for_table(tbl)
					if cols then
						return cols, r_tbl
					end
				end
			end
			for tbl, alias in string.gmatch(buf_line, "[Jj][Oo][Ii][Nn]%s+([`%w_%-%.]+)%s+[Aa][Ss]%s+([`%w_]+)") do
				if M.clean_identifier(alias) == clean_target then
					local cols, r_tbl = M.get_columns_for_table(tbl)
					if cols then
						return cols, r_tbl
					end
				end
			end

			-- 2. FROM/JOIN tbl alias (without AS)
			for tbl, alias in string.gmatch(buf_line, "[Ff][Rr][Oo][Mm]%s+([`%w_%-%.]+)%s+([`%w_]+)") do
				local c_alias = M.clean_identifier(alias)
				if not M.is_sql_keyword(c_alias) and c_alias == clean_target then
					local cols, r_tbl = M.get_columns_for_table(tbl)
					if cols then
						return cols, r_tbl
					end
				end
			end
			for tbl, alias in string.gmatch(buf_line, "[Jj][Oo][Ii][Nn]%s+([`%w_%-%.]+)%s+([`%w_]+)") do
				local c_alias = M.clean_identifier(alias)
				if not M.is_sql_keyword(c_alias) and c_alias == clean_target then
					local cols, r_tbl = M.get_columns_for_table(tbl)
					if cols then
						return cols, r_tbl
					end
				end
			end
		end
	end

	return nil, nil
end

--- Extracts all active tables referenced in FROM and JOIN clauses within buffer lines.
--- @param lines string[]
--- @return table<string, string[]> map of canonical_table_name -> column_list
function M.get_active_tables_in_buffer(lines)
	local active_tables = {}

	for _, buf_line in ipairs(lines) do
		local lower_line = string.lower(buf_line)
		if string.find(lower_line, "from") or string.find(lower_line, "join") then
			for tbl in string.gmatch(buf_line, "[Ff][Rr][Oo][Mm]%s+([`%w_%-%.]+)") do
				local cols, r_tbl = M.get_columns_for_table(tbl)
				if cols and r_tbl then
					active_tables[r_tbl] = cols
				end
			end
			for tbl in string.gmatch(buf_line, "[Jj][Oo][Ii][Nn]%s+([`%w_%-%.]+)") do
				local cols, r_tbl = M.get_columns_for_table(tbl)
				if cols and r_tbl then
					active_tables[r_tbl] = cols
				end
			end
		end
	end

	return active_tables
end

--- Creates an nvim-cmp source adapter for BigQuery schema autocompletion.
--- @return table
function M.new_cmp_source()
	local source = {}

	function source:get_trigger_characters()
		return { "." }
	end

	function source:is_available()
		local ft = vim.bo.filetype
		return ft == "sql" or ft == "mysql" or ft == "plsql"
	end

	function source:complete(params, callback)
		local schema = M.get_schema()
		if not schema then
			return callback()
		end

		local line = params.context.cursor_line
		local col = params.context.cursor.col
		local before_cursor = string.sub(line, 1, col - 1)

		local ok_cmp, cmp = pcall(require, "cmp")
		local field_kind = (ok_cmp and cmp.lsp and cmp.lsp.CompletionItemKind and cmp.lsp.CompletionItemKind.Field) or 5
		local struct_kind = (ok_cmp and cmp.lsp and cmp.lsp.CompletionItemKind and cmp.lsp.CompletionItemKind.Struct)
			or 22

		-- Track A: Dot-scoped column completion (e.g., "my_table.", "i.", "`my_table`.")
		local table_or_alias = string.match(before_cursor, "([`%w_%-%.]+)%.$")
		if table_or_alias then
			local clean_alias = M.clean_identifier(table_or_alias)
			local columns, real_table = M.get_columns_for_table(clean_alias)

			if not columns then
				local line_count = vim.api.nvim_buf_line_count(0)
				local max_lines = math.min(line_count, 1000)
				local lines = vim.api.nvim_buf_get_lines(0, 0, max_lines, false)
				columns, real_table = M.find_table_by_alias(lines, clean_alias)
			end

			if columns then
				local items = {}
				for _, col_name in ipairs(columns) do
					table.insert(items, {
						label = col_name,
						kind = field_kind,
						detail = "BigQuery column (" .. (real_table or clean_alias) .. ")",
					})
				end
				return callback({ items = items, isIncomplete = false })
			end

			return callback()
		end

		-- Track B: Table name completion (after FROM / JOIN)
		if
			string.match(before_cursor, "[Ff][Rr][Oo][Mm]%s+[`%w_%-%.]*$")
			or string.match(before_cursor, "[Jj][Oo][Ii][Nn]%s+[`%w_%-%.]*$")
		then
			local items = {}
			for _, tbl_name in ipairs(M.get_all_tables()) do
				table.insert(items, {
					label = tbl_name,
					kind = struct_kind,
					detail = "BigQuery table",
				})
			end
			if #items > 0 then
				return callback({ items = items, isIncomplete = false })
			end
		end

		-- Track C: Contextual column completion for active tables in query scope
		local line_count = vim.api.nvim_buf_line_count(0)
		local max_lines = math.min(line_count, 1000)
		local lines = vim.api.nvim_buf_get_lines(0, 0, max_lines, false)
		local active_tables = M.get_active_tables_in_buffer(lines)

		local items = {}
		local seen_cols = {}

		for tbl_name, cols in pairs(active_tables) do
			for _, col_name in ipairs(cols) do
				if not seen_cols[col_name] then
					seen_cols[col_name] = true
					table.insert(items, {
						label = col_name,
						kind = field_kind,
						detail = "BigQuery column (" .. tbl_name .. ")",
					})
				end
			end
		end

		if #items > 0 then
			callback({ items = items, isIncomplete = false })
		else
			callback()
		end
	end

	return setmetatable({}, { __index = source })
end

return M
