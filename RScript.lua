-------------------------------
--- Author: Rostal
-------------------------------

require("RScript.tables")

require("RScript.functions")


local function toast(text)
    notify("RScript", tostring(text))
end

local function print(text)
    log.info(tostring(text))
end


--------------------------------
-- Main Tab
--------------------------------

--#region Main Tab

local tab_root <const> = gui.add_tab("RScript")

local MainTab = {}
local MainToggle = {}

----------------
-- 自我
----------------

tab_root:add_text("<<  自我  >>")

tabs.add_input_float(tab_root, "生命恢复速率", MainTab, 1.0, "[ 0.0 ~ 100.0 ]")
tabs.add_input_float(tab_root, "生命恢复程度", MainTab, 0.5, "[ 0.0 ~ 1.0 ]")
tabs.add_checkbox(tab_root, "自定义设置生命恢复", MainTab)
tab_root:add_sameline()
tab_root:add_button("恢复默认生命恢复", function()
    MainTab["自定义设置生命恢复"]:set_enabled(false)
    PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT(PLAYER.PLAYER_ID(), 0.5)
end)
tab_root:add_separator()

tabs.add_input_float(tab_root, "自我受伤倍数", MainTab, 1.0, "[ 0.1 ~ 1.0 ] (数值越低，受到的伤害就越低)")
tabs.add_checkbox(tab_root, "自定义设置受伤倍数", MainTab)
tab_root:add_sameline()
tab_root:add_button("恢复默认受伤倍数", function()
    MainTab["自定义设置受伤倍数"]:set_enabled(false)
    PLAYER.SET_PLAYER_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_WEAPON_MINIGUN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_MELEE_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_VEHICLE_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
    PLAYER.SET_PLAYER_WEAPON_TAKEDOWN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), 1.0)
end)
tab_root:add_separator()

tabs.add_checkbox(tab_root, "步行时人称视角快捷切换", MainTab, false, "第一人称视角和第三人称(近距离)视角快捷切换")
tab_root:add_separator()

----------------
-- 载具
----------------

tab_root:add_text("<<  载具  >>")

tab_root:add_button("无限载具武器弹药", function()
    local vehicle = get_user_vehicle()
    if vehicle ~= 0 and VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(vehicle) then
        for i = 0, 3 do
            local ammo = VEHICLE.GET_VEHICLE_WEAPON_RESTRICTED_AMMO(vehicle, i)
            if ammo ~= -1 then
                VEHICLE.SET_VEHICLE_WEAPON_RESTRICTED_AMMO(vehicle, i, -1)
            end
        end
    end
end)
tab_root:add_sameline()
tabs.add_checkbox(tab_root, "无限动能回收加速", MainTab)
tab_root:add_sameline()
tabs.add_toggle_button(tab_root, "电台只播放音乐", MainToggle, false, function(toggle)
    for _, stationName in pairs(T.VehicleRadioStations) do
        AUDIO.SET_RADIO_STATION_MUSIC_ONLY(stationName, toggle)
    end
end)
tab_root:add_separator()

tabs.add_checkbox(tab_root, "性能升级", MainTab, true)
tab_root:add_sameline()
tabs.add_checkbox(tab_root, "涡轮增压", MainTab, true)
tab_root:add_sameline()
tabs.add_checkbox(tab_root, "属性强化", MainTab, true, "(提高防炸性等)")
tabs.add_input_float(tab_root, "载具受伤倍数", MainTab, 0.5, "[ 0.0 ~ 1.0 ] (数值越低，受到的伤害就越低)")

tab_root:add_button("强化当前载具", function()
    local vehicle = get_user_vehicle(false)
    if vehicle == 0 then
        notify("强化当前载具", "请先进入一辆载具")
    end

    if MainTab["性能升级"]:is_enabled() then
        for _, mod_type in pairs({ 11, 12, 13, 16 }) do
            local mod_num = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, mod_type)
            VEHICLE.SET_VEHICLE_MOD(vehicle, mod_type, mod_num - 1, false)
        end
    end
    if MainTab["涡轮增压"]:is_enabled() then
        for _, mod_type in pairs({ 11, 12, 13, 16 }) do
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
        end
    end
    if MainTab["属性强化"]:is_enabled() then
        strong_vehicle(vehicle)
    end
    if tabs.check_input_value(MainTab["载具受伤倍数"], 0.0, 1.0) then
        local value = MainTab["载具受伤倍数"]:get_value()
        VEHICLE.SET_VEHICLE_DAMAGE_SCALE(vehicle, value)
        VEHICLE.SET_VEHICLE_WEAPON_DAMAGE_SCALE(vehicle, value)
    end
end)
tab_root:add_separator()

----------------
-- 实体
----------------

tab_root:add_text("<<  实体  >>")

local entity_t = {}

entity_t.npc_type_select = 1

function entity_t.check_ped_type(ped)
    if PED.IS_PED_A_PLAYER(ped) then
        return false
    end
    if entity_t.npc_type_select == 1 and not is_friendly_ped(ped) then
        return true
    end
    if entity_t.npc_type_select == 2 and is_hostile_ped(ped) then
        return true
    end
    if entity_t.npc_type_select == 3 then
        return true
    end
    return false
end

MainTab["NPC类型"] = tab_root:add_text("NPC类型: 全部NPC (排除友好)")
tab_root:add_sameline()
tab_root:add_text("选择类型 ->")
tab_root:add_sameline()
tab_root:add_button("全部NPC (排除友好)", function()
    MainTab["NPC类型"]:set_text("NPC类型: 全部NPC (排除友好)")
    entity_t.npc_type = 1
end)
tab_root:add_sameline()
tab_root:add_button("仅敌对NPC", function()
    MainTab["NPC类型"]:set_text("NPC类型: 仅敌对NPC")
    entity_t.npc_type = 2
end)
tab_root:add_sameline()
tab_root:add_button("全部NPC", function()
    MainTab["NPC类型"]:set_text("NPC类型: 全部NPC")
    entity_t.npc_type = 3
end)

tab_root:add_button("NPC 删除", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if entity_t.check_ped_type(ped) then
            delete_entity(ped)
        end
    end
end)
tab_root:add_sameline()
tab_root:add_button("NPC 死亡", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if not ENTITY.IS_ENTITY_DEAD(ped) and entity_t.check_ped_type(ped) then
            SET_ENTITY_HEALTH(ped, 0)
        end
    end
end)
tab_root:add_sameline()
tab_root:add_button("NPC 爆头击杀", function()
    local weaponHash = joaat("WEAPON_APPISTOL")
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if not ENTITY.IS_ENTITY_DEAD(ped) and entity_t.check_ped_type(ped) then
            shoot_ped_head(ped, weaponHash, PLAYER.PLAYER_PED_ID())
        end
    end
end)
tab_root:add_separator()

tabs.add_checkbox(tab_root, "警察 删除", MainTab)
tab_root:add_sameline()
tabs.add_checkbox(tab_root, "警察 死亡", MainTab)
tab_root:add_sameline()
tab_root:add_button("友方NPC 无敌强化", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if not ENTITY.IS_ENTITY_DEAD(ped) and not PED.IS_PED_A_PLAYER(ped) then
            if is_friendly_ped(ped) then
                strong_ped_combat(ped, true)
            end
        end
    end
end)
tab_root:add_sameline()
tab_root:add_button("友方NPC 给予武器", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if not ENTITY.IS_ENTITY_DEAD(ped) and not PED.IS_PED_A_PLAYER(ped) then
            if is_friendly_ped(ped) then
                for _, weaponHash in pairs(T.CommonWeapons) do
                    WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, -1, false, false)
                end
            end
        end
    end
end)
tab_root:add_separator()

tab_root:add_text("敌对实体")
tab_root:add_button("爆炸敌对NPC", function()
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if is_hostile_entity(ped) then
            local coords = ENTITY.GET_ENTITY_COORDS(ped)
            FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                4, 100.0, false, false, 0.0)
        end
    end
end)
tab_root:add_sameline()
tab_root:add_button("摧毁敌对载具", function()
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
tab_root:add_sameline()
tab_root:add_button("摧毁敌对物体", function()
    for _, object in pairs(entities.get_all_objects_as_handles()) do
        if is_hostile_entity(object) then
            SET_ENTITY_HEALTH(object, 0)

            local coords = ENTITY.GET_ENTITY_COORDS(object)
            FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z,
                4, 100.0, false, false, 0.0)
        end
    end
end)


--#endregion



--------------------------------
-- Mission Tab
--------------------------------

--#region Mission Tab

local tab_mission <const> = tab_root:add_tab(" > 任务助手")

local MissionTab = {}

----------------
-- 每日任务
----------------

tab_mission:add_text("每日任务")
tab_mission:add_button("传送到藏匿屋", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(845)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport(coords)
    else
        notify("传送到藏匿屋", "未在地图上找到藏匿屋")
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("通知藏匿屋密码", function()
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
tab_mission:add_sameline()
tab_mission:add_button("传送到杰拉德包裹", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(842)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport(coords)
    else
        notify("传送到杰拉德包裹", "未在地图上找到杰拉德包裹")
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("进入范围后，传送到包裹", function()
    local entity_list = get_entities_by_hash("object", true, 138777325, 2674233009, 765087784)
    if next(entity_list) ~= nil then
        for _, ent in pairs(entity_list) do
            tp_to_entity(ent, 0.0, 0.0, 0.5)
        end
    end
end)
tab_mission:add_separator()

tab_mission:add_button("打开恐霸电脑", function()
    start_game_script("apphackertruck")
end)
tab_mission:add_sameline()
tabs.add_checkbox(tab_mission, "跳过NPC对话", MissionTab)
tab_mission:add_sameline()
tabs.add_checkbox(tab_mission, "自动收集财物", MissionTab, false, "模拟鼠标左键点击拿取财物")
tab_mission:add_separator()

----------------
-- 资产任务
----------------

tab_mission:add_text("<< 资产任务 >>")

tab_mission:add_text("办公室拉货")
tab_mission:add_button("传送到 特种货物", function()
    local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(478)
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("特种货物 传送到我", function()
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
            notify("", "目标不是实体，无法传送到我")
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
                    tp_vehicle_to_me(attached_ent, "delete", "delete")
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
        teleport2(coords.x, coords.y + 2.0, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip2) then
        local coords = HUD.GET_BLIP_COORDS(blip2)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    elseif HUD.DOES_BLIP_EXIST(blip3) then
        local coords = HUD.GET_BLIP_COORDS(blip3)
        teleport2(coords.x, coords.y, coords.z + 1.0)
    end
end)
tab_mission:add_sameline()
tab_mission:add_button("地堡原材料 传送到我", function()
    local blip = HUD.GET_NEXT_BLIP_INFO_ID(556)
    if HUD.DOES_BLIP_EXIST(blip) then
        local ent = HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(blip)
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            set_entity_heading_to_entity(ent, PLAYER.PLAYER_PED_ID())
            tp_entity_to_me(ent)

            if ENTITY.IS_ENTITY_A_VEHICLE(ent) then
                tp_into_vehicle(ent, "delete", "delete")
            end
        else
            notify("", "目标不是实体，无法传送到我")
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
tab_mission:add_sameline()
tab_mission:add_button("工厂原材料 传送到我", function()
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
            notify("", "目标不是实体，无法传送到我")
        end
    end
end)
tab_mission:add_separator()

----------------
-- 公寓抢劫
----------------

tab_mission:add_text("<< 公寓抢劫 >>")

tab_mission:add_text("越狱")
tab_mission:add_button("梅杜莎飞机 无敌", function()
    get_mission_entities_by_hash("vehicle", { 1077420264 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                notify("", "完成！")
            end
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("秃鹰直升机 无敌", function()
    get_mission_entities_by_hash("vehicle", { 788747387 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                notify("", "完成！")
            end
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("敌对天煞 冻结", function()
    get_mission_entities_by_hash("vehicle", { 3013282534 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                ENTITY.FREEZE_ENTITY_POSITION(ent, true)

                notify("", "完成！")
            end
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("光头 无敌强化", function()
    get_mission_entities_by_hash("ped", { 940330470 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                strong_ped_combat(ent, true)

                notify("", "完成！")
            end
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("光头 传送进美杜莎", function()
    local vehicle = 0
    get_mission_entities_by_hash("vehicle", { 1077420264 }, function(ent)
        if is_mission_script_entity(ent) then
            vehicle = ent
        end
    end)

    if vehicle == 0 then return end

    get_mission_entities_by_hash("ped", { 940330470 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                PED.SET_PED_INTO_VEHICLE(ent, vehicle, 0)

                notify("", "完成！")
            end
        end
    end)
end)

tab_mission:add_text("突袭人道实验室")
tab_mission:add_button("九头蛇 无敌", function()
    get_mission_entities_by_hash("vehicle", { 970385471 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                notify("", "完成！")
            end
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("天煞(没有人驾驶的) 无敌", function()
    local i = 0
    get_mission_entities_by_hash("vehicle", { 3013282534 }, function(ent)
        if is_mission_script_entity(ent) then
            if VEHICLE.IS_VEHICLE_SEAT_FREE(ent, -1, true) then
                request_control(ent)
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                if has_control_entity(ent) then
                    i = i + 1
                end
            end
        end
    end)
    notify("", "完成！\n数量: " .. i)
end)
tab_mission:add_sameline()
tab_mission:add_button("女武神直升机 无敌", function()
    get_mission_entities_by_hash("vehicle", { 2694714877 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                notify("", "完成！")
            end
        end
    end)
end)

tab_mission:add_text("首轮募资")
tab_mission:add_button("穿梭者直升机 无敌", function()
    get_mission_entities_by_hash("vehicle", { 744705981 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                notify("", "完成！")
            end
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("油罐车 无敌", function()
    get_mission_entities_by_hash("vehicle", { 1956216962 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                notify("", "完成！")
            end
        end
    end)
end)

tab_mission:add_text("太平洋标准银行")
tab_mission:add_button("厢型车司机 传送到天上", function()
    local i = 0
    get_mission_entities_by_hash("vehicle", { 444171386 }, function(ent)
        if is_mission_script_entity(ent) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
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
    end)
    notify("", "完成！\n数量: " .. i)
end)
tab_mission:add_sameline()
tab_mission:add_button("车队卡车 无敌", function()
    get_mission_entities_by_hash("vehicle", { 630371791 }, function(ent)
        if is_mission_script_entity(ent) then
            if request_control2(ent) then
                set_entity_godmode(ent, true)
                strong_vehicle(ent)

                notify("", "完成！")
            end
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("雷克卓摩托车 升级无敌", function()
    local i = 0
    get_mission_entities_by_hash("vehicle", { 640818791 }, function(ent)
        if is_mission_script_entity(ent) then
            if VEHICLE.IS_VEHICLE_SEAT_FREE(ent, -1, true) then
                request_control(ent, 1)
                set_entity_godmode(ent, true)
                upgrade_vehicle(ent)
                strong_vehicle(ent)

                if has_control_entity(ent) then
                    i = i + 1
                end
            end
        end
    end)
    notify("", "完成！\n数量: " .. i)
end)
tab_mission:add_separator()

----------------
-- 佩里科岛抢劫
----------------

tab_mission:add_text("<< 佩里科岛抢劫 >>")
tab_mission:add_button("摧毁主要目标玻璃柜、保险箱 (会在豪宅外生成主要目标包裹)", function()
    get_mission_entities_by_hash("object", { 2580434079, 1098122770 }, function(ent)
        if request_control2(ent) then
            SET_ENTITY_HEALTH(ent, 0)

            notify("", "完成！")
        end
    end)
end)
tab_mission:add_sameline()
tab_mission:add_button("主要目标掉落包裹 传送到我", function()
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


--#endregion



--------------------------------
-- Manage Entity Tab
--------------------------------

--#region Manage Entity Tab

local tab_manage_entity <const> = tab_root:add_tab(" > 管理实体")

local tab_vehicle_list <const> = tab_manage_entity:add_tab(" >> 载具列表")
local tab_ped_list <const> = tab_manage_entity:add_tab(" >> NPC列表")

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

    tab:add_text("在下方点击选择一个实体，然后进行实体控制")
    ----------
    tab:add_separator()
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
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            if request_control(ent) then
                notify("请求控制实体", "成功")
            else
                notify("请求控制实体", "失败，请重试")
            end
        end
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
        if ENTITY.DOES_ENTITY_EXIST(ent) and NETWORK.NETWORK_IS_SESSION_STARTED() then
            NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(ent)
            local net_id = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(ent)
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
            NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(net_id, PLAYER.PLAYER_ID(), true)

            notify("设置为网络实体", NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(ent) and "成功" or "失败")
        end
    end)
    tab:add_sameline()
    tab:add_button("删除", function()
        local ent = manage_entity[entity_type].ent
        if ENTITY.DOES_ENTITY_EXIST(ent) then
            if PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), ent, true) then
                TP_ENTITY(PLAYER.PLAYER_PED_ID(), ENTITY.GET_ENTITY_COORDS(ent))
            end
            delete_entity(ent)
        end
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

    local entity_script = ENTITY.GET_ENTITY_SCRIPT(ent, 0)
    if entity_script ~= nil then
        gui_table["script"]:set_text("脚本: " .. string.lower(entity_script))
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

    if NETWORK.NETWORK_IS_SESSION_STARTED() then
        info = info .. ", 控制权: " .. PLAYER.GET_PLAYER_NAME(get_entity_owner(ent))
    end

    local entity_script = ENTITY.GET_ENTITY_SCRIPT(ent, 0)
    if entity_script ~= nil then
        info = info .. ", 脚本: " .. string.lower(entity_script)
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
    local target_tab = tab_vehicle_list
    if entity_type == "ped" then
        target_tab = tab_ped_list
    end
    target_tab:clear()
    manage_entity[entity_type].ent = 0

    manage_entity.gui.entity(target_tab, entity_type)

    local num = 0
    for key, ent in pairs(get_all_entities(entity_type)) do
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

tab_manage_entity:add_button("获取载具列表", function()
    manage_entity.get_entity_list("vehicle")
end)
tab_manage_entity:add_sameline()
tab_manage_entity:add_button("获取NPC列表", function()
    manage_entity.get_entity_list("ped")
end)
tab_manage_entity:add_sameline()
tab_manage_entity:add_button("清空载具列表", function()
    manage_entity["vehicle"].enable = false
    tab_vehicle_list:clear()
end)
tab_manage_entity:add_sameline()
tab_manage_entity:add_button("清空NPC列表", function()
    manage_entity["ped"].enable = false
    tab_ped_list:clear()
end)
tab_manage_entity:add_separator()

tab_manage_entity:add_text("筛选设置")
tabs.add_checkbox(tab_manage_entity, "任务实体", ManageEntityTab, true, "(是/否)")
tab_manage_entity:add_sameline()
tabs.add_checkbox(tab_manage_entity, "禁用筛选: 任务实体", ManageEntityTab)

tabs.add_input_float(tab_manage_entity, "距离", ManageEntityTab, 0, "(0表示不限制)")

tabs.add_checkbox(tab_manage_entity, "地图标记点", ManageEntityTab, false, "(有/没有)")
tab_manage_entity:add_sameline()
tabs.add_checkbox(tab_manage_entity, "禁用筛选: 地图标记点", ManageEntityTab, true)

tabs.add_checkbox(tab_manage_entity, "正在移动", ManageEntityTab, false, "(是/否)")
tab_manage_entity:add_sameline()
tabs.add_checkbox(tab_manage_entity, "禁用筛选: 正在移动", ManageEntityTab, true)

tab_manage_entity:add_text("NPC")
tabs.add_checkbox(tab_manage_entity, "与玩家关系", ManageEntityTab, false, "(敌对/友好)")
tab_manage_entity:add_sameline()
tabs.add_checkbox(tab_manage_entity, "禁用筛选: 与玩家关系", ManageEntityTab, true)

tabs.add_checkbox(tab_manage_entity, "在载具内", ManageEntityTab, false, "(是/否)")
tab_manage_entity:add_sameline()
tabs.add_checkbox(tab_manage_entity, "禁用筛选: 在载具内", ManageEntityTab, true)

tab_manage_entity:add_text("载具")
tabs.add_checkbox(tab_manage_entity, "载具司机", ManageEntityTab, false, "(有/没有)")
tab_manage_entity:add_sameline()
tabs.add_checkbox(tab_manage_entity, "禁用筛选: 载具司机", ManageEntityTab, true)


--#endregion



--------------------------------
-- Debug Tab
--------------------------------

local tab_debug <const> = tab_root:add_tab(" > Debug")

local DebugTab = {}

tabs.add_checkbox(tab_debug, "RPG爆炸准星位置", DebugTab, false, "E键使用")
tab_debug:add_sameline()
tabs.add_checkbox(tab_debug, "署名爆炸", DebugTab)

tabs.add_checkbox(tab_debug, "RPG射击准星位置", DebugTab, false, "E键使用")
tab_debug:add_sameline()
tabs.add_checkbox(tab_debug, "署名射击", DebugTab)



script.register_looped("RScript_Debug", function(script_util)
    if DebugTab["RPG爆炸准星位置"]:is_enabled() then
        draw_crosshair()

        local result = get_raycast_result(1500.0)
        if result.hit then
            -- local line_colour = { r = 255, g = 0, b = 255, a = 255 }
            -- local coords = result.endCoords
            -- local my_coords = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())

            -- local ent = result.entityHit
            -- if ENTITY.DOES_ENTITY_EXIST(ent) and ENTITY.GET_ENTITY_TYPE(ent) > 0 then
            --     line_colour = { r = 0, g = 255, b = 0, a = 255 }
            -- end

            -- DRAW_LINE(my_coords, coords, line_colour)


            if PAD.IS_CONTROL_PRESSED(0, 51) then
                local coords = result.endCoords

                local explosion_type = 4 -- EXP_TAG_ROCKET

                if DebugTab["署名爆炸"]:is_enabled() then
                    FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(),
                        coords.x, coords.y, coords.z, explosion_type,
                        1000.0, true, false, 0.0)
                else
                    FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, explosion_type,
                        1000.0, true, false, 0.0, false)
                end

                script_util:sleep(100)
            end
        end
    end

    if DebugTab["RPG射击准星位置"]:is_enabled() then
        draw_crosshair()

        if PAD.IS_CONTROL_PRESSED(0, 51) then
            local start_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
            local end_pos = get_offset_from_cam(1500.0)

            local weapon_hash = 2982836145 -- WEAPON_RPG
            local owner = 0
            if DebugTab["署名射击"]:is_enabled() then
                owner = PLAYER.PLAYER_PED_ID()
            end
            local ignore_ent = get_user_vehicle(false)
            if ignore_ent == 0 then
                ignore_ent = PLAYER.PLAYER_PED_ID()
            end

            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(
                start_pos.x, start_pos.y, start_pos.z + 2.0,
                end_pos.x, end_pos.y, end_pos.z,
                1000.0, true, weapon_hash, owner,
                true, true, 2000,
                ignore_ent, 0)

            script_util:sleep(100)
        end
    end
end)



--------------------------------
-- Loop Script
--------------------------------

script.register_looped("RScript_Main", function()
    if MainTab["自定义设置生命恢复"]:is_enabled() then
        if tabs.check_input_value(MainTab["生命恢复速率"], 0.0, 100.0, false) then
            PLAYER.SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER(PLAYER.PLAYER_ID(), MainTab["生命恢复速率"]:get_value())
        end
        if tabs.check_input_value(MainTab["生命恢复程度"], 0.0, 1.0, false) then
            PLAYER.SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT(PLAYER.PLAYER_ID(), MainTab["生命恢复程度"]:get_value())
        end
    end
    if MainTab["自定义设置受伤倍数"]:is_enabled() then
        if tabs.check_input_value(MainTab["自我受伤倍数"], 0.1, 1.0, false) then
            local value = MainTab["自我受伤倍数"]:get_value()
            PLAYER.SET_PLAYER_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
            PLAYER.SET_PLAYER_WEAPON_MINIGUN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
            PLAYER.SET_PLAYER_MELEE_WEAPON_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
            PLAYER.SET_PLAYER_VEHICLE_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
            PLAYER.SET_PLAYER_WEAPON_TAKEDOWN_DEFENSE_MODIFIER(PLAYER.PLAYER_ID(), value)
        end
    end
    if MainTab["步行时人称视角快捷切换"]:is_enabled() then
        if CAM.IS_FOLLOW_PED_CAM_ACTIVE() then
            if CAM.GET_FOLLOW_PED_CAM_VIEW_MODE() == 1 or CAM.GET_FOLLOW_PED_CAM_VIEW_MODE() == 2 then
                CAM.SET_FOLLOW_PED_CAM_VIEW_MODE(4)
            end
        end
    end
    if MainTab["无限动能回收加速"]:is_enabled() then
        local vehicle = get_user_vehicle(false)
        if vehicle ~= 0 then
            if VEHICLE.GET_VEHICLE_HAS_KERS(vehicle) then
                local vehicle_ptr = memory.handle_to_ptr(vehicle)
                local kers_boost_max = vehicle_ptr:add(0x92c):get_float()
                vehicle_ptr:add(0x930):set_float(kers_boost_max) -- m_kers_boost
            end
        end
    end
    if MainTab["警察 删除"]:is_enabled() then
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            local hash = ENTITY.GET_ENTITY_MODEL(ped)
            if hash == 1581098148 or hash == 2974087609 or hash == 2374966032 then
                delete_entity(ped)
            end
        end
    end
    if MainTab["警察 死亡"]:is_enabled() then
        for _, ped in pairs(entities.get_all_peds_as_handles()) do
            local hash = ENTITY.GET_ENTITY_MODEL(ped)
            if hash == 1581098148 or hash == 2974087609 or hash == 2374966032 then
                SET_ENTITY_HEALTH(ped, 0)
            end
        end
    end


    if MissionTab["跳过NPC对话"]:is_enabled() then
        if AUDIO.IS_SCRIPTED_CONVERSATION_ONGOING() then
            AUDIO.STOP_SCRIPTED_CONVERSATION(false)
        end
    end
end)

script.register_looped("RScript_自动收集财物", function(script_util)
    if MissionTab["自动收集财物"]:is_enabled() then
        if TASK.GET_IS_TASK_ACTIVE(PLAYER.PLAYER_PED_ID(), 135) then
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(0, 237, 1)
            script_util:sleep(30)
        end
    end
end)

script.register_looped("RScript_Manage_Entity", function()
    if manage_entity["vehicle"].enable and tab_vehicle_list:is_selected() then
        manage_entity.gui.update_info("vehicle")
    end
    if manage_entity["ped"].enable and tab_ped_list:is_selected() then
        manage_entity.gui.update_info("ped")
    end
end)
