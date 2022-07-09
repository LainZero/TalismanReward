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

log.info(modName .. " loaded!")

local function check_rewards_on_quest_complete(retval)
  local qm = sdk.get_managed_singleton("snow.QuestManager")

  local qt = qm:call("getQuestType")
  local qrlv = qm:call("getQuestRank_Lv")
  local qlv = qm:call("getQuestLv")
  local qlvex = qm:call("getQuestLvEx")

  local is_mystery = qm:call("isMysteryQuest")
  local is_kingdom = qm:call("isKingdomQuest")

  log.info(modName .. " QuestLv : " .. qlv)
  log.info(modName .. " QuestLevelEx : " .. qlvex)
  log.info(modName .. " QuestRankLevel : " .. qrlv)
  log.info(modName .. " QuestType : " .. qt)
  -- log.info(modName .. " isMystery : " .. tostring(is_mystery))
  -- log.info(modName .. " isKingdom : " .. tostring(is_kingdom))
  log.info(modName .. " Option Rank Criteria : " .. settings.data.questRankCriteria)
  log.info(modName .. " Option Rank EX Criteria : " .. settings.data.questRankEXCriteria)

  if (qlv + 1) >= tonumber(settings.data.questRankCriteria) then
    give_rewards = true
    talisman_level = 3
    log.info(modName .. " TalismanLv : " .. talisman_level)
  elseif ((qlvex + 1) >= tonumber(settings.data.questRankEXCriteria) and qt >= 1) or is_mystery or is_kingdom then
    give_rewards = true
    talisman_level = 5
    log.info(modName .. " TalismanLv : " .. talisman_level)
    log.info(modName .. " Master Rank Quest")
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
  local amount = charms[talisman_level]["points"]
  points:call("addPoint", amount)
end

local function add_tickets(dm)
  local ib = dm:call("get_PlItemBox")
  local amount = charms[talisman_level]["tickets"]
  ib:call("tryAddGameItem(snow.data.ContentsIdSystem.ItemId, System.Int32)", FRIEND_VOUCHER_ID, amount)
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
    if slots > 0 then
      slots = slots - 1
      refill_resources()
      local list = alchemy:call("getPatturnDataList")
      local list_array = list:call("ToArray")
      local pattern = list_array[talisman_level]
      local num = math.min(slots, tonumber(settings.data.rewardCounts));
      for i = num, 1, -1 do
        alchemy:call("selectPatturn", pattern)
        local amount = charms[talisman_level]["tickets"]
        alchemy:call("addUsingItem", FRIEND_VOUCHER_ID, amount)
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
function (arg) end,
check_rewards_on_quest_complete)

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
