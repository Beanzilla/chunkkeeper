
local iron = "default:steel_ingot"
local gold = "defualt:gold_ingot"
local diamond = "default:diamond"

if chunkkeeper.get_game() == "MCL" then
    iron = "mcl_core:iron_ingot"
    gold = "mcl_core:gold_ingot"
    diamond = "mcl_core:diamond"
end

minetest.register_craft({
    output = "chunkkeeper:keeper_off",
    recipe = {
        {"", diamond, ""},
        {iron, diamond, iron},
        {iron, gold, iron}
    }
})
