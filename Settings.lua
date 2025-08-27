MyAddonDB.updateInterval = MyAddonDB.updateInterval or 0.2
MyAddonDB.tokenSize = MyAddonDB.tokenSize or 20

local settingsHeight = 1
local settings = {
    {
       settingText = "Display Player Token",
       settingTooltip = "While enabled, a token for the player will be generated",
       settingType = "checkbox",
       settingKey = "displayPlayerToken",
    },
    {
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
    {
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
    {
        settingText = "Tokens per row",
        settingTooltip = "Configure the number of tokens per row",
        settingType = "slider",
        settingMin = 1,
        settingMax  = 40,
        settingValue = MyAddonDB.tokensPerRow or 5,
        settingDecimals = 0,
        settingStep = 1,
        settingKey = "tokensPerRow",
    },
    {
        settingText = "X-Offset",
        settingTooltip = "Configure the initial X-offset of the tokens",
        settingType = "editbox",
        settingWidth = 40,
        settingHeight = 20,
        settingValue = MyAddonDB.xOffset or 0,
        settingKey = "xOffset",
    },
    {
        settingText = "Y-Offset",
        settingTooltip = "Configure the initial Y-offset of the tokens",
        settingType = "editbox",
        settingWidth = 40,
        settingHeight = 20,
        settingValue = MyAddonDB.yOffset or 0,
        settingKey = "yOffset",
    },
}

MENU_CLOSED = MENU_CLOSED or "MENU_CLOSED"

local settingsFrame = CreateFrame("Frame", "MyAddonSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(400, 600)
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

--- Edit Box Helper Functions ---

local defaultWidth = 40
local defaultHeight = 20
local defaultMaxLetters = 10

local function SetEditBoxProperties(editBox, width, height, maxChars)
    editBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -30 + (settingsHeight * -30))
    if not width then width = defaultWidth end
    if not height then height = defaultHeight end
    if not maxLetters then maxLetters = defaultMaxLetters end
    editBox:SetSize(width, height)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(maxLetters)
    editBox:SetFontObject("GameFontHighlight")
end

local function CreateLabelForBox(editBox)
    local label = editBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", 0, 4)
    label:SetText("Enter " .. settings[editBox.index].settingText .. ": ")
end

local function RestrictEditBoxInput(editBox)
    editBox:SetScript("OnChar", function(self, char)
        if not char:match("[0-9]") and not char:match("-") then
            return
        end
    end)
end

local function ValidateAndSaveEditBoxInput(editBox)
    editBox:SetScript("OnEnterPressed", function(self)
        local input = self:GetText()
        if input:match("^-?[0-9]+$") then
            MyAddonDB[editBox.key] = input
            self:ClearFocus()
        else
            self:SetText(MyAddonDB[editBox.key])
            self:ClearFocus()
        end
    end)
end

--- Edit Box Helper Functions ---|

local function CreateEditBox(editBoxText, key, tooltip, width, height, maxChars, index)
    local editBox = CreateFrame("EditBox",  "MyAddonEditBoxID" .. settingsHeight, settingsFrame, "InputBoxTemplate")
    editBox.key = key
    editBox.index = index
    
    SetEditBoxProperties(editBox, width, height, maxChars)
    CreateLabelForBox(editBox)
    RestrictEditBoxInput(editBox)
    ValidateAndSaveEditBoxInput(editBox)

    settingsHeight = settingsHeight + 1.5
    return editBox
end

--- Slider Helper Functions ---

local sliderWidth = 200
local sliderHeight = 20

local function SetSliderProperties(slider, min, max, value)
    slider:SetWidth(sliderWidth)
    slider:SetHeight(sliderHeight)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(settings[slider.index].settingStep)
    slider:SetValue(value) 
end

local function AddSliderText(slider, min, max, value)
    slider.label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slider.label:SetPoint("TOP", slider, "BOTTOM", 0, -5)
    slider.label:SetText(value)

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

local function HandleSliderValueChanges(slider)
    slider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = round(value, settings[slider.key].settingDecimals) -- instead of creating a key element in the menu item, create an index element that allows us to access the setting instead. Then we can access settings in order 
        MyAddonDB[slider.key] = roundedValue
        slider.label:SetText(roundedValue)
    end)
end

--- Slider Helper Functions ---|

local function CreateSlider(sliderText, key, tooltip, min, max, index)
    local slider = CreateFrame("Slider", "MyAddonSlider" .. sliderText, settingsFrame, "OptionsSliderTemplate")
    slider.Text:SetText(sliderText)
    slider:SetPoint("CENTER", settingsFrame, "TOP", 0, -30 + (settingsHeight * -30))
    slider.key = key
    slider.index = index

    if MyAddonDB.settingsKeys[key] == nil then
        MyAddonDB.settingsKeys[key] = true
    end
    
    value = MyAddonDB[key] or settings[key].settingDefault
    SetSliderProperties(slider, min, max, value)
    AddSliderText(slider, min, max, value)
    HandleSliderValueChanges(slider)
    
    settingsHeight = settingsHeight + 2.5
    return slider
end

local function CreateCheckbox(checkboxText, key, checkboxTooltip, index)
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

        for index, setting in pairs(settings) do
            if setting.settingType == "checkbox" then
                CreateCheckbox(setting.settingText, setting.settingKey, setting.settingTooltip, index)
            elseif setting.settingType == "slider" then
                CreateSlider(setting.settingText, setting.settingKey, setting.settingTooltip, setting.settingMin, setting.settingMax, index)
            elseif setting.settingType == "editbox" or setting.settingType == "editBox" then
                CreateEditBox(setting.settingText, setting.settingKey, setting.settingTooltip, setting.settingWidth, setting.settingHeight, setting.settingMaxChars, index)
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
        if settingsFrame:IsShown() then
            settingsFrame:Hide()
        else
            settingsFrame:Show()
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
