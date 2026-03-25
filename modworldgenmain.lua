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
    AddRoom(room_id, {
        colour = room_cfg.colour,
        value = ground(room_cfg.ground),
        tags = room_cfg.tags,
        contents = {
            distributepercent = room_cfg.distributepercent,
            distributeprefabs = room_cfg.distributeprefabs,
        },
    })
end

for room_id, room_cfg in pairs(CFG.Worldgen.Rooms) do
    add_room(room_id, room_cfg)
end

-- 把 CFG.Worldgen.Task 组装成一个 task
AddTask(CFG.Worldgen.TaskId, {
    locks = { LOCKS.NONE },
    keys_given = { KEYS.NONE },
    entrance_room = CFG.Worldgen.Task.entrance_room,
    room_choices = CFG.Worldgen.Task.room_choices,
    room_bg = ground(CFG.Worldgen.Task.room_bg),
    background_room = CFG.Worldgen.Task.background_room,
    colour = CFG.Worldgen.Task.colour,
})

-- 把该 task 挂到指定 level（主世界生成入口）上
AddLevelPreInit(CFG.Worldgen.LevelId, function(level)
    if level.location == CFG.Worldgen.Location and level.tasks ~= nil then
        table.insert(level.tasks, CFG.Worldgen.TaskId)
    end
end)
