RTTAddon = LibStub("AceAddon-3.0"):NewAddon("RTTAddon")
RTTAddon.callbacks = {}

local function InitializePlaterAPIAccess()
    Plater = _G["Plater"]
    if Plater then 
        print("Plater NamePlates successfully accessed by RTT")
        return Plater 
    end
    return nil
end

local function InitializeElvUIAPIAccess()
    if ElvUI then
        local NP = ElvUI[1]:GetModule("NamePlates", true)
        if NP then
            print("ElvUI NamePlates successfully accessed by RTT")
            return NP
        end
    end
    return nil
end

function RTTAddon:OnInitialize()
    local defaults = {
        profile = {
            displayPlayerToken = true,
            updateInterval = 0.2,
            tokenSize = 16,
            tokensPerRow = 5,
            xOffset = 0,
            yOffset = 0,
            rowSpacing = 20,
            columnSpacing = 20,
            anchor = "TOPLEFT",
            growDirection = 1,
            onlyDisplayDuringCombat = false,
            iconStyle = classIcons,

            minimap = {
                hide = false,
            },
        },   
    }

    RTTAddon.db = LibStub("AceDB-3.0"):New("RTTDB", defaults, true)

    InitializeOptionsMenu()
    local LDB = CreateLibraryDataBroker()
    RegisterMinimap(LDB)

    SLASH_RTT1 = "/gtt"
    SlashCmdList["RTT"] = function()
        LibStub("AceConfigDialog-3.0"):Open("RTTAddon")    
    end

    Plater = InitializePlaterAPIAccess()
    NP = InitializeElvUIAPIAccess()
    print("Group Target Trackers successfully loaded!")
end

local tokenTextures = {}
local targetCounts = {}
local currentTargets = {}

local function GetUnitIcon(unitID) -- possible roles: "tank", "healer", "rdps", "mdps"
   unitSpecID = unitSpecCache[UnitGUID(unitID)]
   if RTTAddon.db.profile.iconStyle then
        if RTTAddon.db.profile.iconStyle == "classIcons" then
            return classIcons[unitSpecID]
        end  
   end
   
   return roleIcons[unitSpecID]
end

local function GetTexturePath(unitID)
    local icon = GetUnitIcon(unitID)
    return "Interface\\Addons\\GroupTargetTrackers\\Textures\\" ..  icon
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
    texture:SetSize(RTTAddon.db.profile.tokenSize, RTTAddon.db.profile.tokenSize)
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

    if RTTAddon.db.profile.tokenSize then
        texture:SetSize(RTTAddon.db.profile.tokenSize, RTTAddon.db.profile.tokenSize)
    else
        print("Error: RTTAddon.db.profile.tokenSize not initialized. Setting to defaults")
        texture:SetSize(16, 16)
        RTTAddon.db.profile.tokenSize = 16
    end
end

function RefreshTokens()
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
    local growDirection = RTTAddon.db.profile.growDirection
    if growDirection == 1 then return { 1, 1 } end
    if growDirection == 2 then return { 1, -1 } end
    if growDirection == 3 then return { -1, 1 } end
    if growDirection == 4 then return { -1, -1 } end
    return { 1, 1 }
end

local function CalculateTargetCountOffset(targetNamePlate)
    local rowPosition  = (targetCounts[targetNamePlate] - 1) % RTTAddon.db.profile.tokensPerRow
    local tokenScaleMultiplier = RTTAddon.db.profile.tokenSize / 16
    local growDirection = GetGrowDirection()
    return rowPosition * 20 * tokenScaleMultiplier * growDirection[1] -- this magic number 20 is esssentially the spacing between tokens. It should be added later as an option
end

local function CalculateRowCountOffset(targetNamePlate)
    local rowCount = math.ceil(targetCounts[targetNamePlate]/RTTAddon.db.profile.tokensPerRow)
    local tokenScaleMultiplier = RTTAddon.db.profile.tokenSize / 16
    local growDirection = GetGrowDirection()
    return (rowCount - 1) * 20 * tokenScaleMultiplier * growDirection[2]
end

local function UpdateTexture(targetNamePlate, texture)
    texture:Hide()
    texture:SetParent(targetNamePlate.UnitFrame)
    if Plater then 
        texture:SetParent(targetNamePlate.unitFrame)
    elseif ElvUI then 
        texture:SetParent(targetNamePlate) 
    end
    local targetCountOffset = CalculateTargetCountOffset(targetNamePlate)
    local rowCountOffset = CalculateRowCountOffset(targetNamePlate)
    local anchorNum = RTTAddon.db.profile.anchor
    texture:SetPoint("CENTER", targetNamePlate, RTTAddon.db.profile.anchor, RTTAddon.db.profile.xOffset + targetCountOffset, RTTAddon.db.profile.yOffset + rowCountOffset)
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
        elseif ElvUI and ElvUI[1].private.nameplates.enable then
            if not NP then 
                NP = InitializeElvUIAPIAccess()
            end
            for plate, _ in pairs(NP.Plates) do -- loop through all nameplates (nameplate1, nameplate2, nameplate3, nameplate4, etc.)
                local plateUnit = plate.unit or (plate.UnitFrame and plate.UnitFrame.unit) or (plate.unitFrame and plate.unitFrame.unit)
                if UnitGUID(unit .. "target") == UnitGUID(plateUnit) then
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

local isInCombat = false
local function IsInCombat()
    return isInCombat
end

local eventListenerFrame = CreateFrame("Frame", "RTTAddonEventListenerFrame", UIParent)
eventListenerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventListenerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
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
    elseif event == "ADDON_LOADED" and arg1 == "GroupTargetTrackers" then
        if not RTTAddon.db.profile.onlyDisplayDuringCombat then ticker = InitializeUpdateLoop() end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local specIndex = GetSpecialization()
        local specID = GetSpecializationInfo(specIndex)
        unitSpecCache[UnitGUID("player")] = specID
        RefreshToken("player")
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        removedNamePlate = C_NamePlate.GetNamePlateForUnit(arg1)
        HideRemovedNamePlateTextures(removedNamePlate)
    elseif event == "PLAYER_REGEN_DISABLED" then
        isInCombat = true
        if ticker then ticker:Cancel() end
        ticker = InitializeUpdateLoop()
    elseif event == "PLAYER_REGEN_ENABLED" then
        isInCombat = false
        if RTTAddon.db.profile.onlyDisplayDuringCombat then StopUpdateLoop() end
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
    ticker = C_Timer.NewTicker(RTTAddon.db.profile.updateInterval, Update)
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

function HidePlayerTexture()
    tokenTextures["player"]:Hide()
end

local function UpdatePlayer()
    unitID = "player"
    if UnitInRaid(unitID) then return end
    if not tokenTextures[unitID] then
        CreateToken(unitID)
    end
    if not RTTAddon.db.profile.displayPlayerToken and tokenTextures[unitID]:IsShown() then 
        tokenTextures[unitID]:Hide()
        return
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
    local updateInterval = RTTAddon.db.profile.updateInterval or 0.2
    return C_Timer.NewTicker(updateInterval, Update)
end

function StopUpdateLoop()
    ticker:Cancel()
    for unit, texture in pairs(tokenTextures) do 
       texture:Hide() 
    end
end

function Update()
    if RTTAddon.db.profile.onlyDisplayDuringCombat and not IsInCombat() then StopUpdateLoop() end
    UpdateGroup()
    if RTTAddon.db.profile.displayPlayerToken then UpdatePlayer() end
    ResetTargetCounts()
end
