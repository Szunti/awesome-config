-- {{{ The quit submenu
return { { "Logout", awesome.quit },
	 { "Reboot", "systemctl reboot"},
	 { "Suspend", "dbus-send --system --print-reply --dest=org.freedesktop.UPower "
	               .. "/org/freedesktop/UPower org.freedesktop.UPower.Suspend" },
	 { "Hibernate", "dbus-send --system --print-reply --dest=org.freedesktop.UPower "
	                 .. "/org/freedesktop/UPower org.freedesktop.UPower.Hibernate" },
	 { "Shutdown", "systemctl poweroff"}
       }

-- }}}
