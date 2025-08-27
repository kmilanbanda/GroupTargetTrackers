MyAddon = MyAddon or {}
MyAddon.callbacks = {}

if not MyAddonDB then
    MyAddonDB = {}
end

print("Rain Target Trackers successfully loaded!")
if not MyAddonDB.loadCount then
    MyAddonDB.loadCount = 0
end
MyAddonDB.loadCount = MyAddonDB.loadCount + 1

local function InitializePlaterAPIAccess()
    Plater = _G["Plater"]
    if Plater then
        print("Plater API accessed successfully!")
    end
    return Plater
end
local Plater = InitializePlaterAPIAccess()

SLASH_DUMP1 = "/refresh"
SlashCmdList["DUMP"] = function()
    RefreshTokens()
end

local circleTextures = {}
local targetCounts = {}
local currentTargets = {}

local function GetAtlas(unitID)
    local role = UnitGroupRolesAssigned(unitID)
    
    local atlas = ""
    if role == "TANK" then
        atlas = "groupfinder-icon-role-large-tank"
    elseif role == "HEALER" then
        atlas = "groupfinder-icon-role-large-heal" -- It is critical that this says "heal" and not "healer"
    else
        atlas = "groupfinder-icon-role-large-dps"
    end
    return atlas
end

local function CreateToken(unitID)
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
    texture:SetAtlas(GetAtlas(unitID))
    texture:SetSize(MyAddonDB.tokenSize, MyAddonDB.tokenSize)
    circleTextures[unitID] = texture
end

local function RefreshToken(unitID)
    texture = circleTextures[unitID]

    texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
    texture:SetAtlas(GetAtlas(unitID))
    if MyAddonDB.tokenSize then
        texture:SetSize(MyAddonDB.tokenSize, MyAddonDB.tokenSize)
    else
        print("Error: MyAddonDB.tokenSize not initialized. Setting to defaults")
        texture:SetSize(16, 16)
        MyAddonDB.tokenSize =  16
    end
end

local function RefreshTokens()
    for unit, _ in pairs(circleTextures) do
        RefreshToken(unit)
    end
end

local function CreateTargetCount(targetNamePlate) 
	targetCounts[targetNamePlate] = 0
end

local function IncTargetCount(targetNamePlate)
	targetCounts[targetNamePlate] = targetCounts[targetNamePlate] + 1
end

local function DecTargetCount(targetNamePlate)
	targetCounts[targetNamePlate] = targetCounts[targetNamePlate] - 1
	if targetCounts[targetNamePlate] < 0 then
		targetCounts[targetNamePlate] = 0
	end
end

local function ResetTargetCount(targetNamePlate)
	targetCounts[targetNamePlate] = 0
end

local function ResetTargetCounts()
    for target, _ in pairs(targetCounts) do
        ResetTargetCount(target)
    end
end

local function UpdateTexture(targetNamePlate, texture)
    texture:Hide()
    texture:SetParent(targetNamePlate.UnitFrame)
    if Plater then texture:SetParent(targetNamePlate.unitFrame) end
    local targetCountMultiplier = MyAddonDB.tokenSize / 16
    local targetCountOffset = (targetCounts[targetNamePlate] - 1) * 20 * targetCountMultiplier
    texture:SetPoint(MyAddonDB.anchor, targetNamePlate, MyAddonDB.anchor, 10 + MyAddonDB.xOffset + targetCountOffset, MyAddonDB.yOffset)
    texture:Show()
end

function UnitHasTarget(unit)
	return UnitExists(unit .. "target")
end

local function UpdateToken(unit)
    local texture = circleTextures[unit]
    if UnitHasTarget(unit) then
        local targetNamePlate = C_NamePlate.GetNamePlateForUnit(unit .. "target")
        if Plater then
            local plates = Plater.GetAllShownPlates()
            for _, plate in pairs(plates) do
               if not plate.unitFrame.unit then
                   break
               end
               if UnitGUID(unit .. "target") == UnitGUID(plate.unitFrame.unit) then
                   targetNamePlate = plate
               end
            end
        end
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

local function IsUnitsTarget(unitID, targetID)
    return UnitGUID(unitID) == UnitGUID(targetID)
end

local eventListenerFrame = CreateFrame("Frame", "MyAddonEventListenerFrame", UIParent)
eventListenerFrame:RegisterEvent("ADDON_LOADED")
eventListenerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventListenerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventListenerFrame:RegisterEvent("GROUP_JOINED")
local function eventHandler(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        RefreshTokens()
    elseif event == "ADDON_LOADED" and arg1 == "RainTargetTrackers" then 
        MyAddonDB.updateInterval = MyAddonDB.updateInterval or 0.2
        MyAddonDB.tokenSize = MyAddonDB.tokenSize or 16
        MyAddonDB.tokensPerRow = MyAddonDB.tokensPerRow or 5
        MyAddonDB.xOffset = MyAddonDB.xOffset or 0
        MyAddonDB.yOffset = MyAddonDB.yOffset or 0
        MyAddonDB.rowSpacing = MyAddonDB.rowSpacing or 20
        MyAddonDB.columnSpacing = MyAddonDB.columnSpacing or 20
        MyAddonDB.anchor = MyAddonDB.anchor or "TOPLEFT"
    end
end

eventListenerFrame:SetScript("OnEvent", eventHandler)

function OnMenuClosed(frame)
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(MyAddonDB.updateInterval, Update)
    RefreshTokens()    
end

function GetGroupType()
    if UnitInRaid("player") then
        return "raid"
    else
        return "party"
    end
end

local function ResetTargetCounts()
    for target, _ in pairs(targetCounts) do
        ResetTargetCount(target)
    end
end

local function UpdatePlayer()
    unitID = "player"
    if not circleTextures[unitID] then
        CreateToken(unitID)
    end
    UpdateToken(unitID)
end

local function UpdateGroup(groupType)
    groupType = GetGroupType()
    for i = 1, 30, 1
    do
        unitID = groupType .. i
        if not UnitExists(unitID) then break end
        if not circleTextures[unitID] then
            CreateToken(unitID)
        end
        UpdateToken(unitID)
    end
end

function InitializeUpdateLoop()
    local updateInterval = MyAddonDB.updateInterval or 0.2
    return C_Timer.NewTicker(updateInterval, Update)
end

function Update()
    UpdatePlayer()
    UpdateGroup()
    ResetTargetCounts()
end
ticker = InitializeUpdateLoop()
