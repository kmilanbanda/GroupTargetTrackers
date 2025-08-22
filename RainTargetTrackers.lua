MyAddon = MyAddon or {}

if not MyAddonDB then
    MyAddonDB = {}
end

print("Rain Target Trackers successfully loaded!")
if not MyAddonDB.loadCount then
    MyAddonDB.loadCount = 0
end
MyAddonDB.loadCount = MyAddonDB.loadCount + 1

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

SLASH_ADDON1 = "/rtt"
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

local circleTextures = {}
local targetCounts = {}
local currentTargets = {}

local UpdateInterval = 0.2

function CreateCircle(unitID)
    if not unitID then
        return
    end

    local newCircle = CreateFrame("Frame", unitID .. "CircleFrame")
    if not newCircle then
        print("Circle creation failed for ".. unitID)
        return
    end

    local texture = newCircle:CreateTexture(unitID .. "Circle", "OVERLAY")
    if not texture then
        print("Texture creation failed for", UnitID)
        return
    end

    texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
    local role = UnitGroupRolesAssigned(unitID)
    local atlas = ""
    if role == "TANK" then
        atlas = "groupfinder-icon-role-large-tank"
    elseif role == "HEALER" then
        atlas = "groupfinder-icon-role-large-heal" -- It is critical that this says "heal" and not "healer"
    else
        atlas = "groupfinder-icon-role-large-dps"
    end
    texture:SetAtlas(atlas)
    texture:SetSize(16,16)
    circleTextures[unitID] = texture
end

function CreateTargetCount(targetNamePlate) --use GUID as key instead?
	targetCounts[targetNamePlate] = 0
end

function IncTargetCount(targetNamePlate)
	targetCounts[targetNamePlate] = targetCounts[targetNamePlate] + 1
end

function DecTargetCount(targetNamePlate)
	targetCounts[targetNamePlate] = targetCounts[targetNamePlate] - 1
	if targetCounts[targetNamePlate] < 0 then
		targetCounts[targetNamePlate] = 0
	end
end

function ResetTargetCount(targetNamePlate)
	targetCounts[targetNamePlate] = 0
end

function UpdateCountsOnTargets(targetNamePlate)
	--loop through all eligible units targets and correct the counters?	
end

function UpdateTexture(targetNamePlate, texture) -- must replace magic numbers at some point with actual user options
    --print("updating texture")
    texture:Hide()
    texture:SetParent(targetNamePlate.UnitFrame)
    local circleOffset = (targetCounts[targetNamePlate] - 1) * 20
    texture:SetPoint("CENTER", targetNamePlate, "CENTER", -60 + circleOffset, 20)
    texture:Show()
    --print("texture showing")
end

function UnitHasTarget(unit)
	return UnitExists(unit .. "target")
end

function UpdateCircle(unit)
    texture = circleTextures[unit]
    if UnitHasTarget(unit) then
        local targetNamePlate = C_NamePlate.GetNamePlateForUnit(unit .. "target")
        if targetNamePlate then
            if not targetCounts[targetNamePlate] then
                CreateTargetCount(targetNamePlate) 
            end
            if currentTargets[unit] then 
                if not currentTargets[unit] == targetNamePlate then
                    currentTargets[unit] = targetNamePlate
                end
            end
            currentTargets[unit] = targetNamePlate
            IncTargetCount(currentTargets[unit])

            if texture then
                UpdateTexture(targetNamePlate, texture)    
            else
                print("~Error: texture not found")
            end
        end
    else
        if currentTargets[unit] then
			currentTargets[unit] = nil
        end
        texture:Hide()
    end
end

local partyPattern = "^party%d+$"
local raidPattern = "^raid%d+$"

local function IsEligibleUnit(unitID)
    if not unitID or type(unitID) ~= "string" then
	return false
    end
    return string.match(unitID, partyPattern) or string.match(unitID, raidPattern) or unitID == "player"
end

local function PrintTargetChanges(unitID)
    print("Unit: " .. unitID)

    local targetUnit = unitID .. "target"
    
    if MyAddonDB.settingsKeys.enableGUIDPrinting then
        local unitGUID = UnitGUID(unitID)
        local targetGUID = UnitGUID(targetUnit)
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

local function IsUnitsTarget(unitID, targetID)
    return UnitGUID(unitID) == UnitGUID(targetID)
end

local eventListenerFrame = CreateFrame("Frame", "MyAddonEventListenerFrame", UIParent)
local function eventHandler(self, event, unitID)
    if event == "UNIT_TARGET" then
--        if IsEligibleUnit(unitID) then
--            if not circleTextures[unitID] then
--                print("Creating circle for " .. unitID)
--                CreateCircle(unitID)
--            end
--            UpdateCircle(unitID)
--
--            if MyAddonDB.settingsKeys.enablePrinting then
--                PrintTargetChanges(unitID)
--	        end
--        end
--
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        for unit, texture in pairs(circleTextures) do
            local targetID = unit .. "target"
            if IsUnitsTarget(unitID, targetID) then
                --reset target count to zero
                --targetNamePlate = currentTarget[unit]
                --ResetTargetCount(targetNamePlate)
                --texture:Hide()
            end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        for unit, texture in pairs(circleTextures) do
            local targetID = unit .. "target"
            if IsUnitsTarget(unitID, targetID) then
                --ResetTargetCount(currentTarget[unit])
				--UpdateCircle(texture, unit)
                --texture:Show()
            end
        end
    end
end

local function GetGroupType()
    if UnitInRaid("player") then
        return "raid"
    else
        return "party"
    end
end

function Update()
    groupType = GetGroupType()
    unitID = "player"
    if not circleTextures[unitID] then
        CreateCircle(unitID)
    end
    UpdateCircle(unitID)
    for i = 1, 30, 1
    do
        unitID = groupType .. i
        if not UnitExists(unitID) then break end
        if not circleTextures[unitID] then
            CreateCircle(unitID)
        end
        UpdateCircle(unitID)
    end

    for target, count in pairs(targetCounts) do
        ResetTargetCount(target)
    end
end
local ticker = C_Timer.NewTicker(UpdateInterval, Update)

eventListenerFrame:SetScript("OnEvent", eventHandler)
eventListenerFrame:RegisterEvent("UNIT_TARGET")
eventListenerFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventListenerFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

function MyAddon:ToggleMainFrame()
    if not mainFrame:IsShown() then
        mainFrame:Show()
    else
        mainFrame:Hide()
    end
end
