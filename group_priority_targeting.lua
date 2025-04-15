if not MyAddonDB then
    MyAddonDB = {}
end

print("group_priority_targeting successfully loaded!")

local mainFrame = CreateFrame("Frame", "MyAddonMainFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(500, 350)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame.TitleBg:SetHeight(30)
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, -3)
mainFrame.title:SetText("Group Priority Targeting")
mainFrame:Hide()

mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
mainFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)

mainFrame:SetScript("OnShow", function()
        PlaySound(808)
end)

mainFrame:SetScript("OnHide", function()
        PlaySound(808)
end)

SLASH_ADDON1 = "/gpt"
SLASH_ADDON2 = "/group_priority_targets"
SlashCmdList["ADDON"] = function()
	if mainFrame:IsShown() then
    		mainFrame:Hide()
	else
    		mainFrame:Show()
	end
end

table.insert(UISpecialFrames, "MyAddonMainFrame")

mainFrame.playerName = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.playerName:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -35)
mainFrame.playerName:SetText("Character: " .. UnitName("player"))
mainFrame.playerName:SetText("Character: " .. UnitName("player") .. " (Level " .. UnitLevel("player") .. ")")

local eventListenerFrame = CreateFrame("Frame", "MyAddonEventListenerFrame", UIParent)
local function eventHandler(self, event, ...)
    local _, eventType = CombatLogGetCurrentEventInfo()

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if eventType then
            print(eventType)
        else
            print("No data found!")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
	print("Player exited combat!")
    elseif event == "PLAYER_REGEN_DISABLED" then
	print("Player entered combat!")
    end
end

eventListenerFrame:SetScript("OnEvent", eventHandler)
eventListenerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventListenerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventListenerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
