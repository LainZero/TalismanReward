local give_rewards = false

local function better_rewards(retval)
    local qm = sdk.get_managed_singleton("snow.QuestManager")
    local qlv = qm:call("getQuestLv")
    local qlvex = qm:call("getQuestLvEx")
    local elv = qm:call("getEnemyLv")
    if qlvex >= 7 then
        give_rewards = true
    end
end

local function get_rewards(retval)
    if give_rewards then
        local fm = sdk.get_managed_singleton("snow.data.FacilityDataManager")
        local alchemy = fm:call("getAlchemy")
        local slots = alchemy:call("getRemainingSlotNum")
        if slots > 0 then
            local dm = sdk.get_managed_singleton("snow.data.DataManager")
            local ib = dm:call("get_PlItemBox")
            ib:call("tryAddGameItem(snow.data.ContentsIdSystem.ItemId, System.Int32)", 68158506, 19)
            local list = alchemy:call("getPatturnDataList"):call("ToArray")
            alchemy:call("selectPatturn", list[3])
            alchemy:call("addUsingItem", 68158506, 19)
            alchemy:call("reserveAlchemy")
            alchemy:call("invokeCycleMethod")
        end
    end
    give_rewards = false
end

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("setQuestClear"), 
function (args)end,
better_rewards)

sdk.hook(sdk.find_type_definition("snow.data.FacilityDataManager"):get_method("onChangedGameStatus"), 
function (args)end,
get_rewards)
