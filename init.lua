
chunkkeeper = {}
chunkkeeper.modpath = minetest.get_modpath("chunkkeeper")
chunkkeeper.version = "1.1"

chunkkeeper.settings = {
    fuel_multiplier = 2.0
}

function chunkkeeper.get_game()
    if minetest.registered_nodes["default:dirt"] then
        return "MTG"
    elseif minetest.registered_nodes["mcl_core:dirt"] then
        return "MCL"
    else
        return "???"
    end
end

function chunkkeeper.log(msg)
    if type(msg) == "table" then
        msg = minetest.serialize(msg)
    elseif type(msg) ~= "string" then
        msg = tostring(msg)
    end
    minetest.log("action", "[chunkkeeper] " .. msg)
end
chunkkeeper.log("Version: " .. chunkkeeper.version)

function chunkkeeper.dofile(filename)
    dofile(chunkkeeper.modpath .. DIR_DELIM .. filename .. ".lua")
end

function chunkkeeper.img(name)
    return "chunkkeeper_" .. name .. ".png"
end

chunkkeeper.dofile("register")
chunkkeeper.dofile("crafting")

chunkkeeper.log("Ready!")
