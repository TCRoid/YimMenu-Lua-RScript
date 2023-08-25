-------------------------------
--- Author: Rostal
-------------------------------

local tab_root = gui.add_tab("RScript")
local tab_manage_vehicle_list = tab_root:add_tab(" > 管理载具列表")
local tab_mission = tab_root:add_tab(" > 任务助手")

-- Main Page
local vehicle_manage = {
    checkbox = {},
    input = {}
}

-- Manage Vehicle List Page
local ctrl_vehicle = 0
local ctrl_page = {
    enable = false
}

-- Mission Helper Page
local mission_page = {
    checkbox = {},
}



--------------------
-- Functions
--------------------
v3 = {
    ['new'] = function(x, y, z)
        return { ['x'] = x, ['y'] = y, ['z'] = z }
    end,
    --return a - b
    ['subtract'] = function(a, b)
        return v3.new(a.x - b.x, a.y - b.y, a.z - b.z)
    end,
    --return a + b
    ['add'] = function(a, b)
        return v3.new(a.x + b.x, a.y + b.y, a.z + b.z)
    end,
    ['mag'] = function(a)
        return math.sqrt(a.x ^ 2 + a.y ^ 2 + a.z ^ 2)
    end,
    ['norm'] = function(a)
        local mag = v3.mag(a)
        return v3.div(a, mag)
    end,
    --return a * b
    ['mult'] = function(a, b)
        return v3.new(a.x * b, a.y * b, a.z * b)
    end,
    --return a / b
    ['div'] = function(a, b)
        return v3.new(a.x / b, a.y / b, a.z / b)
    end,
    --return the distance between two vectors
    ['distance'] = function(a, b)
        return v3.mag(v3.subtract(a, b))
    end
}

function SET_ENTITY_COORDS(entity, coords)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, coords.x, coords.y, coords.z, true, false, false)
end

function GET_PED_IN_VEHICLE_SEAT(vehicle, seat)
    if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seat, false) then
        return VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat)
    end
    return 0
end

function GET_VEHICLE_PED_IS_IN(ped)
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        return PED.GET_VEHICLE_PED_IS_IN(ped, false)
    end
    return 0
end

function DRAW_LINE(start_pos, end_pos, colour)
    colour = colour or { r = 255, g = 0, b = 255, a = 255 }
    GRAPHICS.DRAW_LINE(start_pos.x, start_pos.y, start_pos.z,
        end_pos.x, end_pos.y, end_pos.z,
        colour.r, colour.g, colour.b, colour.a)
end

local function toast(text)
    gui.show_message("RScript", text)
end

-----------------------------
-- Local Player Functions
-----------------------------

function teleport(x, y, z, heading)
    local ent = GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID())
    if ent == 0 then
        ent = PLAYER.PLAYER_PED_ID()
    end
    SET_ENTITY_COORDS(ent, v3.new(x, y, z))

    if heading ~= nil then
        ENTITY.SET_ENTITY_HEADING(ent, heading)
    end
end

function teleport2(coords, heading)
    local ent = GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID())
    if ent == 0 then
        ent = PLAYER.PLAYER_PED_ID()
    end
    SET_ENTITY_COORDS(ent, coords)

    if heading ~= nil then
        ENTITY.SET_ENTITY_HEADING(ent, heading)
    end
end

function tp_to_me(entity, offsetX, offsetY, offsetZ)
    offsetX = offsetX or 0.0
    offsetY = offsetY or 0.0
    offsetZ = offsetZ or 0.0
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), offsetX, offsetY, offsetZ)
    SET_ENTITY_COORDS(entity, coords)
end

function tp_to_entity(entity, offsetX, offsetY, offsetZ)
    offsetX = offsetX or 0.0
    offsetY = offsetY or 0.0
    offsetZ = offsetZ or 0.0
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, offsetX, offsetY, offsetZ)
    teleport2(coords)
end

function tp_into_vehicle(vehicle)
    if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        --unlock doors
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vehicle, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_TEAMS(vehicle, false)
        VEHICLE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(vehicle, false)
        --clear wanted
        VEHICLE.SET_VEHICLE_IS_WANTED(vehicle, false)
        VEHICLE.SET_VEHICLE_INFLUENCES_WANTED_LEVEL(vehicle, false)
        VEHICLE.SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(vehicle, true)
        VEHICLE.SET_VEHICLE_IS_STOLEN(vehicle, false)
        VEHICLE.SET_POLICE_FOCUS_WILL_TRACK_VEHICLE(vehicle, false)
        --driver
        local driver = GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
        if driver ~= 0 then
            delete_entity(driver)
        end
        --tp into
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, false)
        PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, -1)
    end
end

function tp_vehicle_to_me(vehicle)
    set_entity_head_to_entity(vehicle, PLAYER.PLAYER_PED_ID())
    tp_to_me(vehicle)
    tp_into_vehicle(vehicle)
end

-------------------------
-- Entity Functions
-------------------------

function request_control(entity, timeout)
    timeout = timeout or 5
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and NETWORK.NETWORK_IS_SESSION_STARTED() then
        local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)
        local start_time = os.time()
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) do
            if os.time() - start_time >= timeout then
                break
            end
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
            script_util:yield()
        end
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

function get_entity_owner(entity)
    if NETWORK.NETWORK_IS_SESSION_STARTED() then
        local ptr = memory.handle_to_ptr(entity)
        local netObject = ptr:add(0xD0):deref()
        if netObject:is_null() then
            return -1
        end
        local owner_id = netObject:add(0x49):get_byte()
        return owner_id
    end
    return PLAYER.PLAYER_ID()
end

function set_entity_godmode(ent, toggle)
    ENTITY.SET_ENTITY_INVINCIBLE(ent, toggle)
    ENTITY.SET_ENTITY_PROOFS(ent, toggle, toggle, toggle, toggle, toggle, toggle, toggle, toggle)
    ENTITY.SET_ENTITY_CAN_BE_DAMAGED(ent, not toggle)
end

function delete_entity(ent)
    if ENTITY.DOES_ENTITY_EXIST(ent) then
        ENTITY.DETACH_ENTITY(ent, true, true)
        ENTITY.SET_ENTITY_VISIBLE(ent, false, false)
        NETWORK.NETWORK_SET_ENTITY_ONLY_EXISTS_FOR_PARTICIPANTS(ent, true)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ent, 0.0, 0.0, -1000.0, false, false, false)
        ENTITY.SET_ENTITY_COLLISION(ent, false, false)
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, true, true)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(ent)
        ENTITY.DELETE_ENTITY(memory.handle_to_ptr(ent))
    end
end

function get_entities_by_hash(Type, isMission, ...)
    Type = string.lower(Type)
    local all_entity = {}

    if Type == "ped" then
        all_entity = entities.get_all_peds_as_handles()
    elseif Type == "vehicle" then
        all_entity = entities.get_all_vehicles_as_handles()
    elseif Type == "object" then
        all_entity = entities.get_all_objects_as_handles()
    end

    local entity_list = {}
    local hash_list = { ... }

    for k, ent in pairs(all_entity) do
        local EntityHash = ENTITY.GET_ENTITY_MODEL(ent)
        for _, Hash in pairs(hash_list) do
            if EntityHash == Hash then
                if isMission then
                    if ENTITY.IS_ENTITY_A_MISSION_ENTITY(ent) then
                        table.insert(entity_list, ent)
                    end
                else
                    table.insert(entity_list, ent)
                end
            end
        end
    end

    return entity_list
end

function is_hostile_ped(ped)
    if PED.IS_PED_IN_COMBAT(ped, PLAYER.PLAYER_PED_ID()) then
        return true
    end

    local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(ped, PLAYER.PLAYER_PED_ID())
    if rel == 4 or rel == 5 then -- Wanted or Hate
        return true
    end
end

function is_hostile_entity(entity)
    if ENTITY.IS_ENTITY_A_PED(entity) then
        if is_hostile_ped(entity) then
            return true
        end
    end

    if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        local driver = GET_PED_IN_VEHICLE_SEAT(entity, -1)
        if driver ~= 0 and is_hostile_ped(entity) then
            return true
        end
    end

    local blip = HUD.GET_BLIP_FROM_ENTITY(entity)
    if HUD.DOES_BLIP_EXIST(blip) then
        local blip_colour = HUD.GET_BLIP_COLOUR(blip)
        if blip_colour == 1 or blip_colour == 59 then
            return true
        end
    end
end

function set_entity_head_to_entity(set_ent, to_ent, angle)
    angle = angle or 0.0
    local Head = ENTITY.GET_ENTITY_HEADING(to_ent)
    ENTITY.SET_ENTITY_HEADING(set_ent, Head + angle)
end

-------------------------
-- Vehicle Functions
-------------------------

function get_vehicle_display_name_by_hash(hash)
    local label_name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
    return HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(label_name)
end

function fix_vehicle(vehicle)
    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
    VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000.0)

    VEHICLE.SET_VEHICLE_UNDRIVEABLE(vehicle, false)
    VEHICLE.SET_VEHICLE_IS_CONSIDERED_BY_PLAYER(vehicle, true)
end

function upgrade_vehicle(vehicle)
    VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
    for i = 0, 50 do
        if i ~= 48 and i ~= 23 and i ~= 24 then
            local mod_num = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
            if mod_num > 0 then
                VEHICLE.SET_VEHICLE_MOD(vehicle, i, mod_num - 1, false)
            end
        end
    end
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false)
    VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(vehicle, false)
    VEHICLE.SET_VEHICLE_HAS_UNBREAKABLE_LIGHTS(vehicle, true)
    VEHICLE.SET_VEHICLE_CAN_ENGINE_MISSFIRE(vehicle, false)
    VEHICLE.SET_VEHICLE_CAN_LEAK_OIL(vehicle, false)
    VEHICLE.SET_VEHICLE_CAN_LEAK_PETROL(vehicle, false)

    VEHICLE.SET_DISABLE_VEHICLE_ENGINE_FIRES(vehicle, true)
    VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(vehicle, true)
    VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(vehicle, true)

    for i = 0, 3 do
        VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(vehicle, i, false)
    end
    VEHICLE.SET_HELI_TAIL_BOOM_CAN_BREAK_OFF(vehicle, false)
end

function strong_vehicle(vehicle)
    VEHICLE.SET_VEHICLE_CAN_BREAK(vehicle, false)
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false)
    VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(vehicle, false)
    for i = 0, 5 do
        if VEHICLE.GET_IS_DOOR_VALID(vehicle, i) then
            VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(vehicle, i, false)
        end
    end
    VEHICLE.SET_VEHICLE_HAS_UNBREAKABLE_LIGHTS(vehicle, true)

    VEHICLE.SET_VEHICLE_CAN_ENGINE_MISSFIRE(vehicle, false)
    VEHICLE.SET_VEHICLE_CAN_LEAK_OIL(vehicle, false)
    VEHICLE.SET_VEHICLE_CAN_LEAK_PETROL(vehicle, false)

    VEHICLE.SET_DISABLE_VEHICLE_ENGINE_FIRES(vehicle, true)
    VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(vehicle, true)
    VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(vehicle, true)

    VEHICLE.SET_VEHICLE_STRONG(vehicle, true)
    VEHICLE.SET_VEHICLE_HAS_STRONG_AXLES(vehicle, true)

    --Damage
    VEHICLE.VEHICLE_SET_RAMP_AND_RAMMING_CARS_TAKE_DAMAGE(vehicle, false)
    VEHICLE.SET_INCREASE_WHEEL_CRUSH_DAMAGE(vehicle, false)
    VEHICLE.SET_DISABLE_DAMAGE_WITH_PICKED_UP_ENTITY(vehicle, true)
    VEHICLE.SET_VEHICLE_USES_MP_PLAYER_DAMAGE_MULTIPLIER(vehicle, true)

    --Explode
    VEHICLE.SET_VEHICLE_NO_EXPLOSION_DAMAGE_FROM_DRIVER(vehicle, true)
    VEHICLE.SET_DISABLE_EXPLODE_FROM_BODY_DAMAGE_ON_COLLISION(vehicle, 1)
    VEHICLE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(vehicle, false)
    VEHICLE.SET_VEHICLE_EXPLODES_ON_EXPLOSION_DAMAGE_AT_ZERO_BODY_HEALTH(vehicle, false)
    VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(vehicle, false)

    --Heli
    VEHICLE.SET_HELI_TAIL_BOOM_CAN_BREAK_OFF(vehicle, false)
    VEHICLE.SET_DISABLE_HELI_EXPLODE_FROM_BODY_DAMAGE(vehicle, true)

    --MP Only
    VEHICLE.SET_PLANE_RESIST_TO_EXPLOSION(vehicle, true)
    VEHICLE.SET_HELI_RESIST_TO_EXPLOSION(vehicle, true)

    --Remove Check
    VEHICLE.REMOVE_VEHICLE_UPSIDEDOWN_CHECK(vehicle)
    VEHICLE.REMOVE_VEHICLE_STUCK_CHECK(vehicle)
end

function unlock_vehicle_doors(vehicle)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, false)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vehicle, false)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_TEAMS(vehicle, false)
    VEHICLE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(vehicle, false)
end

-------------------------
-- Other Functions
-------------------------

function run_script(name)
    script.run_in_fiber(function(runscript)
        SCRIPT.REQUEST_SCRIPT(name)
        repeat runscript:yield() until SCRIPT.HAS_SCRIPT_LOADED(name)
        SYSTEM.START_NEW_SCRIPT(name, 5000)
        SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED(name)
    end)
end

-------------------------
-- Page Functions
-------------------------

local function check_match(ent)
    -- 任务实体
    if not vehicle_manage.checkbox.disable_mission:is_enabled() then
        if ENTITY.IS_ENTITY_A_MISSION_ENTITY(ent) then
            if not vehicle_manage.checkbox.mission:is_enabled() then
                return false
            end
        else
            if vehicle_manage.checkbox.mission:is_enabled() then
                return false
            end
        end
    end
    -- 距离
    if vehicle_manage.input.distance:get_value() > 0 then
        local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
        local ent_pos = ENTITY.GET_ENTITY_COORDS(ent)
        if v3.distance(my_pos, ent_pos) > vehicle_manage.input.distance:get_value() then
            return false
        end
    end
    -- 地图标记点
    if not vehicle_manage.checkbox.disable_blip:is_enabled() then
        local blip = HUD.GET_BLIP_FROM_ENTITY(ent)
        if HUD.DOES_BLIP_EXIST(blip) then
            if not vehicle_manage.checkbox.blip:is_enabled() then
                return false
            end
        else
            if vehicle_manage.checkbox.blip:is_enabled() then
                return false
            end
        end
    end
    -- 正在移动
    if not vehicle_manage.checkbox.disable_move:is_enabled() then
        if ENTITY.GET_ENTITY_SPEED(ent) > 0 then
            if not vehicle_manage.checkbox.move:is_enabled() then
                return false
            end
        else
            if vehicle_manage.checkbox.move:is_enabled() then
                return false
            end
        end
    end
    -- 司机
    if not vehicle_manage.checkbox.disable_driver:is_enabled() then
        if not VEHICLE.IS_VEHICLE_SEAT_FREE(ent, -1, false) then
            if not vehicle_manage.checkbox.driver:is_enabled() then
                return false
            end
        else
            if vehicle_manage.checkbox.driver:is_enabled() then
                return false
            end
        end
    end

    -- END
    return true
end

local function get_ent_button_info(ent)
    local info = ""

    local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    local ent_pos = ENTITY.GET_ENTITY_COORDS(ent)

    info = "距离: " .. string.format("%.2f", v3.distance(my_pos, ent_pos))

    info = info .. ", 速度: " .. string.format("%.2f", ENTITY.GET_ENTITY_SPEED(ent))

    local blip = HUD.GET_BLIP_FROM_ENTITY(ent)
    if HUD.DOES_BLIP_EXIST(blip) then
        info = info .. ", 标记点: " .. HUD.GET_BLIP_SPRITE(blip)
    end

    local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
    if ENTITY.IS_ENTITY_A_PED(driver) then
        if PED.GET_PED_TYPE(driver) >= 4 then
            info = info .. ", 司机: NPC"
        else
            info = info .. ", 司机: 玩家"
        end
    end

    if NETWORK.NETWORK_IS_SESSION_STARTED() then
        info = info .. ", 控制权: " .. PLAYER.GET_PLAYER_NAME(get_entity_owner(ent))
    end

    return info
end


--------------------
-- Main Page
--------------------
tab_root:add_text("载具实体控制，获取列表后到 > 管理载具列表 页面查看")

tab_root:add_button("获取载具列表", function()
    if ctrl_page.enable then
        tab_manage_vehicle_list:clear()
    end
    generate_manage_vehicle_page()

    local num = 0
    for key, ent in pairs(entities.get_all_vehicles_as_handles()) do
        if check_match(ent) then
            num = num + 1

            local button_name = num .. ". "

            local hash = ENTITY.GET_ENTITY_MODEL(ent)
            button_name = button_name .. get_vehicle_display_name_by_hash(hash)

            if ent == PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) then
                if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
                    button_name = button_name .. " (当前载具)"
                else
                    button_name = button_name .. " (上一辆载具)"
                end
            end

            tab_manage_vehicle_list:add_button(button_name, function()
                if ENTITY.DOES_ENTITY_EXIST(ent) then
                    if ent ~= ctrl_vehicle then
                        reset_manage_vehicle_checkbox()
                    end
                    ctrl_vehicle = ent
                else
                    gui.show_message("通知", "该实体已不存在")
                end
            end)

            tab_manage_vehicle_list:add_sameline()
            tab_manage_vehicle_list:add_text(get_ent_button_info(ent))
        end
    end

    if num == 0 then
        ctrl_page.enable = false
        tab_manage_vehicle_list:clear()
    end
    gui.show_message("获取载具列表", "获取的载具数量: " .. num)
end)

tab_root:add_separator()
tab_root:add_text("筛选设置")

vehicle_manage.checkbox.mission = tab_root:add_checkbox("任务实体 (是/否)")
vehicle_manage.checkbox.mission:set_enabled(true)
tab_root:add_sameline()
vehicle_manage.checkbox.disable_mission = tab_root:add_checkbox("禁用筛选: 任务实体")

vehicle_manage.input.distance = tab_root:add_input_float("距离 (0表示不限制)")

vehicle_manage.checkbox.blip = tab_root:add_checkbox("地图标记点 (有/没有)")
tab_root:add_sameline()
vehicle_manage.checkbox.disable_blip = tab_root:add_checkbox("禁用筛选: 地图标记点")
vehicle_manage.checkbox.disable_blip:set_enabled(true)

vehicle_manage.checkbox.move = tab_root:add_checkbox("正在移动 (是/否)")
tab_root:add_sameline()
vehicle_manage.checkbox.disable_move = tab_root:add_checkbox("禁用筛选: 正在移动")
vehicle_manage.checkbox.disable_move:set_enabled(true)

vehicle_manage.checkbox.driver = tab_root:add_checkbox("司机 (有/没有)")
tab_root:add_sameline()
vehicle_manage.checkbox.disable_driver = tab_root:add_checkbox("禁用筛选: 司机")
vehicle_manage.checkbox.disable_driver:set_enabled(true)



---------------------------
-- Manage Vehicle Page
---------------------------

local function manage_vehicle_checkbox(name, toggle_on, toggle_off)
    if ctrl_page.checkbox[name]:is_enabled() then
        if not ctrl_page.toggle[name] then
            ctrl_page.toggle[name] = true

            toggle_on()
            --log.info("toggle on")
        end
    else
        if ctrl_page.toggle[name] then
            ctrl_page.toggle[name] = false

            toggle_off()
            --log.info("toggle off")
        end
    end
end

function reset_manage_vehicle_checkbox()
    local name_list = {
        "godmode", "freeze", "no_gravity"
    }

    for _, name in pairs(name_list) do
        ctrl_page.toggle[name] = false
        ctrl_page.checkbox[name]:set_enabled(false)
    end
end

function generate_manage_vehicle_page()
    ctrl_vehicle = 0
    ctrl_page = {
        enable = true,
        text = {},
        checkbox = {},
        input = {},
        toggle = {
            ["godmode"]    = false,
            ["freeze"]     = false,
            ["no_gravity"] = false,
        },
    }

    tab_manage_vehicle_list:add_text("在下方点击选择一辆载具，然后进行实体控制")

    tab_manage_vehicle_list:add_separator()
    tab_manage_vehicle_list:add_text("实体信息")
    ctrl_page.text.vehicle = tab_manage_vehicle_list:add_text("载具: 无")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.text.hash = tab_manage_vehicle_list:add_text("Hash: 0")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.text.index = tab_manage_vehicle_list:add_text("Index: 0")
    ctrl_page.text.coords = tab_manage_vehicle_list:add_text("坐标: x = 0.0, y = 0.0, z = 0.0")
    ctrl_page.text.health = tab_manage_vehicle_list:add_text("血量: 0/0")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.text.distance = tab_manage_vehicle_list:add_text("距离: 0.0")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.text.speed = tab_manage_vehicle_list:add_text("速度: 0.0")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.text.owner = tab_manage_vehicle_list:add_text("控制权: 无")

    ----------
    tab_manage_vehicle_list:add_separator()
    tab_manage_vehicle_list:add_text("实体选项")
    ctrl_page.checkbox["godmode"] = tab_manage_vehicle_list:add_checkbox("无敌")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.checkbox["freeze"] = tab_manage_vehicle_list:add_checkbox("冻结")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.checkbox["no_gravity"] = tab_manage_vehicle_list:add_checkbox("无重力")
    tab_manage_vehicle_list:add_sameline()
    ctrl_page.checkbox["draw_line"] = tab_manage_vehicle_list:add_checkbox("连线指示")

    tab_manage_vehicle_list:add_button("爆炸", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local coords = ENTITY.GET_ENTITY_COORDS(ctrl_vehicle)
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 4, 1000.0, true, false, 0.0, false)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("请求控制", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            if request_control(ctrl_vehicle) then
                gui.show_message("请求控制实体", "成功")
            else
                gui.show_message("请求控制实体", "失败，请重试")
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("设置为任务实体", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ctrl_vehicle, true, false)

            if ENTITY.IS_ENTITY_A_MISSION_ENTITY(ctrl_vehicle) then
                gui.show_message("设置为任务实体", "成功")
            else
                gui.show_message("设置为任务实体", "失败")
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("设置为网络实体", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) and NETWORK.NETWORK_IS_SESSION_STARTED() then
            NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(ctrl_vehicle)
            local net_id = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(ctrl_vehicle)
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
            NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(net_id, PLAYER.PLAYER_ID(), true)

            if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(ctrl_vehicle) then
                gui.show_message("设置为网络实体", "成功")
            else
                gui.show_message("设置为网络实体", "失败")
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("删除", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            if PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), ctrl_vehicle, true) then
                SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), ENTITY.GET_ENTITY_COORDS(ctrl_vehicle))
            end
            delete_entity(ctrl_vehicle)
        end
    end)

    ctrl_page.input.health = tab_manage_vehicle_list:add_input_int("血量")
    ctrl_page.input.health:set_value(1000.0)
    tab_manage_vehicle_list:add_button("设置当前血量", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local value = ctrl_page.input.health:get_value()
            if value >= 0 then
                ENTITY.SET_ENTITY_HEALTH(ctrl_vehicle, value)
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("设置最大血量", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local value = ctrl_page.input.health:get_value()
            if value >= 0 then
                ENTITY.SET_ENTITY_MAX_HEALTH(ctrl_vehicle, value)
            end
        end
    end)

    ----------
    tab_manage_vehicle_list:add_separator()
    tab_manage_vehicle_list:add_text("传送选项")
    ctrl_page.input.tp_y = tab_manage_vehicle_list:add_input_float("前/后")
    ctrl_page.input.tp_y:set_value(2.0)
    ctrl_page.input.tp_x = tab_manage_vehicle_list:add_input_float("左/右")
    ctrl_page.input.tp_z = tab_manage_vehicle_list:add_input_float("上/下")

    tab_manage_vehicle_list:add_button("传送到我", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local tp_x = ctrl_page.input.tp_x:get_value()
            local tp_y = ctrl_page.input.tp_y:get_value()
            local tp_z = ctrl_page.input.tp_z:get_value()

            local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), tp_x, tp_y, tp_z)
            SET_ENTITY_COORDS(ctrl_vehicle, coords)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("传送到实体", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local tp_x = ctrl_page.input.tp_x:get_value()
            local tp_y = ctrl_page.input.tp_y:get_value()
            local tp_z = ctrl_page.input.tp_z:get_value()

            local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ctrl_vehicle, tp_x, tp_y, tp_z)
            teleport2(coords)
        end
    end)

    ----------
    tab_manage_vehicle_list:add_separator()
    tab_manage_vehicle_list:add_text("载具选项")
    tab_manage_vehicle_list:add_button("传送进载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(ctrl_vehicle) then
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ctrl_vehicle, -2)
            else
                gui.show_message("传送进载具", "载具已无空座位")
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("传送进驾驶位", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ctrl_vehicle, -1)
            if ENTITY.IS_ENTITY_A_PED(ped) then
                local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.0, 3.0)
                SET_ENTITY_COORDS(ped, coords)
            end
            PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ctrl_vehicle, -1)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("传送进副驾驶位", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            if VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(ctrl_vehicle) > 0 then
                local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ctrl_vehicle, 0)
                if ENTITY.IS_ENTITY_A_PED(ped) then
                    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.0, 3.0)
                    SET_ENTITY_COORDS(ped, coords)
                end
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ctrl_vehicle, 0)
            else
                gui.show_message("传送进副驾驶位", "载具无副驾驶位")
            end
        end
    end)

    tab_manage_vehicle_list:add_button("修复载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            fix_vehicle(ctrl_vehicle)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("升级载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            upgrade_vehicle(ctrl_vehicle)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("强化载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            strong_vehicle(ctrl_vehicle)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("平放载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(ctrl_vehicle, 5.0)
        end
    end)

    ctrl_page.input.forward_speed = tab_manage_vehicle_list:add_input_float("速度")
    ctrl_page.input.forward_speed:set_value(30.0)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("向前加速", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local value = ctrl_page.input.forward_speed:get_value()
            if value >= 0 then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(ctrl_vehicle, value)
            end
        end
    end)

    tab_manage_vehicle_list:add_button("删除车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.REMOVE_VEHICLE_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("摇下车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.ROLL_DOWN_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("摇上车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.ROLL_UP_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("粉碎车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.SMASH_VEHICLE_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("修复车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.FIX_VEHICLE_WINDOW(ctrl_vehicle, i)
            end
        end
    end)

    tab_manage_vehicle_list:add_button("打开车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 3 do
                VEHICLE.SET_VEHICLE_DOOR_OPEN(ctrl_vehicle, i, false, false)
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("关闭车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_DOORS_SHUT(ctrl_vehicle, false)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("拆下车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_DOOR_BROKEN(ctrl_vehicle, i, false)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("删除车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_DOOR_BROKEN(ctrl_vehicle, i, true)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("解锁车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            unlock_vehicle_doors(ctrl_vehicle)
        end
    end)

    tab_manage_vehicle_list:add_button("打开引擎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(ctrl_vehicle, true, true, false)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("关闭引擎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(ctrl_vehicle, false, true, false)
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("爆掉车胎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.SET_VEHICLE_TYRE_BURST(ctrl_vehicle, i, true, 1000.0)
            end
        end
    end)
    tab_manage_vehicle_list:add_sameline()
    tab_manage_vehicle_list:add_button("修复车胎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.SET_VEHICLE_TYRE_FIXED(ctrl_vehicle, i)
            end
        end
    end)

    ----------
    tab_manage_vehicle_list:add_separator()
    tab_manage_vehicle_list:add_text("载具列表")
end

script.register_looped("RScript_Manage_Vehicle", function()
    if ctrl_page.enable and tab_manage_vehicle_list:is_selected() then
        local ent = ctrl_vehicle
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local hash = ENTITY.GET_ENTITY_MODEL(ent)
            local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
            local ent_pos = ENTITY.GET_ENTITY_COORDS(ent)


            ---- 实体信息 ----
            local display_name = get_vehicle_display_name_by_hash(hash)
            ctrl_page.text.vehicle:set_text("载具: " .. display_name)
            ctrl_page.text.hash:set_text("Hash: " .. hash)
            ctrl_page.text.index:set_text("Index: " .. ent)
            ctrl_page.text.coords:set_text(string.format("坐标: x = %.4f, y = %.4f, z = %.4f",
                ent_pos.x, ent_pos.y, ent_pos.z))
            ctrl_page.text.distance:set_text("距离: " .. string.format("%.4f", v3.distance(my_pos, ent_pos)))
            ctrl_page.text.health:set_text(string.format("血量: %d/%d",
                ENTITY.GET_ENTITY_HEALTH(ent), ENTITY.GET_ENTITY_MAX_HEALTH(ent)))
            ctrl_page.text.speed:set_text("速度: " .. string.format("%.4f", ENTITY.GET_ENTITY_SPEED(ent)))
            ctrl_page.text.owner:set_text("控制权: " .. PLAYER.GET_PLAYER_NAME(get_entity_owner(ent)))


            ---- 实体选项 ----

            -- 无敌
            manage_vehicle_checkbox("godmode", function()
                set_entity_godmode(ent, true)
            end, function()
                set_entity_godmode(ent, false)
            end)
            -- 冻结
            manage_vehicle_checkbox("freeze", function()
                ENTITY.FREEZE_ENTITY_POSITION(ent, true)
            end, function()
                ENTITY.FREEZE_ENTITY_POSITION(ent, false)
            end)
            -- 无重力
            manage_vehicle_checkbox("no_gravity", function()
                ENTITY.SET_ENTITY_HAS_GRAVITY(ent, false)
                VEHICLE.SET_VEHICLE_GRAVITY(ent, false)
            end, function()
                ENTITY.SET_ENTITY_HAS_GRAVITY(ent, true)
                VEHICLE.SET_VEHICLE_GRAVITY(ent, true)
            end)
            -- 连线指示
            if ctrl_page.checkbox["draw_line"]:is_enabled() then
                DRAW_LINE(my_pos, ent_pos)
            end


            -- END
        end
    end
end)



---------------------------
-- Mission Helper Page
---------------------------

tab_mission:add_text("每日任务")
tab_mission:add_button("传送到藏匿屋", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(845)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords)
    else
        gui.show_message("传送", "未在地图上找到藏匿屋")
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("通知藏匿屋密码", function()
    if INTERIOR.GET_INTERIOR_FROM_ENTITY(PLAYER.PLAYER_PED_ID()) == 289793 then
        local code_list = {
            -- hash, code
            { 4221637939, "01-23-45" },
            { 1433270535, "02-12-87" },
            { 944906360,  "05-02-91" },
            { 3046060548, "24-10-81" },
            { 1626709912, "28-03-98" },
            { 921471402,  "28-11-97" },
            { 3648550039, "44-23-37" },
            { 4136820571, "72-68-83" },
            { 1083248297, "73-27-38" },
            { 2104921722, "77-79-73" },
        }
        for k, obj in pairs(entities.get_all_objects_as_handles()) do
            if ENTITY.IS_ENTITY_A_MISSION_ENTITY(obj) then
                local hash = ENTITY.GET_ENTITY_MODEL(obj)
                for _, data in pairs(code_list) do
                    if hash == data[1] then
                        gui.show_message("藏匿屋密码", data[2])
                    end
                end
            end
        end
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("传送到杰拉德包裹", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(842)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords)
    else
        gui.show_message("传送", "未在地图上找到杰拉德包裹")
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("进入范围后，传送到包裹", function()
    local entity_list = get_entities_by_hash("object", true, 138777325, 2674233009, 765087784)
    if next(entity_list) ~= nil then
        for k, ent in pairs(entity_list) do
            tp_to_entity(ent, 0.0, 0.0, 0.5)
        end
    end
end)

tab_mission:add_separator()
tab_mission:add_button("打开恐霸电脑", function()
    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("apphackertruck")) > 0 then
        return
    end
    run_script("apphackertruck")
end)
tab_mission:add_sameline()
mission_page.checkbox.skip_talk = tab_mission:add_checkbox("跳过NPC对话")

tab_mission:add_button("爆炸敌对NPC", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if is_hostile_entity(ped) then
            local coords = ENTITY.GET_ENTITY_COORDS(ped)
            FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                4, 100.0, false, false, 0.0)
        end
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("爆炸敌对载具", function()
    for _, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
        if is_hostile_entity(vehicle) then
            local coords = ENTITY.GET_ENTITY_COORDS(vehicle)
            FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                4, 100.0, false, false, 0.0)
        end
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("爆炸敌对物体", function()
    for _, object in pairs(entities.get_all_objects_as_handles()) do
        if is_hostile_entity(object) then
            local coords = ENTITY.GET_ENTITY_COORDS(object)
            FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                4, 100.0, false, false, 0.0)
        end
    end
end)

tab_mission:add_separator()
tab_mission:add_text("办公室拉货")
tab_mission:add_button("传送到 特种货物", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(478)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport(coords.x, coords.y, coords.z + 1.0)
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("特种货物 传送到我", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(478)
    if HUD.DOES_BLIP_EXIST(blip) then
        local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            set_entity_head_to_entity(ent, PLAYER.PLAYER_PED_ID())
            tp_to_me(ent)

            if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
                tp_into_vehicle(ent)
            end
        else
            toast("目标不是实体，无法传送到我")
        end
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("特种货物(载具) 传送到我", function()
    local entity_list = get_entities_by_hash("object", true, 2972783418, 2272050386)
    if next(entity_list) ~= nil then
        for k, ent in pairs(entity_list) do
            if ENTITY.IS_ENTITY_ATTACHED(ent) then
                local attached_ent = ENTITY.GET_ENTITY_ATTACHED_TO(ent)
                if ENTITY.IS_ENTITY_A_VEHICLE(attached_ent) then
                    tp_vehicle_to_me(attached_ent)
                end
            end
        end
    end
end)

tab_mission:add_separator()
tab_mission:add_text("地堡拉货")
tab_mission:add_button("传送到 地堡原材料", function()
    local blip1 = HUD.GET_CLOSEST_BLIP_INFO_ID(556)
    local blip2 = HUD.GET_CLOSEST_BLIP_INFO_ID(561)
    local blip3 = HUD.GET_CLOSEST_BLIP_INFO_ID(477)

    if HUD.DOES_BLIP_EXIST(blip1) then
        local coords = HUD.GET_BLIP_COORDS(blip1)
        teleport(coords.x, coords.y + 2.0, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip2) then
        local coords = HUD.GET_BLIP_COORDS(blip2)
        teleport(coords.x, coords.y, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip3) then
        local coords = HUD.GET_BLIP_COORDS(blip3)
        teleport(coords.x, coords.y, coords.z + 1.0)
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("地堡原材料 传送到我", function()
    local blip = HUD.GET_NEXT_BLIP_INFO_ID(556)
    if HUD.DOES_BLIP_EXIST(blip) then
        local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            set_entity_head_to_entity(ent, PLAYER.PLAYER_PED_ID())
            tp_to_me(ent)

            if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
                tp_into_vehicle(ent)
            end
        else
            toast("目标不是实体，无法传送到我")
        end
    end
end)

tab_mission:add_separator()
tab_mission:add_text("摩托帮工厂")
tab_mission:add_button("传送到 工厂原材料", function()
    local blip1 = HUD.GET_CLOSEST_BLIP_INFO_ID(501)
    local blip2 = HUD.GET_CLOSEST_BLIP_INFO_ID(64)
    local blip3 = HUD.GET_CLOSEST_BLIP_INFO_ID(427)
    local blip4 = HUD.GET_CLOSEST_BLIP_INFO_ID(423)

    if HUD.DOES_BLIP_EXIST(blip1) then
        local coords = HUD.GET_BLIP_COORDS(blip1)
        teleport(coords.x, coords.y - 1.5, coords.z)
    elseif HUD.DOES_BLIP_EXIST(blip2) then
        local coords = HUD.GET_BLIP_COORDS(blip2)
        teleport(coords.x, coords.y - 1.5, coords.z)
    elseif HUD.DOES_BLIP_EXIST(blip3) then
        local coords = HUD.GET_BLIP_COORDS(blip3)
        teleport(coords.x, coords.y, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip4) then
        local coords = HUD.GET_BLIP_COORDS(blip4)
        teleport(coords.x, coords.y + 1.5, coords.z - 1.0)
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("工厂原材料 传送到我", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(501)
    if HUD.DOES_BLIP_EXIST(blip) then
        local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            set_entity_head_to_entity(ent, PLAYER.PLAYER_PED_ID())
            tp_to_me(ent)

            if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
                tp_into_vehicle(ent)
            end
        else
            toast("目标不是实体，无法传送到我")
        end
    end
end)



script.register_looped("RScript_Mission_Helper", function()
    if mission_page.checkbox.skip_talk:is_enabled() then
        if AUDIO.IS_SCRIPTED_CONVERSATION_ONGOING() then
            AUDIO.STOP_SCRIPTED_CONVERSATION(false)
        end
    end
end)
