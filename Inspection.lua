_G.unitSpecCache = {}

local inspectionQueue = {}
local inspecting = false

function ClearInspectionQueue()
    inspectionQueue = {}
end

function ClearUnitSpecCache()
    _G.unitSpecCache = {}
end

local function ProcessNextInspection()
    if #inspectionQueue == 0 then return end
    local unit = inspectionQueue[1]
    if UnitExists(unit) and CanInspect(unit) then
        NotifyInspect(unit)
        inspecting = true
    else
        table.remove(inspectionQueue, 1)
        C_Timer.After(0.1, ProcessNextInspection)
    end
end

function QueueInspection(unitID)
    if not UnitExists(unitID) or not CanInspect(unitID) then return end
    local guid = UnitGUID(unitID)
    if not guid or unitSpecCache[guid] then return end

    for  _, unit in ipairs(inspectionQueue) do
        if UnitGUID(unit) == guid then return end
    end

    table.insert(inspectionQueue, unitID)
    if not inspecting then
        ProcessNextInspection()
    end
end

INSPECTION_COMPLETE = "INSPECTION_COMPLETE"

local inspectionListenerFrame = CreateFrame("Frame", "InspectionEventListenerFrame", UIParent)
inspectionListenerFrame:RegisterEvent("INSPECT_READY")

inspectionListenerFrame:SetScript("OnEvent", function(_, event, guid)
    if event == "INSPECT_READY" and guid then
        local unit = inspectionQueue[1]
        if unit and UnitGUID(unit) == guid then
            local specID = GetInspectSpecialization(unit)
            if specID and specID ~= 0 then
                local _, specName = GetSpecializationInfoByID(specID)
                unitSpecCache[guid] = specID
            end
        end
        table.remove(inspectionQueue, 1)
        inspecting = false
        RTTAddon:TriggerEvent(INSPECTION_COMPLETE, self, unit)
        C_Timer.After(2, ProcessNextInspection)
    end
end)
