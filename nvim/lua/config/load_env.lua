-- Simple .env loader
local function load_env(path)
	local file = io.open(path, "r")
	if not file then
		return
	end
	for line in file:lines() do
		local key, value = line:match("^(%w+)%s*=%s*(.+)$")
		if key and value then
			vim.env[key] = value
		end
	end
	file:close()
end

load_env(vim.fn.expand("~/dotfiles/.env"))
