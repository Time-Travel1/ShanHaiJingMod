-- 西山域「运行时氛围」：客户端做画面/音效，主机做玩法光环；都用拓扑房间 ID 判定域内。
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

local RUNTIME_MOD_KEY = "sh_xishan_runtime"
local RUNTIME_LOOP_SOUND_TAG = "sh_xishan_loop"

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

local function UpdateLoopSound(inst, enabled, path)
    if inst.SoundEmitter == nil then
        return
    end
    if enabled and path ~= nil and path ~= "" then
        inst.SoundEmitter:PlaySound(path, RUNTIME_LOOP_SOUND_TAG)
    else
        inst.SoundEmitter:KillSound(RUNTIME_LOOP_SOUND_TAG)
    end
end

local function ClampOrDefault(v, d, minv, maxv)
    if type(v) ~= "number" then
        return d
    end
    if minv ~= nil and v < minv then
        return minv
    end
    if maxv ~= nil and v > maxv then
        return maxv
    end
    return v
end

local function ApplyGameplayAura(inst, enabled, rt)
    local gp = rt and rt.Gameplay
    if gp == nil or gp.Enabled ~= true then
        enabled = false
    end

    if inst.components == nil then
        return
    end

    if inst.components.sanity ~= nil and inst.components.sanity.externalmodifiers ~= nil then
        if enabled then
            local sanity_delta = ClampOrDefault(gp.SanityDeltaPerSecond, 0, -20, 20)
            inst.components.sanity.externalmodifiers:SetModifier(RUNTIME_MOD_KEY, sanity_delta)
        else
            inst.components.sanity.externalmodifiers:RemoveModifier(RUNTIME_MOD_KEY)
        end
    end

    if inst.components.hunger ~= nil and inst.components.hunger.burnratemodifiers ~= nil then
        if enabled then
            local hunger_mult = ClampOrDefault(gp.HungerRateMultiplier, 1, 0.2, 3)
            inst.components.hunger.burnratemodifiers:SetModifier(RUNTIME_MOD_KEY, hunger_mult)
        else
            inst.components.hunger.burnratemodifiers:RemoveModifier(RUNTIME_MOD_KEY)
        end
    end

    if inst.components.locomotor ~= nil then
        if enabled then
            local speed_mult = ClampOrDefault(gp.SpeedMultiplier, 1, 0.5, 1.8)
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, RUNTIME_MOD_KEY, speed_mult)
        else
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, RUNTIME_MOD_KEY)
        end
    end
end

local function StartForLocalPlayerClient(inst, cfg)
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
            if rt.EnableLoopSound then
                UpdateLoopSound(inst, inside, rt.SoundLoop)
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
        UpdateLoopSound(inst, false, nil)
    end)
end

local function StartForPlayerMaster(inst, cfg)
    local rt = cfg.Runtime
    if rt == nil or rt.Enabled ~= true then
        return
    end
    local gp = rt.Gameplay
    if gp == nil or gp.Enabled ~= true then
        return
    end

    local roomset = BuildRoomSet(cfg.Worldgen)
    local period = gp.PollPeriod or rt.PollPeriod or 0.4
    if period < 0.1 then
        period = 0.1
    end

    local inside = false

    local function tick()
        if not inst:IsValid() then
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
            ApplyGameplayAura(inst, inside, rt)
        end
    end

    tick()
    inst:DoPeriodicTask(period, tick)

    inst:ListenForEvent("onremove", function()
        ApplyGameplayAura(inst, false, rt)
    end)
end

local M = {}

function M.Init(cfg)
    GLOBAL.AddPlayerPostInit(function(inst)
        if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastersim then
            StartForPlayerMaster(inst, cfg)
        end

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
            StartForLocalPlayerClient(inst, cfg)
        end)
    end)
end

return M
