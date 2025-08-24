MyAddonDB = MyAddonDB or {}
MyAddon.callbacks = MyAddon.callbacks or {}

MyAddonDB.updateInterval = MyAddonDB.updateInterval or 0.2
MyAddonDB.tokenSize = MyAddonDB.tokenSize or 20

local settingsHeight = 1
local settings = {
--    enablePrinting = {
--       settingText = "Enable event tracking",
--       settingTooltip = "While enabled, target changes will be printed to the chatbox",
--       settingType = "checkbox",
--       settingKey = "enablePrinting",
--    },
    updateInterval = {
        settingText = "Update Interval",
        settingTooltip = "Configure the amount of time between updates. A lower value means more frequent updates",
        settingType = "slider",
        settingMin = 0.1,
        settingMax = 1,
        settingValue = MyAddonDB.updateInterval or 0.2,
        settingDecimals = 1,
        settingStep =  0.1,
        settingKey = "updateInterval",
        settingDefault = 0.2
    },
    tokenSize = {
        settingText = "Token Size",
        settingTooltip = "Configure the size of the tokens displayed on enemy nameplates",
        settingType = "slider",
        settingMin = 8,
        settingMax = 64,
        settingValue = MyAddonDB.tokenSize or 20,
        settingDecimals = 0,
        settingStep = 1,
        settingKey = "tokenSize",
        settingDefault = 20
    },
}

MENU_CLOSED = MENU_CLOSED or "MENU_CLOSED"

local settingsFrame = CreateFrame("Frame", "MyAddonSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(400, 300)
settingsFrame:SetPoint("CENTER")
settingsFrame.TitleBg:SetHeight(30)
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
settingsFrame.title:SetPoint("CENTER", settingsFrame.TitleBg, "CENTER", 0, 3)
settingsFrame.title:SetText("Rain Target Tokens")
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

SLASH_ADDON1 = "/rtt"
SlashCmdList["ADDON"] = function()
	if settingsFrame:IsShown() then
    	settingsFrame:Hide()
	else
    	settingsFrame:Show()
	end
end

function MyAddon:RegisterCallback(eventName, callback)
    if not self.callbacks[eventName] then
        self.callbacks[eventName] = {}
    end
    table.insert(self.callbacks[eventName], callback)
end

function MyAddon:TriggerEvent(eventName, ...)
    if self.callbacks[eventName] then
        for _, callback in pairs(self.callbacks[eventName]) do
            callback(...)
        end
    end
end

settingsFrame:SetScript("OnHide", function(self)
    MyAddon:TriggerEvent(MENU_CLOSED, self)
end)

MyAddon:RegisterCallback(MENU_CLOSED, OnMenuClosed)

local sliderWidth = 200
local sliderHeight = 20

local function setSliderProperties(slider, min, max, value)
    slider:SetWidth(sliderWidth)
    slider:SetHeight(sliderHeight)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(settings[slider.key].settingStep)
    slider:SetValue(value) 
end

local function addSliderText(slider, min, max, value)
    slider.label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slider.label:SetPoint("TOP", slider, "BOTTOM", 0, -5)
    slider.label:SetText("Adjust Value: " .. format("%.1f", value))

    slider.low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -5, -20)
    slider.low:SetText(min)

    slider.high = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 5, -20)
    slider.high:SetText(max)
end

function round(number, decimals)
    local multiplier = 10^decimals
    return math.floor(number * multiplier + 0.5) / multiplier
end

local function handleSliderValueChanges(slider)
    slider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = round(value, settings[slider.key].settingDecimals) 
        MyAddonDB[slider.key] = roundedValue
        slider.label:SetText("Adjust Value: " .. format("%.1f", roundedValue))
    end)
end

local function CreateSlider(sliderText, key, tooltip, min, max)
    local slider = CreateFrame("Slider", "MyAddonSlider" .. sliderText, settingsFrame, "OptionsSliderTemplate")
    slider.Text:SetText(sliderText)
    slider:SetPoint("CENTER", settingsFrame, "TOP", 0, -30 + (settingsHeight * -30))
    slider.key = key

    if MyAddonDB.settingsKeys[key] == nil then
        MyAddonDB.settingsKeys[key] = true
    end
    
    value = MyAddonDB[key] or settings[key].settingDefault
    setSliderProperties(slider, min, max, value)
    addSliderText(slider, min, max, value)
    handleSliderValueChanges(slider)
    
    settingsHeight = settingsHeight + 2.5
    return slider
end

local function CreateCheckbox(checkboxText, key, checkboxTooltip)
    local checkbox = CreateFrame("CheckButton", "MyAddonCheckboxID" .. settingsHeight, settingsFrame, "UICheckButtonTemplate")
    checkbox.Text:SetText(checkboxText)
    checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -30 + (settingsHeight * -30))

    if MyAddonDB.settingsKeys[key] == nil  then
        MyAddonDB.settingsKeys[key] = true
    end

    checkbox:SetChecked(MyAddonDB.settingsKeys[key])

    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(checkboxTooltip, nil, nil, nil, nil, true)
    end)

    checkbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    checkbox:SetScript("OnClick", function(self)
        MyAddonDB.settingsKeys[key] = self:GetChecked()
    end)

    settingsHeight = settingsHeight + 2

    return checkbox
end

local eventListenerFrame = CreateFrame("Frame", "MyAddonSettingsEventListenerFrame", UIParent)

eventListenerFrame:RegisterEvent("PLAYER_LOGIN")
eventListenerFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if not MyAddonDB.settingsKeys then
            MyAddonDB.settingsKeys = {}
        end

        for _, setting in pairs(settings) do
            if setting.settingType == "checkbox" then
                CreateCheckbox(setting.settingText, setting.settingKey, setting.settingTooltip)
            elseif setting.settingType == "slider" then
                CreateSlider(setting.settingText, setting.settingKey, setting.settingTooltip, setting.settingMin, setting.settingMax)
            else
                print("Rain Target Trackers: invalid setting type")
            end
        end
    end
end)

local addon = LibStub("AceAddon-3.0"):NewAddon("Rain Target Tracking")
MyAddonMinimapButton = LibStub("LibDBIcon-1.0", true)

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("GPT", {
	type = "data source",
	text = "Rain Target Tracking",
	icon = "Interface\\AddOns\\RainTargetTrackers\\minimap.tga",
	OnClick = function(self, btn)
        if btn == "LeftButton" then
		    MyAddon:ToggleMainFrame()
        elseif btn == "RightButton" then
            if settingsFrame:IsShown() then
                settingsFrame:Hide()
            else
                settingsFrame:Show()
            end
        end
	end,

	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end

		tooltip:AddLine("Rain Target Trackers\n\nLeft-click: Open RTT\nRight-click: Open RTT Settings", nil, nil, nil, nil)
	end,
})

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("RTTMinimapPOS", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})

	MyAddonMinimapButton:Register("RTT", miniButton, self.db.profile.minimap)
end

MyAddonMinimapButton:Show("RTT")
