local resources = {}

function resources.configureResPaths()
    RESPATHS["player"] = "data/img/ball1.png"
    RESPATHS["tile_hole"] = "data/img/tiles/hole.png"
    RESPATHS["tile_wall"] = "data/img/tiles/wall.png"
    RESPATHS["tile_arrow_left"] = "data/img/tiles/arrow_left.png"
    RESPATHS["tile_arrow_right"] = "data/img/tiles/arrow_right.png"
    RESPATHS["tile_arrow_up"] = "data/img/tiles/arrow_up.png"
    RESPATHS["tile_star"] = "data/img/tiles/star.png"
    RESPATHS["tile_finish"] = "data/img/tiles/finish.png"
    RESPATHS["font_gumball"] = "data/fonts/gumball/Gumball.ttf"
    RESPATHS["coolmap1"] = "data/maps/coolmap1.map"
end

return resources