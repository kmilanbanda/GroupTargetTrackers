function InitializeOptionsMenu()
    local options = {
        type = "group",
        name = "Group Target Trackers",
        args = {
            display = {
                type = "group",
                name = "Display",
                args = {
                    displayPlayerToken = {
                        order = 2,
                        type = "toggle",
                        name = "Display Player Token",
                        get = function(info) return RTTAddon.db.profile.displayPlayerToken end,
                        set = function(info, val) 
                            RTTAddon.db.profile.displayPlayerToken = val
                            if not RTTAddon.db.profile.displayPlayerToken then HidePlayerTexture() end
                        end,
                    },
                    updateInterval = {
                        order = 7,
                        type = "range",
                        name = "Update Interval",
                        desc = "Adjust the time between token updates",
                        min = 0.1,
                        max = 2,
                        step = 0.1,
                        bigStep = 0.1,
                        get = function(info) return RTTAddon.db.profile.updateInterval end,
                        set = function(info, val)
                            RTTAddon.db.profile.updateInterval = val
                        end,
                    },
                    tokenSize = {
                        order = 5,
                        type = "range",
                        name = "Token Size",
                        desc = "Adjust the size of the tokens",
                        min = 4,
                        max = 64,
                        step = 1,
                        bigStep = 1,
                        get = function(info) return RTTAddon.db.profile.tokenSize end,
                        set = function(info, val)
                            RTTAddon.db.profile.tokenSize = val
                            RefreshTokens()
                        end,
                    },
                    tokensPerRow = {
                        order = 6,
                        type = "range",
                        name = "Tokens Per Row",
                        desc = "Adjust the number of tokens placed in a row before starting the next row",
                        min = 1,
                        max = 40,
                        step = 1,
                        bigStep = 1,
                        get = function(info) return  RTTAddon.db.profile.tokensPerRow end,
                        set = function(info, val)
                            RTTAddon.db.profile.tokensPerRow = val
                        end,
                    },
                    xOffset = {
                        order = 8,
                        type = "input",
                        name = "X-Offset",
                        desc = "Enter the X-Offset for the first token in the first row",
                        usage = "0",
                        width = "half",
                        get = function(info) return RTTAddon.db.profile.xOffset end,
                        set = function(info, val)
                            RTTAddon.db.profile.xOffset = val
                        end,
                    },
                    yOffset = {
                        order = 9,
                        type = "input",
                        name = "Y-Offset",
                        desc = "Enter the X-Offset for the first token in the first row",
                        usage = "0",
                        width = "half",
                        get = function(info) return RTTAddon.db.profile.yOffset end,
                        set = function(info, val)
                            RTTAddon.db.profile.yOffset = val
                        end,
                    },
                    anchor = {
                        order = 1,
                        type = "select",
                        style = "dropdown",
                        name = "Anchor Position",
                        desc = "Select the anchor position ON THE NAMEPLATE that the first token anchors to",
                        values = {
                            TOPLEFT = "TOPLEFT", 
                            TOP = "TOP", 
                            TOPRIGHT = "TOPRIGHT", 
                            LEFT = "LEFT", 
                            CENTER = "CENTER", 
                            RIGHT = "RIGHT", 
                            BOTTOMLEFT = "BOTTOMLEFT", 
                            BOTTOM = "BOTTOM", 
                            BOTTOMRIGHT = "BOTTOMRIGHT",
                        },
                        get = function(info) return RTTAddon.db.profile.anchor end,
                        set = function(info, val) RTTAddon.db.profile.anchor = val end,
                    },
                    growDirection = {
                        order = 3,
                        type = "select",
                        style = "dropdown",
                        name = "Grow Direction",
                        desc = "Select the grow direction of the collection of tokens on a nameplate",
                        values = { "Right and Up", "Right and Down", "Left and Up", "Left and Down", },
                        get = function(info) return RTTAddon.db.profile.growDirection end,
                        set = function(info, val) RTTAddon.db.profile.growDirection = val end,
                    },
                    onlyDisplayDuringCombat = {
                        order = 4,
                        type = "toggle",
                        name = "Only Display During Combat",
                        get = function(info) return RTTAddon.db.profile.onlyDisplayDuringCombat end,
                        set = function(info, val) 
                            RTTAddon.db.profile.onlyDisplayDuringCombat = val
                            if not RTTAddon.db.profile.onlyDisplayDuringCombat then
                                InitializeUpdateLoop()
                            end
                        end,
                    },
                    iconStyle = {
                        order = 10,
                        type = "select",
                        style = "dropdown",
                        name = "Icon Style (requires reload)",
                        desc = "Select the display style of tokens",
                        values = {
                            roleIcons = "Role Icons", 
                            classIcons = "Class Icons", 
                        },
                        get = function(info) return RTTAddon.db.profile.iconStyle end,
                        set = function(info, val) RTTAddon.db.profile.iconStyle = val end,
                    },
                },
            },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(RTTAddon.db)
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("RTTAddon", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RTTAddon", "Group Target Trackers")
end

function CreateLibraryDataBroker()
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("RTTAddon", {
        type  = "launcher",
        text = "RTT",
        icon = "Interface\\AddOns\\GroupTargetTrackers\\Textures\\GroupTargetTrackers.blp",
        OnClick = function(_, button)
            LibStub("AceConfigDialog-3.0"):Open("RTTAddon")
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("GroupTargetTrackers")
            tooltip:AddLine("|cffffff00Click|r to open options")
        end,
    })
    return LDB
end

function RegisterMinimap(LDB)
    local icon = LibStub("LibDBIcon-1.0")

    icon:Register("RTTAddon", LDB, RTTAddon.db.profile.minimap)
end

MENU_CLOSED = MENU_CLOSED or "MENU_CLOSED"

local settingsFrame = CreateFrame("Frame", "RTTAddonSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(250, 600)
settingsFrame:SetPoint("CENTER")
settingsFrame.TitleBg:SetHeight(30)
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
settingsFrame.title:SetPoint("CENTER", settingsFrame.TitleBg, "CENTER", 0, 3)
settingsFrame.title:SetText("Group Target Trackers")
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

function RTTAddon:RegisterCallback(eventName, callback)
    if not self.callbacks[eventName] then
        self.callbacks[eventName] = {}
    end
    table.insert(self.callbacks[eventName], callback)
end

function RTTAddon:TriggerEvent(eventName, ...)
    if self.callbacks[eventName] then
        for _, callback in pairs(self.callbacks[eventName]) do
            callback(...)
        end
    end
end

settingsFrame:SetScript("OnHide", function(self)
    RTTAddon:TriggerEvent(MENU_CLOSED, self)
end)

RTTAddon:RegisterCallback(MENU_CLOSED, OnMenuClosed)
RTTAddon:RegisterCallback(INSPECTION_COMPLETE, OnInspectionComplete)
