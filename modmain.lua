GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

PrefabFiles = {}
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
