MyAddon = MyAddon or {}

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
local function eventHandler(self, event, unitID)
    if event == "UNIT_TARGET" then
        if MyAddonDB.settingsKeys.enablePrinting then
            print("Unit: " .. unitID)
            local unitGUID = UnitGUID(unitID)

            
            local targetUnit = unitID .. "target"
            local targetGUID = UnitGUID(targetUnit)
            if MyAddonDB.settingsKeys.enableGUIDPrinting then
                if UnitExists(targetUnit) then
                    print(unitID .. " (" .. unitGUID .. ")" .. "'s new target is: " .. UnitName(targetUnit) .. " (" .. targetGUID .. ")")
                else
                    print(unitID .. " (" .. unitGUID .. ")" .. " has no target.")
                end
            else
                if UnitExists(targetUnit) then
                    print(unitID .. "'s new target is: " .. UnitName(targetUnit))
                else
                    print(unitID .. " has no target.")
                end
            end
        end
    end
end

eventListenerFrame:SetScript("OnEvent", eventHandler)
eventListenerFrame:RegisterEvent("UNIT_TARGET")

function MyAddon:ToggleMainFrame()
    if not mainFrame:IsShown() then
        mainFrame:Show()
    else
        mainFrame:Hide()
    end
end
