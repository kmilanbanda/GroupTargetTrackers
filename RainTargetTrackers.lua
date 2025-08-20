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
local countsOnTargets = {}
local currentTargets = {}

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

function UpdateCircle(texture, unit)
    local targetNamePlate = C_NamePlate.GetNamePlateForUnit(unit .. "target")
    if UnitExists(unit .. "target") then
	--adjusting counter for number of tokens on target
        if not countsOnTargets[targetNamePlate] then
            countsOnTargets[targetNamePlate] = 1
        else
            countsOnTargets[targetNamePlate] = countsOnTargets[targetNamePlate] + 1
        end
        if currentTargets[unit] then
            countsOnTargets[targetNamePlate] = countsOnTargets[targetNamePlate] - 1
            if countsOnTargets[targetNamePlate] < 0 then
                countsOnTargets[targetNamePlate] = 0
            end
        end
        currentTargets[unit] = targetNamePlate

        if targetNamePlate and texture then
            print("updating texture")
            texture:Hide()
            texture:SetParent(targetNamePlate.UnitFrame)
            local circleOffset = (countsOnTargets[targetNamePlate] - 1) * 20
            texture:SetPoint("CENTER", targetNamePlate, "CENTER", -60 + circleOffset, 20)
            texture:Show()
            print("texture showing")
        else
            if not targetNamePlate then
                print("target nameplate not found for " .. unit .. "target")
            end
            if not texture then
                print("texture not found")
            end
        end
    else
        if currentTargets[unit] then
            local oldNameplate = currentTargets[unit]
            countsOnTargets[oldNameplate] = countsOnTargets[oldNameplate] - 1
            if countsOnTargets[oldNameplate] < 0 then
                countsOnTargets[oldNameplate] = 0
            end
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
        if IsEligibleUnit(unitID) then
            if not circleTextures[unitID] then
                print("Creating circle for " .. unitID)
                CreateCircle(unitID)
            end
            UpdateCircle(circleTextures[unitID], unitID)
        end

        if MyAddonDB.settingsKeys.enablePrinting then
            PrintTargetChanges(unitID)
	end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        --print("NAME_PLATE_UNIT_REMOVED: " .. unitID)
        for unit, texture in pairs(circleTextures) do
            local targetID = unit .. "target"
            if IsUnitsTarget(unitID, targetID) then
                texture:Hide()
		--print("unitID GUID: " .. UnitGUID(unitID) .. " targetID GUID: " .. UnitGUID(targetID))
                print("Hiding texture for " .. unitID .. " due to nameplate removal")
            end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        --print("NAME_PLATE_UNIT_ADDED: " .. unitID)
        for unit, texture in pairs(circleTextures) do
            local targetID = unit .. "target"
            if IsUnitsTarget(unitID, targetID) then
		UpdateCircle(texture, unit)
                texture:Show()
		--print("unitID GUID: " .. UnitGUID(unitID) .. " targetID GUID: " .. UnitGUID(targetID))
                print("Updating texture for " .. unit .. " due to nameplate addition")
            end
        end
    end
end

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
