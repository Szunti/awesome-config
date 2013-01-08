-- This module changes the metatable of vicious.widgets to also
-- see the widgets in this directory, if there is a widget with the same name
-- the widget in this directory is used
-- returns the vicious module

local setmetatable = getmetatable
local vicious = require("vicious")
-- widgets already required by vicious
local package = { searchpath = package.searchpath,
		  path = package.path}

local _NAME = "vic_custom_widgets"

-- change the metatable
local mtable = getmetatable(vicious.widgets)
-- save the old __index
local old_index = mtable.__index

mtable.__index =
function(table, index)
   -- check if we have the file
   local custom_mod_name = _NAME .. "." .. index
   if ( package.searchpath (custom_mod_name, package.path) ) then
      return require(custom_mod_name)
   else
      return old_index(table, index)
   end
end

return vicious
