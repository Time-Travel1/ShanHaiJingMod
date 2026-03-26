GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- worldgen 主逻辑入口（只负责把配置“读出来并注册到 DST worldgen”）
-- 你不要在这里改数值/名字，尽量在 scripts/sh_config.lua 改。
-- 本文件的职责：
-- 1) 读取 sh_config.lua 的 Rooms/Task/LevelId/Location
-- 2) AddRoom(room_id, room_cfg) 把每个房间注册到 worldgen
-- 3) AddTask(TaskId, ...) 把房间集合组装成一个可落位任务
-- 4) 在 AddLevelPreInit(LevelId) 钩子里把 TaskId 插入到对应 level.tasks


-- scripts/sh_config.lua 会以 GLOBAL.require("sh_config") 的方式被读入
local CFG = GLOBAL.require("sh_config")
local LOCKS = GLOBAL.LOCKS
local KEYS = GLOBAL.KEYS

local function ground(id)
    -- ground id 是 "ROCKY"/"DIRT" 这类键名，映射到 GLOBAL.GROUND.<键>
    return GLOBAL.GROUND[id]
end

local function add_room(room_id, room_cfg)
    -- room_cfg 必须具备：colour / ground / tags / distributepercent / distributeprefabs
    local contents = {
        distributepercent = room_cfg.distributepercent,
        distributeprefabs = room_cfg.distributeprefabs,
    }
    -- 可选：强标记地标（countprefabs）用于“至少生成 N 个”
    if room_cfg.countprefabs ~= nil then
        contents.countprefabs = room_cfg.countprefabs
    end

    AddRoom(room_id, {
        colour = room_cfg.colour,
        value = ground(room_cfg.ground),
        tags = room_cfg.tags,
        contents = contents,
    })
end

for room_id, room_cfg in pairs(CFG.Worldgen.Rooms) do
    add_room(room_id, room_cfg)
end

-- 注册多个 task 变体（只改变 room_choices，从而让区域大小随 world_size 变化）
-- 约定：task id = CFG.Worldgen.TaskId .. "_" .. variantKey
local function variant_task_id(variantKey)
    return CFG.Worldgen.TaskId .. "_" .. tostring(variantKey)
end

for variantKey, variantCfg in pairs(CFG.Worldgen.TaskVariants or {}) do
    AddTask(variant_task_id(variantKey), {
        locks = { LOCKS.NONE },
        keys_given = { KEYS.NONE },
        entrance_room = CFG.Worldgen.Task.entrance_room,
        room_choices = variantCfg.room_choices,
        room_bg = ground(CFG.Worldgen.Task.room_bg),
        background_room = CFG.Worldgen.Task.background_room,
        colour = CFG.Worldgen.Task.colour,
    })
end

-- 把对应变体 task 挂到指定 level（主世界生成入口）上
AddLevelPreInit(CFG.Worldgen.LevelId, function(level)
    if level.location == CFG.Worldgen.Location and level.tasks ~= nil then
        -- DST 不同版本 level 字段命名不一定一致，因此用多种候选字段兜底
        local function normalize(sz)
            if sz == nil then
                return nil
            end
            if type(sz) ~= "string" then
                sz = tostring(sz)
            end
            return string.lower(sz)
        end

        local ws =
            normalize(level.world_size)
            or normalize(level.worldSize)
            or normalize(level.map_size)
            or normalize(level.mapSize)
            or normalize(level.worldsettings and (level.worldsettings.world_size or level.worldsettings.worldSize))
            or normalize(level.worldsettings_overrides and (level.worldsettings_overrides.world_size or level.worldsettings_overrides.worldSize))

        -- 根据 world_size 选择 task 变体：
        -- 1) 优先精确映射（small/default/large/huge 等）
        -- 2) 再做兜底：用字符串包含判断（避免不同版本字段命名不一致导致精确匹配失败）
        local variantKey = "DEFAULT"
        if ws and CFG.Worldgen.WorldSizeToVariant and CFG.Worldgen.WorldSizeToVariant[ws] then
            variantKey = CFG.Worldgen.WorldSizeToVariant[ws]
        elseif ws then
            if string.find(ws, "small", 1, true) then
                variantKey = "SMALL"
            elseif string.find(ws, "huge", 1, true) then
                variantKey = "HUGE"
            elseif string.find(ws, "large", 1, true) then
                -- 有些版本“large”可能就是你想要的“大区域”观感；这里直接走 HUGE 方案
                variantKey = "HUGE"
            elseif string.find(ws, "medium", 1, true) then
                variantKey = "DEFAULT"
            elseif string.find(ws, "default", 1, true) then
                variantKey = "DEFAULT"
            end
        end

        table.insert(level.tasks, variant_task_id(variantKey))
    end
end)
