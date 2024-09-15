--------------------------------
-- Author: Rostal
--------------------------------

local SUPPORT_GAME_VERSION <const> = "1.69-3274"

--#region check game version

script.run_in_fiber(function()
    local build_version = memory.scan_pattern("8B C3 33 D2 C6 44 24 20"):add(0x24):rip()
    local online_version = build_version:add(0x20)
    local CURRENT_GAME_VERSION <const> = string.format("%s-%s", online_version:get_string(), build_version:get_string())

    if SUPPORT_GAME_VERSION ~= CURRENT_GAME_VERSION then
        gui.show_message("[RScript]", "未兼容当前游戏版本, 部分功能可能会失效")
    end
end)

--#endregion


require("RScript.tables")
require("RScript.functions")


self = nil
MainLoop = {} -- No Delay

--------------------------------
-- Locals
--------------------------------

Locals = {
    ["fm_mission_controller"] = {
        sFMMC_SBD = {
            -- MC_serverBD_1.sFMMC_SBD.niVehicle[index]
            niVehicle = 22960 + 834 + 81 + 1
        }
    },
    ["fm_mission_controller_2020"] = {
        sFMMC_SBD = {
            -- MC_serverBD_1.sFMMC_SBD.niVehicle[index]
            niVehicle = 53558 + 777 + 81 + 1
        }
    }
}

----------------------------------------
-- Menu: Main
----------------------------------------

local menu_root <const> = gui.add_tab("RScript")

local MenuMain = { _parent = menu_root }

----------------
-- 自我
----------------

menu_root:add_text("<<  自我  >>")

menu.add_input_float(MenuMain, "生命恢复速率", 1.0, "[ 0.0 ~ 100.0 ]")
menu.add_input_float(MenuMain, "生命恢复程度", 0.5, "[ 0.0 ~ 1.0 ]")
menu.add_toggle_loop(MenuMain, "自定义设置生命恢复", "", function()
    local rate = menu.get_input_value(MenuMain["生命恢复速率"], 0.0, 100.0)
    local percent = menu.get_input_value(MenuMain["生命恢复程度"], 0.0, 1.0)

    PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), rate)
    PLAYER.SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT(PLAYER.PLAYER_ID(), percent)
end, function()
    PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT(PLAYER.PLAYER_ID(), 0.5)
end)

menu_root:add_separator()

menu.add_input_float(MenuMain, "自我受伤倍数", 1.0, "[ 0.1 ~ 1.0 ]")
menu.add_toggle_loop(MenuMain, "自定义设置受伤倍数", "(数值越低，受到的伤害就越低)", function()
    local value = menu.get_input_value(MenuMain["自我受伤倍数"], 0.1, 1.0)
    PLAYER.SET_PLAYER_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
    PLAYER.SET_PLAYER_WEAPON_MINIGUN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
    PLAYER.SET_PLAYER_MELEE_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
    PLAYER.SET_PLAYER_VEHICLE_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
    PLAYER.SET_PLAYER_WEAPON_TAKEDOWN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
end, function()
    PLAYER.SET_PLAYER_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_WEAPON_MINIGUN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_MELEE_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_VEHICLE_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_WEAPON_TAKEDOWN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
end)

menu_root:add_separator()

menu.add_toggle_loop(MenuMain, "步行时人称视角快捷切换", "(第一人称视角 和 第三人称近距离视角 快捷切换)", function()
    if CAM.IS_FOLLOW_PED_CAM_ACTIVE() then
        if CAM.GET_FOLLOW_PED_CAM_VIEW_MODE() == 1 or CAM.GET_FOLLOW_PED_CAM_VIEW_MODE() == 2 then
            CAM.SET_FOLLOW_PED_CAM_VIEW_MODE(4)
        end
    end
end)
menu_root:add_button("强制进入警星闪烁状态", function()
    PLAYER.FORCE_START_HIDDEN_EVASION(PLAYER.PLAYER_ID())
end)
menu_root:add_sameline()
menu.add_toggle_loop(MenuMain, "禁止刷出警察", "(通缉前开启，仅单人时有效)", function()
    PLAYER.SET_DISPATCH_COPS_FOR_PLAYER(PLAYER.PLAYER_ID(), false)
end, function()
    PLAYER.SET_DISPATCH_COPS_FOR_PLAYER(PLAYER.PLAYER_ID(), true)
end)

menu_root:add_separator()

----------------
-- 载具
----------------

menu_root:add_text("<<  载具  >>")

menu.add_toggle_loop(MenuMain, "无限动能回收加速", "", function()
    local vehicle = get_user_vehicle(false)
    if vehicle ~= 0 then
        if VEHICLE.GET_VEHICLE_HAS_KERS(vehicle) then
            local vehicle_ptr = memory.handle_to_ptr(vehicle)
            --local kers_boost_max = vehicle_ptr:add(0x92c):get_float()
            vehicle_ptr:add(0x930):set_float(3.0) -- m_kers_boost
        end
    end
end)
menu_root:add_sameline()
menu.add_toggle_button(MenuMain, "电台只播放音乐", false, function(toggle)
    for _, stationName in pairs(T.VehicleRadioStations) do
        AUDIO.SET_RADIO_STATION_MUSIC_ONLY(stationName, toggle)
    end
end)
menu_root:add_sameline()
menu_root:add_button("移除当前载具通缉状态", function()
    local vehicle = get_user_vehicle()
    if vehicle ~= 0 then
        clear_vehicle_wanted(vehicle)

        toast("完成！")
    end
end)

menu_root:add_separator()

menu.add_toggle(MenuMain, "性能升级", true)
menu_root:add_sameline()
menu.add_toggle(MenuMain, "涡轮增压", true)
menu_root:add_sameline()
menu.add_toggle(MenuMain, "属性强化", true, "(提高防炸性等)")

menu.add_input_float(MenuMain, "载具受伤倍数", 0.5, "[ 0.0 ~ 1.0 ]")
menu_root:add_text("(数值越低，受到的伤害就越低)")

menu_root:add_button("强化当前或上一辆载具", function()
    local vehicle = get_user_vehicle()
    if vehicle == 0 then
        notify("强化载具", "请先进入一辆载具")
        return
    end

    if MenuMain["性能升级"]:is_enabled() then
        for _, mod_type in pairs({ 11, 12, 13, 16 }) do
            local mod_num = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, mod_type)
            VEHICLE.SET_VEHICLE_MOD(vehicle, mod_type, mod_num - 1, false)
        end
    end
    if MenuMain["涡轮增压"]:is_enabled() then
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
    end
    if MenuMain["属性强化"]:is_enabled() then
        strong_vehicle(vehicle)
    end

    local damage_scale = menu.get_input_value(MenuMain["载具受伤倍数"], 0.0, 1.0)
    VEHICLE.SET_VEHICLE_DAMAGE_SCALE(vehicle, damage_scale)
    VEHICLE.SET_VEHICLE_WEAPON_DAMAGE_SCALE(vehicle, damage_scale)

    notify("强化载具", "完成！")
end)
menu_root:add_sameline()
menu_root:add_button("弱化当前或上一辆载具", function()
    local vehicle = get_user_vehicle()
    if vehicle == 0 then
        notify("弱化载具", "请先进入一辆载具")
        return
    end

    for i = 0, 5 do
        if VEHICLE.GET_IS_DOOR_VALID(vehicle, i) then
            VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(vehicle, i, true)
        end
    end
    VEHICLE.SET_VEHICLE_HAS_UNBREAKABLE_LIGHTS(vehicle, false)
    VEHICLE.SET_VEHICLE_CAN_BREAK(vehicle, true)

    ENTITY.SET_ENTITY_MAX_HEALTH(vehicle, 1000)
    SET_ENTITY_HEALTH(vehicle, 1000)

    VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000)
    VEHICLE.SET_VEHICLE_BODY_HEALTH(vehicle, 1000)
    VEHICLE.SET_VEHICLE_PETROL_TANK_HEALTH(vehicle, 1000)
    VEHICLE.SET_HELI_MAIN_ROTOR_HEALTH(vehicle, 1000)
    VEHICLE.SET_HELI_TAIL_ROTOR_HEALTH(vehicle, 1000)

    VEHICLE.SET_VEHICLE_DAMAGE_SCALE(vehicle, 1.0)
    VEHICLE.SET_VEHICLE_WEAPON_DAMAGE_SCALE(vehicle, 1.0)

    VEHICLE.SET_VEHICLE_NO_EXPLOSION_DAMAGE_FROM_DRIVER(vehicle, false)

    VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(vehicle, true)

    VEHICLE.SET_VEHICLE_CAN_ENGINE_MISSFIRE(vehicle, true)
    VEHICLE.SET_VEHICLE_CAN_LEAK_OIL(vehicle, true)
    VEHICLE.SET_VEHICLE_CAN_LEAK_PETROL(vehicle, true)

    VEHICLE.SET_DISABLE_VEHICLE_ENGINE_FIRES(vehicle, false)
    VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(vehicle, false)
    VEHICLE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(vehicle, false)

    VEHICLE.SET_VEHICLE_STRONG(vehicle, false)
    VEHICLE.SET_VEHICLE_HAS_STRONG_AXLES(vehicle, false)

    VEHICLE.VEHICLE_SET_RAMP_AND_RAMMING_CARS_TAKE_DAMAGE(vehicle, true)
    VEHICLE.SET_INCREASE_WHEEL_CRUSH_DAMAGE(vehicle, true)
    VEHICLE.SET_DISABLE_DAMAGE_WITH_PICKED_UP_ENTITY(vehicle, 0)
    VEHICLE.SET_VEHICLE_USES_MP_PLAYER_DAMAGE_MULTIPLIER(vehicle, 0)
    VEHICLE.SET_FORCE_VEHICLE_ENGINE_DAMAGE_BY_BULLET(vehicle, true)

    VEHICLE.SET_DISABLE_EXPLODE_FROM_BODY_DAMAGE_ON_COLLISION(vehicle, 0)
    VEHICLE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(vehicle, true)
    VEHICLE.SET_VEHICLE_EXPLODES_ON_EXPLOSION_DAMAGE_AT_ZERO_BODY_HEALTH(vehicle, true)

    VEHICLE.SET_HELI_TAIL_BOOM_CAN_BREAK_OFF(vehicle, true)
    VEHICLE.SET_DISABLE_HELI_EXPLODE_FROM_BODY_DAMAGE(vehicle, 0)

    VEHICLE.SET_PLANE_RESIST_TO_EXPLOSION(vehicle, false)
    VEHICLE.SET_HELI_RESIST_TO_EXPLOSION(vehicle, false)

    notify("弱化载具", "完成！")
end)

menu_root:add_separator()

----------------
-- 实体
----------------

menu_root:add_text("<<  实体  >>")

local entity_t = {
    npc_type_select = 0
}

function entity_t.check_ped_type(ped)
    if PED.IS_PED_A_PLAYER(ped) then
        return false
    end
    if entity_t.npc_type_select == 0 and not is_friendly_ped(ped) then
        return true
    end
    if entity_t.npc_type_select == 1 and is_hostile_ped(ped) then
        return true
    end
    if entity_t.npc_type_select == 2 then
        return true
    end
    return false
end

function entity_t.is_cop_ped(ped)
    local hash = ENTITY.GET_ENTITY_MODEL(ped)
    return hash == 1581098148 or hash == 2974087609 or hash == 2374966032
end

menu_root:add_imgui(function()
    entity_t.npc_type_select, clicked = ImGui.Combo("选择NPC类型", entity_t.npc_type_select, {
        "全部NPC (排除友好)", "仅敌对NPC", "全部NPC"
    }, 3)
end)

menu_root:add_button("NPC 删除", function()
    script.run_in_fiber(function()
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            if entity_t.check_ped_type(ped) then
                delete_entity(ped)
            end
        end
    end)
end)
menu_root:add_sameline()
menu_root:add_button("NPC 死亡", function()
    script.run_in_fiber(function()
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            if not ENTITY.IS_ENTITY_DEAD(ped) and entity_t.check_ped_type(ped) then
                SET_ENTITY_HEALTH(ped, 0)
            end
        end
    end)
end)
menu_root:add_sameline()
menu_root:add_button("NPC 爆头击杀", function()
    script.run_in_fiber(function()
        local weaponHash = joaat("WEAPON_APPISTOL")
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            if not ENTITY.IS_ENTITY_DEAD(ped) and entity_t.check_ped_type(ped) then
                shoot_ped_head(ped, weaponHash, PLAYER.PLAYER_PED_ID())
            end
        end
    end)
end)

menu_root:add_separator()

menu.add_toggle_loop(MenuMain, "警察 删除", "", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if entity_t.is_cop_ped(ped) then
            delete_entity(ped)
        end
    end
end)
menu_root:add_sameline()
menu.add_toggle_loop(MenuMain, "警察 死亡", "", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if entity_t.is_cop_ped(ped) then
            SET_ENTITY_HEALTH(ped, 0)
        end
    end
end)
menu_root:add_sameline()
menu_root:add_button("友方NPC 无敌强化", function()
    script.run_in_fiber(function()
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            if not ENTITY.IS_ENTITY_DEAD(ped) and not PED.IS_PED_A_PLAYER(ped) then
                if is_friendly_ped(ped) then
                    strong_ped_combat(ped, true)
                end
            end
        end
    end)
end)
menu_root:add_sameline()
menu_root:add_button("友方NPC 给予武器", function()
    script.run_in_fiber(function()
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            if not ENTITY.IS_ENTITY_DEAD(ped) and not PED.IS_PED_A_PLAYER(ped) then
                if is_friendly_ped(ped) then
                    for _, weaponHash in pairs(T.CommonWeapons) do
                        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped, weaponHash, -1, false)
                    end
                end
            end
        end
    end)
end)

menu_root:add_separator()

menu_root:add_text("敌对实体")
menu_root:add_button("爆炸敌对NPC", function()
    script.run_in_fiber(function()
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            if is_hostile_entity(ped) then
                local coords = ENTITY.GET_ENTITY_COORDS(ped)
                FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                    4, 100.0, false, false, 0.0)
            end
        end
    end)
end)
menu_root:add_sameline()
menu_root:add_button("摧毁敌对载具", function()
    script.run_in_fiber(function()
        for _, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
            if is_hostile_entity(vehicle) then
                SET_ENTITY_HEALTH(vehicle, 0)
                VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000.0)

                local coords = ENTITY.GET_ENTITY_COORDS(vehicle)
                FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                    4, 100.0, false, false, 0.0)
            end
        end
    end)
end)
menu_root:add_sameline()
menu_root:add_button("摧毁敌对物体", function()
    script.run_in_fiber(function()
        for _, object in pairs(entities.get_all_objects_as_handles()) do
            if is_hostile_entity(object) then
                SET_ENTITY_HEALTH(object, 0)

                local coords = ENTITY.GET_ENTITY_COORDS(object)
                FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                    4, 100.0, false, false, 0.0)
            end
        end
    end)
end)

menu_root:add_separator()

menu_root:add_text("拾取物")
menu.add_toggle(MenuMain, "仅任务拾取物", true)
menu_root:add_sameline()
menu_root:add_button("拾取物 传送到我", function()
    script.run_in_fiber(function()
        for _, pickup in pairs(get_all_pickups_as_handles()) do
            if MenuMain["仅任务拾取物"]:is_enabled() and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(pickup) then
                goto continue
            end

            OBJECT.SET_PICKUP_OBJECT_COLLECTABLE_IN_VEHICLE(pickup)
            tp_entity_to_me(pickup)

            ::continue::
        end
    end)
end)





----------------------------------------
-- Menu: Mission
----------------------------------------

local menu_mission <const> = menu_root:add_tab("[RS] 任务助手")

local MenuMission = { _parent = menu_mission }

----------------
-- 日常任务
----------------

menu_mission:add_text("<<  日常任务  >>")

menu_mission:add_button("传送到 藏匿屋", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(845)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport(coords)
    else
        notify("传送到藏匿屋", "未在地图上找到藏匿屋")
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("通知藏匿屋密码", function()
    if get_user_interior() == 289793 then
        local code_list = {
            [4221637939] = "01-23-45",
            [1433270535] = "02-12-87",
            [944906360] = "05-02-91",
            [3046060548] = "24-10-81",
            [1626709912] = "28-03-98",
            [921471402] = "28-11-97",
            [3648550039] = "44-23-37",
            [4136820571] = "72-68-83",
            [1083248297] = "73-27-38",
            [2104921722] = "77-79-73",
        }
        for _, obj in pairs(entities.get_all_objects_as_handles()) do
            if ENTITY.IS_ENTITY_A_MISSION_ENTITY(obj) then
                local hash = ENTITY.GET_ENTITY_MODEL(obj)
                if code_list[hash] ~= nil then
                    notify("藏匿屋密码", code_list[hash])
                end
            end
        end
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("传送到 杰拉德包裹", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(842)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport(coords)
    else
        notify("传送到杰拉德包裹", "未在地图上找到杰拉德包裹")
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("进入范围后，传送到包裹", function()
    local entity_list = get_entities_by_hash(ENTITY_OBJECT, true, 138777325, 2674233009, 765087784)
    if next(entity_list) ~= nil then
        for _, ent in pairs(entity_list) do
            tp_to_entity(ent, 0.0, 0.0, 0.5)
        end
    end
end)

menu_mission:add_button("传送到 电脑", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(521)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords.x - 1.0, coords.y + 1.0, coords.z)
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("传送到 夜总会VIP客户", function()
    local blip = HUD.GET_NEXT_BLIP_INFO_ID(480)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords.x, coords.y, coords.z + 0.8)
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("传送到 地图蓝点", function()
    local blip = HUD.GET_NEXT_BLIP_INFO_ID(143)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords.x, coords.y, coords.z + 0.8)
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("出口载具 传送到我", function()
    local blip = HUD.GET_NEXT_BLIP_INFO_ID(143)
    if HUD.DOES_BLIP_EXIST(blip) then
        local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
        if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
            tp_vehicle_to_me(ent)
        end
    end
end)

menu_mission:add_button("打开恐霸电脑", function()
    start_game_script("apphackertruck")
end)
menu_mission:add_sameline()
menu.add_toggle_loop(MenuMission, "跳过NPC对话", "", function()
    if AUDIO.IS_SCRIPTED_CONVERSATION_ONGOING() then
        AUDIO.STOP_SCRIPTED_CONVERSATION(false)
    end
end)
menu_mission:add_sameline()
menu.add_toggle(MenuMission, "自动收集财物", false, "(模拟鼠标左键点击拿取财物，不要一直开启)")

menu_mission:add_separator()

----------------
-- 资产任务
----------------

menu_mission:add_text("<<  资产任务  >>")

menu_mission:add_text("办公室拉货")
menu_mission:add_button("传送到 特种货物", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(478)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("特种货物 传送到我", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_pickups("gb_contraband_buy")
        if next(entity_list) ~= nil then
            OBJECT.SET_MAX_NUM_PORTABLE_PICKUPS_CARRIED_BY_PLAYER(ENTITY.GET_ENTITY_MODEL(entity_list[1]), 3)
            for _, ent in pairs(entity_list) do
                tp_pickup_to_me(ent)
            end
            return
        end

        local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(478)
        if HUD.DOES_BLIP_EXIST(blip) then
            local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
            if ENTITY.DOES_ENTITY_EXIST(ent) then
                set_entity_heading_to_entity(ent, PLAYER.PLAYER_PED_ID())
                tp_entity_to_me(ent)

                if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
                    tp_into_vehicle(ent, "delete", "delete")
                end
            else
                toast("目标不是实体，无法传送到我")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("特种货物(载具) 传送到我", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_OBJECT, "gb_contraband_buy", 2972783418, 2272050386)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if ENTITY.IS_ENTITY_ATTACHED(ent) then
                local attached_ent = ENTITY.GET_ENTITY_ATTACHED_TO(ent)
                if ENTITY.IS_ENTITY_A_VEHICLE(attached_ent) then
                    tp_vehicle_to_me(attached_ent, "delete", "delete")
                end
            end
        end
    end)
end)

menu_mission:add_text("地堡拉货")
menu_mission:add_button("传送到 地堡原材料", function()
    local blip1 = HUD.GET_CLOSEST_BLIP_INFO_ID(556)
    local blip2 = HUD.GET_CLOSEST_BLIP_INFO_ID(561)
    local blip3 = HUD.GET_CLOSEST_BLIP_INFO_ID(477)

    if HUD.DOES_BLIP_EXIST(blip1) then
        local coords = HUD.GET_BLIP_COORDS(blip1)
        teleport2(coords.x, coords.y + 2.0, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip2) then
        local coords = HUD.GET_BLIP_COORDS(blip2)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip3) then
        local coords = HUD.GET_BLIP_COORDS(blip3)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("地堡原材料 传送到我", function()
    script.run_in_fiber(function()
        local blip = HUD.GET_NEXT_BLIP_INFO_ID(556)
        if not HUD.DOES_BLIP_EXIST(blip) then
            local entity_list = get_mission_pickups("gb_gunrunning")
            if next(entity_list) ~= nil then
                for _, ent in pairs(entity_list) do
                    tp_entity_to_me(ent)
                end
            end
            return
        end

        local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            set_entity_heading_to_entity(ent, PLAYER.PLAYER_PED_ID())
            tp_entity_to_me(ent)

            if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
                tp_into_vehicle(ent, "delete", "delete")
            end
        else
            toast("目标不是实体，无法传送到我")
        end
    end)
end)

menu_mission:add_text("机库空运货物")
menu_mission:add_button("传送到 机库空运货物", function()
    local blip = HUD.GET_NEXT_BLIP_INFO_ID(568)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("机库空运货物 传送到我", function()
    script.run_in_fiber(function()
        for _, ent in pairs(get_all_pickups_as_handles()) do
            if ENTITY.IS_ENTITY_A_MISSION_ENTITY(ent) then
                local entity_script = GET_ENTITY_SCRIPT(ent)
                if entity_script == "gb_smuggler" or entity_script == "fm_content_smuggler_resupply" then
                    tp_pickup_to_me(ent)
                end
            end
        end
    end)
end)

menu_mission:add_text("摩托帮工厂")
menu_mission:add_button("传送到 工厂原材料", function()
    local blip1 = HUD.GET_CLOSEST_BLIP_INFO_ID(501)
    local blip2 = HUD.GET_CLOSEST_BLIP_INFO_ID(64)
    local blip3 = HUD.GET_CLOSEST_BLIP_INFO_ID(427)
    local blip4 = HUD.GET_CLOSEST_BLIP_INFO_ID(423)

    if HUD.DOES_BLIP_EXIST(blip1) then
        local coords = HUD.GET_BLIP_COORDS(blip1)
        teleport2(coords.x, coords.y - 1.5, coords.z)
    elseif HUD.DOES_BLIP_EXIST(blip2) then
        local coords = HUD.GET_BLIP_COORDS(blip2)
        teleport2(coords.x, coords.y - 1.5, coords.z)
    elseif HUD.DOES_BLIP_EXIST(blip3) then
        local coords = HUD.GET_BLIP_COORDS(blip3)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip4) then
        local coords = HUD.GET_BLIP_COORDS(blip4)
        teleport2(coords.x, coords.y + 1.5, coords.z - 1.0)
    end
end)
menu_mission:add_sameline()
menu_mission:add_button("工厂原材料 传送到我", function()
    script.run_in_fiber(function()
        local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(501)
        if HUD.DOES_BLIP_EXIST(blip) then
            local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
            if ENTITY.DOES_ENTITY_EXIST(ent) then
                set_entity_heading_to_entity(ent, PLAYER.PLAYER_PED_ID())
                tp_entity_to_me(ent)

                if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
                    tp_into_vehicle(ent, "delete", "delete")
                end
            else
                toast("目标不是实体，无法传送到我")
            end
        end
    end)
end)

menu_mission:add_separator()

----------------
-- 佩里科岛抢劫
----------------

menu_mission:add_text("<<  佩里科岛抢劫  >>")
menu_mission:add_button("摧毁主要目标玻璃柜、保险箱 (会在豪宅外生成主要目标包裹)", function()
    script.run_in_fiber(function()
        local entity_list = get_entities_by_hash(ENTITY_OBJECT, false, 2580434079, 1098122770)
        if next(entity_list) ~= nil then
            for _, ent in pairs(entity_list) do
                if request_control2(ent) then
                    SET_ENTITY_HEALTH(ent, 0)
                end
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("主要目标掉落包裹 传送到我", function()
    script.run_in_fiber(function()
        local blip = HUD.GET_NEXT_BLIP_INFO_ID(765)
        if HUD.DOES_BLIP_EXIST(blip) then
            local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
            if ENTITY.DOES_ENTITY_EXIST(ent) then
                if request_control2(ent) then
                    tp_entity_to_me(ent)
                end
            end
        end
    end)
end)

local CayoPericoDoors = {
    joaat("h4_prop_h4_gate_l_01a"),
    joaat("h4_prop_h4_gate_r_01a"),
    joaat("h4_prop_h4_gate_02a"),
    joaat("h4_prop_h4_gate_03a"),
    joaat("h4_prop_h4_gate_05a"),
    joaat("v_ilev_garageliftdoor"),
    joaat("h4_prop_office_elevator_door_01"),
    joaat("h4_prop_h4_gate_r_03a"),
    joaat("h4_prop_h4_gate_l_03a"),
    joaat("prop_fnclink_02gate6_r"),
    joaat("prop_fnclink_02gate6_l"),
    joaat("h4_prop_h4_garage_door_01a"),
    joaat("prop_fnclink_03gate5")
}
menu_mission:add_button("删除门 (仅本地)", function()
    script.run_in_fiber(function()
        for _, obj in pairs(entities.get_all_objects_as_handles()) do
            local objHash = ENTITY.GET_ENTITY_MODEL(obj)
            for __, hash in pairs(CayoPericoDoors) do
                if objHash == hash then
                    delete_entity(obj)
                end
            end
        end
    end)
end)

menu_mission:add_separator()

----------------
-- 公寓抢劫
----------------

menu_mission:add_text("<<  公寓抢劫  >>")

menu_mission:add_text("越狱")
menu_mission:add_button("梅杜莎飞机 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 1077420264)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("秃鹰直升机 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 788747387)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("敌对天煞 冻结", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 3013282534)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                ENTITY.FREEZE_ENTITY_POSITION(ent, true)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("光头 无敌强化", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_PED, "fm_mission_controller", 940330470)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                strong_ped_combat(ent, true)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("光头 传送进美杜莎", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 1077420264)
        if next(entity_list) == nil then
            return
        end
        local velum2 = entity_list[1]

        entity_list = get_mission_entities_by_hash(ENTITY_PED, "fm_mission_controller", 940330470)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                PED.SET_PED_INTO_VEHICLE(ent, velum2, 0)

                toast("完成！")
            end
        end
    end)
end)

menu_mission:add_text("突袭人道实验室")
menu_mission:add_button("九头蛇 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 970385471)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("天煞(没有人驾驶的) 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 30132825342)
        if next(entity_list) == nil then
            return
        end

        local i = 0
        for _, ent in pairs(entity_list) do
            if VEHICLE.IS_VEHICLE_SEAT_FREE(ent, -1, true) then
                request_control(ent)
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                if has_control_entity(ent) then
                    i = i + 1
                end
            end
        end
        toast("完成！\n数量: " .. i)
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("女武神直升机 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 2694714877)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)

menu_mission:add_text("首轮募资")
menu_mission:add_button("穿梭者直升机 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 744705981)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("油罐车 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 1956216962)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)

menu_mission:add_text("太平洋标准银行")
menu_mission:add_button("厢型车 添加地图标记点", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 444171386)
        if next(entity_list) == nil then
            return
        end

        local blip_sprite = 535 -- radar_target_a
        for _, ent in pairs(entity_list) do
            local blip = HUD.GET_BLIP_FROM_ENTITY(ent)
            if not HUD.DOES_BLIP_EXIST(blip) then
                blip = HUD.ADD_BLIP_FOR_ENTITY(ent)
                HUD.SET_BLIP_SPRITE(blip, blip_sprite)
                HUD.SET_BLIP_COLOUR(blip, 5) -- Yellow
                HUD.SET_BLIP_SCALE(blip, 0.8)
            end

            blip_sprite = blip_sprite + 1
        end
        toast("完成！")
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("厢型车司机 传送到天上", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 444171386)
        if next(entity_list) == nil then
            return
        end

        local i = 0
        for _, ent in pairs(entity_list) do
            local ped = GET_PED_IN_VEHICLE_SEAT(ent, -1)
            if ped ~= 0 and not PED.IS_PED_A_PLAYER(ped) then
                request_control(ped)

                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                set_entity_move(ped, 0.0, 0.0, 500.0)
                ENTITY.FREEZE_ENTITY_POSITION(ped, true)

                if has_control_entity(ped) then
                    i = i + 1
                end
            end
        end
        toast("完成！\n数量: " .. i)
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("车队卡车 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 630371791)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("雷克卓摩托车 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 640818791)
        if next(entity_list) == nil then
            return
        end

        local i = 0
        for _, ent in pairs(entity_list) do
            request_control(ent, 500)

            set_entity_godmode(ent, true)
            upgrade_vehicle(ent)
            strong_vehicle(ent)

            if has_control_entity(ent) then
                i = i + 1
            end
        end
        toast("完成！\n数量: " .. i)
    end)
end)

menu_mission:add_separator()

----------------
-- 末日豪劫
----------------

menu_mission:add_text("<<  末日豪劫  >>")

menu_mission:add_button("14号探员 无敌强化", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_PED, "fm_mission_controller", 4227433577)
        if next(entity_list) == nil then
            return
        end

        local weaponHash = util.joaat("WEAPON_SPECIALCARBINE")

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped, weaponHash, -1, true)
                strong_ped_combat(ent, true)

                toast("完成！")
            end
        end
    end)
end)
menu_mission:add_sameline()
menu_mission:add_button("护送ULP直升机 无敌", function()
    script.run_in_fiber(function()
        local entity_list = get_mission_entities_by_hash(ENTITY_VEHICLE, "fm_mission_controller", 2310691317)
        if next(entity_list) == nil then
            return
        end

        for _, ent in pairs(entity_list) do
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                toast("完成！")
            end
        end
    end)
end)





----------------------------------------
-- Menu: Mission Vehicle
----------------------------------------

local menu_mission_vehicle <const> = menu_root:add_tab("[RS] 任务载具助手")

local HeistMissionVehicle = {
    vehicleList = {},
    updateVehicleList = false,

    replaceVehicles = {
        { joaat("oppressor2"), get_label_text("oppressor2") },

        { joaat("kuruma2"),    get_label_text("kuruma2") },
        { joaat("toreador"),   get_label_text("toreador") },
        { joaat("insurgent3"), get_label_text("insurgent3") },
        { joaat("deluxo"),     get_label_text("deluxo") },
        { joaat("vigilante"),  get_label_text("vigilante") },

        { joaat("krieger"),    get_label_text("krieger") },
        { joaat("t20"),        get_label_text("t20") },

        { joaat("Lazer"),      get_label_text("Lazer") },
        { joaat("hydra"),      get_label_text("hydra") },
        { joaat("raiju"),      get_label_text("raiju") },
        { joaat("buzzard"),    get_label_text("buzzard") },

        { joaat("khanjali"),   get_label_text("khanjali") },
        { joaat("phantom2"),   get_label_text("phantom2") },
    },
    replaceVehicleHash = {},
    replaceVehicleList = {},

    vehicleData = {}
}

function HeistMissionVehicle.getVehicleList()
    local script_name = get_running_mission_controller_script()
    if script_name == nil then
        return {}
    end

    local vehicle_list = {}
    for _, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
        if ENTITY.IS_ENTITY_A_MISSION_ENTITY(vehicle) then
            if GET_ENTITY_SCRIPT(vehicle) == script_name then
                table.insert(vehicle_list, vehicle)
            end
        end
    end
    return vehicle_list
end

function HeistMissionVehicle.getDriverName(vehicle)
    local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false)

    if PED.IS_PED_A_PLAYER(driver) then
        local player_id = get_player_from_ped(driver)
        return PLAYER.GET_PLAYER_NAME(player_id)
    end

    local driver_hash = ENTITY.GET_ENTITY_MODEL(driver)
    local driver_model = reverse_ped_hash(driver_hash)
    if driver_model == "" then
        return driver_hash .. " [NPC]"
    end
    return driver_model .. " [NPC]"
end

function HeistMissionVehicle.getVehicleInfo(vehicle, index)
    local title = index .. ". " .. get_vehicle_display_name(vehicle)
    local textList = {}

    if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, -1, false) then
        table.insert(textList, "司机: " .. HeistMissionVehicle.getDriverName(vehicle))
    end

    local blip = HUD.GET_BLIP_FROM_ENTITY(vehicle)
    if HUD.DOES_BLIP_EXIST(blip) then
        local blip_sprite = HUD.GET_BLIP_SPRITE(blip)
        if blip_sprite == 1 then
            title = title .. " [目标点]"
        else
            title = title .. " [标记点]"
        end

        local blip_colour = HUD.GET_BLIP_COLOUR(blip)
        if blip_colour == 54 then
            table.insert(textList, "BLIP_COLOUR_BLUEDARK")
        end
    end

    if vehicle == PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) then
        if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
            title = title .. " [当前载具]"
        else
            title = title .. " [上一辆载具]"
        end
    end

    local owner = get_entity_owner(vehicle)
    table.insert(textList, "控制权: " .. PLAYER.GET_PLAYER_NAME(owner))
    table.insert(textList, "乘客数: " .. VEHICLE.GET_VEHICLE_NUMBER_OF_PASSENGERS(vehicle, false, false))

    return title, textList
end

function HeistMissionVehicle.getNetIdAddr(vehicle, script_name)
    local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(vehicle)
    if not NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netId) then
        return 0
    end

    for i = 0, 31, 1 do
        local addr = Locals[script_name].sFMMC_SBD.niVehicle + i
        if locals.get_int(script_name, addr) == netId then
            return addr
        end
    end

    return 0
end

function HeistMissionVehicle.replaceVehicle(vehicle, hash)
    local coords = ENTITY.GET_ENTITY_COORDS(vehicle)
    local heading = ENTITY.GET_ENTITY_HEADING(vehicle)

    -- 生成替换载具，先放到天上
    local replaceVeh = VEHICLE.CREATE_VEHICLE(hash, coords.x, coords.y, coords.z + 2000, heading, true, true, false)
    ENTITY.FREEZE_ENTITY_POSITION(replaceVeh, true)

    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(replaceVeh, true, false)

    NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(replaceVeh)
    local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(replaceVeh)
    if not NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netId) then
        -- 没有成功获得 net id
        delete_entity(replaceVeh)
        return 0
    end

    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netId, true)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
    NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netId, PLAYER.PLAYER_ID(), true)


    strong_vehicle(replaceVeh)
    upgrade_vehicle(replaceVeh)

    -- 传送原载具到其它地方
    ENTITY.DETACH_ENTITY(vehicle, false, false)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)
    ENTITY.SET_ENTITY_COLLISION(vehicle, false, false)
    TP_ENTITY(vehicle, vec3:new(7000, 7000, -100))

    -- 传送替换载具到原载具位置
    TP_ENTITY(replaceVeh, coords)
    ENTITY.FREEZE_ENTITY_POSITION(replaceVeh, false)

    return netId
end

function HeistMissionVehicle.init()
    for key, item in pairs(HeistMissionVehicle.replaceVehicles) do
        HeistMissionVehicle.replaceVehicleHash[key] = item[1]
        HeistMissionVehicle.replaceVehicleList[key] = item[2]
    end
end

HeistMissionVehicle.init()

menu_mission_vehicle:add_imgui(function()
    if ImGui.Button("刷新载具列表", 320, 48) then
        HeistMissionVehicle.updateVehicleList = true
    end

    -- 刷新载具列表
    if HeistMissionVehicle.updateVehicleList then
        HeistMissionVehicle.vehicleList = HeistMissionVehicle.getVehicleList()

        HeistMissionVehicle.updateVehicleList = false
        HeistMissionVehicle.vehicleData = {}
    end

    if next(HeistMissionVehicle.vehicleList) == nil then
        return
    end

    for index, vehicle in pairs(HeistMissionVehicle.vehicleList) do
        if not ENTITY.DOES_ENTITY_EXIST(vehicle) then
            goto continue
        end

        -- 初始化每个载具的数据
        if HeistMissionVehicle.vehicleData[index] == nil then
            HeistMissionVehicle.vehicleData[index] = {
                isDrawLine = false,
                replaceVehicleSelect = 0
            }
        end

        -- 获取载具基本信息
        local title, textList = HeistMissionVehicle.getVehicleInfo(vehicle, index)

        ImGui.Spacing()
        if ImGui.TreeNode(title) then
            ImGui.Spacing()

            for _, text in pairs(textList) do
                ImGui.BulletText(text)
            end
            ImGui.Spacing()


            HeistMissionVehicle.vehicleData[index].isDrawLine = ImGui.Checkbox("绘制连线",
                HeistMissionVehicle.vehicleData[index].isDrawLine)
            if HeistMissionVehicle.vehicleData[index].isDrawLine then
                draw_line_to_entity(vehicle)
            end
            ImGui.SameLine()
            if ImGui.Button("请求控制", 96, 32) then
                script.run_in_fiber(function()
                    if request_control(vehicle) then
                        toast("请求控制实体成功！")
                    else
                        toast("请求控制实体失败，请重试")
                    end
                end)
            end

            if ImGui.Button("无敌") then
                set_entity_godmode(vehicle, true)
            end
            ImGui.SameLine()
            if ImGui.Button("强化") then
                strong_vehicle(vehicle)
            end
            ImGui.SameLine()
            if ImGui.Button("升级") then
                upgrade_vehicle(vehicle)
            end

            if ImGui.Button("传送到 我并驾驶") then
                local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
                if ENTITY.IS_ENTITY_A_PED(ped) then
                    set_entity_move(ped, 0.0, 0.0, 3.0)
                end
                ENTITY_HEADING(vehicle, user_heading())
                tp_entity_to_me(vehicle)
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, -1)
            end

            if ImGui.Button("传送进 驾驶位") then
                local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
                if ENTITY.IS_ENTITY_A_PED(ped) then
                    set_entity_move(ped, 0.0, 0.0, 3.0)
                end
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, -1)
            end
            ImGui.SameLine()
            if ImGui.Button("传送进 副驾驶位") then
                if VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) > 0 then
                    local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, 0)
                    if ENTITY.IS_ENTITY_A_PED(ped) then
                        set_entity_move(ped, 0.0, 0.0, 3.0)
                    end
                    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, 0)
                else
                    toast("载具无副驾驶位")
                end
            end
            ImGui.SameLine()
            if ImGui.Button("传送进 空座位") then
                if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(vehicle) then
                    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, -2)
                else
                    toast("载具已无空座位")
                end
            end

            ImGui.Spacing()

            HeistMissionVehicle.vehicleData[index].replaceVehicleSelect = ImGui.Combo("选择替换载具",
                HeistMissionVehicle.vehicleData[index].replaceVehicleSelect,
                HeistMissionVehicle.replaceVehicleList, 14, 5)

            if ImGui.Button("替换载具", 128, 32) then
                script.run_in_fiber(function(script_util)
                    if is_any_player_in_vehicle(vehicle) then
                        notify("替换载具", "有玩家在该载具内")
                        return
                    end

                    local script_name = get_running_mission_controller_script()

                    if NETWORK.NETWORK_GET_HOST_OF_SCRIPT(script_name, 0, 0) ~= PLAYER.PLAYER_ID() then
                        network.force_script_host(script_name)
                        script_util:yield()
                        if NETWORK.NETWORK_GET_HOST_OF_SCRIPT(script_name, 0, 0) ~= PLAYER.PLAYER_ID() then
                            notify("替换载具", "成为脚本主机失败，请重试")
                            return
                        end
                    end

                    if not request_control(vehicle) then
                        notify("替换载具", "请求控制载具失败，请重试")
                        return
                    end


                    local hash = HeistMissionVehicle.replaceVehicleHash
                        [HeistMissionVehicle.vehicleData[index].replaceVehicleSelect + 1]

                    STREAMING.REQUEST_MODEL(hash)
                    while not STREAMING.HAS_MODEL_LOADED(hash) do
                        STREAMING.REQUEST_MODEL(hash)
                        script_util:yield()
                    end

                    script.execute_as_script(script_name, function()
                        local netIdAddr = HeistMissionVehicle.getNetIdAddr(vehicle, script_name)
                        if netIdAddr == 0 then
                            return
                        end

                        local netId = HeistMissionVehicle.replaceVehicle(vehicle, hash)
                        if netId == 0 then
                            return
                        end

                        locals.set_int(script_name, netIdAddr, netId)
                        notify("替换载具", "完成！")
                    end)

                    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
                end)
            end


            ImGui.Spacing()
            ImGui.Separator()
            ImGui.TreePop()
        end


        ::continue::
    end
end)





----------------------------------------
-- Menu: Manage Entity
----------------------------------------

local menu_manage_entity <const> = menu_root:add_tab("[RS] 管理实体")

local menu_vehicle_list <const> = menu_manage_entity:add_tab(" >> 载具列表")
local menu_ped_list <const> = menu_manage_entity:add_tab(" >> NPC列表")

local MenuManageEntity = { _parent = menu_manage_entity }

local ManageEntityTab = {}


local manage_entity = {
    gui = {},
    ["vehicle"] = {
        enable = false,
        ent = 0,
        ent_name = "无",
        guis = {},
    },
    ["ped"] = {
        enable = false,
        ent = 0,
        ent_name = "无",
        guis = {},
    },
}

function manage_entity.gui.info(tab, entity_type)
    local gui_table = manage_entity[entity_type].guis

    tab:add_text("在下方点击选择一个实体，然后进行实体控制；对于网络实体需要先请求控制")
    tab:add_separator()
    ----------

    gui_table["ent_name"] = tab:add_text("当前选择实体: 无")
    tab:add_sameline()
    gui_table["ent_exist"] = tab:add_text("")

    gui_table["hash"] = tab:add_text("Hash: 0")
    tab:add_sameline()
    gui_table["index"] = tab:add_text("Index: 0")
    tab:add_sameline()
    gui_table["model"] = tab:add_text("Model: 0")
    gui_table["coords"] = tab:add_text("坐标: x = 0.0, y = 0.0, z = 0.0")
    gui_table["health"] = tab:add_text("血量: 0/0")
    tab:add_sameline()
    gui_table["distance"] = tab:add_text("距离: 0.0")
    tab:add_sameline()
    gui_table["speed"] = tab:add_text("速度: 0.0")
    tab:add_sameline()
    gui_table["owner"] = tab:add_text("控制权: 无")
    gui_table["display_name"] = tab:add_text("载具: 无")
    tab:add_sameline()
    gui_table["script"] = tab:add_text("脚本: 无")
end

function manage_entity.gui.entity(tab, entity_type)
    local gui_table = manage_entity[entity_type].guis

    manage_entity.gui.info(tab, entity_type)

    tab:add_separator()
    tab:add_text("实体选项")

    tab:add_button("无敌", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            set_entity_godmode(ent, true)
        end
    end)
    tab:add_sameline()
    tab:add_button("取消无敌", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            set_entity_godmode(ent, false)
        end
    end)
    tab:add_sameline()
    tab:add_button("冻结", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            ENTITY.FREEZE_ENTITY_POSITION(ent, false)
        end
    end)
    tab:add_sameline()
    tab:add_button("取消冻结", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            ENTITY.FREEZE_ENTITY_POSITION(ent, false)
        end
    end)
    tab:add_sameline()
    tab:add_button("爆炸", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local coords = ENTITY.GET_ENTITY_COORDS(ent)
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 4, 1000.0, true, false, 0.0, false)
        end
    end)

    tab:add_button("请求控制", function()
        script.run_in_fiber(function()
            local ent = manage_entity[entity_type].ent
            if ENTITY.DOES_ENTITY_EXIST(ent) then
                if request_control(ent) then
                    notify("请求控制实体", "成功")
                else
                    notify("请求控制实体", "失败，请重试")
                end
            end
        end)
    end)
    tab:add_sameline()
    tab:add_button("设置为任务实体", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, true, false)

            notify("设置为任务实体", ENTITY.IS_ENTITY_A_MISSION_ENTITY(ent) and "成功" or "失败")
        end
    end)
    tab:add_sameline()
    tab:add_button("设置为网络实体", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) and is_in_session() then
            NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(ent)
            local net_id = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(ent)
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
            NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(net_id, PLAYER.PLAYER_ID(), true)

            notify("设置为网络实体", NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(ent) and "成功" or "失败")
        end
    end)
    tab:add_sameline()
    tab:add_button("删除", function()
        script.run_in_fiber(function()
            local ent = manage_entity[entity_type].ent
            if ENTITY.DOES_ENTITY_EXIST(ent) then
                if PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), ent, true) then
                    TP_ENTITY(PLAYER.PLAYER_PED_ID(), ENTITY.GET_ENTITY_COORDS(ent))
                end
                delete_entity(ent)
            end
        end)
    end)

    ----------
    tabs.add_input_int(tab, "实体血量", gui_table, 1000)
    tab:add_button("设置当前血量", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local value = gui_table["实体血量"]:get_value()
            if value >= 0 then
                SET_ENTITY_HEALTH(ent, value)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("设置最大血量", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local value = gui_table["实体血量"]:get_value()
            if value >= 0 then
                ENTITY.SET_ENTITY_MAX_HEALTH(ent, value)
            end
        end
    end)

    ----------
    tab:add_separator()
    tab:add_text("传送选项")
    tabs.add_input_float(tab, "前/后", gui_table, 2.0)
    tabs.add_input_float(tab, "左/右", gui_table)
    tabs.add_input_float(tab, "上/下", gui_table)

    tab:add_button("传送到我", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local tp_y = gui_table["前/后"]:get_value()
            local tp_x = gui_table["左/右"]:get_value()
            local tp_z = gui_table["上/下"]:get_value()

            tp_entity_to_me(ent, tp_x, tp_y, tp_z)
        end
    end)
    tab:add_sameline()
    tab:add_button("传送到实体", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local tp_y = gui_table["前/后"]:get_value()
            local tp_x = gui_table["左/右"]:get_value()
            local tp_z = gui_table["上/下"]:get_value()

            tp_to_entity(ent, tp_x, tp_y, tp_z)
        end
    end)

    ----------
    if entity_type == "vehicle" then
        manage_entity.gui.vehicle(tab)
    elseif entity_type == "ped" then
        manage_entity.gui.ped(tab)
    end

    ----------
    tab:add_separator()
    tab:add_text("实体列表")
end

function manage_entity.gui.vehicle(tab)
    local entity_type = "vehicle"
    local gui_table = manage_entity[entity_type].guis

    tab:add_separator()
    tab:add_text("载具选项")

    tab:add_button("传送进载具", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(ent) then
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ent, -2)
            else
                notify("传送进载具", "载具已无空座位")
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("传送进驾驶位", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
            if ENTITY.IS_ENTITY_A_PED(ped) then
                set_entity_move(ped, 0.0, 0.0, 3.0)
            end
            PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ent, -1)
        end
    end)
    tab:add_sameline()
    tab:add_button("传送进副驾驶位", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            if VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(ent) > 0 then
                local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, 0)
                if ENTITY.IS_ENTITY_A_PED(ped) then
                    set_entity_move(ped, 0.0, 0.0, 3.0)
                end
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), ent, 0)
            else
                notify("传送进副驾驶位", "载具无副驾驶位")
            end
        end
    end)

    tab:add_button("修复载具", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            fix_vehicle(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("升级载具", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            upgrade_vehicle(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("强化载具", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            strong_vehicle(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("平放载具", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(ent, 5.0)
        end
    end)

    tabs.add_input_float(tab, "速度", gui_table, 30)
    tab:add_sameline()
    tab:add_button("向前加速", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local value = gui_table["速度"]:get_value()
            if value >= 0 then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(ent, value)
            end
        end
    end)

    tab:add_button("删除车窗", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 7 do
                VEHICLE.REMOVE_VEHICLE_WINDOW(ent, i)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("摇下车窗", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 7 do
                VEHICLE.ROLL_DOWN_WINDOW(ent, i)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("摇上车窗", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 7 do
                VEHICLE.ROLL_UP_WINDOW(ent, i)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("粉碎车窗", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 7 do
                VEHICLE.SMASH_VEHICLE_WINDOW(ent, i)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("修复车窗", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 7 do
                VEHICLE.FIX_VEHICLE_WINDOW(ent, i)
            end
        end
    end)

    tab:add_button("打开车门", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 3 do
                VEHICLE.SET_VEHICLE_DOOR_OPEN(ent, i, false, false)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("关闭车门", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            VEHICLE.SET_VEHICLE_DOORS_SHUT(ent, false)
        end
    end)
    tab:add_sameline()
    tab:add_button("拆下车门", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            VEHICLE.SET_VEHICLE_DOOR_BROKEN(ent, i, false)
        end
    end)
    tab:add_sameline()
    tab:add_button("删除车门", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            VEHICLE.SET_VEHICLE_DOOR_BROKEN(ent, i, true)
        end
    end)
    tab:add_sameline()
    tab:add_button("解锁车门", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            unlock_vehicle_doors(ent)
        end
    end)

    tab:add_button("打开引擎", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(ent, true, true, false)
        end
    end)
    tab:add_sameline()
    tab:add_button("关闭引擎", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(ent, false, true, false)
        end
    end)
    tab:add_sameline()
    tab:add_button("爆掉车胎", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 7 do
                VEHICLE.SET_VEHICLE_TYRE_BURST(ent, i, true, 1000.0)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("修复车胎", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for i = 0, 7 do
                VEHICLE.SET_VEHICLE_TYRE_FIXED(ent, i)
            end
        end
    end)
end

function manage_entity.gui.ped(tab)
    local entity_type = "ped"
    local gui_table = manage_entity[entity_type].guis

    tab:add_separator()
    tab:add_text("NPC选项")

    tab:add_button("传送到我的载具", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            local vehicle = get_user_vehicle(false)
            if vehicle ~= 0 then
                if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(vehicle) then
                    PED.SET_PED_INTO_VEHICLE(ent, vehicle, -2)
                else
                    notify("传送到我的载具", "载具已无空座位")
                end
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("燃烧", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            FIRE.START_ENTITY_FIRE(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("停止燃烧", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            FIRE.STOP_ENTITY_FIRE(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("移除全部武器", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            WEAPON.REMOVE_ALL_PED_WEAPONS(ent)
        end
    end)

    tab:add_button("强化作战能力", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            strong_ped_combat(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("给予武器", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            for _, weaponHash in pairs(T.CommonWeapons) do
                WEAPON.GIVE_WEAPON_TO_PED(ent, weaponHash, -1, false, false)
            end
        end
    end)
    tab:add_sameline()
    tab:add_button("清理外观", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            PED.RESET_PED_VISIBLE_DAMAGE(ent)
            PED.CLEAR_PED_LAST_DAMAGE_BONE(ent)
            PED.CLEAR_PED_BLOOD_DAMAGE(ent)
            PED.CLEAR_PED_WETNESS(ent)
            PED.CLEAR_PED_ENV_DIRT(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("复活", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            PED.RESURRECT_PED(ent)
        end
    end)
    tab:add_sameline()
    tab:add_button("中断动作", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ent)
        end
    end)
end

function manage_entity.gui.update_info(entity_type)
    local ent = manage_entity[entity_type].ent
    local gui_table = manage_entity[entity_type].guis

    if not ENTITY.DOES_ENTITY_EXIST(ent) then
        if ent ~= 0 then
            gui_table["ent_exist"]:set_text(" >>> 该实体已不存在")
        end
        return
    end
    gui_table["ent_exist"]:set_text("")

    local hash = ENTITY.GET_ENTITY_MODEL(ent)
    local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    local ent_pos = ENTITY.GET_ENTITY_COORDS(ent)

    gui_table["ent_name"]:set_text("当前选择实体: " .. manage_entity[entity_type].ent_name)
    gui_table["hash"]:set_text("Hash: " .. hash)
    gui_table["index"]:set_text("Index: " .. ent)
    gui_table["coords"]:set_text(string.format("坐标: x = %.4f, y = %.4f, z = %.4f",
        ent_pos.x, ent_pos.y, ent_pos.z))
    gui_table["distance"]:set_text("距离: " .. string.format("%.4f", v3.distance(my_pos, ent_pos)))
    gui_table["health"]:set_text(string.format("血量: %d/%d",
        ENTITY.GET_ENTITY_HEALTH(ent), ENTITY.GET_ENTITY_MAX_HEALTH(ent)))
    gui_table["speed"]:set_text("速度: " .. string.format("%.4f", ENTITY.GET_ENTITY_SPEED(ent)))
    gui_table["owner"]:set_text("控制权: " .. PLAYER.GET_PLAYER_NAME(get_entity_owner(ent)))

    if entity_type == "vehicle" then
        gui_table["model"]:set_text("Model: " .. reverse_vehicle_hash(hash))
        gui_table["display_name"]:set_text("载具: " .. get_vehicle_display_name_by_hash(hash))
    elseif entity_type == "ped" then
        gui_table["model"]:set_text("Model: " .. reverse_ped_hash(hash))
        local ped_veh = GET_VEHICLE_PED_IS_IN(ent)
        if ped_veh ~= 0 then
            gui_table["display_name"]:set_text("载具: " .. get_vehicle_display_name_by_hash(ent))
        else
            gui_table["display_name"]:set_text("载具: 无")
        end
    end

    local entity_script = GET_ENTITY_SCRIPT(ent)
    if entity_script ~= "" then
        gui_table["script"]:set_text("脚本: " .. entity_script)
    else
        gui_table["script"]:set_text("脚本: 无")
    end
end

function manage_entity.get_entity_info(ent, index)
    local name = index .. ". "
    local info = ""

    local hash = ENTITY.GET_ENTITY_MODEL(ent)

    ----------

    local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    local ent_pos = ENTITY.GET_ENTITY_COORDS(ent)

    info = "距离: " .. string.format("%.2f", v3.distance(my_pos, ent_pos))

    info = info .. ", 速度: " .. string.format("%.2f", ENTITY.GET_ENTITY_SPEED(ent))

    if is_in_session() then
        info = info .. ", 控制权: " .. PLAYER.GET_PLAYER_NAME(get_entity_owner(ent))
    end

    local entity_script = GET_ENTITY_SCRIPT(ent)
    if entity_script ~= "" then
        info = info .. ", 脚本: " .. entity_script
    end

    local blip = HUD.GET_BLIP_FROM_ENTITY(ent)
    if HUD.DOES_BLIP_EXIST(blip) then
        info = info .. ", 标记点: " .. HUD.GET_BLIP_SPRITE(blip)
    end

    if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
        name = name .. get_vehicle_display_name_by_hash(hash)

        if ent == PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false) then
            if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
                name = name .. " [当前载具]"
            else
                name = name .. " [上一辆载具]"
            end
        elseif not VEHICLE.IS_VEHICLE_SEAT_FREE(ent, -1, false) then
            local driver = GET_PED_IN_VEHICLE_SEAT(ent, -1)
            if driver ~= 0 then
                if PED.GET_PED_TYPE(driver) >= 4 then
                    info = info .. ", 司机: NPC"
                else
                    info = info .. ", 司机: 玩家"

                    local driver_player = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(driver)
                    if NETWORK.NETWORK_IS_PLAYER_ACTIVE(driver_player) then
                        name = name .. " [" .. PLAYER.GET_PLAYER_NAME(driver_player) .. "]"
                    end
                end
            end
        end
    else
        local ped_name = reverse_ped_hash(hash)
        if ped_name ~= "" then
            name = name .. ped_name
        else
            name = name .. hash
        end
    end

    if ENTITY.IS_ENTITY_A_PED(ent) then
        if is_friendly_ped(ent) then
            name = name .. " [友好]"
        elseif is_hostile_ped(ent) then
            name = name .. " [敌对]"
        end

        local ped_veh = GET_VEHICLE_PED_IS_IN(ent)
        if ped_veh ~= 0 then
            info = info .. ", 载具: " .. get_vehicle_display_name(ped_veh)
        end
    end

    return name, info
end

function manage_entity.check_match(ent)
    if not ManageEntityTab["禁用筛选: 任务实体"]:is_enabled() then
        if ENTITY.IS_ENTITY_A_MISSION_ENTITY(ent) then
            if not ManageEntityTab["任务实体"]:is_enabled() then
                return false
            end
        else
            if ManageEntityTab["任务实体"]:is_enabled() then
                return false
            end
        end
    end

    if ManageEntityTab["距离"]:get_value() > 0 then
        local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
        local ent_pos = ENTITY.GET_ENTITY_COORDS(ent)
        if v3.distance(my_pos, ent_pos) > ManageEntityTab["距离"]:get_value() then
            return false
        end
    end

    if not ManageEntityTab["禁用筛选: 地图标记点"]:is_enabled() then
        local blip = HUD.GET_BLIP_FROM_ENTITY(ent)
        if HUD.DOES_BLIP_EXIST(blip) then
            if not ManageEntityTab["地图标记点"]:is_enabled() then
                return false
            end
        else
            if ManageEntityTab["地图标记点"]:is_enabled() then
                return false
            end
        end
    end

    if not ManageEntityTab["禁用筛选: 正在移动"]:is_enabled() then
        if ENTITY.GET_ENTITY_SPEED(ent) > 0 then
            if not ManageEntityTab["正在移动"]:is_enabled() then
                return false
            end
        else
            if ManageEntityTab["正在移动"]:is_enabled() then
                return false
            end
        end
    end


    if ENTITY.IS_ENTITY_A_PED(ent) then
        if PED.IS_PED_A_PLAYER(ent) then
            return false
        end

        if not ManageEntityTab["禁用筛选: 与玩家关系"]:is_enabled() then
            if is_hostile_ped(ent) then
                if not ManageEntityTab["与玩家关系"]:is_enabled() then
                    return false
                end
            elseif is_friendly_ped(ent) then
                if ManageEntityTab["与玩家关系"]:is_enabled() then
                    return false
                end
            end
        end

        if not ManageEntityTab["禁用筛选: 在载具内"]:is_enabled() then
            if PED.IS_PED_IN_ANY_VEHICLE(ent, false) then
                if not ManageEntityTab["在载具内"]:is_enabled() then
                    return false
                end
            else
                if ManageEntityTab["在载具内"]:is_enabled() then
                    return false
                end
            end
        end
    end


    if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
        if not ManageEntityTab["禁用筛选: 载具司机"]:is_enabled() then
            if not VEHICLE.IS_VEHICLE_SEAT_FREE(ent, -1, false) then
                if not ManageEntityTab["载具司机"]:is_enabled() then
                    return false
                end
            else
                if ManageEntityTab["载具司机"]:is_enabled() then
                    return false
                end
            end
        end
    end


    -- END
    return true
end

function manage_entity.get_entity_list(entity_type)
    local target_tab = menu_vehicle_list
    local entityType = ENTITY_VEHICLE
    if entity_type == "ped" then
        target_tab = menu_ped_list
        entityType = ENTITY_PED
    end
    target_tab:clear()
    manage_entity[entity_type].ent = 0

    manage_entity.gui.entity(target_tab, entity_type)

    local num = 0
    for key, ent in pairs(get_all_entities(entityType)) do
        if manage_entity.check_match(ent) then
            num = num + 1

            local button_name, button_info = manage_entity.get_entity_info(ent, num)

            target_tab:add_button(button_name, function()
                if ENTITY.DOES_ENTITY_EXIST(ent) then
                    manage_entity[entity_type].ent = ent
                    manage_entity[entity_type].ent_name = button_name
                    notify("选择实体", button_name)
                else
                    notify("选择实体", "该实体已不存在")
                end
            end)
            target_tab:add_sameline()
            target_tab:add_text(button_info)
        end
    end

    if num == 0 then
        target_tab:clear()
        manage_entity[entity_type].enable = false
    else
        manage_entity[entity_type].enable = true
        notify("获取实体列表", "实体数量: " .. num)
    end
end

menu_manage_entity:add_button("获取载具列表", function()
    manage_entity.get_entity_list("vehicle")
end)
menu_manage_entity:add_sameline()
menu_manage_entity:add_button("获取NPC列表", function()
    manage_entity.get_entity_list("ped")
end)
menu_manage_entity:add_sameline()
menu_manage_entity:add_button("清空载具列表", function()
    manage_entity["vehicle"].enable = false
    menu_vehicle_list:clear()
end)
menu_manage_entity:add_sameline()
menu_manage_entity:add_button("清空NPC列表", function()
    manage_entity["ped"].enable = false
    menu_ped_list:clear()
end)
menu_manage_entity:add_separator()

menu_manage_entity:add_text("筛选设置")
tabs.add_checkbox(menu_manage_entity, "任务实体", ManageEntityTab, true, "(是/否)")
menu_manage_entity:add_sameline()
tabs.add_checkbox(menu_manage_entity, "禁用筛选: 任务实体", ManageEntityTab)

tabs.add_input_float(menu_manage_entity, "距离", ManageEntityTab, 0, "(0表示不限制)")

tabs.add_checkbox(menu_manage_entity, "地图标记点", ManageEntityTab, false, "(有/没有)")
menu_manage_entity:add_sameline()
tabs.add_checkbox(menu_manage_entity, "禁用筛选: 地图标记点", ManageEntityTab, true)

tabs.add_checkbox(menu_manage_entity, "正在移动", ManageEntityTab, false, "(是/否)")
menu_manage_entity:add_sameline()
tabs.add_checkbox(menu_manage_entity, "禁用筛选: 正在移动", ManageEntityTab, true)

menu_manage_entity:add_text("NPC")
tabs.add_checkbox(menu_manage_entity, "与玩家关系", ManageEntityTab, false, "(敌对/友好)")
menu_manage_entity:add_sameline()
tabs.add_checkbox(menu_manage_entity, "禁用筛选: 与玩家关系", ManageEntityTab, true)

tabs.add_checkbox(menu_manage_entity, "在载具内", ManageEntityTab, false, "(是/否)")
menu_manage_entity:add_sameline()
tabs.add_checkbox(menu_manage_entity, "禁用筛选: 在载具内", ManageEntityTab, true)

menu_manage_entity:add_text("载具")
tabs.add_checkbox(menu_manage_entity, "载具司机", ManageEntityTab, false, "(有/没有)")
menu_manage_entity:add_sameline()
tabs.add_checkbox(menu_manage_entity, "禁用筛选: 载具司机", ManageEntityTab, true)








--------------------------------
-- Loop Script
--------------------------------


script.register_looped("RScript.Main", function()
    for key, item in pairs(MainLoop) do
        if item.toggle:is_enabled() then
            item.on_tick()

            if item.on_stop ~= nil then
                MainLoop[key].need_to_run_stop = true
            end
        else
            if item.need_to_run_stop then
                item.on_stop()
                MainLoop[key].need_to_run_stop = false
            end
        end
    end
end)


script.register_looped("RScript.AutoCollect", function(script_util)
    if MenuMission["自动收集财物"]:is_enabled() then
        if TASK.GET_IS_TASK_ACTIVE(PLAYER.PLAYER_PED_ID(), 135) then
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(0, 237, 1)
            script_util:sleep(30)
        end
    end
end)


script.register_looped("RScript.ManageEntity", function()
    if manage_entity["vehicle"].enable and menu_vehicle_list:is_selected() then
        manage_entity.gui.update_info("vehicle")
    end

    if manage_entity["ped"].enable and menu_ped_list:is_selected() then
        manage_entity.gui.update_info("ped")
    end
end)
