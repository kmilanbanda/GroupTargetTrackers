local checkboxes = 0
local settings = {
    {
        settingText = "Enable tracking of Kills",
        settingKey = "enableKillTracking",
        settingTooltip = "While enabled, your kills will be tracked.",
    },
    {
        settingText = "Enable tracking of Currency",
        settingKey = "enableCurrencyTracking",
        settingTooltip = "While enabled, your currency gained will be tracked.",
    },
}

local function CreateCheckbox(checkboxText, key, checkboxTooltip)
    local checkbox = CreateFrame("CheckButton", "MyAddonCheckboxID" .. checkboxes, settingsFrame, "UICheckButtonTemplate")
    checkbox.Text:SetText(checkboxText)
    checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -30 + (checkboxes * -30))
end

local settingsFrame = CreateFrame("Frame", "MyAddonSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(400, 300)
settingsFrame:SetPoint("CENTER")
settingsFrame.TitleBg:SetHeight(30)
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
settingsFrame.title:SetPoint("CENTER", settingsFrame.TitleBg, "CENTER", 0, -3)
settingsFrame.title:SetText("MyAddon Settings")
settingsFrame:Hide()
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)

settingsFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)