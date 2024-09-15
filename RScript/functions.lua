----------------------------------------
-- Alternative for Native Functions
----------------------------------------

function TP_ENTITY(entity, coords, heading)
    if heading ~= nil then
        ENTITY.SET_ENTITY_HEADING(entity, heading)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, coords.x, coords.y, coords.z, true, false, false)
end

function ENTITY_HEADING(entity, heading)
    if heading ~= nil then
        ENTITY.SET_ENTITY_HEADING(entity, heading)
        return heading
    end
    return ENTITY.GET_ENTITY_HEADING(entity)
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

function DRAW_BOX(start_pos, end_pos, colour)
    colour = colour or { r = 255, g = 0, b = 255, a = 255 }
    GRAPHICS.DRAW_BOX(start_pos.x, start_pos.y, start_pos.z,
        end_pos.x, end_pos.y, end_pos.z,
        colour.r, colour.g, colour.b, colour.a)
end

function SET_ENTITY_HEALTH(entity, health)
    ENTITY.SET_ENTITY_HEALTH(entity, health, 0, 0)
end

function SET_VEHICLE_ENGINE_ON(vehicle, toggle)
    VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, toggle, true, false)
end

function SET_VEHICLE_ON_GROUND_PROPERLY(vehicle)
    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(vehicle, 5.0)
end

function GET_ENTITY_SCRIPT(entity)
    local entity_script = ENTITY.GET_ENTITY_SCRIPT(entity, 0)
    if entity_script == nil then return "" end
    return string.lower(entity_script)
end

----------------------------------------
-- Local Player Functions
----------------------------------------

function get_user_vehicle(include_last)
    if include_last == nil then include_last = true end
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
    if not ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then return 0 end
    if not include_last and not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then return 0 end
    return vehicle
end

function teleport(coords, heading)
    local ent = get_user_vehicle(false)
    if ent == 0 then ent = PLAYER.PLAYER_PED_ID() end

    TP_ENTITY(ent, coords, heading)
end

function teleport2(x, y, z, heading)
    teleport(v3.new(x, y, z), heading)
end

function user_heading(heading)
    local ent = get_user_vehicle(false)
    if ent == 0 then ent = PLAYER.PLAYER_PED_ID() end

    if heading ~= nil then
        ENTITY.SET_ENTITY_HEADING(ent, heading)
        return heading
    end
    return ENTITY.GET_ENTITY_HEADING(ent)
end

function get_user_interior()
    if INTERIOR.IS_INTERIOR_SCENE() then
        return INTERIOR.GET_INTERIOR_FROM_ENTITY(PLAYER.PLAYER_PED_ID())
    end
    return -1
end

function tp_entity_to_me(entity, offsetX, offsetY, offsetZ)
    offsetX = offsetX or 0.0
    offsetY = offsetY or 0.0
    offsetZ = offsetZ or 0.0
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), offsetX, offsetY, offsetZ)
    TP_ENTITY(entity, coords)
end

function tp_to_entity(entity, offsetX, offsetY, offsetZ)
    offsetX = offsetX or 0.0
    offsetY = offsetY or 0.0
    offsetZ = offsetZ or 0.0
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, offsetX, offsetY, offsetZ)
    teleport(coords)
end

function tp_into_vehicle(vehicle, door, driver, seat)
    seat = seat or -1
    unlock_vehicle_doors(vehicle)
    clear_vehicle_wanted(vehicle)
    -- unfreeze
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
    VEHICLE.SET_VEHICLE_UNDRIVEABLE(vehicle, false)

    if door == "delete" then
        VEHICLE.SET_VEHICLE_DOOR_BROKEN(vehicle, 0, true) -- left front door
    end

    if driver ~= nil then
        local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat)
        if ped ~= 0 then
            if driver == "tp" then
                set_entity_move(ped, 0.0, 5.0, 3.0)
            elseif driver == "delete" then
                delete_entity(ped)
            end
        end
    end

    VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, false)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(vehicle)

    PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, seat)
end

function tp_vehicle_to_me(vehicle, door, driver, seat)
    ENTITY_HEADING(vehicle, user_heading())
    tp_entity_to_me(vehicle)
    tp_into_vehicle(vehicle, door, driver, seat)
end

function tp_pickup_to_me(pickup, attachToSelf)
    if ENTITY.IS_ENTITY_ATTACHED(pickup) then
        ENTITY.DETACH_ENTITY(pickup, true, true)
        ENTITY.SET_ENTITY_VISIBLE(pickup, true, false)
    end
    OBJECT.SET_PICKUP_OBJECT_COLLECTABLE_IN_VEHICLE(pickup)

    if attachToSelf then
        OBJECT.ATTACH_PORTABLE_PICKUP_TO_PED(pickup, PLAYER.PLAYER_PED_ID())
    else
        tp_entity_to_me(pickup)
    end
end

function draw_line_to_entity(entity, colour)
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
    local ent_pos = ENTITY.GET_ENTITY_COORDS(entity)
    DRAW_LINE(player_pos, ent_pos, colour)

    local size = 0.25
    local box_pos1 = { x = ent_pos.x - size, y = ent_pos.y + size, z = ent_pos.z + 1000.0 }
    local box_pos2 = { x = ent_pos.x + size, y = ent_pos.y - size, z = ent_pos.z - 1000.0 }
    DRAW_BOX(box_pos1, box_pos2, colour)
end

----------------------------------------
-- Entity Functions
----------------------------------------

function set_entity_move(entity, offsetX, offsetY, offsetZ)
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, offsetX, offsetY, offsetZ)
    TP_ENTITY(entity, coords)
end

function set_entity_heading_to_entity(setEntity, toEntity, angle)
    angle = angle or 0.0
    local heading = ENTITY.GET_ENTITY_HEADING(toEntity)
    ENTITY.SET_ENTITY_HEADING(setEntity, heading + angle)
end

function tp_entity_to_entity(tpEntity, toEntity, offsetX, offsetY, offsetZ)
    offsetX = offsetX or 0.0
    offsetY = offsetY or 0.0
    offsetZ = offsetZ or 0.0
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(toEntity, offsetX, offsetY, offsetZ)
    TP_ENTITY(tpEntity, coords)
end

function set_entity_godmode(entity, toggle)
    ENTITY.SET_ENTITY_INVINCIBLE(entity, toggle)
    ENTITY.SET_ENTITY_PROOFS(entity, toggle, toggle, toggle, toggle, toggle, toggle, toggle, toggle)
    ENTITY.SET_ENTITY_CAN_BE_DAMAGED(entity, not toggle)
end

function is_hostile_entity(entity)
    if ENTITY.IS_ENTITY_A_PED(entity) then
        if is_hostile_ped(entity) then
            return true
        end
    end

    if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        local driver = GET_PED_IN_VEHICLE_SEAT(entity, -1)
        if is_hostile_ped(driver) then
            return true
        end
    end

    local blip = HUD.GET_BLIP_FROM_ENTITY(entity)
    if HUD.DOES_BLIP_EXIST(blip) then
        local blip_colour = HUD.GET_BLIP_COLOUR(blip)
        if blip_colour == 1 or blip_colour == 59 then -- red
            return true
        end
    end

    return false
end

function delete_entity(ent)
    if not ENTITY.DOES_ENTITY_EXIST(ent) then
        return
    end

    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) then
        entities.take_control_of(ent)
    end

    ENTITY.DETACH_ENTITY(ent, true, true)
    ENTITY.SET_ENTITY_VISIBLE(ent, false, false)
    NETWORK.NETWORK_SET_ENTITY_ONLY_EXISTS_FOR_PARTICIPANTS(ent, true)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ent, 0.0, 0.0, -1000.0, false, false, false)
    ENTITY.SET_ENTITY_COLLISION(ent, false, false)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, true, true)
    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(ent)
    ENTITY.DELETE_ENTITY(ent)
end

----------------------------------------
-- Entities Functions
----------------------------------------

--- @param entityType ENTITY_TYPE
--- @return table<int, Entity>
function get_all_entities(entityType)
    if entityType == ENTITY_PED then
        return entities.get_all_peds_as_handles()
    end
    if entityType == ENTITY_VEHICLE then
        return entities.get_all_vehicles_as_handles()
    end
    if entityType == ENTITY_OBJECT then
        return entities.get_all_objects_as_handles()
    end

    return {}
end

--- @param entityType ENTITY_TYPE
--- @param isMission boolean
--- @param ... Hash
--- @return table<int, Entity>
function get_entities_by_hash(entityType, isMission, ...)
    local entity_list = {}
    local hash_list = { ... }

    for key, entity in pairs(get_all_entities(entityType)) do
        local entity_hash = ENTITY.GET_ENTITY_MODEL(entity)
        for _, hash in pairs(hash_list) do
            if entity_hash == hash then
                if isMission then
                    if ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) then
                        table.insert(entity_list, entity)
                    end
                else
                    table.insert(entity_list, entity)
                end
            end
        end
    end

    return entity_list
end

function get_mission_entities_by_hash2(entityType, hashList, callback)
    local entity_list = {}
    for key, ent in pairs(get_all_entities(entityType)) do
        if ENTITY.IS_ENTITY_A_MISSION_ENTITY(ent) then
            for _, Hash in pairs(hashList) do
                if EntityHash == Hash then
                    table.insert(entity_list, ent)

                    if callback ~= nil then
                        callback(ent)
                    end
                end
            end
        end
    end

    return entity_list
end

--- @param entityType ENTITY_TYPE
--- @param scriptName string
--- @param ... Hash
--- @return table<int, Entity>
function get_mission_entities_by_hash(entityType, scriptName, ...)
    if not is_script_running(scriptName) then
        return {}
    end

    local entity_list = {}
    local hash_list = { ... }

    for key, entity in pairs(get_all_entities(entityType)) do
        local entity_hash = ENTITY.GET_ENTITY_MODEL(entity)
        for _, hash in pairs(hash_list) do
            if entity_hash == hash then
                if GET_ENTITY_SCRIPT(entity) == scriptName then
                    table.insert(entity_list, entity)
                end
            end
        end
    end

    return entity_list
end

--- @param scriptName string
--- @return table<int, Entity>
function get_mission_pickups(scriptName)
    if not is_script_running(scriptName) then
        return {}
    end

    local entity_list = {}
    for _, entity in pairs(get_all_pickups_as_handles()) do
        if GET_ENTITY_SCRIPT(entity) == scriptName then
            table.insert(entity_list, entity)
        end
    end
    return entity_list
end

----------------------------------------
-- Ped Functions
----------------------------------------

function is_player_ped(ped)
    if PED.GET_PED_TYPE(ped) >= 4 then
        return false
    end
    return true
end

function is_hostile_ped(ped)
    if PED.IS_PED_IN_COMBAT(ped, PLAYER.PLAYER_PED_ID()) then
        return true
    end

    local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(ped, PLAYER.PLAYER_PED_ID())
    if rel == 3 or rel == 4 or rel == 5 then -- Dislike or Wanted or Hate
        return true
    end

    return false
end

function is_friendly_ped(ped)
    local rel = PED.GET_RELATIONSHIP_BETWEEN_PEDS(ped, PLAYER.PLAYER_PED_ID())
    if rel == 0 or rel == 1 then -- Respect or Like
        return true
    end

    return false
end

function shoot_ped_head(targetPed, weaponHash, owner)
    local head_pos = PED.GET_PED_BONE_COORDS(targetPed, 0x322c, 0, 0, 0)
    local vector = ENTITY.GET_ENTITY_FORWARD_VECTOR(targetPed)
    local start_pos = {}
    start_pos.x = head_pos.x + vector.x
    start_pos.y = head_pos.y + vector.y
    start_pos.z = head_pos.z + vector.z

    local target_ped_veh = GET_VEHICLE_PED_IS_IN(targetPed)

    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(
        start_pos.x, start_pos.y, start_pos.z,
        head_pos.x, head_pos.y, head_pos.z,
        1000, true,
        weaponHash or 584646201,
        owner or 0,
        false, false, 1000,
        target_ped_veh, targetPed)
end

function strong_ped_combat(ped, isGodmode, canRagdoll)
    if isGodmode == nil then isGodmode = false end
    if canRagdoll == nil then canRagdoll = true end

    -- GODMODE
    ENTITY.SET_ENTITY_INVINCIBLE(ped, isGodmode)
    ENTITY.SET_ENTITY_PROOFS(ped, isGodmode, isGodmode, isGodmode, isGodmode, isGodmode, isGodmode, isGodmode,
        isGodmode)

    -- RAGDOLL
    PED.SET_PED_CAN_RAGDOLL(ped, canRagdoll)

    -- PERCEPTIVE
    PED.SET_PED_HIGHLY_PERCEPTIVE(ped, true)
    PED.SET_PED_VISUAL_FIELD_PERIPHERAL_RANGE(ped, 500.0)
    PED.SET_PED_SEEING_RANGE(ped, 500.0)
    PED.SET_PED_HEARING_RANGE(ped, 500.0)
    PED.SET_PED_ID_RANGE(ped, 500.0)
    PED.SET_PED_VISUAL_FIELD_MIN_ANGLE(ped, -180.0)
    PED.SET_PED_VISUAL_FIELD_MAX_ANGLE(ped, 180.0)
    PED.SET_PED_VISUAL_FIELD_MIN_ELEVATION_ANGLE(ped, -180.0)
    PED.SET_PED_VISUAL_FIELD_MAX_ELEVATION_ANGLE(ped, 180.0)
    PED.SET_PED_VISUAL_FIELD_CENTER_ANGLE(ped, 90.0)

    -- WEAPON
    PED.SET_PED_CAN_SWITCH_WEAPON(ped, true)
    WEAPON.SET_PED_INFINITE_AMMO_CLIP(ped, true)
    WEAPON.SET_EQIPPED_WEAPON_START_SPINNING_AT_FULL_SPEED(ped)

    -- COMBAT
    PED.SET_PED_SHOOT_RATE(ped, 1000)
    PED.SET_PED_ACCURACY(ped, 100)
    PED.SET_PED_COMBAT_ABILITY(ped, 2)       -- Professional
    PED.SET_PED_COMBAT_RANGE(ped, 2)         -- Far
    -- PED.SET_PED_COMBAT_MOVEMENT(ped, 2) -- Will Advance
    PED.SET_PED_TARGET_LOSS_RESPONSE(ped, 1) -- Never Lose Target

    -- COMBAT FLOAT
    PED.SET_COMBAT_FLOAT(ped, 6, 1.0) -- Weapon Accuracy
    PED.SET_COMBAT_FLOAT(ped, 7, 1.0) -- Fight Proficiency

    -- FLEE ATTRIBUTES
    PED.SET_PED_FLEE_ATTRIBUTES(ped, 512, true) -- Never Flee

    -- TASK PATH
    TASK.SET_PED_PATH_CAN_USE_CLIMBOVERS(ped, true)
    TASK.SET_PED_PATH_CAN_USE_LADDERS(ped, true)
    TASK.SET_PED_PATH_CAN_DROP_FROM_HEIGHT(ped, true)
    TASK.SET_PED_PATH_AVOID_FIRE(ped, false)
    TASK.SET_PED_PATH_MAY_ENTER_WATER(ped, true)

    -- CONFIG FLAG
    PED.SET_PED_CONFIG_FLAG(ped, 107, true)  -- Dont Activate Ragdoll From BulletImpact
    PED.SET_PED_CONFIG_FLAG(ped, 108, true)  -- Dont Activate Ragdoll From Explosions
    PED.SET_PED_CONFIG_FLAG(ped, 109, true)  -- Dont Activate Ragdoll From Fire
    PED.SET_PED_CONFIG_FLAG(ped, 110, true)  -- Dont Activate Ragdoll From Electrocution
    PED.SET_PED_CONFIG_FLAG(ped, 430, false) -- Ignore Being On Fire

    -- OTHER
    PED.SET_PED_SUFFERS_CRITICAL_HITS(ped, false) -- Disable Headshot
    PED.SET_DISABLE_HIGH_FALL_DEATH(ped, true)

    -- COMBAT ATTRIBUTES
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 4, true)   -- Can Use Dynamic Strafe Decisions
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true)   -- Always Fight
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 6, false)  -- Flee Whilst In Vehicle
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 13, true)  -- Aggressive
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 14, true)  -- Can Investigate
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 17, false) -- Always Flee
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 20, true)  -- Can Taunt In Vehicle
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 21, true)  -- Can Chase Target On Foot
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 22, true)  -- Will Drag Injured Peds to Safety
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 24, true)  -- Use Proximity Firing Rate
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 27, true)  -- Perfect Accuracy
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 28, true)  -- Can Use Frustrated Advance
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 29, true)  -- Move To Location Before Cover Search
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 38, true)  -- Disable Bullet Reactions
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 39, true)  -- Can Bust
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 41, true)  -- Can Commandeer Vehicles
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 42, true)  -- Can Flank
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)  -- Can Fight Armed Peds When Not Armed
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 49, false) -- Use Enemy Accuracy Scaling
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 52, true)  -- Use Vehicle Attack
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 53, true)  -- Use Vehicle Attack If Vehicle Has Mounted Guns
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 54, true)  -- Always Equip Best Weapon
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 55, true)  -- Can See Underwater Peds
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 58, true)  -- Disable Flee From Combat
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 60, true)  -- Can Throw Smoke Grenade
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 78, true)  -- Disable All Randoms Flee
end

function get_player_from_ped(ped)
    return NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)
end

----------------------------------------
-- Vehicle Functions
----------------------------------------

function get_vehicle_display_name(vehicle)
    local hash = ENTITY.GET_ENTITY_MODEL(vehicle)
    local label_name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
    return get_label_text(label_name)
end

function get_vehicle_display_name_by_hash(hash)
    local label_name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
    return get_label_text(label_name)
end

function upgrade_vehicle(vehicle)
    VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)

    local excluded_mod_types = { 14, 15, 23, 24, 48 }
    for i = 0, 50 do
        if not table.contains(excluded_mod_types, i) then
            local mod_num = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
            if mod_num > 0 then
                VEHICLE.SET_VEHICLE_MOD(vehicle, i, mod_num - 1, false)
            end
        end
    end
    for i = 17, 22 do
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, i, true)
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

function fix_vehicle(vehicle)
    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
    VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 5000.0)
    SET_ENTITY_HEALTH(vehicle, ENTITY.GET_ENTITY_MAX_HEALTH(vehicle))
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
    VEHICLE.SET_DISABLE_DAMAGE_WITH_PICKED_UP_ENTITY(vehicle, 1)
    VEHICLE.SET_VEHICLE_USES_MP_PLAYER_DAMAGE_MULTIPLIER(vehicle, 1)
    VEHICLE.SET_FORCE_VEHICLE_ENGINE_DAMAGE_BY_BULLET(vehicle, false)

    --Explode
    VEHICLE.SET_VEHICLE_NO_EXPLOSION_DAMAGE_FROM_DRIVER(vehicle, true)
    VEHICLE.SET_DISABLE_EXPLODE_FROM_BODY_DAMAGE_ON_COLLISION(vehicle, 1)
    VEHICLE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(vehicle, false)
    VEHICLE.SET_VEHICLE_EXPLODES_ON_EXPLOSION_DAMAGE_AT_ZERO_BODY_HEALTH(vehicle, false)
    VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(vehicle, false)

    --Heli
    VEHICLE.SET_HELI_TAIL_BOOM_CAN_BREAK_OFF(vehicle, false)
    VEHICLE.SET_DISABLE_HELI_EXPLODE_FROM_BODY_DAMAGE(vehicle, 1)

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

    VEHICLE.SET_VEHICLE_IS_CONSIDERED_BY_PLAYER(vehicle, true)
    VEHICLE.SET_VEHICLE_EXCLUSIVE_DRIVER(vehicle, 0, 0)
end

function clear_vehicle_wanted(vehicle)
    VEHICLE.SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(vehicle, true)
    VEHICLE.SET_VEHICLE_IS_STOLEN(vehicle, false)
    VEHICLE.SET_VEHICLE_IS_WANTED(vehicle, false)
    VEHICLE.SET_POLICE_FOCUS_WILL_TRACK_VEHICLE(vehicle, false)
    VEHICLE.SET_VEHICLE_INFLUENCES_WANTED_LEVEL(vehicle, false)
    VEHICLE.SET_DISABLE_WANTED_CONES_RESPONSE(vehicle, true)
end

function is_any_player_in_vehicle(vehicle)
    for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
        if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seat, false) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat, false)
            if PED.IS_PED_A_PLAYER(ped) then
                return true
            end
        end
    end
end

----------------------------------------
-- Network Functions
----------------------------------------

-- function request_control(entity, timeout)
--     if is_in_session() and not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
--         timeout = timeout or 2
--         script.run_in_fiber(function(script_util)
--             local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
--             NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)
--             local start_time = os.time()
--             while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) do
--                 if os.time() - start_time >= timeout then
--                     break
--                 end
--                 NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
--                 script_util:yield()
--             end
--         end)
--     end
--     return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
-- end

function request_control(entity, timeout)
    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        return true
    end

    timeout = timeout or 300
    return entities.take_control_of(entity, timeout)
end

function request_control2(entity, timeout)
    if request_control(entity, timeout) then
        return true
    end
    notify("", "未能成功控制实体，请重试")
    return false
end

function has_control_entity(entity)
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

function get_entity_owner(entity)
    if is_in_session() and NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(entity) then
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

function is_in_session()
    return NETWORK.NETWORK_IS_SESSION_STARTED() and not is_script_running("maintransition")
end

----------------------------------------
-- Script Functions
----------------------------------------

function is_script_running(script_name)
    return SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat(script_name)) > 0
end

function start_game_script(script_name)
    script.run_in_fiber(function(script_util)
        if is_script_running(script_name) then
            return true
        end

        SCRIPT.REQUEST_SCRIPT(script_name)
        while not SCRIPT.HAS_SCRIPT_LOADED(script_name) do
            script_util:yield()
        end
        SYSTEM.START_NEW_SCRIPT(script_name, 5000)
        SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED(script_name)
        return true
    end)
end

function is_mission_controller_script_running()
    return is_script_running("fm_mission_controller") or is_script_running("fm_mission_controller_2020")
end

function get_running_mission_controller_script()
    local script_name = "fm_mission_controller"
    if is_script_running(script_name) then
        return script_name
    end

    script_name = "fm_mission_controller_2020"
    if is_script_running(script_name) then
        return script_name
    end

    return nil
end

----------------------------------------
-- Raycast Functions
----------------------------------------

function rotation_to_direction(rotation)
    local x = (3.14159265359 / 180) * rotation.x
    local z = (3.14159265359 / 180) * rotation.z
    local num = math.abs(math.cos(x))
    return {
        x = -math.sin(z) * num,
        y = math.cos(z) * num,
        z = math.sin(x)
    }
end

function get_offset_from_cam(distance)
    local cam_coords = CAM.GET_GAMEPLAY_CAM_COORD()
    local rot = CAM.GET_GAMEPLAY_CAM_ROT(2)
    local dir = rotation_to_direction(rot)

    return {
        x = cam_coords.x + dir.x * distance,
        y = cam_coords.y + dir.y * distance,
        z = cam_coords.z + dir.z * distance,
    }
end

function get_raycast_result(distance)
    distance = distance or 1500.0

    local cam_coords = CAM.GET_FINAL_RENDERED_CAM_COORD()
    local offset = get_offset_from_cam(distance)

    local handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
        cam_coords.x, cam_coords.y, cam_coords.z,
        offset.x, offset.y, offset.z,
        -1,
        0,
        3) -- SCRIPT_SHAPETEST_OPTION_IGNORE_GLASS | SCRIPT_SHAPETEST_OPTION_IGNORE_SEE_THROUGH

    local status, hit, endCoords, surfaceNormal, entityHit = SHAPETEST.GET_SHAPE_TEST_RESULT(handle, nil, nil, nil, nil)
    if status ~= 2 then
        return {}
    end

    return {
        hit = hit,
        endCoords = endCoords,
        surfaceNormal = surfaceNormal,
        entityHit = entityHit
    }
end

----------------------------------------
-- Misc Functions
----------------------------------------

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

function get_label_text(labelName)
    local text = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(labelName)
    if text == "" or text == "NULL" then
        return text
    end

    text = string.gsub(text, "~n~", "\n")
    text = string.gsub(text, "µ", " ")
    return text
end

function notify(title, message)
    gui.show_message("[RScript] " .. title, message)
end

function toast(text)
    gui.show_message("[RScript]", tostring(text))
end

function print(text)
    log.info(tostring(text))
end

--- @param text string
--- @param x float
--- @param y float
--- @param scale? float 1.0 = normal / 2.0 = double
--- @param color? table<key, int> r, g, b, a should between 0 and 255. Alpha 0 is invisible.
function draw_text(text, x, y, scale, color)
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")

    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)

    --[[
        FONT_STANDARD = 0,
        FONT_CURSIVE = 1,
        FONT_ROCKSTAR_TAG = 2,
        FONT_LEADERBOARD = 3,
        FONT_CONDENSED = 4,
        FONT_STYLE_FIXED_WIDTH_NUMBERS = 5,
        FONT_CONDENSED_NOT_GAMERNAME = 6,
        FONT_STYLE_PRICEDOWN = 7,
        FONT_STYLE_TAXI = 8
    ]]
    -- Set the text font
    HUD.SET_TEXT_FONT(0)

    if scale then
        -- Sets the text scale by using a multiplier
        HUD.SET_TEXT_SCALE(scale, scale)
    end

    if color then
        -- Sets the colour of the text
        HUD.SET_TEXT_COLOUR(color.r, color.g, color.b, color.a)
    end

    -- Sets points where text will wrap round and displayed on a new line
    HUD.SET_TEXT_WRAP(0.0, 1.0)

    -- Draws an drop shadow behind the text
    HUD.SET_TEXT_DROP_SHADOW()

    -- Draw a drop shadow behind onscreen intro text
    HUD.SET_TEXT_DROPSHADOW(1, 0, 0, 0, 0)

    -- Draws an outline round the entire text
    HUD.SET_TEXT_OUTLINE()

    -- Draws an outline round the entire text
    HUD.SET_TEXT_EDGE(1, 0, 0, 0, 0)

    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end

function draw_crosshair()
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
    HUD.SET_TEXT_FONT(0)
    HUD.SET_TEXT_SCALE(1.0, 0.5)
    HUD.SET_TEXT_CENTRE(true)
    HUD.SET_TEXT_OUTLINE()
    HUD.SET_TEXT_COLOUR(255, 255, 255, 255)
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("·")
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.49997, 0.478, 0)
end

----------------------------------------
-- Table Functions
----------------------------------------

function reverse_ped_hash(hash)
    return T.PedHashTable[hash] or ""
end

function reverse_vehicle_hash(hash)
    return T.VehicleHashTable[hash] or ""
end

function reverse_weapon_hash(hash)
    return T.WeaponHashTable[hash] or ""
end

function table.contains(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

----------------------------------------
-- Pickup Pool Functions
----------------------------------------

PickupPool = {}
PickupPool.__index = PickupPool

function PickupPool:is_vaild(index)
    local bit_value = self.m_bit_array:add(index):get_byte()

    return bit_value > 1 and bit_value < 80
end

function PickupPool:get_address(index)
    return self.m_pool_address:add(self.m_item_size * index)
end

function PickupPool.init()
    script.run_in_fiber(function()
        local ptr = memory.scan_pattern("48 8B 05 ? ? ? ? 0F B7 50 10 48 8B 05")
        if ptr:is_null() then -- Check for null pointer.
            log.warning("Pickup Pool pattern scan failed")
            return
        end
        local m_pickup_pool = ptr:add(0xE):rip():deref()
        if m_pickup_pool:is_null() then -- Check for null pointer.
            log.warning("Pickup Pool pattern scan failed")
            return
        end

        PickupPool.m_pool_address = m_pickup_pool:deref()
        PickupPool.m_bit_array = m_pickup_pool:add(0x8):deref()
        PickupPool.m_size = m_pickup_pool:add(0x10):get_dword()
        PickupPool.m_item_size = m_pickup_pool:add(0x14):get_dword()

        -- print(string.format(
        --     "m_pickup_pool: %x, m_pool_address: %x, m_bit_array: %x",
        --     m_pickup_pool:get_address(),
        --     PickupPool.m_pool_address:get_address(),
        --     PickupPool.m_bit_array:get_address()
        -- ))

        PickupPool.initialized = true
    end)
end

PickupPool.init()

--- @return table<int, pointer>
function get_all_pickups_as_pointers()
    local self = setmetatable({}, PickupPool)
    if not self.initialized then
        return {}
    end

    local pickups = {}

    for index = 0, self.m_size - 1 do
        if self:is_vaild(index) then
            local addr = self:get_address(index)
            table.insert(pickups, addr)
        end
    end

    return pickups
end

--- @return table<int, Pickup>
function get_all_pickups_as_handles()
    local self = setmetatable({}, PickupPool)
    if not self.initialized then
        return {}
    end

    local pickups = {}

    for index = 0, self.m_size - 1 do
        if self:is_vaild(index) then
            local addr = self:get_address(index)
            local handle = memory.ptr_to_handle(addr)
            table.insert(pickups, handle)
        end
    end

    return pickups
end

----------------------------------------
-- Tab Functions (Old)
----------------------------------------

tabs = {}

function tabs.add_input_float(tab, name, tab_tables, default_value, help_text)
    local t = tab:add_input_float(name)

    if tab_tables ~= nil then
        tab_tables[name] = t
    end
    if default_value ~= nil then
        t:set_value(default_value)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end
end

function tabs.add_input_int(tab, name, tab_tables, default_value, help_text)
    local t = tab:add_input_int(name)

    if tab_tables ~= nil then
        tab_tables[name] = t
    end
    if default_value ~= nil then
        t:set_value(default_value)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end
end

function tabs.add_input_string(tab, name, tab_tables, default_value, help_text)
    local t = tab:add_input_string(name)

    if tab_tables ~= nil then
        tab_tables[name] = t
    end
    if default_value ~= nil then
        t:set_value(default_value)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end
end

function tabs.add_checkbox(tab, name, tab_tables, enabled, help_text)
    local t = tab:add_checkbox(name)

    if tab_tables ~= nil then
        tab_tables[name] = t
    end
    if enabled ~= nil then
        t:set_enabled(enabled)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end
end

function tabs.add_toggle_button(tab, name, toggle_tables, toggle, toggle_func)
    local t
    t = tab:add_button(string.format("%s: %s", name, toggle and "开" or "关"), function()
        local new_toggle = not toggle_tables[name]

        toggle_tables[name] = new_toggle
        t:set_text(string.format("%s: %s", name, new_toggle and "开" or "关"))

        if toggle_func ~= nil then
            toggle_func(new_toggle)
        end
    end)

    toggle_tables[name] = toggle
end

function tabs.check_input_value(input, min_value, max_value, show_warning)
    if show_warning == nil then show_warning = true end

    local value = tonumber(input:get_value())
    if value == nil then
        if show_warning then
            notify(input:get_text(), "数值输入格式错误！")
        end
        return false
    end
    if value < min_value then
        if show_warning then
            notify(input:get_text(), "数值输入超过最小范围: " .. tostring(min_value))
        end
        return false
    end
    if value > max_value then
        if show_warning then
            notify(input:get_text(), "数值输入超过最大范围: " .. tostring(max_value))
        end
        return false
    end
    return true
end

----------------------------------------
-- Menu Functions
----------------------------------------

menu = {}

function menu.add_button(menu_parent, name, help_text, on_click)
    if help_text ~= nil then
        name = name .. " " .. help_text
    end
    menu_parent:add_button(name, on_click)
end

function menu.add_input_float(menu_table, name, default_value, help_text)
    local t = menu_table._parent:add_input_float(name)

    if default_value ~= nil then
        t:set_value(default_value)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end

    menu_table[name] = t
    return t
end

function menu.add_input_int(menu_table, name, default_value, help_text)
    local t = menu_table._parent:add_input_int(name)

    if default_value ~= nil then
        t:set_value(default_value)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end

    menu_table[name] = t
    return t
end

function menu.add_input_string(menu_table, name, default_value, help_text)
    local t = menu_table._parent:add_input_string(name)

    if default_value ~= nil then
        t:set_value(default_value)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end

    menu_table[name] = t
    return t
end

function menu.add_toggle(menu_table, name, enabled, help_text)
    local t = menu_table._parent:add_checkbox(name)

    if enabled ~= nil then
        t:set_enabled(enabled)
    end
    if help_text ~= nil then
        t:set_text(name .. " " .. help_text)
    end

    menu_table[name] = t
    return t
end

function menu.add_toggle_loop(menu_table, name, help_text, on_tick, on_stop)
    local t = menu_table._parent:add_checkbox(name)

    if help_text and help_text ~= "" then
        t:set_text(name .. " " .. help_text)
    end
    if on_tick then
        MainLoop[name] = {
            toggle = t,
            on_tick = on_tick,
            on_stop = on_stop,
            need_to_run_stop = false
        }
    end

    return t
end

function menu.add_toggle_button(menu_table, name, toggle, on_change)
    local t
    local _toggle = toggle
    t = menu_table._parent:add_button(string.format("%s: %s", name, toggle and "开" or "关"), function()
        local new_toggle = not _toggle

        _toggle = new_toggle
        t:set_text(string.format("%s: %s", name, new_toggle and "开" or "关"))

        if on_change ~= nil then
            on_change(new_toggle)
        end
    end)
end

function menu.get_input_value(input, min_value, max_value)
    local input_value = input:get_value()

    if input_value < min_value then
        input:set_value(min_value)
        return min_value
    end

    if input_value > max_value then
        input:set_value(max_value)
        return max_value
    end

    return input_value
end
