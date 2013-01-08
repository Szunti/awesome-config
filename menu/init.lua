-- {{{ Menu
-- Returns the main menu for awesome, includes the other files as submenus

local awful = require("awful")
local beautiful = require("beautiful")

local mainmenu =  awful.menu({ items =  { { "awesome", require("menu.awesome"), beautiful.awesome_icon },
					  -- terminal is a global variable defined in rc.lua
					  { "open terminal", terminal },
					  { "quit" , require("menu.quit") },
					}
			     })

return mainmenu
