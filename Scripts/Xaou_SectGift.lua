-- Xaou 009 Sect Gift v1.0
-- Opens the game's native school gift flow after selecting a world-map school.

local XaouSectGift = GameMain:NewMod("Xaou_SectGift")

local BUTTON_TH = "มอบของขวัญสำนัก"
local BUTTON_EN = "Sect Gift"
local EVENT_KEY = "XaouSectGift_SelectNpc"
local FRIEND_POINT_PER_GIFT = 1
local RELATION_PER_GIFT = 100

local function show_message(text)
    local shown = false
    pcall(function()
        CS.Wnd_Message.Show(tostring(text), 1, nil, true, "Xaou 009", 0, 0, "")
        shown = true
    end)
    if not shown then
        pcall(function()
            CS.WorldLuaHelper():ShowMsgBox(tostring(text))
            shown = true
        end)
    end
    if not shown then
        pcall(function() print("[XaouSectGift] " .. tostring(text)) end)
    end
end

local function cs_count(values)
    if values == nil then return 0 end
    local count = nil
    pcall(function() count = tonumber(values.Count) end)
    if count == nil then pcall(function() count = tonumber(values.Length) end) end
    return count or 0
end

local function cs_get(values, index)
    if values == nil then return nil end
    local value = nil
    pcall(function() value = values:get_Item(index) end)
    if value == nil then pcall(function() value = values[index] end) end
    return value
end

local function read_select_index(result)
    if result == nil then return nil end
    local index = tonumber(result)
    if index ~= nil then return index end

    local count = nil
    pcall(function() count = tonumber(result.Count) end)
    if count ~= nil and count > 0 then
        index = tonumber(cs_get(result, 0))
    end
    return index
end

local function school_name(global_mgr, school_id)
    local value = nil
    pcall(function() value = global_mgr:GetSchoolName(school_id, false) end)
    if value == nil or tostring(value) == "" then
        pcall(function() value = global_mgr:GetSchoolName(school_id) end)
    end
    if value == nil or tostring(value) == "" then
        value = "สำนัก " .. tostring(school_id)
    end
    return tostring(value)
end

local function leader_name(trade_mgr, school_id)
    local value = nil
    pcall(function()
        local data = trade_mgr:GetSchoolTrade(school_id)
        if data ~= nil and data.Leader ~= nil then value = data.Leader.name end
    end)
    if value == nil or tostring(value) == "" then return "ไม่พบข้อมูลเจ้าสำนัก" end
    return tostring(value)
end

local function build_school_rows()
    local rows = {}
    local global_mgr = CS.XiaWorld.SchoolGlobleMgr.Instance
    local school_mgr = CS.XiaWorld.SchoolMgr.Instance
    local trade_mgr = CS.XiaWorld.TradeMgr.Instance
    if global_mgr == nil or school_mgr == nil or trade_mgr == nil then
        return rows, "ระบบสำนักของเกมยังไม่พร้อม"
    end

    local ids = nil
    pcall(function() ids = CS.XiaWorld.SchoolGlobleMgr.PureSchoolIds end)
    if ids == nil then pcall(function() ids = global_mgr.PureSchoolIds end) end

    local seen = {}
    for index = 0, cs_count(ids) - 1 do
        local school_id = tonumber(cs_get(ids, index))
        if school_id ~= nil and not seen[school_id] then
            seen[school_id] = true
            local relation = 0
            pcall(function() relation = tonumber(school_mgr:GetSchoolRelation(school_id)) or 0 end)
            rows[#rows + 1] = {
                id = school_id,
                name = school_name(global_mgr, school_id),
                leader = leader_name(trade_mgr, school_id),
                relation = relation
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.relation == b.relation then return a.id < b.id end
        return a.relation > b.relation
    end)
    return rows, nil
end

local function get_school_power(school_id)
    local power = nil
    pcall(function()
        power = CS.XiaWorld.SchoolGlobleMgr.Instance:GetSchoolPower(school_id)
    end)
    return power
end

local function get_gift_count(school_id)
    local value = 0
    local power = get_school_power(school_id)
    if power ~= nil then
        pcall(function() value = tonumber(power.GiftCount) or 0 end)
    end
    return value
end

local function get_friend_point(school_id)
    local value = 0
    pcall(function()
        local trade = CS.XiaWorld.TradeMgr.Instance:GetSchoolTrade(school_id)
        if trade ~= nil then value = tonumber(trade.FriendPoint) or 0 end
    end)
    return value
end

local function add_friend_point(school_id, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    local ok = pcall(function()
        CS.XiaWorld.TradeMgr.Instance.SchoolTrade:AddFriendPoint(school_id, amount)
    end)
    if ok then return true end

    ok = pcall(function()
        CS.XiaWorld.TradeMgr.Instance:GetSchoolTrade(school_id):AddFriendPoint(amount)
    end)
    return ok
end

local function get_school_relation(school_id)
    local value = 0
    pcall(function()
        value = tonumber(CS.XiaWorld.SchoolMgr.Instance:GetSchoolRelation(school_id)) or 0
    end)
    return value
end

local function add_school_relation(school_id, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return true end

    return pcall(function()
        CS.XiaWorld.SchoolMgr.Instance:AddSchoolRelation(school_id, amount)
    end)
end

local function sync_relation_from_friend_points(school_id)
    local points = get_friend_point(school_id)
    local relation = get_school_relation(school_id)
    local target = math.min(1200, math.max(0, points * RELATION_PER_GIFT))
    if relation < target then
        add_school_relation(school_id, target - relation)
        relation = get_school_relation(school_id)
    end
    return relation
end

local function open_native_gift(row)
    if row == nil then return false end

    sync_relation_from_friend_points(row.id)

    local wnd = nil
    pcall(function() wnd = CS.Wnd_SchoolGiveGift.Instance end)
    if wnd == nil then
        show_message("ไม่พบหน้ามอบของขวัญของเกม\nWnd_SchoolGiveGift.Instance = nil")
        return false
    end

    XaouSectGift._giftWatch = {
        schoolId = row.id,
        schoolName = row.name,
        giftCount = get_gift_count(row.id),
        friendPoint = get_friend_point(row.id),
        relation = get_school_relation(row.id),
        errorShown = false
    }

    local ok, err = pcall(function()
        wnd:ShowSchool(
            row.id,
            "มอบของขวัญแก่ " .. row.name,
            "เจ้าสำนัก: " .. row.leader
        )
    end)
    if not ok then
        XaouSectGift._giftWatch = nil
        show_message(
            "เปิดหน้ามอบของขวัญไม่สำเร็จ\n"
            .. "สำนัก: " .. row.name
            .. "\nSchoolId: " .. tostring(row.id)
            .. "\n" .. tostring(err)
        )
        return false
    end
    return true
end

function XaouSectGift:OnStep(dt)
    self._watchTimer = (self._watchTimer or 0) + (tonumber(dt) or 0)
    if self._watchTimer < 0.5 then return end
    self._watchTimer = 0

    local watch = self._giftWatch
    if watch == nil then return end

    local current_gifts = get_gift_count(watch.schoolId)
    local current_points = get_friend_point(watch.schoolId)
    local current_relation = get_school_relation(watch.schoolId)
    local gift_delta = current_gifts - (watch.giftCount or 0)

    if gift_delta > 0 then
        local native_point_delta = math.max(0, current_points - (watch.friendPoint or 0))
        local required_points = gift_delta * FRIEND_POINT_PER_GIFT
        local missing_points = math.max(0, required_points - native_point_delta)
        local native_relation_delta = math.max(0, current_relation - (watch.relation or 0))
        local required_relation = gift_delta * RELATION_PER_GIFT
        local missing_relation = math.max(0, required_relation - native_relation_delta)

        if missing_points > 0 then
            local added = add_friend_point(watch.schoolId, missing_points)
            if added then
                current_points = get_friend_point(watch.schoolId)
                show_message(
                    "มอบของขวัญสำเร็จ\n"
                    .. "ได้รับแต้มบุญคุณ +" .. tostring(missing_points)
                    .. "\nแต้มปัจจุบัน: " .. tostring(current_points)
                )
            elseif not watch.errorShown then
                watch.errorShown = true
                show_message("มอบของขวัญสำเร็จ แต่เพิ่มแต้มบุญคุณไม่สำเร็จ")
            end
        end

        if missing_relation > 0 then
            local relation_added = add_school_relation(watch.schoolId, missing_relation)
            if relation_added then
                current_relation = get_school_relation(watch.schoolId)
                show_message(
                    "เพิ่มความสัมพันธ์สำนักสำเร็จ"
                    .. "\nความสัมพันธ์ปัจจุบัน: " .. string.format("%.0f", current_relation)
                    .. "\nแต้มบุญคุณปัจจุบัน: " .. tostring(current_points)
                )
            elseif not watch.errorShown then
                watch.errorShown = true
                show_message("มอบของขวัญสำเร็จ แต่เพิ่มความสัมพันธ์สำนักไม่สำเร็จ")
            end
        end

        watch.giftCount = current_gifts
        watch.friendPoint = current_points
        watch.relation = current_relation
    elseif current_points ~= watch.friendPoint then
        watch.friendPoint = current_points
        watch.relation = current_relation
    end
end

function XaouSectGift:Open()
    local rows, build_error = build_school_rows()
    if #rows == 0 then
        show_message(build_error or "ไม่พบสำนักที่สามารถมอบของขวัญได้")
        return false
    end

    local choices = {}
    for index = 1, #rows do
        local row = rows[index]
        choices[index] =
            row.name
            .. "\nเจ้าสำนัก: " .. row.leader
            .. " | ความสัมพันธ์: " .. string.format("%.0f", row.relation)
    end

    local helper = nil
    pcall(function() helper = CS.WorldLuaHelper() end)
    if helper == nil or helper.ShowSelectBox == nil then
        show_message("ไม่พบหน้าต่างเลือกรายชื่อสำนัก")
        return false
    end

    local ok, err = pcall(function()
        helper:ShowSelectBox("เลือกสำนักที่จะมอบของขวัญ", choices, 1, 1, function(result)
            local selected = read_select_index(result)
            if selected == nil then return end

            -- ACS Mobile returns a zero-based selected index.
            local row = rows[selected + 1]
            if row == nil then row = rows[selected] end
            if row ~= nil then open_native_gift(row) end
        end)
    end)
    if not ok then
        show_message("เปิดรายชื่อสำนักไม่สำเร็จ\n" .. tostring(err))
        return false
    end
    return true
end

function XaouSectGift:AddButton(npc)
    if npc == nil then return end
    pcall(function() npc:RemoveBtnData(BUTTON_TH) end)
    pcall(function() npc:RemoveBtnData(BUTTON_EN) end)
    pcall(function()
        npc:AddBtnData(
            BUTTON_TH,
            "res/Sprs/ui/icon_gift",
            "GameMain:GetMod('Xaou_SectGift'):Open()",
            "เลือกสำนักบนแผนที่โลก แล้วเปิดหน้ามอบของขวัญเดิมของเกม",
            nil
        )
    end)
end

function XaouSectGift:OnEnter()
    local events = GameMain:GetMod("_Event", true)
    local select_npc = nil
    pcall(function() select_npc = g_emEvent.SelectNpc end)
    if events ~= nil and select_npc ~= nil then
        events:RegisterEvent(select_npc, function(_, npc)
            self:AddButton(npc)
        end, EVENT_KEY)
    end
end

function XaouSectGift:OnLeave()
    local events = GameMain:GetMod("_Event", true)
    local select_npc = nil
    pcall(function() select_npc = g_emEvent.SelectNpc end)
    if events ~= nil and select_npc ~= nil then
        pcall(function() events:UnRegisterEvent(select_npc, EVENT_KEY) end)
    end
end

function XaouSectGift:NeedSyncData()
    return false
end
