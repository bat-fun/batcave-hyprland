hl.curve("batcave", {
    type = "bezier",
    points = {
        {0.16, 1},
        {0.3, 1},
    }
})

hl.curve("gothamSpring", {
    type = "spring",
    mass = 1,
    stiffness = 190,
    dampening = 26,
})

hl.curve("quiet", {
    type = "bezier",
    points = {
        {0.25, 0.8},
        {0.35, 1},
    }
})

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 8,
    bezier = "default"
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    spring = "gothamSpring",
    style = "popin 92%"
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4,
    spring = "gothamSpring",
    style = "popin 92%"
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "quiet",
    style = "popin 87%"
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3,
    bezier = "quiet"
})

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 5,
    bezier = "batcave",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "quiet",
    style = "slidefade 18%"
})