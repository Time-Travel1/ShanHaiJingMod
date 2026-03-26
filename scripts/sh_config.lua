-- 西山域可调配置（唯一入口）
-- 你只需要改这里（尽量不要改 Lua 逻辑代码），就能调整：
-- 1) 在地图上出现的「任务 / 房间」ID与名称（仅用于 worldgen 拼接）
-- 2) 每个房间使用的地皮类型（ground）与分布权重（distributeprefabs）
-- 3) 小地图小格的颜色（colour）
-- 4) 客户端「域内氛围」：Runtime（轮询周期、是否叠色、colour cube 路径、进出音效）
--
-- 重要提醒：
-- - room_id / TaskId / LevelId 等 ID：不要随便改。DST worldgen 可能会缓存或复用旧 ID，改错会导致“看起来没生成”或表现异常。
-- - ground 字段：必须是 GLOBAL.GROUND 里已有的键名（比如 ROCKY / DIRT / SAVANNA 等）。本文件里的 code 会把 ground="ROCKY" 映射到 GLOBAL.GROUND.ROCKY。
-- - distributeprefabs 里的 key：必须是游戏里已经存在的 prefab 名称（原版或你自己的 prefab）。否则 worldgen 分布那项会报错或直接不生成。
-- - distributepercent / distributeprefabs 的数值：属于“权重/密度”，不是百分比保证；调参需新档验证（或至少重开世界）。
--
-- 备注：modinfo.lua 的「显示名/简介」仍由 DST 的 modinfo 机制决定，不能稳定从这里动态读取。
-- 本文件主要用于 worldgen 与可调环境参数。

local M = {}

M.Mod = {
    DisplayName = "山海经 · 西山域",
    Version = "0.2.4",
    Description = [[
【第一阶段】主世界森林追加「西山域」生成任务：化石林 + 多岩 + 疏林（twiggy）+ 灰土/岩地混搭，小地图黄绿偏金色块可辨；仍为官方地皮占位，神山建筑与域内天气在后续版本加入。

【第二阶段（占位）】原版地标 + 氛围生物；新增最小玩法闭环（西山灵草→草叶→护符），并保留域内氛围与轻量玩法光环可配置。

新建世界后跑图寻找西山域地块。
]],
}

M.Worldgen = {
    -- 只挂到哪个主世界生成入口
    -- LevelId：联机版主世界的开关（通常是 SURVIVAL_TOGETHER）
    LevelId = "SURVIVAL_TOGETHER",
    -- 具体到哪类地表 level（常见：forest / savanna / desert ...）
    Location = "forest",

    -- 这个就是 AddTask() 注册出来的任务 ID
    TaskId = "XISHAN_DOMAIN",
    Task = {
        -- 任务从哪个房间类型作为入口（worldgen 用它决定先给玩家落在哪种 room）
        entrance_room = "Forest",
        -- room_choices：每个房间类型出现的“权重次数”
        -- 这里的 key 必须与 Rooms[...] 的房间 ID 一致
        room_bg = "ROCKY", -- maps to GLOBAL.GROUND.ROCKY in code
        background_room = "BGNoise",
        -- 小地图房间色块用的 RGBA；调参可以让西山域更容易一眼认出来
        colour = { r = 0.96, g = 0.82, b = 0.22, a = 1 },
        room_choices = {
            XISHAN_CLEARING = 2,
            XISHAN_SLOPE = 2,
            XISHAN_PEAK = 1,
        },
    },

    -- 动态区域大小（世界规模驱动）
    -- 说明：
    --   你当前的第一版是把同一个 task（TaskId）挂到世界生成里。
    --   这会导致小世界/大世界的「房间数」观感可能接近。
    --   为了让你要的“不一样”，我们注册多个 task 变体，然后按世界 world_size 选择其中一个。
    --
    -- 重要：
    --   - 不建议改下面生成变体 task 的后缀规则（代码里会用 TaskId .. "_" .. variantKey）
    --   - room_choices 的 key 必须是 Rooms[...] 里实际存在的房间 ID（XISHAN_CLEARING / XISHAN_SLOPE / XISHAN_PEAK）
    --   - 数值是“出现次数/权重次数”，不是百分比保证；调参需要新档验证。
    TaskVariants = {
        -- 小世界：更少房间 => 区域观感更小
        SMALL = {
            room_choices = {
                XISHAN_CLEARING = 1,
                XISHAN_SLOPE = 1,
                XISHAN_PEAK = 1,
            },
        },

        -- 默认世界：保持你当前的第一版表现
        DEFAULT = {
            room_choices = {
                XISHAN_CLEARING = 2,
                XISHAN_SLOPE = 2,
                XISHAN_PEAK = 1,
            },
        },

        -- 巨型世界：更多房间 => 区域观感更大
        HUGE = {
            room_choices = {
                XISHAN_CLEARING = 3,
                XISHAN_SLOPE = 3,
                XISHAN_PEAK = 2,
            },
        },
    },

    -- 映射：把 DST world_size 字符串映射到上面变体 key
    -- 如果你在游戏里看到的世界规模选项字符串不同，把这里补上映射即可。
    WorldSizeToVariant = {
        small = "SMALL",
        medium = "DEFAULT",
        default = "DEFAULT",
        large = "HUGE",
        huge = "HUGE",
    },

    -- 三个房间（room）定义：AddRoom() 会逐个把这里内容“拼进任务”
    Rooms = {
        XISHAN_CLEARING = {
            -- 房间色块（小地图/噪声可视层面）
            colour = { r = 0.52, g = 0.50, b = 0.28, a = 0.38 },
            -- 该房间对应的地皮类型：映射到 GLOBAL.GROUND[ground]
            ground = "ROCKY",
            -- worldgen 标签：用于生成器分类/兼容
            tags = { "ExitPiece", "RoadPoison" },
            -- 该房间的“内容分布密度”系数（比重，非硬百分比）
            distributepercent = 0.42,
            -- 该房间内会分布的 prefab 权重
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

                -- 第二阶段占位地标（原版 prefab，不新增贴图/道具）
                -- ancient_altar：上古祭坛类地标，可用于形成“神山气质”的核心剪影
                ancient_altar = 0.006,
                -- resurrectionstone：触碰石（可用于少量复活点/符号化神坛）
                resurrectionstone = 0.003,
                -- fireflies：氛围小生物/粒子感，增强“进域一震”的可见度
                fireflies = 0.012,

                -- 第二版占位：山野氛围（全原版 prefab）
                butterfly = 0.014,
                crow = 0.010,
                flower = 0.012,
                sh_xishan_herb = 0.020,
            },
        },
        XISHAN_SLOPE = {
            colour = { r = 0.45, g = 0.48, b = 0.30, a = 0.38 },
            ground = "DIRT",
            tags = { "ExitPiece", "RoadPoison" },
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

                -- 神异聚落/山路意象（占位）
                ancient_altar = 0.004,
                resurrectionstone = 0.002,
                fireflies = 0.008,

                butterfly = 0.010,
                crow = 0.008,
                molehill = 0.018,
                flower = 0.010,
                sh_xishan_herb = 0.016,
            },
        },
        XISHAN_PEAK = {
            colour = { r = 0.58, g = 0.52, b = 0.26, a = 0.40 },
            ground = "ROCKY",
            tags = { "ExitPiece", "RoadPoison" },
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

                -- 峰顶更“神”，地标权重略升，但仍保持稀有，避免挤占地皮与可玩性
                ancient_altar = 0.008,
                resurrectionstone = 0.001,
                fireflies = 0.006,

                -- 金玉/神异联想：大理石树极稀有；若某 DST 版本 worldgen 不认该 prefab，可改回 0 或删掉此行
                marbletree = 0.004,
                sh_xishan_herb = 0.008,
            },
        },
    },
}

-- 运行时氛围（不进存档；仅影响当前客户端画面/音效）
-- 判定方式：TheWorld.Map:GetTopologyIDAtPoint → 与 Worldgen.Rooms 的房间 ID 比对（勿与 worldgen 房间名脱节）。
M.Runtime = {
    -- 总开关：false 时不注册客户端轮询（零开销）
    Enabled = true,
    -- 检测周期（秒）。越小越跟脚，略增客户端负担；不建议低于 0.1
    PollPeriod = 0.35,
    -- 是否启用「调色立方」叠色（playervision:SetCustomCCTable）。幽灵视角等官方优先级仍高于本项。
    EnableColourCube = true,
    -- 以下为 DST 原版 colour cube 贴图路径；想更淡可四门都改成 identity_colourcube（几乎无叠色）
    ColourCube = {
        day = "images/colour_cubes/ruins_dim_cc.tex",
        dusk = "images/colour_cubes/ruins_dim_cc.tex",
        night = "images/colour_cubes/ruins_dark_cc.tex",
        full_moon = "images/colour_cubes/ruins_dim_cc.tex",
    },
    -- 进入域时播放的一次性音效（留空 = 不播）。须为游戏内存在的 SoundEvent 路径。
    SoundEnter = "",
    -- 离开域时播放的一次性音效（留空 = 不播）
    SoundLeave = "",
    -- 是否播放域内循环音效（会在进入域时开始、离开域时停止）
    EnableLoopSound = false,
    -- 循环音效路径（留空 = 不播）
    SoundLoop = "",

    -- 轻量玩法光环（主机判定，所有玩家一致生效）
    -- 仍属“占位玩法”层，不涉及新道具/新贴图。
    Gameplay = {
        -- 总开关：false 则不改理智/饥饿/移速
        Enabled = true,
        -- 主机检测周期（秒），建议 >= 0.2
        PollPeriod = 0.35,
        -- 域内理智每秒附加值：正数回理智，负数掉理智（例如 -0.5）
        SanityDeltaPerSecond = 0.15,
        -- 域内饥饿速率倍率：1 = 不变；<1 更耐饿；>1 更耗饥饿
        HungerRateMultiplier = 0.95,
        -- 域内移速倍率：1 = 不变
        SpeedMultiplier = 1.03,
    },
}

return M

