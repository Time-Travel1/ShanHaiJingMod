GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- 西山域：主世界森林 level 中追加独立 task。
-- 基础可辨识环境：官方地皮上堆「化石树 + 多岩 + 疏林（twiggy）+ 瘠薄草甸」，与小地图房间色调，与周边常青密林/草原拉开剪影；专用贴图 turf 后续再加。

local LOCKS = GLOBAL.LOCKS
local KEYS = GLOBAL.KEYS

-- 岩石旷野：化石树成片、裸岩多、草/浆果刻意压低，读出「荒山石塬」。
AddRoom("XISHAN_CLEARING", {
    colour = { r = 0.52, g = 0.50, b = 0.28, a = 0.38 },
    value = GLOBAL.GROUND.ROCKY,
    tags = { "ExitPiece", "RoadPoison" },
    contents = {
        distributepercent = 0.42,
        distributeprefabs = {
            rock1 = 0.12,
            rock2 = 0.12,
            rock_flintless = 0.08,
            flint = 0.04,
            rock_petrified_tree_short = 0.07,
            rock_petrified_tree_med = 0.06,
            rock_petrified_tree_tall = 0.05,
            rock_petrified_tree_old = 0.04,
            twiggy_short = 0.07,
            twiggy_normal = 0.05,
            twigs = 0.10,
            grass = 0.03,
            berrybush = 0.005,
            skeleton = 0.02,
            houndbone = 0.015,
            goldnugget = 0.012,
        },
    },
})

-- 灰土缓坡：常青与化石混交，保留一点「经行山路」感。
AddRoom("XISHAN_SLOPE", {
    colour = { r = 0.45, g = 0.48, b = 0.30, a = 0.38 },
    value = GLOBAL.GROUND.DIRT,
    tags = { "ExitPiece", "RoadPoison" },
    contents = {
        distributepercent = 0.38,
        distributeprefabs = {
            rock1 = 0.08,
            rock2 = 0.08,
            rock_flintless = 0.05,
            flint = 0.03,
            rock_petrified_tree_short = 0.04,
            rock_petrified_tree_med = 0.04,
            rock_petrified_tree_tall = 0.04,
            rock_petrified_tree_old = 0.03,
            pinecone = 0.03,
            evergreen_short = 0.08,
            evergreen_normal = 0.10,
            evergreen_tall = 0.08,
            twiggy_tall = 0.04,
            skeleton = 0.015,
            goldnugget = 0.01,
        },
    },
})

-- 石峰脊线：几乎纯石与枯化树影，地块内一眼偏「绝岭」。
AddRoom("XISHAN_PEAK", {
    colour = { r = 0.58, g = 0.52, b = 0.26, a = 0.4 },
    value = GLOBAL.GROUND.ROCKY,
    tags = { "ExitPiece", "RoadPoison" },
    contents = {
        distributepercent = 0.45,
        distributeprefabs = {
            rock1 = 0.16,
            rock2 = 0.14,
            rock_flintless = 0.10,
            flint = 0.03,
            rock_petrified_tree_old = 0.09,
            rock_petrified_tree_tall = 0.07,
            rock_petrified_tree_med = 0.05,
            rock_petrified_tree_short = 0.04,
            twigs = 0.08,
            grass = 0.01,
            skeleton = 0.025,
            houndbone = 0.02,
            goldnugget = 0.015,
        },
    },
})

AddTask("XISHAN_DOMAIN", {
    locks = { LOCKS.NONE },
    keys_given = { KEYS.NONE },
    entrance_room = "Forest",
    room_choices = {
        ["XISHAN_CLEARING"] = 2,
        ["XISHAN_SLOPE"] = 2,
        ["XISHAN_PEAK"] = 1,
    },
    room_bg = GLOBAL.GROUND.ROCKY,
    background_room = "BGNoise",
    colour = { r = 0.96, g = 0.82, b = 0.22, a = 1 },
})

AddLevelPreInit("SURVIVAL_TOGETHER", function(level)
    if level.location == "forest" and level.tasks ~= nil then
        table.insert(level.tasks, "XISHAN_DOMAIN")
    end
end)
