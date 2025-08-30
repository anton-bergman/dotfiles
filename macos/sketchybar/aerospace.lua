-- items/aerospace.lua
local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local max_workspaces = 9
local focused_workspace_index = nil

local workspaces = {}

-- Updates workspace UI to reflect current window state
-- Shows window icons when apps are open and hides them when empty,
-- except for the focused workspace which shows a placeholder
local function updateWindows(workspace_index)
	local get_windows =
		string.format("aerospace list-windows --workspace %s --format '%%{app-name}' --json", workspace_index)
	sbar.exec(get_windows, function(open_windows)
		local icon_line = ""
		local no_app = true
		for i, open_window in ipairs(open_windows) do
			no_app = false
			local app = open_window["app-name"]
			-- Fallback to default icon if app-specific icon isn't found
			local lookup = app_icons[app]
			local icon = ((lookup == nil) and app_icons["default"] or lookup)
			icon_line = icon_line .. " " .. icon
		end
		sbar.animate("tanh", 10, function()
			if no_app then
				-- Show placeholder for empty focused workspace
				workspaces[workspace_index]:set({
					icon = { drawing = true, padding_right = 15 },
					label = { drawing = false },
					background = { drawing = true },
					padding_right = 1,
					padding_left = 4,
				})
				return
			end

			workspaces[workspace_index]:set({
				icon = { drawing = true, padding_right = 8 },
				label = { drawing = true, string = icon_line },
				background = { drawing = true },
				padding_right = 1,
				padding_left = 4,
			})
		end)
	end)
end

for workspace_index = 1, max_workspaces do
	local workspace = sbar.add("item", {
		icon = {
			font = { family = settings.font.numbers },
			string = workspace_index,
			padding_left = 15,
			padding_right = 8,
			color = colors.white,
			highlight_color = colors.red,
		},
		label = {
			padding_right = 20,
			color = colors.grey,
			highlight_color = colors.white,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
		},
		padding_right = 1,
		padding_left = 4,
		background = {
			color = colors.bg1,
		},
	})

	workspaces[workspace_index] = workspace

	workspace:subscribe("aerospace_workspace_change", function(env)
		focused_workspace_index = tonumber(env.FOCUSED_WORKSPACE)
		local is_focused = focused_workspace_index == workspace_index

		sbar.animate("tanh", 10, function()
			workspace:set({
				icon = { highlight = is_focused },
				label = { highlight = is_focused },
				background = {
					border_color = is_focused and colors.grey or colors.bg2,
				},
			})
		end)
	end)

	-- Update windows when focus within workspace changes
	workspace:subscribe("aerospace_focus_change", function()
		updateWindows(workspace_index)
	end)

	-- Allow workspace switching via click
	workspace:subscribe("mouse.clicked", function()
		local focus_workspace = "aerospace workspace " .. workspace_index
		sbar.exec(focus_workspace)
	end)

	workspace:subscribe("mouse.entered", function()
		sbar.animate("tanh", 10, function()
			workspace:set({
				icon = { highlight = true },
				label = { highlight = true },
				background = { border_color = colors.grey },
			})
		end)
	end)

	workspace:subscribe("mouse.exited", function()
		-- Maintain highlight if this is the focused workspace
		sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
			sbar.animate("tanh", 10, function()
				workspace:set({
					icon = { highlight = workspace_index == tonumber(focused_workspace) },
					label = { highlight = workspace_index == tonumber(focused_workspace) },
					background = {
						border_color = workspace_index == tonumber(focused_workspace) and colors.grey or colors.bg2,
					},
				})
			end)
		end)
	end)

	-- Set initial workspace state
	updateWindows(workspace_index)
	sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
		workspaces[tonumber(focused_workspace)]:set({
			icon = { highlight = true },
			label = { highlight = true },
			background = {
				border_color = colors.grey,
			},
		})
	end)
end
