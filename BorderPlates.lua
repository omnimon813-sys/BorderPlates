-- Border Plates 1.0.0: marco del jugador con texturas propias.
-- Marco original de Blizzard oculto por completo.

local MEDIA = "Interface\\AddOns\\BorderPlates\\Media\\"

-- Ajuste de escala: 0.35 es mucho más pequeño y manejable en pantalla.
local SCALE = 0.35

local PLATE_W, PLATE_H = 512 * SCALE, 128 * SCALE
local BAR_H = 32 * SCALE
local HEAD_ROOM = 40 * SCALE

local defaults = {
    point = "TOPLEFT", relPoint = "TOPLEFT", x = 18, y = -18,
    zoom = 0.7, px = 0, py = 0, pz = 0,
    textMode = "both",
    locked = true, -- Bloqueado por defecto
    positionPreset = "original",
}

local db

local function BPMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffaa80ffBorder Plates:|r " .. msg)
end

------------------------------------------------------------
-- Ocultar el marco original de Blizzard (PlayerFrame)
------------------------------------------------------------
local function HideBlizzardPlayerFrame()
    if PlayerFrame then
        PlayerFrame:Hide()
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:SetScript("OnUpdate", nil)
        PlayerFrame:SetScript("OnEvent", nil)
    end
end

------------------------------------------------------------
-- Utilidades de Colores por Tipo de Recurso
------------------------------------------------------------
local function PowerColor(powerType)
    if powerType == 1 then return 1, 0.12, 0.12 end         -- Ira
    if powerType == 2 then return 1, 0.5, 0.25 end          -- Enfoque
    if powerType == 3 then return 1, 0.94, 0.12 end         -- Energía
    if powerType == 6 then return 0.2, 0.8, 1.0 end         -- Poder rúnico
    if powerType == 0 then return 0.12, 0.5, 1.0 end        -- Maná
    return 0.62, 0.42, 0.88                                 -- Predeterminado
end

local function FormatValue(cur, max, mode)
    cur, max = cur or 0, max or 0
    local pct = 0
    if max > 0 then pct = math.floor(cur / max * 100 + 0.5) end
    if mode == "num" then
        return cur .. " / " .. max
    elseif mode == "pct" then
        return pct .. "%"
    end
    return cur .. " / " .. max .. "  (" .. pct .. "%)"
end

------------------------------------------------------------
-- Barras con extremos diagonales
------------------------------------------------------------
local function MakeBar(parent, borderTex, windowTex, texW)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetWidth(texW * SCALE)
    bar:SetHeight(BAR_H)

    bar.winL, bar.winR = 10, texW - 8
    bar.texW = texW

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(MEDIA .. windowTex)
    bg:SetVertexColor(0.04, 0.025, 0.06, 1)
    bg:SetAllPoints(bar)

    local fill = bar:CreateTexture(nil, "BORDER")
    fill:SetTexture(MEDIA .. windowTex)
    fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    bar.fill = fill
    bar.isFlat = false
    if bar.isFlat then fill:SetTexture("Interface\\Buttons\\WHITE8X8") end

    local border = bar:CreateTexture(nil, "ARTWORK")
    border:SetTexture(MEDIA .. borderTex)
    border:SetAllPoints(bar)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.text = text

    return bar
end

local function SetBar(bar, value, maximum, isReversed)
    local pct = 0
    if maximum and maximum > 0 then
        pct = math.max(0, math.min(1, (value or 0) / maximum))
    end
    local visiblePx = bar.winL + (bar.winR - bar.winL) * pct
    if bar.isFlat then visiblePx = bar.winR * pct end
    local frac = visiblePx / bar.texW
    
    -- Ajuste de ancho
    bar.fill:SetWidth(math.max(0.001, bar:GetWidth() * frac))
    
    -- Si es reverso, invertimos la textura, si no, normal.
    if bar.isFlat then
        bar.fill:SetTexCoord(0, 1, 0, 1) -- Sin diagonales internas ni deformacion.
    elseif isReversed then
        bar.fill:SetTexCoord(frac, 0, 0, 1)
    else
        bar.fill:SetTexCoord(0, frac, 0, 1)
    end
end

------------------------------------------------------------
-- Marco principal
------------------------------------------------------------
local f = CreateFrame("Frame", "BorderPlatesPlayerFrame", UIParent)
f:SetWidth(PLATE_W)
f:SetHeight(HEAD_ROOM + PLATE_H + 4 + BAR_H + 2 + BAR_H)
f:SetPoint(defaults.point, UIParent, defaults.relPoint, defaults.x, defaults.y)
f:SetFrameStrata("MEDIUM")
f:SetClampedToScreen(true)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
-- Menu original del jugador al hacer clic derecho en la placa/retrato.
f:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" and PlayerFrameDropDown and ToggleDropDownMenu then
        ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor", 0, 0)
    end
end)

-- Bloqueo de arrastre más estricto
f:SetScript("OnDragStart", function(self)
    if db and not db.locked then 
        self:StartMoving() 
    else
        BPMessage("El marco está bloqueado. Usa /bp unlock para moverlo.")
    end
end)

f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then
        local point, _, relPoint, x, y = self:GetPoint()
        db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
    end
end)

local baseLevel = f:GetFrameLevel()

-- Placa (parte de atrás)
local plateFrame = CreateFrame("Frame", nil, f)
plateFrame:SetWidth(PLATE_W)
plateFrame:SetHeight(PLATE_H)
plateFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -HEAD_ROOM)
plateFrame:SetFrameLevel(baseLevel + 1)
plateFrame:EnableMouse(false)
local plateTex = plateFrame:CreateTexture(nil, "BACKGROUND")
plateTex:SetTexture(MEDIA .. "plate")
plateTex:SetAllPoints(plateFrame)

-- Retrato 3D
local model = CreateFrame("PlayerModel", "BorderPlatesPlayerModel", f)
model:SetWidth(104 * SCALE / 0.625)
model:SetHeight(112 * SCALE / 0.625)
model:SetPoint("BOTTOMLEFT", plateFrame, "BOTTOMLEFT", 6 * SCALE / 0.625, 6 * SCALE / 0.625)
model:SetFrameLevel(baseLevel + 2)
model:EnableMouse(false) -- El clic llega al marco principal.

local function ApplyModel()
    model:SetUnit("player")
    if model.SetCamera then model:SetCamera(0) end
    if model.SetPortraitZoom then model:SetPortraitZoom(db and db.zoom or defaults.zoom) end
    if model.SetPosition then
        model:SetPosition(db and db.px or 0, db and db.py or 0, db and db.pz or 0)
    end
end

-- Repisa metálica frontal
local frontFrame = CreateFrame("Frame", nil, f)
frontFrame:SetWidth(96 * SCALE / 0.625)
frontFrame:SetHeight(12 * SCALE / 0.625)
frontFrame:SetPoint("BOTTOMLEFT", plateFrame, "BOTTOMLEFT", 4 * SCALE / 0.625, 2 * SCALE / 0.625)
frontFrame:SetFrameLevel(baseLevel + 3)
frontFrame:EnableMouse(false)
local frontTex = frontFrame:CreateTexture(nil, "ARTWORK")
frontTex:SetTexture(MEDIA .. "plate_front")
frontTex:SetAllPoints(frontFrame)

-- Textos e insignia
local textFrame = CreateFrame("Frame", nil, f)
textFrame:SetAllPoints(plateFrame)
textFrame:SetFrameLevel(baseLevel + 4)
textFrame:EnableMouse(false)

local name = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
name:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 125 * SCALE / 0.625, -10 * SCALE / 0.625)
name:SetWidth(130 * SCALE / 0.625)
name:SetHeight(18 * SCALE / 0.625)
name:SetJustifyH("LEFT")

local level = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
level:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 125 * SCALE / 0.625, -46 * SCALE / 0.625)
level:SetJustifyH("LEFT")

-- Icono circular: WoW 3.3.5a no dispone de mascaras de textura modernas.
-- Dibujamos el icono de clase en franjas horizontales recortadas formando un circulo.
local iconSize = 28 * SCALE / 0.625
local iconCX = 281 * SCALE / 0.625
local iconCY = -40 * SCALE / 0.625
local _, playerClass = UnitClass("player")
local coords = playerClass and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[playerClass]
local slices = 28
for i = 0, slices - 1 do
    local top = i / slices
    local bottom = (i + 1) / slices
    local middle = (top + bottom) * 0.5
    local circleX = math.sqrt(math.max(0, 1 - (2 * middle - 1)^2)) * 0.5
    local left = 0.5 - circleX
    local right = 0.5 + circleX
    local strip = textFrame:CreateTexture(nil, "OVERLAY")
    strip:SetWidth(iconSize * (right - left))
    strip:SetHeight(iconSize / slices + 0.02)
    strip:SetPoint("TOPLEFT", textFrame, "TOPLEFT",
        iconCX - iconSize / 2 + iconSize * left,
        iconCY + iconSize / 2 - iconSize * top)
    if coords then
        strip:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        strip:SetTexCoord(coords[1] + (coords[2] - coords[1]) * left,
            coords[1] + (coords[2] - coords[1]) * right,
            coords[3] + (coords[4] - coords[3]) * top,
            coords[3] + (coords[4] - coords[3]) * bottom)
    else
        strip:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        strip:SetTexCoord(left, right, top, bottom)
    end
end

-- Barras: salud y recurso alineadas dentro del ancho de la placa.
-- Se mantiene el romboide de 1.0.0; ambas barras tienen el mismo ancho.
-- La inclinacion original equivale a 22 pixeles en una textura de 512.
-- Calculamos un margen para que ni el extremo izquierdo del recurso
-- ni el extremo derecho de la salud sobresalgan de la placa.
local BAR_SHIFT = PLATE_W * 22 / (512 + 22)
local BAR_WIDTH = PLATE_W - BAR_SHIFT

local health = MakeBar(f, "bar_health", "win_health", 512)
health:SetWidth(BAR_WIDTH)
health:SetPoint("TOPLEFT", plateFrame, "BOTTOMLEFT", BAR_SHIFT, -4)
health:SetFrameLevel(baseLevel + 1)

local power = MakeBar(f, "bar_power", "win_power", 512)
power:SetWidth(BAR_WIDTH)
power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", -BAR_SHIFT, 0)
power:SetFrameLevel(baseLevel + 1)

health.fill:SetVertexColor(0.12, 0.82, 0.22, 1)

-- Fragmento de dano: desaparece en una animacion breve, sin barra retrasada.
local damage = health:CreateTexture(nil, "OVERLAY")
damage:SetTexture("Interface\\Buttons\\WHITE8X8")
damage:SetVertexColor(1, 0.25, 0.12, 0.85)
damage:SetHeight(BAR_H * 0.60)
damage:Hide()
local damageElapsed, lastHealth, lastMaxHealth = 0, nil, nil
local damageTicker = CreateFrame("Frame", nil, health)
damageTicker:Hide()
damageTicker:SetScript("OnUpdate", function(self, elapsed)
    damageElapsed = damageElapsed + elapsed
    local t = math.min(1, damageElapsed / 0.55)
    damage:SetAlpha(1 - t)
    if t >= 1 then damage:Hide(); self:Hide() end
end)
local function AnimateHealthLoss(current, maximum)
    if lastHealth and lastMaxHealth and maximum > 0 and current < lastHealth then
        local from = math.min(1, lastHealth / lastMaxHealth)
        local to = math.max(0, math.min(1, current / maximum))
        local width = health:GetWidth()
        damage:ClearAllPoints()
        damage:SetPoint("LEFT", health, "LEFT", width * to, 0)
        damage:SetWidth(math.max(0.001, width * (from - to)))
        damage:SetAlpha(1)
        damage:Show()
        damageElapsed = 0
        damageTicker:Show()
    end
    lastHealth, lastMaxHealth = current, maximum
end

------------------------------------------------------------
-- Soporte de Runas para Caballero de la Muerte (DK)
------------------------------------------------------------
if playerClass == "DEATHKNIGHT" and RuneFrame then
    RuneFrame:SetParent(f)
    RuneFrame:ClearAllPoints()
    RuneFrame:SetPoint("TOP", power, "BOTTOM", 0, -4)
    RuneFrame:SetScale(0.85)
    RuneFrame:Show()
end

------------------------------------------------------------
-- Actualización de datos y colores dinámicos
------------------------------------------------------------
local function Update()
    HideBlizzardPlayerFrame()
    local mode = db and db.textMode or defaults.textMode

    local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
    AnimateHealthLoss(hp, hpMax)
    SetBar(health, hp, hpMax, false) -- Dirección normal para vida
    health.text:SetText(FormatValue(hp, hpMax, mode))

    local pType = UnitPowerType("player")
    local p, pMax = UnitPower("player"), UnitPowerMax("player")
    local r, g, b = PowerColor(pType)
    power.fill:SetVertexColor(r, g, b, 1)
    -- CAMBIO: Usamos false para que crezca de izquierda a derecha (tangente correcta)
    SetBar(power, p, pMax, false) 
    power.text:SetText(FormatValue(p, pMax, (mode == "both") and "num" or mode))

    name:SetText(UnitName("player") or "Jugador")
    level:SetText("Nivel " .. tostring(UnitLevel("player") or "?"))
    local _, cls = UnitClass("player")
    if cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls] then
        local c = RAID_CLASS_COLORS[cls]
        name:SetTextColor(c.r, c.g, c.b)
    end
end

------------------------------------------------------------
-- Ajustes guardados
------------------------------------------------------------
local function SetPreset(which)
    db.positionPreset = which
    if which == "original" then
        db.point, db.relPoint, db.x, db.y = "TOPLEFT", "TOPLEFT", 18, -18
    elseif which == "center" then
        db.point, db.relPoint, db.x, db.y = "CENTER", "CENTER", -270, -150
    end
end

local function ApplyPosition()
    f:ClearAllPoints()
    f:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

local function LoadSettings()
    BorderPlatesDB = BorderPlatesDB or {}
    db = BorderPlatesDB
    for k, v in pairs(defaults) do
        if db[k] == nil then db[k] = v end
    end
    if not db.positionMigrated032 then
        if db.point == "CENTER" and db.relPoint == "CENTER" and db.x == -270 and db.y == -150 then
            SetPreset("original")
        end
        db.positionMigrated032 = true
    end
    ApplyPosition()
    ApplyModel()
    HideBlizzardPlayerFrame()
    Update()
end

------------------------------------------------------------
-- Eventos
------------------------------------------------------------
local events = CreateFrame("Frame")
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP",
    "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_MANA", "UNIT_RAGE", "UNIT_FOCUS", "UNIT_ENERGY", "UNIT_RUNIC_POWER",
    "UNIT_MAXMANA", "UNIT_MAXRAGE", "UNIT_MAXFOCUS", "UNIT_MAXENERGY", "UNIT_MAXRUNIC_POWER",
    "UNIT_POWER", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "UNIT_NAME_UPDATE", "UNIT_MODEL_CHANGED", "UNIT_PORTRAIT_UPDATE",
    "PLAYER_EQUIPMENT_CHANGED",
}) do events:RegisterEvent(event) end

events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "BorderPlates" then LoadSettings() end
        return
    end
    if not db then return end

    HideBlizzardPlayerFrame()

    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_EQUIPMENT_CHANGED" then
        ApplyModel()
        Update()
    elseif event == "UNIT_MODEL_CHANGED" or event == "UNIT_PORTRAIT_UPDATE" then
        if arg1 == "player" then ApplyModel() end
    elseif event == "PLAYER_LEVEL_UP" or arg1 == "player" then
        Update()
    end
end)

f:SetScript("OnShow", function() 
    if db then 
        ApplyModel() 
        HideBlizzardPlayerFrame()
    end 
end)

------------------------------------------------------------
-- Comandos
------------------------------------------------------------
local function Help()
    BPMessage("1.0.0 cargado.")
    BPMessage("/bp location original | center")
    BPMessage("/bp show | hide | reset | lock | unlock")
    BPMessage("/bp text num | pct | both")
    BPMessage("/bp zoom 0 a 1")
    BPMessage("/bp pos x y z")
    BPMessage("/bp raidtest (activar/desactivar banda simulada)")
end

SLASH_BORDERPLATES1 = "/bp"
SlashCmdList["BORDERPLATES"] = function(msg)
    if not db then return end
    msg = string.lower(msg or "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")

    if cmd == "raidtest" then
        if BorderPlatesRaidToggleTest then BorderPlatesRaidToggleTest() end
    elseif cmd == "hide" then
        f:Hide()
        BPMessage("marco ocultado. Usa /bp show para mostrarlo.")
    elseif cmd == "show" then
        f:Show()
        ApplyModel()
        BPMessage("marco visible.")
    elseif cmd == "location" then
        if rest == "original" or rest == "center" then
            if InCombatLockdown() then
                BPMessage("No se pueden cambiar las posiciones durante el combate.")
                return
            end
            SetPreset(rest)
            ApplyPosition()
            if BorderPlatesTargetSetPreset then BorderPlatesTargetSetPreset(rest) end
            BPMessage("ubicacion de ambos marcos: " .. rest)
        else
            BPMessage("usa /bp location original o /bp location center")
        end
    elseif cmd == "reset" then
        if InCombatLockdown() then
            BPMessage("No se pueden cambiar las posiciones durante el combate.")
            return
        end
        SetPreset("original")
        db.zoom, db.px, db.py, db.pz = defaults.zoom, defaults.px, defaults.py, defaults.pz
        ApplyPosition()
        if BorderPlatesTargetSetPreset then BorderPlatesTargetSetPreset("original") end
        ApplyModel()
        BPMessage("posición de ambos marcos y retrato restablecidos.")
    elseif cmd == "lock" then
        db.locked = true
        BPMessage("ambos marcos bloqueados.")
    elseif cmd == "unlock" then
        db.locked = false
        BPMessage("ambos marcos desbloqueados (arrastre independiente).")
    elseif cmd == "text" then
        if rest == "num" or rest == "pct" or rest == "both" then
            db.textMode = rest
            Update()
            BPMessage("textos: " .. rest)
        else
            BPMessage("usa /bp text num, /bp text pct o /bp text both")
        end
    elseif cmd == "zoom" then
        local z = tonumber(rest)
        if z then
            db.zoom = math.max(0, math.min(1, z))
            ApplyModel()
            BPMessage("zoom del retrato: " .. string.format("%.2f", db.zoom))
        else
            BPMessage("usa /bp zoom 0.7 (valores de 0 a 1)")
        end
    elseif cmd == "pos" then
        local x, y, z = rest:match("^(%S+)%s+(%S+)%s+(%S+)$")
        x, y, z = tonumber(x), tonumber(y), tonumber(z)
        if x and y and z then
            db.px, db.py, db.pz = x, y, z
            ApplyModel()
            BPMessage("posición del modelo: " .. x .. ", " .. y .. ", " .. z)
        else
            BPMessage("usa /bp pos 0 0 0 (tres números)")
        end
    else
        Help()
    end
end