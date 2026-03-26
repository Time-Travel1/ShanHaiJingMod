local assets =
{
    Asset("ANIM", "anim/sign_home.zip"),
}

local prefabs =
{
    "boards",
    "cutstone",
}

local function onhammered(inst, worker)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:DropLoot()
    end
    local fx = SpawnPrefab("collapse_small")
    if fx ~= nil then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    inst:Remove()
end

local function onhit(inst)
    if inst.AnimState ~= nil then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .3)

    inst.AnimState:SetBank("sign_home")
    inst.AnimState:SetBuild("sign_home")
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("homesign.tex")

    inst:AddTag("structure")
    inst:AddTag("xishan_marker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "boards", "cutstone" })

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeHauntableWork(inst)

    return inst
end

return Prefab("sh_xishan_marker", fn, assets, prefabs)
