local assets =
{
    Asset("ANIM", "anim/grass1.zip"),
}

local prefabs =
{
    "sh_xishan_leaf",
}

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

local function makebarrenfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("idle", true)
end

local function onpickedfn(inst, picker)
    inst.AnimState:PlayAnimation("picked")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .1)

    inst.MiniMapEntity:SetIcon("grass.tex")

    inst.AnimState:SetBank("grass1")
    inst.AnimState:SetBuild("grass1")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("plant")
    inst:AddTag("renewable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable:SetUp("sh_xishan_leaf", TUNING.GRASS_REGROW_TIME)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.makebarrenfn = makebarrenfn
    inst.components.pickable.onregenfn = onregenfn

    inst:AddComponent("lootdropper")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableIgnite(inst)

    return inst
end

return Prefab("sh_xishan_herb", fn, assets, prefabs)
