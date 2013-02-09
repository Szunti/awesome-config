local r = require("utils.runonce")

-- {{{ Programs
r.run("mpd")
r.run("xscreensaver -nosplash")
--r.run("transmission-gtk -m")
r.run("deluge")
r.run("artha")
r.run("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
--r.run("urxvtd -o")
--r.run("pidgin")

-- }}}
