-------------------------------
--- Author: Rostal
-------------------------------

local tab_root = gui.add_tab("RScript")
local tab_manage_vehicle = tab_root:add_tab(" > 管理载具列表")

-- Main Page
local vehicle_manage = {
    checkbox = {},
    input = {}
}

-- Manage Vehicle Page
local ctrl_vehicle = 0
local ctrl_page = {
    enable = false
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

local function SET_ENTITY_COORDS(entity, coords)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, coords.x, coords.y, coords.z, true, false, false)
end

local function GET_VEHICLE_PED_IS_IN(ped)
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        return PED.GET_VEHICLE_PED_IS_IN(ped, false)
    end
    return 0
end

local function DRAW_LINE(start_pos, end_pos, colour)
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

local function teleport(x, y, z, heading)
    local ent = GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID())
    if ent == 0 then
        ent = PLAYER.PLAYER_PED_ID()
    end
    SET_ENTITY_COORDS(ent, v3.new(x, y, z))

    if heading ~= nil then
        ENTITY.SET_ENTITY_HEADING(ent, heading)
    end
end

local function teleport2(coords, heading)
    local ent = GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID())
    if ent == 0 then
        ent = PLAYER.PLAYER_PED_ID()
    end
    SET_ENTITY_COORDS(ent, coords)

    if heading ~= nil then
        ENTITY.SET_ENTITY_HEADING(ent, heading)
    end
end

-------------------------
-- Entity Functions
-------------------------

local function request_control(entity, timeout)
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

local function get_entity_owner(entity)
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

local function set_entity_godmode(ent, toggle)
    ENTITY.SET_ENTITY_INVINCIBLE(ent, toggle)
    ENTITY.SET_ENTITY_PROOFS(ent, toggle, toggle, toggle, toggle, toggle, toggle, toggle, toggle)
    ENTITY.SET_ENTITY_CAN_BE_DAMAGED(ent, not toggle)
end

local function delete_entity(ent)
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

-------------------------
-- Vehicle Functions
-------------------------

local function get_vehicle_display_name_by_hash(hash)
    local label_name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
    return HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(label_name)
end

local function fix_vehicle(vehicle)
    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
    VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000.0)

    VEHICLE.SET_VEHICLE_UNDRIVEABLE(vehicle, false)
    VEHICLE.SET_VEHICLE_IS_CONSIDERED_BY_PLAYER(vehicle, true)
end

local function upgrade_vehicle(vehicle)
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

local function strong_vehicle(vehicle)
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

local function unlock_vehicle_doors(vehicle)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, 1)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(vehicle, false)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_NON_SCRIPT_PLAYERS(vehicle, false)
    VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_TEAMS(vehicle, false)
    VEHICLE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(vehicle, false)
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
        tab_manage_vehicle:clear()
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

            tab_manage_vehicle:add_button(button_name, function()
                if ENTITY.DOES_ENTITY_EXIST(ent) then
                    if ent ~= ctrl_vehicle then
                        reset_manage_vehicle_checkbox()
                    end
                    ctrl_vehicle = ent
                else
                    gui.show_message("通知", "该实体已不存在")
                end
            end)

            tab_manage_vehicle:add_sameline()
            tab_manage_vehicle:add_text(get_ent_button_info(ent))
        end
    end

    if num == 0 then
        ctrl_page.enable = false
        tab_manage_vehicle:clear()
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

    tab_manage_vehicle:add_text("在下方点击选择一辆载具，然后进行实体控制")

    tab_manage_vehicle:add_separator()
    tab_manage_vehicle:add_text("实体信息")
    ctrl_page.text.vehicle = tab_manage_vehicle:add_text("载具: 无")
    tab_manage_vehicle:add_sameline()
    ctrl_page.text.hash = tab_manage_vehicle:add_text("Hash: 0")
    tab_manage_vehicle:add_sameline()
    ctrl_page.text.index = tab_manage_vehicle:add_text("Index: 0")
    ctrl_page.text.coords = tab_manage_vehicle:add_text("坐标: x = 0.0, y = 0.0, z = 0.0")
    ctrl_page.text.health = tab_manage_vehicle:add_text("血量: 0/0")
    tab_manage_vehicle:add_sameline()
    ctrl_page.text.distance = tab_manage_vehicle:add_text("距离: 0.0")
    tab_manage_vehicle:add_sameline()
    ctrl_page.text.speed = tab_manage_vehicle:add_text("速度: 0.0")
    tab_manage_vehicle:add_sameline()
    ctrl_page.text.owner = tab_manage_vehicle:add_text("控制权: 无")

    ----------
    tab_manage_vehicle:add_separator()
    tab_manage_vehicle:add_text("实体选项")
    ctrl_page.checkbox["godmode"] = tab_manage_vehicle:add_checkbox("无敌")
    tab_manage_vehicle:add_sameline()
    ctrl_page.checkbox["freeze"] = tab_manage_vehicle:add_checkbox("冻结")
    tab_manage_vehicle:add_sameline()
    ctrl_page.checkbox["no_gravity"] = tab_manage_vehicle:add_checkbox("无重力")
    tab_manage_vehicle:add_sameline()
    ctrl_page.checkbox["draw_line"] = tab_manage_vehicle:add_checkbox("连线指示")

    tab_manage_vehicle:add_button("爆炸", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local coords = ENTITY.GET_ENTITY_COORDS(ctrl_vehicle)
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 4, 1000.0, true, false, 0.0, false)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("请求控制", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            if request_control(ctrl_vehicle) then
                gui.show_message("请求控制实体", "成功")
            else
                gui.show_message("请求控制实体", "失败，请重试")
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("设置为任务实体", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ctrl_vehicle, true, false)

            if ENTITY.IS_ENTITY_A_MISSION_ENTITY(ctrl_vehicle) then
                gui.show_message("设置为任务实体", "成功")
            else
                gui.show_message("设置为任务实体", "失败")
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("设置为网络实体", function()
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
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("删除", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            if PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), ctrl_vehicle, true) then
                SET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), ENTITY.GET_ENTITY_COORDS(ctrl_vehicle))
            end
            delete_entity(ctrl_vehicle)
        end
    end)

    ctrl_page.input.health = tab_manage_vehicle:add_input_int("血量")
    ctrl_page.input.health:set_value(1000.0)
    tab_manage_vehicle:add_button("设置当前血量", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local value = ctrl_page.input.health:get_value()
            if value >= 0 then
                ENTITY.SET_ENTITY_HEALTH(ctrl_vehicle, value)
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("设置最大血量", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local value = ctrl_page.input.health:get_value()
            if value >= 0 then
                ENTITY.SET_ENTITY_MAX_HEALTH(ctrl_vehicle, value)
            end
        end
    end)

    ----------
    tab_manage_vehicle:add_separator()
    tab_manage_vehicle:add_text("传送选项")
    ctrl_page.input.tp_y = tab_manage_vehicle:add_input_float("前/后")
    ctrl_page.input.tp_y:set_value(2.0)
    ctrl_page.input.tp_x = tab_manage_vehicle:add_input_float("左/右")
    ctrl_page.input.tp_z = tab_manage_vehicle:add_input_float("上/下")

    tab_manage_vehicle:add_button("传送到我", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local tp_x = ctrl_page.input.tp_x:get_value()
            local tp_y = ctrl_page.input.tp_y:get_value()
            local tp_z = ctrl_page.input.tp_z:get_value()

            local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), tp_x, tp_y, tp_z)
            SET_ENTITY_COORDS(ctrl_vehicle, coords)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("传送到实体", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local tp_x = ctrl_page.input.tp_x:get_value()
            local tp_y = ctrl_page.input.tp_y:get_value()
            local tp_z = ctrl_page.input.tp_z:get_value()

            local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ctrl_vehicle, tp_x, tp_y, tp_z)
            teleport2(coords)
        end
    end)

    ----------
    tab_manage_vehicle:add_separator()
    tab_manage_vehicle:add_text("载具选项")
    tab_manage_vehicle:add_button("传送进载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(ctrl_vehicle) then
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ctrl_vehicle, -2)
            else
                gui.show_message("传送进载具", "载具已无空座位")
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("传送进驾驶位", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ctrl_vehicle, -1)
            if ENTITY.IS_ENTITY_A_PED(ped) then
                local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.0, 3.0)
                SET_ENTITY_COORDS(ped, coords)
            end
            PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ctrl_vehicle, -1)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("传送进副驾驶位", function()
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

    tab_manage_vehicle:add_button("修复载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            fix_vehicle(ctrl_vehicle)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("升级载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            upgrade_vehicle(ctrl_vehicle)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("强化载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            strong_vehicle(ctrl_vehicle)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("平放载具", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(ctrl_vehicle, 5.0)
        end
    end)

    ctrl_page.input.forward_speed = tab_manage_vehicle:add_input_float("速度")
    ctrl_page.input.forward_speed:set_value(30.0)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("向前加速", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            local value = ctrl_page.input.forward_speed:get_value()
            if value >= 0 then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(ctrl_vehicle, value)
            end
        end
    end)

    tab_manage_vehicle:add_button("删除车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.REMOVE_VEHICLE_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("摇下车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.ROLL_DOWN_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("摇上车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.ROLL_UP_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("粉碎车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.SMASH_VEHICLE_WINDOW(ctrl_vehicle, i)
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("修复车窗", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.FIX_VEHICLE_WINDOW(ctrl_vehicle, i)
            end
        end
    end)

    tab_manage_vehicle:add_button("打开车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 3 do
                VEHICLE.SET_VEHICLE_DOOR_OPEN(ctrl_vehicle, i, false, false)
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("关闭车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_DOORS_SHUT(ctrl_vehicle, false)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("拆下车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_DOOR_BROKEN(ctrl_vehicle, i, false)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("删除车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_DOOR_BROKEN(ctrl_vehicle, i, true)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("解锁车门", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            unlock_vehicle_doors(ctrl_vehicle)
        end
    end)

    tab_manage_vehicle:add_button("打开引擎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(ctrl_vehicle, true, true, false)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("关闭引擎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(ctrl_vehicle, false, true, false)
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("爆掉车胎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.SET_VEHICLE_TYRE_BURST(ctrl_vehicle, i, true, 1000.0)
            end
        end
    end)
    tab_manage_vehicle:add_sameline()
    tab_manage_vehicle:add_button("修复车胎", function()
        if ENTITY.DOES_ENTITY_EXIST(ctrl_vehicle) then
            for i = 0, 7 do
                VEHICLE.SET_VEHICLE_TYRE_FIXED(ctrl_vehicle, i)
            end
        end
    end)

    ----------
    tab_manage_vehicle:add_separator()
    tab_manage_vehicle:add_text("载具列表")
end

script.register_looped("RScript_Manage_Vehicle", function()
    if ctrl_page.enable and tab_manage_vehicle:is_selected() then
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
