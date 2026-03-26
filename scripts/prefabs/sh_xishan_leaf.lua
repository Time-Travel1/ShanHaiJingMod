local assets =
{
    Asset("ANIM", "anim/cutgrass.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("cutgrass")
    inst.AnimState:SetBuild("cutgrass")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("molebait")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"
    inst.components.inventoryitem.imagename = "cutgrass"

    inst:AddComponent("stackable")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GOODIES
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.sanityvalue = TUNING.SANITY_TINY

    inst:AddComponent("tradable")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("sh_xishan_leaf", fn, assets)
