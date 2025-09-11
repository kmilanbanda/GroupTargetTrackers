local settingsHeight = 0
local settings = {
    {
       settingText = "Display Player Token",
       settingTooltip = "While enabled, a token for the player will be generated. Not applicable in raid",
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
    {
        settingText = "Token Anchor",
        settingTooltip = "Choose the point a token's position will be based on",
        settingType = "dropdown",
        settingKey = "anchor",
        settingValue = MyAddonDB.anchor or "TOPLEFT",
        settingOptions = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT", },
    },
    {
        settingText = "Grow Direction",
        settingTooltip = "Choose the direction the rows of tokens grow",
        settingType = "dropdown",
        settingKey = "growDirection",
        settingValue = MyAddonDB.growDirection or { 1, 1, },
        settingOptions = { "Right and Up", "Right and Down", "Left and Up", "Left and Down", },
    },
    {
        settingText = "Only Display During Combat",
        settingTooltip = "If checked, Rain Target Trackers will only display tokens during combat",
        settingType = "checkbox",
        settingKey = "onlyDisplayDuringCombat",
    },
}

MENU_CLOSED = MENU_CLOSED or "MENU_CLOSED"

local settingsFrame = CreateFrame("Frame", "MyAddonSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(250, 550)
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
MyAddon:RegisterCallback(INSPECTION_COMPLETE, OnInspectionComplete)

--- Dropdown Helper Functions ---

local function SetDropdownProperties(dropdown, setting, options)
    dropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -30 + (settingsHeight * -30))
    dropdown:SetDefaultText(MyAddonDB[dropdown.key])

    dropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateTitle(setting.settingText)

        for _, option in ipairs(setting.settingOptions) do
            rootDescription:CreateButton(option, function()
                MyAddonDB[dropdown.key] = option
                dropdown:SetDefaultText(option)
            end)
        end
    end)
end

local function CreateDropdownTitle(dropdown, setting)
    local title = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 5)
    title:SetText(setting.settingText)
    title:SetTextColor(1, 0.82, 0)
end

--- Dropdown Helper Functions ---|

local function CreateDropdown(setting, index)
    local dropdown = CreateFrame("DropdownButton", "RainTargetTrackersDropdownID" .. settingsHeight, settingsFrame, "WowStyle1DropdownTemplate")
    dropdown.key = setting.settingKey
    dropdown.index = index

    SetDropdownProperties(dropdown, setting)
    CreateDropdownTitle(dropdown, setting)

    settingsHeight = settingsHeight + 1.5
end

--- Edit Box Helper Functions ---

local defaultWidth = 40
local defaultHeight = 20
local defaultMaxChars = 10

local function SetEditBoxProperties(editBox, setting)
    editBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -30 + (settingsHeight * -30))
    editBox:SetSize(setting.settingWidth, setting.settingHeight)
    editBox:SetText(MyAddonDB[editBox.key])
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(defaultMaxChars)
    editBox:SetFontObject("GameFontHighlight")
end

local function CreateLabelForBox(editBox)
    local label = editBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", -5, 4)
    label:SetText("Enter " .. settings[editBox.index].settingText .. ": ")
end

local function ValidateAndSaveEditBoxInput(editBox)
    editBox:SetScript("OnEnterPressed", function(self)
        local input = self:GetText()
        if input:match("^-?[0-9]+$") then
            MyAddonDB[editBox.key] = input
            self:SetText(MyAddonDB[editBox.key])
            self:ClearFocus()
        else
            self:SetText(MyAddonDB[editBox.key])
            self:ClearFocus()
        end
    end)
end

--- Edit Box Helper Functions ---|

local function CreateEditBox(setting, index)
    local editBox = CreateFrame("EditBox",  "MyAddonEditBoxID" .. settingsHeight, settingsFrame, "InputBoxTemplate")
    editBox.key = setting.settingKey
    editBox.index = index
    
    SetEditBoxProperties(editBox, setting)
    CreateLabelForBox(editBox)
    ValidateAndSaveEditBoxInput(editBox)

    settingsHeight = settingsHeight + 1.5
    return editBox
end

--- Slider Helper Functions ---

local sliderWidth = 200
local sliderHeight = 20

local function SetSliderProperties(slider, setting, value)
    slider:SetWidth(sliderWidth)
    slider:SetHeight(sliderHeight)
    slider:SetMinMaxValues(setting.settingMin, setting.settingMax)
    slider:SetValueStep(settings[slider.index].settingStep)
    slider:SetValue(value) 
end

local function AddSliderText(slider, setting, value)
    slider.label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slider.label:SetPoint("TOP", slider, "BOTTOM", 0, -5)
    slider.label:SetText(value)

    slider.low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -5, -20)
    slider.low:SetText(setting.settingMin)

    slider.high = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 5, -20)
    slider.high:SetText(setting.settingMax)
end

function round(number, decimals)
    local multiplier = 10^decimals
    return math.floor(number * multiplier + 0.5) / multiplier
end

local function HandleSliderValueChanges(slider)
    slider:SetScript("OnValueChanged", function(self, value)
        local roundedValue = round(value, settings[slider.index].settingDecimals) -- instead of creating a key element in the menu item, create an index element that allows us to access the setting instead. Then we can access settings in order 
        MyAddonDB[slider.key] = roundedValue
        slider.label:SetText(roundedValue)
    end)
end

--- Slider Helper Functions ---|

local function CreateSlider(setting, index)
    local slider = CreateFrame("Slider", "MyAddonSlider" .. setting.settingText, settingsFrame, "OptionsSliderTemplate")
    slider.Text:SetText(setting.settingKey)
    slider.Text:SetTextColor(1, 0.82, 0)
    slider:SetPoint("CENTER", settingsFrame, "TOP", 0, -30 + (settingsHeight * -30))
    slider.key = setting.settingKey
    slider.index = index
    
    value = MyAddonDB[slider.key] or settings[index].settingDefault
    SetSliderProperties(slider, setting, value)
    AddSliderText(slider, setting, value)
    HandleSliderValueChanges(slider)
    
    settingsHeight = settingsHeight + 2.5
    return slider
end

--- Checkbox Helper Functions ---

local function SetCheckboxProperties(checkbox, setting)
    checkbox.Text:SetText(setting.settingText)
    checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -30 + (settingsHeight * -30))
end

local function UpdateCheckbox(checkbox)
    if MyAddonDB.settingsKeys[checkbox.key] == nil  then
        MyAddonDB.settingsKeys[checkbox.key] = true
    end
    checkbox:SetChecked(MyAddonDB.settingsKeys[checkbox.key])
end

local function SetCheckboxScripts(checkbox, setting)
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.settingTooltip, nil, nil, nil, nil, true)
    end)

    checkbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    checkbox:SetScript("OnClick", function(self)
        MyAddonDB.settingsKeys[setting.settingKey] = self:GetChecked()
        MyAddonDB[checkbox.key] = MyAddonDB.settingsKeys[setting.settingKey]
    end)
end

--- Checkbox Helper Functions ---|


local function CreateCheckbox(setting)
    local checkbox = CreateFrame("CheckButton", "MyAddonCheckboxID" .. settingsHeight, settingsFrame, "UICheckButtonTemplate")
    checkbox.key = setting.settingKey

    SetCheckboxProperties(checkbox, setting)
    UpdateCheckbox(checkbox)
    SetCheckboxScripts(checkbox, setting)

    settingsHeight = settingsHeight + 2
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
                CreateCheckbox(setting, index)
            elseif setting.settingType == "slider" then
                CreateSlider(setting, index)
            elseif setting.settingType == "editbox" or setting.settingType == "editBox" then
                CreateEditBox(setting, index)
            elseif setting.settingType == "dropdown" then
                CreateDropdown(setting, index)
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
	icon = "Interface\\AddOns\\RainTargetTrackers\\logo.tga",
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
