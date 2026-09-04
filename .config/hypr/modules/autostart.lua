-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("~/.local/bin/batcave-init")
    hl.exec_cmd("waybar")
end)

