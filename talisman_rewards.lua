local modName = "Talisman Reward"
local folderName = modName
local version = "Version: 2.1.4"
local give_rewards = false
local talisman_level = 5
local FRIEND_VOUCHER_ID = 68158506
local charms = {[3]={points=500, tickets=19},[5]={points=1000, tickets=25}}

local modUtils = require(folderName .. "/modUtils")

local settings = modUtils.getConfigHandler({
  enabledTalismanReward = true,
  questRankCriteria = 7.0,
  questRankEXCriteria = 6.0,
  rewardCounts = 1.0
}, folderName)

local fm = sdk.get_managed_singleton("snow.data.FacilityDataManager");
local qm = sdk.get_managed_singleton("snow.QuestManager");
local dm = sdk.get_managed_singleton("snow.data.DataManager");

log.info(modName .. " loaded!")

-- if (qlv + 1) >= 4 or (qlvex + 1) >= 4 or qr >= 1 then -- 集会所上位★4(オサイズチ)
-- if (qlv + 1) >= 1 or (qlvex + 1) >= 1 or qr >= 0 then -- 集会所イベント下位(ソニックリング)
-- if (qlv + 1) >= 0 or (qlvex + 1) >= 0 or qr >= 0 then -- 里★1 ホオズキ(自分でクリア)
local function check_rewards_on_quest_complete(retval)
    local qm = sdk.get_managed_singleton("snow.QuestManager")
    local qrlv = qm:call("getQuestRank_Lv")
    local qlvex = qm:call("getQuestLvEx")
    local qlv = qm:call("getQuestLv")

    log.info(modName .. " qlv : " .. qlv)
    log.info(modName .. " qlvex : " .. qlvex)
    log.info(modName .. " qrlv : " .. qrlv)
    log.info(modName .. " Criteria : " .. settings.data.questRankCriteria)
    log.info(modName .. " EX Criteria : " .. settings.data.questRankEXCriteria)

    -- if qrlv >=2 and qlv>=5 then
    if (qlv + 1) >= tonumber(settings.data.questRankCriteria) then
        give_rewards = true
        talisman_level = 5
        log.info(modName .. " TalismanLv : " .. talisman_level)
    -- elseif qlvex >= 7 or qrlv >=2 then
    elseif (qlvex + 1) >= tonumber(settings.data.questRankEXCriteria) then
        give_rewards = true
        talisman_level = 5
        log.info(modName .. " TalismanLv : " .. talisman_level)
    end
end

local function swap_talismans(alchemy, index)
    local af = alchemy:call("get_Function")
    local list = af:get_field("_ReserveInfoList")
    local array = list:call("ToArray")
    local temp = array:get_element(0)

    array:call("SetValue", array:get_element(index), 0)
    for i=1, index do
        local curr = array:get_element(i)
        array:call("SetValue", temp, i)
        temp = curr
    end

    list:call("Clear")
    list:call("AddRange", array)
end

local function add_points(dm)
    local points = dm:call("get_VillagePointData")
    points:call("addPoint", charms[talisman_level]["points"])
end

local function add_tickets(dm)
    local ib = dm:call("get_PlItemBox")
    ib:call("tryAddGameItem(snow.data.ContentsIdSystem.ItemId, System.Int32)", FRIEND_VOUCHER_ID, charms[talisman_level]["tickets"])
end

local function refill_resources()
    local dm = sdk.get_managed_singleton("snow.data.DataManager")
    add_points(dm)
    add_tickets(dm)
end

local function add_talismans_to_pot(retval)
    if give_rewards and settings.data.enabledTalismanReward then
        local fm = sdk.get_managed_singleton("snow.data.FacilityDataManager")
        local alchemy = fm:call("getAlchemy")
        local slots = alchemy:call("getRemainingSlotNum")
        log.info(modName .. " RemainingSlot : " .. slots);
        if slots > 0 then
            slots = slots - 1
            refill_resources()
            local list = alchemy:call("getPatturnDataList"):call("ToArray")
            local pattern = list[talisman_level]
            local num = math.min(slots, tonumber(settings.data.rewardCounts));
            for i = num, 1, -1 do
              alchemy:call("selectPatturn", pattern)
              alchemy:call("addUsingItem", FRIEND_VOUCHER_ID, charms[talisman_level]["tickets"])
              alchemy:call("reserveAlchemy")
              if slots < 9 then
                  swap_talismans(alchemy, 10 - slots - 1)
              end
              alchemy:call("invokeCycleMethod")
            end
        end
    end
    give_rewards = false
end

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("setQuestClear"),
function (args)end,
check_rewards_on_quest_complete)

sdk.hook(sdk.find_type_definition("snow.SnowSessionManager"):get_method("_onSucceedQuickQuest"),
check_rewards_on_quest_complete,
function (retval) end)

sdk.hook(sdk.find_type_definition("snow.data.FacilityDataManager"):get_method("executeCycle"), 
function (args)end,
add_talismans_to_pot)

-- Talisman Reward Configuration on REFramework UI
re.on_draw_ui(function()
  if imgui.tree_node(modName) then
    local changedEnabled, userenabled = imgui.checkbox("Talisman Reward",
                                                       settings.data
                                                         .enabledTalismanReward)
    settings.handleChange(changedEnabled, userenabled, "enabledTalismanReward")

    local changedCriteria, userQuestRankCriteria = imgui.slider_int(
                                                     "Quest Rank grater than",
                                                     settings.data
                                                       .questRankCriteria, 0, 7,
                                                     '%d')
    settings.handleChange(changedCriteria, userQuestRankCriteria,
                          "questRankCriteria")

    local changedEXCriteria, userQuestRankEXCriteria = imgui.slider_int(
                                                     "Quest Rank EX grater than",
                                                     settings.data
                                                       .questRankEXCriteria, 0, 7,
                                                     '%d')
    settings.handleChange(changedEXCriteria, userQuestRankEXCriteria,
                          "questRankEXCriteria")

    local changedRewardCounts, userRewardCounts = imgui.slider_int(
                                                    "Reward Counts",
                                                    settings.data.rewardCounts,
                                                    1, 5, '%d')
    settings.handleChange(changedRewardCounts, userRewardCounts, "rewardCounts")

    if not settings.isSavingAvailable then
      imgui.text(
        "WARNING: JSON utils not available (your REFramework version may be outdated). Configuration will not be saved between restarts.")
    end

    imgui.text(version)
    imgui.tree_pop()
  end
end)
