-- {{ Top panel

local awful = require("awful")
local setmetatable = setmetatable
-- vicious with support for our custom widgets
--local vicious = require("vicious")
local vicious = require("vic_custom_widgets")
local beautiful = require("beautiful")
local wibox = require("wibox")

local table = { insert = table.insert }
local string = { match = string.match,
		 gsub = string.gsub}

-- this table will be returned
local tpanel = {}

-- {{{ Shared widgets

-- Create a laucher widget and a main menu
tpanel.mainmenu = require("menu")
local menulauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
					     menu = tpanel.mainmenu })

-- date and clock
local date_text = wibox.widget.textbox()
vicious.register(date_text, vicious.widgets.date, "%a %b %d, %R")
local datewidget = wibox.layout.margin(date_text, 5, 5)

local cpuwidgets = {}
local cpu_count = 8
for i = 1, cpu_count do
   local cw = awful.widget.progressbar( { width = 6 })
   cw:set_background_color( beautiful.bg_normal )
   cw:set_color("#FF5656")
   cw:set_border_color(nil)
   cw:set_vertical(true)
   vicious.register(cw, vicious.widgets.cpu, "$" .. (i+1), 1)
   table.insert(cpuwidgets, cw)
end
-- Cache else would got wrong values, cause widget gives the cpu usage between subsequent calls
vicious.cache(vicious.widgets.cpu)

local remote_text = wibox.widget.textbox()
vicious.register(remote_text, vicious.widgets.stdout,
		 function (w, args)
		    return string.gsub("<b>t1</b>:$1  <b>t2</b>:$2  <b>t3</b>:$3", "$(%d+)",
				       function (param)
					  local ind = tonumber(param)
					  -- get the first line
					  local line =  string.match(args[ind], "(.-)\n") or args[ind]
					  if string.match(args[ind], "^ssh:") then
					     return "-"
					  else
					     local count = tonumber(line)
					     if count then
						-- line should be the number of running processes
						-- we have to subtract the number of helper processes

						-- two more helper processes for t1:
						--   wc cause pgrep doesn't understand -c there
						--   bash can't quit cause of the pipe
						if ind == 1 then
						   count = count -2
						end

						-- and we have sshd for everyone
						return count - 1
					     else
						-- line wasn't a number, maybe a "-" indicating that server is down
						-- or "?" as we don't have info yet
						return line
					     end
					  end
				       end)
		 end,
		 10,
		 { { command = "ssh t1 'pgrep -u $USER \"\" | wc -l '",
		     id = "t1-disl",
		     timeout = 5,
		     timeout_val = "-",
		     default_val = "?"},
		   { command = "ssh t2 'pgrep -c -u $USER \"\"'",
		     id = "t2-disl",
		     timeout = 5,
		     timeout_val = "-",
		     default_val = "?"},
		   { command = "ssh t3 'pgrep -c -u $USER \"\"'",
		     id = "t3-disl",
		     timeout = 5,
		     timeout_val = "-",
		     default_val = "?"}
		 })
local remotewidget = wibox.layout.margin(remote_text, 5, 5)

-- }}}

-- keybindings, mousebutton bindings
local taglist_buttons = awful.util.table.join(
                        awful.button({ }, 1, awful.tag.viewonly),
			awful.button({ modkey }, 1, awful.client.movetotag),
			awful.button({ }, 3, awful.tag.viewtoggle),
			awful.button({ modkey }, 3, awful.client.toggletag),
			awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
			awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                        )

local tasklist_buttons = awful.util.table.join(
                         awful.button({ }, 1, function (c)
					        if c == client.focus then
						   c.minimized = true
						else
						   -- Without this, the following
						   -- :isvisible() makes no sense
						   c.minimized = false
						   if not c:isvisible() then
						      awful.tag.viewonly(c:tags()[1])
						   end
						   -- This will also un-minimize
						   -- the client, if needed
						   client.focus = c
						   c:raise()
						end
					      end),
			 awful.button({ }, 3, function ()
					        if instance then
						   instance:hide()
						   instance = nil
						else
						   instance = awful.menu.clients({ width=250 })
						end
					      end),
			 awful.button({ }, 4, function ()
					        awful.client.focus.byidx(1)
						if client.focus then client.focus:raise() end
					      end),
			 awful.button({ }, 5, function ()
                                                awful.client.focus.byidx(-1)
						if client.focus then client.focus:raise() end
					      end))

-- panel.add_to_screen(s) add a panel to screen s
-- panel has fields for the widgets in it eg. wibox, promptbox, ...
-- this function returns the panel table

function tpanel.add_to_screen(s)
   -- widgets that should be created for all screens
   local panel = {}
   panel.wibox = awful.wibox({ position = "top", screen = s})
   panel.promptbox = awful.widget.prompt()
   -- Create an imagebox widget which will contains an icon indicating which layout we're using.
   panel.layoutbox = awful.widget.layoutbox(s)
   panel.layoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
   -- Create a taglist widget
   panel.taglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

   -- Create a tasklist widget
   panel.tasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

   -- Add references to shared widgets
   panel.menulauncher = menulauncher
   panel.cpuwidgets = cpuwidgets
   panel.datewidget = datewidget
   panel.remotewidget = remotewidget

   -- Widgets that are aligned to the left
   local left_layout = wibox.layout.fixed.horizontal()
   left_layout:add(panel.menulauncher)
   left_layout:add(panel.taglist)
   left_layout:add(panel.promptbox)
   panel.left_layout = left_layout

   -- Widgets that are aligned to the right
   local right_layout = wibox.layout.fixed.horizontal()
   if s == 1 then right_layout:add(wibox.widget.systray()) end
   right_layout:add(panel.remotewidget)
   for i = 1, #panel.cpuwidgets do
      right_layout:add(panel.cpuwidgets[i])
   end
   right_layout:add(panel.datewidget)
   right_layout:add(panel.layoutbox)
   panel.right_layout = right_layout

   -- Now bring it all together (with the tasklist in the middle)
   local layout = wibox.layout.align.horizontal()
   layout:set_left(left_layout)
   layout:set_middle(panel.tasklist)
   layout:set_right(right_layout)
   panel.layout = layout

   panel.wibox:set_widget(layout)
   return panel
end

return tpanel
