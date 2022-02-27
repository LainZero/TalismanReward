local modName = "Talisman Reward"
local folderName = modName
local give_rewards = false

local modUtils = require(folderName .. "/modUtils")

local settings = modUtils.getConfigHandler({
    enabledTalismanReward = true,
    questRankCriteria = 7.0,
    rewardCounts = 1.0
}, folderName)

local fm = sdk.get_managed_singleton("snow.data.FacilityDataManager");
local qm = sdk.get_managed_singleton("snow.QuestManager");
local dm = sdk.get_managed_singleton("snow.data.DataManager");

log.info(modName .. " loaded!")

local function better_rewards(retval)
    if give_rewards == false then
        local qlv = qm:call("getQuestLv");
        local qlvex = qm:call("getQuestLvEx");
        local qr = qm:call("getQuestRank_Lv");
        local elv = qm:call("getEnemyLv");

        log.info(modName .. " qlv : " .. qlv)
        log.info(modName .. " qlvex : " .. qlvex)
        log.info(modName .. " qr : " .. qr)
        log.info(modName .. " Criteria : " .. settings.data.questRankCriteria)

        -- if (qlv + 1) >= 4 or (qlvex + 1) >= 4 or qr >= 1 then -- 集会所上位★4(オサイズチ)
        -- if (qlv + 1) >= 1 or (qlvex + 1) >= 1 or qr >= 0 then -- 集会所イベント下位(ソニックリング)
        -- if (qlv + 1) >= 0 or (qlvex + 1) >= 0 or qr >= 0 then -- 里★1 ホオズキ(自分でクリア)
        if (qlv + 1) >= tonumber(settings.data.questRankCriteria) then
            give_rewards = true;
        end
    end
end

local function get_rewards(retval)
    if qm == nil then
        fm = sdk.get_managed_singleton("snow.data.FacilityDataManager");
        qm = sdk.get_managed_singleton("snow.QuestManager");
        dm = sdk.get_managed_singleton("snow.data.DataManager");
    end

    if settings.data.enabledTalismanReward then
        if give_rewards then
            local alchemy = fm:call("getAlchemy");
            local slots = alchemy:call("getRemainingSlotNum");
            log.info(modName .. " RemainingSlot : " .. slots);
            if slots > 0 then
                local ib = dm:call("get_PlItemBox");
                local vp = dm:call("get_VillagePointData");
                local num = math.min(slots, tonumber(settings.data.rewardCounts));
                ib:call("tryAddGameItem(snow.data.ContentsIdSystem.ItemId, System.Int32)", 68158506, 19 * num);
                vp:call("addPoint(System.UInt32)", 500 * num);
                local list = alchemy:call("getPatturnDataList"):call("ToArray");
                for i = num, 1, -1 do
                    alchemy:call("selectPatturn", list[3]);
                    alchemy:call("addUsingItem", 68158506, 19);
                    alchemy:call("reserveAlchemy");
                    alchemy:call("invokeCycleMethod");
                end
            end
            give_rewards = false;
        end
    end
end

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("setQuestClear"),
function (args)end,
better_rewards);

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("setQuestClearSub"),
function (args)end,
better_rewards);

sdk.hook(sdk.find_type_definition("snow.data.FacilityDataManager"):get_method("onChangedGameStatus"),
function (args)end,
get_rewards);

-- Talisman Reward Configuration on REFramework UI
re.on_draw_ui(function()
    if imgui.tree_node(modName) then
        local changedEnabled, userenabled =
            imgui.checkbox("Talisman Reward", settings.data.enabledTalismanReward)
        settings.handleChange(changedEnabled, userenabled, "enabledTalismanReward")

        local changedCriteria, userQuestRankCriteria =
            imgui.slider_int("Quest Rank grater than", settings.data.questRankCriteria, 0, 7, '%d')
        settings.handleChange(changedCriteria, userQuestRankCriteria, "questRankCriteria")

        local changedRewardCounts, userRewardCounts =
            imgui.slider_int("Reward Counts", settings.data.rewardCounts, 1, 5, '%d')
        settings.handleChange(changedRewardCounts, userRewardCounts, "rewardCounts")

        if not settings.isSavingAvailable then
            imgui.text(
                "WARNING: JSON utils not available (your REFramework version may be outdated). Configuration will not be saved between restarts.")
        end

        imgui.text(version)
        imgui.tree_pop()
    end
end)