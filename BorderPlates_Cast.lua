-- Barras de lanzamiento para jugador y objetivo (WoW 3.3.5a).
-- Independientes de los marcos seguros y de sus barras de vida/recurso.
local function CreateCast(unit, owner, mirrored)
    local bar = CreateFrame("StatusBar", "BorderPlatesCast_" .. unit, owner)
    bar:SetSize(166, 12)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetStatusBarColor(0.95, 0.68, 0.2)
    bar:SetFrameStrata("MEDIUM")
    bar:SetFrameLevel(owner:GetFrameLevel() + 8)
    bar:SetPoint("TOP", owner, "BOTTOM", 0, -5)
    -- Colocar el casteo debajo de la mascota cuando realmente exista.
    -- No depende de la clase: tambien funciona con mascotas temporales.
    local function UpdatePosition()
        if unit ~= "player" then return end
        local petFrame = _G.BorderPlatesPetFrame
        local anchor = (petFrame and UnitExists("pet") and petFrame:IsShown()) and petFrame or owner
        if bar.castAnchor ~= anchor then
            bar:ClearAllPoints()
            if anchor == owner then
                bar:SetPoint("TOP", owner, "BOTTOM", 0, -5)
            else
                -- La mascota esta desplazada a la izquierda: conservar el centro
                -- horizontal del jugador y usar solo la altura inferior de la mascota.
                bar:SetPoint("TOP", owner, "BOTTOM", 0, -5)
                bar:SetPoint("TOP", owner, "BOTTOM", 0, -5 - math.max(0, (owner:GetBottom() or 0) - (anchor:GetBottom() or 0)))
            end
            bar.castAnchor = anchor
        end
    end
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.05, 0.04, 0.08, 0.9)
    local border = CreateFrame("Frame", nil, bar)
    border:SetPoint("TOPLEFT", bar, -1, 1)
    border:SetPoint("BOTTOMRIGHT", bar, 1, -1)
    border:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=9})
    local name = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("LEFT", bar, "LEFT", 4, 0)
    name:SetWidth(126)
    name:SetJustifyH("LEFT")
    local timer = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timer:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    local icon = bar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint(mirrored and "LEFT" or "RIGHT", bar, mirrored and "RIGHT" or "LEFT", mirrored and 3 or -3, 0)
    local active, channel, startTime, endTime = false, false, 0, 0
    local function Refresh()
        UpdatePosition()
        if not UnitExists(unit) then active=false; bar:Hide(); return end
        local spell, _, _, texture, startMS, endMS, _, _, notInterruptible = UnitCastingInfo(unit)
        local isChannel = false
        if not spell then
            spell, _, _, texture, startMS, endMS, _, notInterruptible = UnitChannelInfo(unit)
            isChannel = spell ~= nil
        end
        if not spell or not startMS or not endMS then active=false; bar:Hide(); return end
        startTime, endTime = startMS / 1000, endMS / 1000
        channel = isChannel
        active = true
        name:SetText(spell)
        icon:SetTexture(texture)
        bar:SetMinMaxValues(0, math.max(0.01, endTime - startTime))
        if notInterruptible then bar:SetStatusBarColor(0.65, 0.65, 0.65)
        elseif channel then bar:SetStatusBarColor(0.35, 0.65, 1)
        else bar:SetStatusBarColor(0.95, 0.68, 0.2) end
        bar:Show()
    end
    bar:SetScript("OnUpdate", function(self)
        if not active then return end
        UpdatePosition()
        local now = GetTime()
        local remaining = math.max(0, endTime - now)
        local elapsed = math.max(0, now - startTime)
        self:SetValue(channel and remaining or elapsed)
        timer:SetFormattedText("%.1f", remaining)
        if remaining <= 0 then Refresh() end
    end)
    local events = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "UNIT_PET", "PLAYER_TARGET_CHANGED", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"}) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnEvent", function(self, event, eventUnit)
        if event == "PLAYER_ENTERING_WORLD" or (unit == "player" and event == "UNIT_PET" and eventUnit == "player") or (unit == "target" and event == "PLAYER_TARGET_CHANGED") or eventUnit == unit then
            Refresh()
        end
    end)
    bar:Hide()
end
CreateCast("player", BorderPlatesPlayerFrame, false)
CreateCast("target", BorderPlatesTargetFrame, true)
