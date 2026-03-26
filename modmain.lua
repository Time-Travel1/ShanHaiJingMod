GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

PrefabFiles = {
    "sh_xishan_herb",
    "sh_xishan_leaf",
    "sh_xishan_talisman",
    "sh_xishan_marker",
}
Assets = {}

local CFG = GLOBAL.require("sh_config")
GLOBAL.require("sh_xishan_runtime").Init(CFG)

-- modmain 里的职责：
-- - 把可配置的显示名写进 STRINGS（用于游戏界面里可能出现的名字/本地化key）
-- - worldgen：modworldgenmain.lua + scripts/sh_config.lua
-- - 域内客户端氛围：scripts/sh_xishan_runtime.lua（读 CFG.Runtime）
--
-- 备注：
-- - modinfo.lua 的名称/简介是 DST 的启动配置，不能稳定从这里动态读取，所以 modinfo.lua 里仍是静态字符串。
-- - 这里仅用于把 CFG.Mod.DisplayName 写入 STRINGS（如果你的 DST 版本/界面会用到该 key）。
STRINGS.NAMES.SHANHAIJING_XISHAN = CFG.Mod.DisplayName
STRINGS.NAMES.SH_XISHAN_HERB = "西山灵草"
STRINGS.NAMES.SH_XISHAN_LEAF = "西山草叶"
STRINGS.NAMES.SH_XISHAN_TALISMAN = "西山护符"
STRINGS.NAMES.SH_XISHAN_MARKER = "西山域界碑"

STRINGS.RECIPE_DESC.SH_XISHAN_TALISMAN = "以西山草叶编成的护身符。"

STRINGS.CHARACTERS.GENERIC.DESCRIBE.SH_XISHAN_HERB = "有股山中寒气。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SH_XISHAN_LEAF = "闻起来比普通草更清冽。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SH_XISHAN_TALISMAN = "佩在身上，心会更定。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SH_XISHAN_MARKER = "刻痕指向西山域深处。"

AddRecipe2(
    "sh_xishan_talisman",
    {
        Ingredient("sh_xishan_leaf", 4),
        Ingredient("goldnugget", 1),
        Ingredient("flint", 1),
    },
    TECH.SCIENCE_ONE,
    { numtogive = 1 },
    { "MAGIC" }
)
