
-- Persistance: https://github.com/minetest/minetest/blob/master/doc/lua_api.txt#L6403-L6413
-- lwscratch robot Persistance: https://github.com/loosewheel/lwscratch/blob/master/robot.lua#L81-L88

-- Removes time from the time_left, but allows for super_user placed versions with no issues
function chunkkeeper.processFuel(pos)
    local node = minetest.get_node_or_nil(pos)
    local meta = minetest.get_meta(pos)
    local timer = meta:get_int("time_left") or 0
    local super = meta:get_int("super_user") == 1
    local run = meta:get_int("running") == 1
    local dirty = false
    --chunkkeeper.log({timer=timer, super=super, running=run})
    if not super and run then
        timer = timer - 1
        if timer <= 0 then
            if timer < 0 then
                timer = 0
            end
            if run then
                meta:set_int("running", 0)
                meta:set_int("time_left", timer)
                run = false
                --chunkkeeper.log({timer=timer, super=super, running=run})
                dirty = true
                minetest.swap_node(pos, {name = "chunkkeeper:keeper_off"})
            end
        end
        meta:set_int("time_left", timer)
        dirty = true
    elseif super then -- Just update with super
        dirty = true
    end
    if run then -- Change persistance based on running or not (this could also mean the keeper's running was manually toggled)
        minetest.forceload_block(pos)
        --chunkkeeper.log({msg="Persisting position", pos=pos})
    else
        minetest.forceload_free_block(pos)
        --chunkkeeper.log({msg="Stopped persisting position", pos=pos})
    end

    if dirty then
        if not super then
            chunkkeeper.update_formspec(pos)
        else
            chunkkeeper.update_formspec_inf(pos)
        end
    end
    return true
end

-- Attempt to get the MCL formspec to build a formspec able to be shown via their stuff
local mclform = rawget(_G, "mcl_formspec") or nil

-- Returns days hours minutes and seconds of a given timestamp (in seconds)
function chunkkeeper.ts2string(timestamp)
    local mins = math.floor(timestamp / 60)
    timestamp = timestamp - (mins * 60)
    local hours = math.floor(mins / 60)
    mins = mins - (hours * 60)
    local days = math.floor(hours / 24)
    hours = hours - (days * 24)

    local result = ""
    if days ~= 0 then
        result = result .. days .. "d"
    end
    if hours ~= 0 then
        result = result .. hours .. "h"
    end
    if mins ~= 0 then
        result = result .. mins .. "m"
    end
    result = result .. timestamp .. "s"
    return result
end

-- Updates formspec and infotext
function chunkkeeper.update_formspec(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local timer = meta:get_int("time_left")
    local super = meta:get_int("super_user") == 1
    local run = meta:get_int("running") == 1
    local hide_owner = meta:get_int("hide_owner") == 1
    local owner = meta:get_string("owner")

    local running_button = ""
    if run then
        running_button = "Run: On"
    else
        running_button = "Run: Off"
    end
    local hide_owner_button = ""
    if hide_owner then
        hide_owner_button = "Owner: Hidden"
    else
        hide_owner_button = "Owner: Shown"
    end

    -- Inventory and settings (formspec)
    if chunkkeeper.get_game() == "MTG" then
        meta:set_string("formspec",
            "size[8,6]" ..
            "label[0.3,0.3;"..chunkkeeper.ts2string(timer).."]" ..
            "list[context;main;2,0;1,1;]" ..
            "button[0,1; 1.5,1;toggle_running;"..minetest.formspec_escape(running_button).."]" ..
            "button[3,1; 2.5,1;toggle_hide_owner;" .. minetest.formspec_escape(hide_owner_button) .."]" ..
            "list[current_player;main;0,2;8,4;]" ..
            "listring[current_player;main]"  ..
            "listring[context;main]"
        )
    elseif chunkkeeper.get_game() == "MCL" and mclform ~= nil then
        meta:set_string("formspec",
            "size[9, 6.5]"..
            "label[0.3,0.3;"..chunkkeeper.ts2string(timer).."]"..
            "list[context;main;2,0;1,1;]"..
            mclform.get_itemslot_bg(2, 0, 1, 1)..
            "button[0,1; 1.5,1;toggle_running;"..minetest.formspec_escape(running_button).."]" ..
            "button[3,1; 2.5,1;toggle_hide_owner;" .. minetest.formspec_escape(hide_owner_button) .."]" ..
            "label[0,1.85;Inventory]"..
--            "list[current_player;main;0,6.5;9,4;]" ..
--            mclform.get_itemslot_bg(0, 6.5, 9, 4)..
		    "list[current_player;main;0,2.5;9,3;9]"..
		    mclform.get_itemslot_bg(0,2.5,9,3)..
		    "list[current_player;main;0,5.74;9,1;]"..
		    mclform.get_itemslot_bg(0,5.74,9,1)..
            "listring[current_player;main]"  ..
            "listring[context;main]"
        )
    end

    -- Hover text (infotext)
    local title = owner .. "'s Chunk Keeper (" .. tostring(chunkkeeper.ts2string(timer)) .. ")"
    if hide_owner or owner == "" then
        title = "Chunk Keeper (" .. tostring(chunkkeeper.ts2string(timer)) .. ")"
    end
    if super then
        if not hide_owner and owner ~= "" then
            title = owner .. "'s Chunk Keeper (Inf)"
        else
            title = "Chunk Keeper (Inf)"
        end
    end

    meta:set_string("infotext", title)
end

-- Updates formspec and infotext (for super keepers)
function chunkkeeper.update_formspec_inf(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local timer = meta:get_int("time_left")
    local super = meta:get_int("super_user") == 1
    local run = meta:get_int("running") == 1
    local hide_owner = meta:get_int("hide_owner") == 1
    local owner = meta:get_string("owner")

    local running_button = ""
    if run then
        running_button = "Run: On"
    else
        running_button = "Run: Off"
    end
    local hide_owner_button = ""
    if hide_owner then
        hide_owner_button = "Owner: Hidden"
    else
        hide_owner_button = "Owner: Shown"
    end

    -- Inventory and settings (formspec)
    if chunkkeeper.get_game() == "MTG" then
        meta:set_string("formspec",
            "size[8,6]" ..
            "label[0.3,0.3;Inf]" ..
            "list[context;main;2,0;1,1;]" ..
            "button[0,1; 1.5,1;toggle_running;"..minetest.formspec_escape(running_button).."]" ..
            "button[3,1; 2.5,1;toggle_hide_owner;" .. minetest.formspec_escape(hide_owner_button) .."]" ..
            "list[current_player;main;0,2;8,4;]" ..
            "listring[current_player;main]"  ..
            "listring[context;main]"
        )
    elseif chunkkeeper.get_game() == "MCL" and mclform ~= nil then
        meta:set_string("formspec",
            "size[9, 6.5]"..
            "label[0.3,0.3;Inf]"..
            "list[context;main;2,0;1,1;]"..
            mclform.get_itemslot_bg(2, 0, 1, 1)..
            "button[0,1; 1.5,1;toggle_running;"..minetest.formspec_escape(running_button).."]" ..
            "button[3,1; 2.5,1;toggle_hide_owner;" .. minetest.formspec_escape(hide_owner_button) .."]" ..
            "label[0,1.85;Inventory]"..
--            "list[current_player;main;0,6.5;9,4;]" ..
--            mclform.get_itemslot_bg(0, 6.5, 9, 4)..
		    "list[current_player;main;0,2.5;9,3;9]"..
		    mclform.get_itemslot_bg(0,2.5,9,3)..
		    "list[current_player;main;0,5.74;9,1;]"..
		    mclform.get_itemslot_bg(0,5.74,9,1)..
            "listring[current_player;main]"  ..
            "listring[context;main]"
        )
    end

    -- Hover text (infotext)
    local title = owner .. "'s Chunk Keeper (Inf)"
    if hide_owner or owner == "" then
        title = "Chunk Keeper (Inf)"
    end
    if super then
        if not hide_owner and owner ~= "" then
            title = owner .. "'s Chunk Keeper (Inf)"
        else
            title = "Chunk Keeper (Inf)"
        end
    end

    meta:set_string("infotext", title)
end

minetest.register_node("chunkkeeper:keeper_off", {
    short_description = "Chunk Keeper (Off)",
    description = "Chunk Keeper (Off)\nKeeps the mapblock it's located in active\nConsumes burnable items to add time",
    tiles = {
        chunkkeeper.img("top_off"), -- Top
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom")
    },
    is_ground_content = false,
    groups = {handy = 1, oddly_breakable_by_hand = 3},
    drop = "chunkkeeper:keeper_off",
    on_construct = function (pos, node)
        local meta = minetest.get_meta(pos)
        meta:set_int("super_user", 0) -- not inf
        meta:set_int("time_left", 0) -- no time
        meta:set_int("running", 0) -- off
        meta:set_int("hide_owner", 0) -- off
        meta:set_string("owner", "") -- no playername (not yet)
        local inv = meta:get_inventory()
        inv:set_size("main", 1) -- input burnables here (all burn times increased by at least x2)
    end,
    after_place_node = function (pos, placer)
        if placer and placer:is_player() then -- Only update the owner when we have an owner
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            minetest.get_node_timer(pos):start(1)
            chunkkeeper.update_formspec(pos)
        end
    end,
    allow_metadata_inventory_put = function (pos, listname, index, stack, player) -- Add fuel!
        local meta = minetest.get_meta(pos)
        local count = stack:get_count()
        chunkkeeper.log({pos=pos, listname=listname, index=index, stack=stack:to_table(), player=player:get_player_name()})
        local inv = meta:get_inventory()
        if player:get_player_name() ~= meta:get_string("owner") or meta:get_string("owner") == "" then
            if not minetest.check_player_privs(player, {protection_bypass=true}) then
                return count -- No inventory allowed, bad player, bad.
            end
        end
        if listname ~= "main" then
            chunkkeeper.log({listname=listname, errmsg = "Invalid inventory, expected 'main'"})
            return count -- Invalid inventory name
        end
        local recipe = minetest.get_craft_result({
            method = "fuel",
            items = {stack}
        })
        if not recipe then
            chunkkeeper.log({stack=stack:to_table(), errmsg = "Failed getting recipes for stack"})
            return count
        end
        if recipe.time == 0 then
            chunkkeeper.log({stack=stack:to_table(), errmsg = "Didn't get a burnable item?"})
            return count
        end
        local timer = meta:get_int("time_left")
        timer = timer + ((recipe.time * count) * chunkkeeper.settings.fuel_multiplier)
        meta:set_int("time_left", timer)
        chunkkeeper.update_formspec(pos)
        stack:clear()
        inv:set_list("main", {})
        return -1 -- Eat all fuel, this will make things vanish but the time will increase (intended stuff)
    end,
    on_receive_fields = function (pos, formname, fields, player)
        local meta = minetest.get_meta(pos)
        chunkkeeper.log({pos=pos, formname=formname, fields=fields, player=player:get_player_name()})
        local run = meta:get_int("running") == 1
        local hide_owner = meta:get_int("hide_owner") == 1
        local super = meta:get_int("super_user") == 1
        local owner = meta:get_string("owner")
        if owner ~= "" and player:get_player_name() ~= owner then
            if not minetest.check_player_privs(player, {protection_bypass=true}) then
                return -- Invalid user, non-owner access
            end
        end
        local dirty = false
        if fields.toggle_running then
            if run then
                meta:set_int("running", 0)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_off"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_off"})
                end
            else
                meta:set_int("running", 1)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_on"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_on"})
                end
            end
            dirty = true
        elseif fields.toggle_hide_owner then
            if hide_owner then
                meta:set_int("hide_owner", 0)
            else
                meta:set_int("hide_owner", 1)
            end
            dirty = true
        end
        if dirty then
            chunkkeeper.update_formspec(pos)
        end
    end,
    on_timer = function (pos, elapsed)
        return chunkkeeper.processFuel(pos)
    end
})

minetest.register_node("chunkkeeper:keeper_on", {
    short_description = "Chunk Keeper (On)",
    description = "Chunk Keeper (On)\nKeeps the mapblock it's located in active\nConsumes burnable items to add time",
    tiles = {
        { -- Top
            name = chunkkeeper.img("top_on_animated"),
            animation={
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = 2.0
            }
        },
        --chunkkeeper.img("top_off"), -- Top
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom")
    },
    is_ground_content = false,
    groups = {handy = 1, oddly_breakable_by_hand = 3},
    drop = "chunkkeeper:keeper_off",
    on_construct = function (pos, node)
        local meta = minetest.get_meta(pos)
        meta:set_int("super_user", 0) -- not inf
        meta:set_int("time_left", 0) -- no time
        meta:set_int("running", 0) -- off
        meta:set_int("hide_owner", 0) -- off
        meta:set_string("owner", "") -- no playername (not yet)
        local inv = meta:get_inventory()
        inv:set_size("main", 1) -- input burnables here (all burn times increased by at least x2)
    end,
    after_place_node = function (pos, placer)
        if placer and placer:is_player() then -- Only update the owner when we have an owner
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            minetest.get_node_timer(pos):start(1)
            chunkkeeper.update_formspec(pos)
        end
    end,
    allow_metadata_inventory_put = function (pos, listname, index, stack, player) -- Add fuel!
        local meta = minetest.get_meta(pos)
        local count = stack:get_count()
        --chunkkeeper.log({pos=pos, listname=listname, index=index, stack=stack:to_table(), player=player:get_player_name()})
        local inv = meta:get_inventory()
        if player:get_player_name() ~= meta:get_string("owner") or meta:get_string("owner") == "" then
            if not minetest.check_player_privs(player, {protection_bypass=true}) then
                return count -- No inventory allowed, bad player, bad.
            end
        end
        if listname ~= "main" then
            chunkkeeper.log({listname=listname, errmsg = "Invalid inventory, expected 'main'"})
            return count -- Invalid inventory name
        end
        local recipe = minetest.get_craft_result({
            method = "fuel",
            items = {stack}
        })
        if not recipe then
            chunkkeeper.log({stack=stack:to_table(), errmsg = "Failed getting recipes for stack"})
            return count
        end
        if recipe.time == 0 then
            chunkkeeper.log({stack=stack:to_table(), errmsg = "Didn't get a burnable item?"})
            return count
        end
        local timer = meta:get_int("time_left")
        timer = timer + ((recipe.time * count) * chunkkeeper.settings.fuel_multiplier)
        meta:set_int("time_left", timer)
        chunkkeeper.update_formspec(pos)
        stack:clear()
        inv:set_list("main", {})
        return -1 -- Eat all fuel, this will make things vanish but the time will increase (intended stuff)
    end,
    on_receive_fields = function (pos, formname, fields, player)
        local meta = minetest.get_meta(pos)
        --chunkkeeper.log({pos=pos, formname=formname, fields=fields, player=player:get_player_name()})
        local run = meta:get_int("running") == 1
        local hide_owner = meta:get_int("hide_owner") == 1
        local super = meta:get_int("super_user") == 1
        local owner = meta:get_string("owner")
        if owner ~= "" and player:get_player_name() ~= owner then
            if not minetest.check_player_privs(player, {protection_bypass=true}) then
                return -- Invalid user, non-owner access
            end
        end
        local dirty = false
        if fields.toggle_running then
            if run then
                meta:set_int("running", 0)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_off"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_off"})
                end
            else
                meta:set_int("running", 1)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_on"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_on"})
                end
            end
            dirty = true
        elseif fields.toggle_hide_owner then
            if hide_owner then
                meta:set_int("hide_owner", 0)
            else
                meta:set_int("hide_owner", 1)
            end
            dirty = true
        end
        if dirty then
            chunkkeeper.update_formspec(pos)
        end
    end,
    on_timer = function (pos, elapsed)
        return chunkkeeper.processFuel(pos)
    end
})

-- Super User (Infinite time)
minetest.register_node("chunkkeeper:keeper_inf_off", {
    short_description = "Chunk Keeper (Off)",
    description = "Chunk Keeper (Off)\nKeeps the mapblock it's located in active\nThis one has unlimited time",
    tiles = {
        chunkkeeper.img("top_off"), -- Top
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom")
    },
    is_ground_content = false,
    groups = {handy = 1, oddly_breakable_by_hand = 3},
    drop = "chunkkeeper:keeper_inf_off",
    on_construct = function (pos, node)
        local meta = minetest.get_meta(pos)
        meta:set_int("super_user", 1) -- inf
        meta:set_int("time_left", 0) -- no time
        meta:set_int("running", 0) -- off
        meta:set_int("hide_owner", 0) -- off
        meta:set_string("owner", "") -- no playername (not yet)
        local inv = meta:get_inventory() -- Un-needed as infinite keeper's don't need time
        inv:set_size("main", 1) -- input burnables here (all burn times increased by at least x2)
    end,
    after_place_node = function (pos, placer)
        if placer and placer:is_player() then -- Only update the owner when we have an owner
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            minetest.get_node_timer(pos):start(1)
            chunkkeeper.update_formspec_inf(pos)
        end
    end,
    allow_metadata_inventory_put = function (pos, listname, index, stack, player) -- Add fuel!
        local count = stack:get_count()
        return count -- Invalid for infinite time
    end,
    on_recieve_fields = function (pos, formname, fields, player)
        local meta = minetest.get_meta(pos)
        local run = meta:get_int("running") == 1
        local hide_owner = meta:get_int("hide_owner") == 1
        local super = meta:get_int("super_user") == 1
        local owner = meta:get_string("owner")
        if owner ~= "" and player:get_player_name() ~= owner then
            if not minetest.check_player_privs(player, {protection_bypass=true}) then
                return -- Invalid user, non-owner access
            end
        end
        local dirty = false
        if fields.toggle_running then
            if run then
                meta:set_int("running", 0)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_off"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_off"})
                end
            else
                meta:set_int("running", 1)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_on"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_on"})
                end
            end
            dirty = true
        elseif fields.toggle_hide_owner then
            if hide_owner then
                meta:set_int("hide_owner", 0)
            else
                meta:set_int("hide_owner", 1)
            end
        end
        if dirty then
            chunkkeeper.update_formspec_inf(pos)
        end
    end,
    on_timer = function (pos, elapsed)
        return chunkkeeper.processFuel(pos) -- Needs to run for changing persistance
    end
})

minetest.register_node("chunkkeeper:keeper_inf_on", {
    short_description = "Chunk Keeper (On)",
    description = "Chunk Keeper (On)\nKeeps the mapblock it's located in active\nThis one has unlimited time",
    tiles = {
        { -- Top
            name = chunkkeeper.img("top_on_animated"),
            animation={
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = 2.0
            }
        },
        --chunkkeeper.img("top_off"), -- Top
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom"),
        chunkkeeper.img("sides_bottom")
    },
    is_ground_content = false,
    groups = {handy = 1, oddly_breakable_by_hand = 3},
    drop = "chunkkeeper:keeper_inf_off",
    on_construct = function (pos, node)
        local meta = minetest.get_meta(pos)
        meta:set_int("super_user", 1) -- inf
        meta:set_int("time_left", 0) -- no time
        meta:set_int("running", 0) -- off
        meta:set_int("hide_owner", 0) -- off
        meta:set_string("owner", "") -- no playername (not yet)
        local inv = meta:get_inventory()
        inv:set_size("main", 1) -- input burnables here (all burn times increased by at least x2)
    end,
    after_place_node = function (pos, placer)
        if placer and placer:is_player() then -- Only update the owner when we have an owner
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            minetest.get_node_timer(pos):start(1)
            chunkkeeper.update_formspec_inf(pos)
        end
    end,
    allow_metadata_inventory_put = function (pos, listname, index, stack, player) -- Add fuel!
        local count = stack:get_count()
        return count -- Invalid there is no need to add time for a infinite time
    end,
    on_recieve_fields = function (pos, formname, fields, player)
        local meta = minetest.get_meta(pos)
        local run = meta:get_int("running") == 1
        local hide_owner = meta:get_int("hide_owner") == 1
        local super = meta:get_int("super_user") == 1
        local owner = meta:get_string("owner")
        if owner ~= "" and player:get_player_name() ~= owner then
            if not minetest.check_player_privs(player, {protection_bypass=true}) then
                return -- Invalid user, non-owner access
            end
        end
        local dirty = false
        if fields.toggle_running then
            if run then
                meta:set_int("running", 0)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_off"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_off"})
                end
            else
                meta:set_int("running", 1)
                if not super then
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_on"})
                else
                    minetest.swap_node(pos, {name = "chunkkeeper:keeper_inf_on"})
                end
            end
            dirty = true
        elseif fields.toggle_hide_owner then
            if hide_owner then
                meta:set_int("hide_owner", 0)
            else
                meta:set_int("hide_owner", 1)
            end
            dirty = true
        end
        if dirty then
            chunkkeeper.update_formspec_inf(pos)
        end
    end,
    on_timer = function (pos, elapsed)
        return chunkkeeper.processFuel(pos) -- Needs to run for persistance
    end
})

