local modName = "Talisman Reward"
local give_rewards = false
local fm = sdk.get_managed_singleton("snow.data.FacilityDataManager");
local qm = sdk.get_managed_singleton("snow.QuestManager");
local dm = sdk.get_managed_singleton("snow.data.DataManager");

log.info(modName .. " loaded!")

local function better_rewards(retval)
    if give_rewards == false then
        local qlv = qm:call("getQuestLv")
        local qlvex = qm:call("getQuestLvEx")
        local qr = qm:call("getQuestRank_Lv")
        local elv = qm:call("getEnemyLv")

        log.info(modName .. " qlv : " .. qlv)
        log.info(modName .. " qlvex : " .. qlvex)
        log.info(modName .. " qr : " .. qr)

        -- if (qlv + 1) >= 4 or (qlvex + 1) >= 4 or qr >= 1 then -- 集会所上位★4(オサイズチ)
        -- if (qlv + 1) >= 1 or (qlvex + 1) >= 1 or qr >= 0 then -- 集会所イベント下位(ソニックリング)
        -- if (qlv + 1) >= 0 or (qlvex + 1) >= 0 or qr >= 0 then -- 里★1 ホオズキ(自分でクリア)
            give_rewards = true
        -- end
    end
end

local function get_rewards(retval)
    if qm == nil then
        fm = sdk.get_managed_singleton("snow.data.FacilityDataManager")
        qm = sdk.get_managed_singleton("snow.QuestManager");
        dm = sdk.get_managed_singleton("snow.data.DataManager");
    end

    if give_rewards then
        local alchemy = fm:call("getAlchemy")
        local slots = alchemy:call("getRemainingSlotNum")
        if slots > 0 then
            local ib = dm:call("get_PlItemBox")
            ib:call("tryAddGameItem(snow.data.ContentsIdSystem.ItemId, System.Int32)", 68158506, 19)
            local list = alchemy:call("getPatturnDataList"):call("ToArray")
            alchemy:call("selectPatturn", list[3])
            alchemy:call("addUsingItem", 68158506, 19)
            alchemy:call("reserveAlchemy")
            alchemy:call("invokeCycleMethod")
        end
        give_rewards = false
    end
end

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("setQuestClear"), 
function (args)end,
better_rewards);

sdk.hook(sdk.find_type_definition("snow.data.FacilityDataManager"):get_method("onChangedGameStatus"), 
function (args)end,
get_rewards);
