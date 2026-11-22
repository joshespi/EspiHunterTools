local ADDON_NAME = "EspiHunterTools"
local _, class = UnitClass("player")
if class ~= "HUNTER" then
    return
end
if not (C_PetInfo and C_PetInfo.GetPetHappiness and C_SpellBook and C_SpellBook.IsSpellKnown) then
    print("|cffffd166Espi Hunter Tools:|r this client is missing the pet or spellbook APIs the addon needs, so it is disabled.")
    return
end

local CALL_PET = 883
local ASPECT_OF_THE_CHEETAH = 5118
local HAPPINESS_UNHAPPY = 1 -- red
local HAPPINESS_CONTENT = 2 -- yellow
local PANEL_WIDTH, PANEL_ONE_LINE, PANEL_TWO_LINES = 380, 34, 58
local DEFAULT_POINT = { "TOP", "UIParent", "CENTER", 0, 148 }

-- Older clients may not have the secret-value API. Treat nothing as secret there.
local isSecret = issecretvalue or function() return false end

local defaults = { scale = 1, sound = false, point = nil }
local db = {}
local unlocked = false

local panel = CreateFrame("Frame", nil, UIParent)
panel:SetSize(PANEL_WIDTH, PANEL_ONE_LINE)
panel:SetFrameStrata("HIGH")
panel:SetClampedToScreen(true)
panel:SetMovable(true)
panel:EnableMouse(false)
panel:RegisterForDrag("LeftButton")
panel:Hide()

local background = panel:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetColorTexture(0.04, 0.045, 0.055, 0.88)

local lines = {}
for index = 1, 2 do
    local line = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    line:SetPoint("TOP", 0, -8 - (index - 1) * 24)
    lines[index] = line
end

local RED = { 1, 0.38, 0.30 }
local YELLOW = { 1, 0.83, 0.40 }
local ORANGE = { 1, 0.50, 0.32 }

local warnings = {
    missing = { text = "No pet summoned", color = RED },
    dead = { text = "Your pet is dead", color = RED },
    content = { text = "Feed your pet - content (yellow)", color = YELLOW },
    unhappy = { text = "Feed your pet - unhappy (red)", color = ORANGE },
    cheetah = { text = "Drop Aspect of the Cheetah", color = RED },
    cheetahUnknown = { text = "Check Cheetah - buff data restricted", color = YELLOW },
}
local PREVIEW = { text = "Espi Hunter Tools - drag to move", color = YELLOW }

local function SetLine(line, warning)
    line:SetText(warning.text)
    line:SetTextColor(unpack(warning.color))
end

local function PlayAlertSound()
    if db.sound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING)
    end
end

local lastKey

local function HidePanel()
    lastKey = nil
    panel:Hide()
end

local function ShowPreview()
    SetLine(lines[1], PREVIEW)
    lines[2]:Hide()
    panel:SetHeight(PANEL_ONE_LINE)
    panel:Show()
end

local function ShowWarnings(petWarning, cheetahWarning)
    local first = petWarning or cheetahWarning
    if not first then
        HidePanel()
        return
    end

    local second = petWarning and cheetahWarning
    SetLine(lines[1], warnings[first])

    if second then
        SetLine(lines[2], warnings[second])
        lines[2]:Show()
    else
        lines[2]:Hide()
    end

    panel:SetHeight(second and PANEL_TWO_LINES or PANEL_ONE_LINE)

    -- Fade in and play the sound only when the set of warnings changes.
    local key = first .. "/" .. (second or "")
    local wasShown = panel:IsShown()
    if not wasShown or key ~= lastKey then
        if not wasShown and UIFrameFadeIn then
            UIFrameFadeIn(panel, 0.15, 0, 1)
        end
        PlayAlertSound()
    end
    lastKey = key
    panel:Show()
end

local function GetPetWarning(inCombat)
    local exists = UnitExists("pet")
    if isSecret(exists) then
        return
    end
    if not exists then
        if inCombat and C_SpellBook.IsSpellKnown(CALL_PET) then
            return "missing"
        end
        return
    end

    -- A dead pet only warns in combat; out of combat you can just revive it.
    local dead = UnitIsDead("pet")
    if isSecret(dead) then
        return
    end
    if dead then
        return inCombat and "dead" or nil
    end

    local happiness = C_PetInfo.GetPetHappiness()
    if isSecret(happiness) then
        return
    end
    if happiness == HAPPINESS_UNHAPPY then
        return "unhappy"
    elseif happiness == HAPPINESS_CONTENT then
        return "content"
    end
end

local function GetCheetahWarning()
    if not C_SpellBook.IsSpellKnown(ASPECT_OF_THE_CHEETAH) then
        return
    end
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
        return
    end

    -- A restricted lookup can fail or return an unreadable value. Treat either as unknown.
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, ASPECT_OF_THE_CHEETAH)
    if not ok or isSecret(aura) then
        return "cheetahUnknown"
    end
    if aura then
        return "cheetah"
    end
    if C_Secrets and C_Secrets.ShouldSpellAuraBeSecret
        and C_Secrets.ShouldSpellAuraBeSecret(ASPECT_OF_THE_CHEETAH) then
        return "cheetahUnknown"
    end
end

local function Refresh()
    if unlocked then
        ShowPreview()
        return
    end

    -- No alerts while dead, on a flight path or in a vehicle.
    if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") or UnitInVehicle("player") then
        HidePanel()
        return
    end

    local inCombat = InCombatLockdown()
    ShowWarnings(GetPetWarning(inCombat), inCombat and GetCheetahWarning() or nil)
end

-- Position, scale and lock state.
local function ApplyPosition()
    local point = db.point or DEFAULT_POINT
    panel:ClearAllPoints()
    panel:SetPoint(point[1], UIParent, point[3], point[4], point[5])
    panel:SetScale(db.scale or 1)
end

local function SetUnlocked(value)
    unlocked = value
    panel:EnableMouse(value)
    Refresh()
end

panel:SetScript("OnDragStart", function(self)
    if unlocked then
        self:StartMoving()
    end
end)
panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    db.point = { point, "UIParent", relativePoint, x, y }
end)

local function Say(message)
    print("|cffffd166Espi Hunter Tools:|r " .. message)
end

SLASH_ESPIHUNTER1 = "/espihunter"
SLASH_ESPIHUNTER2 = "/eht"
SlashCmdList.ESPIHUNTER = function(input)
    local command, argument = strsplit(" ", strtrim((input or ""):lower()), 2)
    argument = argument and strtrim(argument)

    if command == "unlock" then
        SetUnlocked(true)
        Say("unlocked. Drag the alert, then type /espihunter lock.")
    elseif command == "lock" then
        SetUnlocked(false)
        Say("locked.")
    elseif command == "scale" then
        local scale = tonumber(argument)
        if scale and scale >= 0.5 and scale <= 2 then
            db.scale = scale
            panel:SetScale(scale)
            Say("scale set to " .. scale .. ".")
        else
            Say("usage: /espihunter scale 0.5-2")
        end
    elseif command == "sound" then
        if argument == "on" or argument == "off" then
            db.sound = argument == "on"
            Say("sound " .. argument .. ".")
        else
            Say("usage: /espihunter sound on|off")
        end
    elseif command == "reset" then
        db.point, db.scale, db.sound = defaults.point, defaults.scale, defaults.sound
        ApplyPosition()
        Say("position, scale and sound reset.")
    else
        Say("commands: unlock, lock, scale <0.5-2>, sound on|off, reset")
    end
end

-- Coalesce bursts of events (pet health, auras) into one refresh per frame.
local dirty = false
local throttle = CreateFrame("Frame")
throttle:Hide()
throttle:SetScript("OnUpdate", function(self)
    self:Hide()
    dirty = false
    Refresh()
end)

local function QueueRefresh()
    if not dirty then
        dirty = true
        throttle:Show()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")
events:RegisterEvent("PLAYER_CONTROL_LOST")
events:RegisterEvent("PLAYER_CONTROL_GAINED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterUnitEvent("UNIT_PET", "player")
events:RegisterUnitEvent("UNIT_HEALTH", "pet")
events:RegisterUnitEvent("UNIT_HAPPINESS", "pet")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
events:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then
            return
        end
        EspiHunterToolsDB = EspiHunterToolsDB or {}
        db = EspiHunterToolsDB
        for key, value in pairs(defaults) do
            if db[key] == nil then
                db[key] = value
            end
        end
        ApplyPosition()
        events:UnregisterEvent("ADDON_LOADED")
        return
    end
    QueueRefresh()
end)
