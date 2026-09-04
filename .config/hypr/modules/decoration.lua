-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,

        border_size = 1,

        col = {
        active_border = {
            colors = {
                "rgba(7892adff)",
                "rgba(3b4d61ff)",
            },
            angle = 45,
        },

        inactive_border = "rgba(30343a88)",
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 0.94,

        shadow = {
            enabled = true,
            range = 8,
            render_power = 3,
            color = "rgba(05070acc)",
        },

        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            vibrancy = 0.10,
            new_optimizations = true,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },
})

