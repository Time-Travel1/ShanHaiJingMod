-- 西山域「运行时氛围」：仅客户端；用拓扑房间 ID 判断是否在西山域内。
-- 逻辑与数值尽量读 sh_config.lua 的 M.Runtime，避免写死。

local function BuildRoomSet(worldgen)
    local t = {}
    if worldgen and worldgen.Rooms then
        for room_id in pairs(worldgen.Rooms) do
            t[room_id] = true
        end
    end
    return t
end

local function IsInDomain(world, px, py, pz, roomset)
    if world == nil or world.Map == nil or world.topology == nil or world.topology.ids == nil then
        return false
    end
    local ok, tid = pcall(function()
        return world.Map:GetTopologyIDAtPoint(px, py, pz)
    end)
    if not ok or tid == nil or tid == "" then
        return false
    end
    return roomset[tid] == true
end

local function CopyColourCubeTable(src)
    if src == nil then
        return nil
    end
    return {
        day = src.day,
        dusk = src.dusk,
        night = src.night,
        full_moon = src.full_moon,
    }
end

local function ApplyVision(inst, enabled, cc_table)
    local vision = inst.components.playervision
    if vision == nil then
        return
    end
    if enabled and cc_table ~= nil then
        vision:SetCustomCCTable(cc_table, nil)
    else
        vision:SetCustomCCTable(nil, nil)
    end
end

local function PlayIfConfigured(inst, path)
    if path == nil or path == "" then
        return
    end
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound(path)
    end
end

local function StartForPlayer(inst, cfg)
    local rt = cfg.Runtime
    if rt == nil or rt.Enabled ~= true then
        return
    end

    local roomset = BuildRoomSet(cfg.Worldgen)
    local period = rt.PollPeriod or 0.4
    if period < 0.1 then
        period = 0.1
    end

    local cc_table = nil
    if rt.EnableColourCube and rt.ColourCube then
        cc_table = CopyColourCubeTable(rt.ColourCube)
    end

    local inside = false

    local function tick()
        if inst ~= GLOBAL.ThePlayer or not inst:IsValid() then
            return
        end
        local world = GLOBAL.TheWorld
        if world == nil or world.Map == nil then
            return
        end
        local x, y, z = inst.Transform:GetWorldPosition()
        local now = IsInDomain(world, x, y, z, roomset)
        if now ~= inside then
            inside = now
            if rt.EnableColourCube then
                ApplyVision(inst, inside, cc_table)
            end
            if inside then
                PlayIfConfigured(inst, rt.SoundEnter)
            else
                PlayIfConfigured(inst, rt.SoundLeave)
            end
        end
    end

    tick()
    inst:DoPeriodicTask(period, tick)

    inst:ListenForEvent("onremove", function()
        if inside and rt.EnableColourCube then
            ApplyVision(inst, false, nil)
        end
    end)
end

local M = {}

function M.Init(cfg)
    GLOBAL.AddPlayerPostInit(function(inst)
        if not GLOBAL.TheNet:GetIsClient() then
            return
        end
        inst:DoTaskInTime(0, function()
            if not GLOBAL.TheNet:GetIsClient() then
                return
            end
            if inst ~= GLOBAL.ThePlayer then
                return
            end
            StartForPlayer(inst, cfg)
        end)
    end)
end

return M
