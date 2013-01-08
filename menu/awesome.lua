-- {{{ The awesome submenu

return { { "manual", terminal .. " -e man awesome" },
	 { "edit config", editor_cmd .. " " .. awesome.conffile },
	 { "restart", awesome.restart },
	 { "quit", awesome.quit }
       }

--}}}
