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
    if not Plater then
        print("Plater API could not be accessed.")
    end
    return Plater
end
local Plater = InitializePlaterAPIAccess()

local tokenTextures = {}
local targetCounts = {}
local currentTargets = {}

local function GetUnitRole(unitID) -- possible roles: "tank", "healer", "rdps", "mdps"
   unitSpecID = unitSpecCache[UnitGUID(unitID)]
   return specRoles[unitSpecID]
end

local function GetTexturePath(unitID)
    local role = GetUnitRole(unitID)
    local path = ""
    if role == "tank" then
        path =  "Interface\\Addons\\RainTargetTrackers\\Textures\\tank.blp"
    elseif role == "healer" then
        path =  "Interface\\Addons\\RainTargetTrackers\\Textures\\healer.blp"
    elseif role == "rdps" then
        path =  "Interface\\Addons\\RainTargetTrackers\\Textures\\rdps.blp"
    elseif role == "mdps" then
        path =  "Interface\\Addons\\RainTargetTrackers\\Textures\\mdps.blp"
    else
        print("Error: no role or incorrect role given. role =", role)
    end
    return path
end

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
    if not UnitExists(unitID) then
        return
    end
    local newToken = CreateFrame("Frame", unitID .. "TokenFrame")
    if not newToken then
        return
    end

    local texture = newToken:CreateTexture(unitID .. "Token", "OVERLAY")
    if not texture then
        return
    end
    if unitSpecCache[UnitGUID(unitID)] then
        texture:SetTexture(GetTexturePath(unitID))
    else
        texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
        texture:SetAtlas(GetAtlas(unitID))
    end    
    texture:SetSize(MyAddonDB.tokenSize, MyAddonDB.tokenSize)
    tokenTextures[unitID] = texture
end

local function RefreshToken(unitID)
    texture = tokenTextures[unitID]

    if not texture then 
        return 
    end
    if unitSpecCache[UnitGUID(unitID)] then
        texture:SetTexture(GetTexturePath(unitID))
    else
        texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
        texture:SetAtlas(GetAtlas(unitID))
        QueueInspection(unitID)
    end

    if MyAddonDB.tokenSize then
        texture:SetSize(MyAddonDB.tokenSize, MyAddonDB.tokenSize)
    else
        print("Error: MyAddonDB.tokenSize not initialized. Setting to defaults")
        texture:SetSize(16, 16)
        MyAddonDB.tokenSize = 16
    end
end

local function RefreshTokens()
    for unit, _ in pairs(tokenTextures) do
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

local function GetGrowDirection()
    growDirection = MyAddonDB.growDirection
    if growDirection == "Right and Up" then return { 1, 1 } end
    if growDirection == "Right and Down" then return { 1, 1 } end
    if growDirection == "Left and Up" then return { -1, -1 } end
    if growDirection == "Left and Down" then return { -1, -1 } end
    return { 1, 1 }
end

local function UpdateTexture(targetNamePlate, texture)
    texture:Hide()
    texture:SetParent(targetNamePlate.UnitFrame)
    if Plater then texture:SetParent(targetNamePlate.unitFrame) end
    local growDirection = GetGrowDirection()
    local tokenScaleMultiplier = MyAddonDB.tokenSize / 16
    local rowPosition = (targetCounts[targetNamePlate] - 1) % MyAddonDB.tokensPerRow
    local targetCountOffset = (rowPosition) * 20 * tokenScaleMultiplier * growDirection[1]
    local rowCount = math.ceil(targetCounts[targetNamePlate]/MyAddonDB.tokensPerRow) 
    local rowCountOffset = (rowCount - 1) * 20 * tokenScaleMultiplier * growDirection[2]
    texture:SetPoint("CENTER", targetNamePlate, MyAddonDB.anchor, MyAddonDB.xOffset + targetCountOffset, MyAddonDB.yOffset + rowCountOffset)
    texture:Show()
end

function UnitHasTarget(unit)
	return UnitExists(unit .. "target")
end

local function UpdateToken(unit)
    local texture = tokenTextures[unit]
    if not texture then 
        CreateToken(unit)
        texture = tokenTextures[unit]
    end

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
        if texture then
            texture:Hide()
        end
    end
end

local function InitializePlayer()
    local unitID = "player"
    local specIndex = GetSpecialization()
    local specID = GetSpecializationInfo(specIndex)
    if specID then unitSpecCache[UnitGUID(unitID)] = specID end
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

local function HideRemovedNamePlateTextures(removedNameplate)
    for unit, targetNamePlate in pairs(currentTargets) do
        if targetNamePlate == removedNameplate then texture:Hide() end
    end
end

local eventListenerFrame = CreateFrame("Frame", "MyAddonEventListenerFrame", UIParent)
eventListenerFrame:RegisterEvent("ADDON_LOADED")
eventListenerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventListenerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventListenerFrame:RegisterEvent("GROUP_JOINED")
eventListenerFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
local function eventHandler(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        InitializePlayer()
        RefreshTokens()
        if event == "PLAYER_ENTERING_WORLD" then currentTargets = {} end
    elseif event == "ADDON_LOADED" and arg1 == "RainTargetTrackers" then 
        MyAddonDB.updateInterval = MyAddonDB.updateInterval or 0.2
        MyAddonDB.tokenSize = MyAddonDB.tokenSize or 16
        MyAddonDB.tokensPerRow = MyAddonDB.tokensPerRow or 5
        MyAddonDB.xOffset = MyAddonDB.xOffset or 0
        MyAddonDB.yOffset = MyAddonDB.yOffset or 0
        MyAddonDB.rowSpacing = MyAddonDB.rowSpacing or 20
        MyAddonDB.columnSpacing = MyAddonDB.columnSpacing or 20
        MyAddonDB.anchor = MyAddonDB.anchor or "TOPLEFT"
        MyAddonDB.growDirection = MyAddonDB.growDirection or "Right and Up"
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local specIndex = GetSpecialization()
        local specID = GetSpecializationInfo(specIndex)
        unitSpecCache[UnitGUID("player")] = specID
        RefreshToken("player")
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        removedNamePlate = C_NamePlate.GetNamePlateForUnit(arg1)
        HideRemovedNamePlateTextures(removedNamePlate)
    end
end

eventListenerFrame:SetScript("OnEvent", eventHandler)

function OnInspectionComplete(frame, unit)
    if not UnitExists(unit) then 
        return 
    end
    RefreshToken(unit)
end

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
    if UnitInRaid(unitID) then return end
    if not tokenTextures[unitID] then
        CreateToken(unitID)
    end
    UpdateToken(unitID)
end

local function InitializeGroup()
    groupType = GetGroupType()
    for i = 1, 40, 1
    do
        unitID = groupType .. i
        if not UnitExists(unitID) then break end
        guid = UnitGUID(unitID)
        if not unitSpecCache[guid] then QueueInspection(unitID) end
    end
end

local function UpdateGroup()
    groupType = GetGroupType()
    for i = 1, 40, 1
    do
        unitID = groupType .. i
        if not UnitExists(unitID) then break end
        guid = UnitGUID(unitID)
        if not unitSpecCache[guid] then QueueInspection(unitID) end
        if not tokenTextures[unitID] then
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
    UpdateGroup()
    if MyAddonDB.settingsKeys["displayPlayerToken"] then UpdatePlayer() end
    ResetTargetCounts()
end
ticker = InitializeUpdateLoop()
