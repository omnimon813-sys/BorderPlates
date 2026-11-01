-- Border Plates 1.0.0: marco de mascota. Las tres filas (vida, recurso, nombre) salen
-- directamente del retrato: lado izquierdo recto y una sola diagonal continua a la derecha.
local MEDIA = "Interface\\AddOns\\BorderPlates\\Media\\"
local db

------------------------------------------------------------
-- Geometría. Debe coincidir con las texturas pet_bar_* / pet_win_* (128x16).
-- Un único factor K en ancho y alto: la diagonal conserva la pendiente del jugador.
------------------------------------------------------------
local K = 0.75
local TEX_W, TEX_H = 128, 16
local BAR_W, BAR_H = TEX_W * K, TEX_H * K            -- 96 x 12
local GAP = 1                                        -- separación vertical entre filas
local PORTRAIT = 3 * BAR_H + 2 * GAP                 -- 38: el retrato mide lo mismo que las tres filas juntas
local SLOPE = 16 / 22
local WIN_L, WIN_R = 4, 122                          -- ventana en píxeles de textura (fila superior)
local SW = SLOPE * (14 - 2)                          -- inclinación de la ventana
local STEP = SLOPE * (BAR_H + GAP) / K               -- cuánto se acorta cada fila (px de textura)
local BAR_X = PORTRAIT - 3                           -- las barras se solapan 3 px con el retrato: sin rendija
local W, H = BAR_X + BAR_W, PORTRAIT

local f = CreateFrame("Button", "BorderPlatesPetFrame", UIParent, "SecureUnitButtonTemplate")
f:SetWidth(W)
f:SetHeight(H)
f:SetFrameStrata("MEDIUM")
f:SetFrameLevel(12)
f:EnableMouse(true)
f:RegisterForClicks("AnyUp")
f:SetAttribute("unit", "pet")
f:SetAttribute("type1", "target")
f:SetAttribute("type2", nil)
f:HookScript("OnClick", function(self, button)
    if button ~= "RightButton" or not UnitExists("pet") then return end
    if PetFrameDropDown and ToggleDropDownMenu then
        PetFrameDropDown.unit = "pet"
        PetFrameDropDown.name = UnitName("pet")
        ToggleDropDownMenu(1, nil, PetFrameDropDown, "cursor", 0, 0)
    end
end)
-- La mascota del jugador es una unidad fija (pet), no una lista de mascotas
-- de banda. Su visibilidad se gobierna mediante un controlador seguro.
if RegisterStateDriver then
    RegisterStateDriver(f, "visibility", "[pet] show; hide")
end

local baseLevel = f:GetFrameLevel()

local function Place()
    if InCombatLockdown() then return end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", BorderPlatesPlayerFrame, "BOTTOMLEFT", 10, -9)
    f:SetScale((db and db.petScale) or 1)
    if db then db.petPoint, db.petRelPoint, db.petX, db.petY = nil, nil, nil, nil end
end

-- Placa del retrato (lado derecho recto, para que las barras se unan sin escalón)
local portraitBack = f:CreateTexture(nil, "BACKGROUND")
portraitBack:SetTexture(MEDIA .. "pet_plate.tga")
portraitBack:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
portraitBack:SetWidth(PORTRAIT)
portraitBack:SetHeight(PORTRAIT)

-- Modelo 3D: más alto que la placa, la cabeza sobresale por arriba
local portrait = CreateFrame("PlayerModel", nil, f)
portrait:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 1, -(PORTRAIT - 2))
portrait:SetWidth(PORTRAIT - 4)
portrait:SetHeight(52)
portrait:SetFrameLevel(baseLevel + 3)
portrait:EnableMouse(false)

-- Repisa metálica por delante del modelo
local lipFrame = CreateFrame("Frame", nil, f)
lipFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -(PORTRAIT - 7))
lipFrame:SetWidth(PORTRAIT - 6)
lipFrame:SetHeight(5)
lipFrame:SetFrameLevel(baseLevel + 5)
lipFrame:EnableMouse(false)
local lip = lipFrame:CreateTexture(nil, "ARTWORK")
lip:SetTexture(MEDIA .. "plate_front.tga")
lip:SetAllPoints(lipFrame)

------------------------------------------------------------
-- Filas: fondo, relleno recortado y contorno. `row` = 0, 1, 2 (vida, recurso, nombre).
-- Todas arrancan en el mismo X (pegadas al retrato) y cada una es más corta que la anterior,
-- así sus extremos derechos forman una sola diagonal.
------------------------------------------------------------
local function MakeRow(row, borderName, windowName)
    local b = CreateFrame("Frame", nil, f)
    b:SetPoint("TOPLEFT", f, "TOPLEFT", BAR_X, -row * (BAR_H + GAP))
    b:SetWidth(BAR_W)
    b:SetHeight(BAR_H)
    b:SetFrameLevel(baseLevel + 2)
    b:EnableMouse(false)
    b.winR = WIN_R - row * STEP                       -- borde derecho de la ventana (arriba), en px de textura
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(MEDIA .. windowName)
    bg:SetVertexColor(.04, .025, .06, 1)
    bg:SetAllPoints(b)
    b.bg = bg
    local fill = b:CreateTexture(nil, "BORDER")
    fill:SetTexture(MEDIA .. windowName)
    fill:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    b.fill = fill
    local border = b:CreateTexture(nil, "ARTWORK")
    border:SetTexture(MEDIA .. borderName)
    border:SetAllPoints(b)
    return b
end

local hp = MakeRow(0, "pet_bar_health.tga", "pet_win_health.tga")
local power = MakeRow(1, "pet_bar_power.tga", "pet_win_power.tga")
local nameRow = MakeRow(2, "pet_bar_name.tga", "pet_win_name.tga")
nameRow.bg:SetVertexColor(.16, .10, .26, 1)
nameRow.fill:Hide()

-- Textos de las barras, centrados en el interior real de la ventana (no en el marco entero)
local function BarText(b)
    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    local center = (WIN_L + b.winR - SW / 2) / 2      -- centro de la ventana (px de textura)
    txt:SetPoint("CENTER", b, "LEFT", center * K, 0)
    b.text = txt
end
BarText(hp)
BarText(power)

-- Nombre (izquierda) y nivel (derecha) dentro de la tercera fila
local winRightBottom = (nameRow.winR - SW) * K        -- borde derecho útil de la fila del nombre
local name = nameRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
name:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
name:SetPoint("LEFT", nameRow, "LEFT", WIN_L * K + 3, 0)
name:SetWidth(winRightBottom - (WIN_L * K + 3) - 14)
name:SetHeight(BAR_H)
name:SetJustifyH("LEFT")
local level = nameRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
level:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
level:SetPoint("RIGHT", nameRow, "LEFT", winRightBottom - 3, 0)

------------------------------------------------------------
-- Datos
------------------------------------------------------------
local function Format(cur, max)
    local mode = db and db.textMode or "both"
    local pct = max > 0 and math.floor(cur / max * 100 + .5) or 0
    if mode == "pct" then return pct .. "%" end
    if mode == "num" then return cur .. "/" .. max end
    return pct .. "%"   -- compacto para que quepa en la barra pequeña
end

local function UpdateBar(b, cur, max, r, g, bl)
    local pct = max > 0 and math.max(0, math.min(1, cur / max)) or 0
    local frac = (WIN_L + (b.winR - WIN_L) * pct) / TEX_W
    b.fill:SetWidth(math.max(.001, BAR_W * frac))
    b.fill:SetTexCoord(0, frac, 0, 1)
    b.fill:SetVertexColor(r, g, bl, 1)
    b.text:SetText(Format(cur, max))
end

local function HideDefault()
    if PetFrame then
        PetFrame:UnregisterAllEvents()
        if not InCombatLockdown() then PetFrame:Hide() end
    end
end

local function Refresh()
    if not db then return end
    HideDefault()
    if not UnitExists("pet") then
            return
    end
    UpdateBar(hp, UnitHealth("pet") or 0, UnitHealthMax("pet") or 0, .12, .82, .22)
    local t = UnitPowerType("pet")
    local r, g, b = .12, .5, 1
    if t == 1 then r, g, b = 1, .12, .12
    elseif t == 2 then r, g, b = 1, .5, .25
    elseif t == 3 then r, g, b = 1, .94, .12
    elseif t == 6 then r, g, b = .2, .8, 1 end
    UpdateBar(power, UnitPower("pet") or 0, UnitPowerMax("pet") or 0, r, g, b)
    name:SetText(UnitName("pet") or "Mascota")
    level:SetText(tostring(UnitLevel("pet") or "?"))
end

local function RefreshModel()
    if not UnitExists("pet") then return end
    portrait:SetUnit("pet")
    if portrait.SetCamera then portrait:SetCamera(0) end
    if portrait.SetPortraitZoom then portrait:SetPortraitZoom((db and db.petZoom) or 1.18) end
    if portrait.SetPosition then portrait:SetPosition(0, 0, 0) end
end

------------------------------------------------------------
-- Eventos (en 3.3.5a el recurso se anuncia con UNIT_MANA / UNIT_FOCUS / UNIT_ENERGY /
-- UNIT_RAGE / UNIT_RUNIC_POWER; UNIT_POWER no existe, por eso se registran ambos juegos)
------------------------------------------------------------
local events = CreateFrame("Frame")
for _, ev in ipairs({
    "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "UNIT_PET", "PLAYER_REGEN_ENABLED",
    "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_MANA", "UNIT_FOCUS", "UNIT_ENERGY", "UNIT_RAGE", "UNIT_RUNIC_POWER",
    "UNIT_MAXMANA", "UNIT_MAXFOCUS", "UNIT_MAXENERGY", "UNIT_MAXRAGE", "UNIT_MAXRUNIC_POWER",
    "UNIT_POWER", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_MODEL_CHANGED", "UNIT_PORTRAIT_UPDATE",
}) do events:RegisterEvent(ev) end

events:SetScript("OnEvent", function(self, event, unit)
    if event == "ADDON_LOADED" then
        if unit == "BorderPlates" then
            BorderPlatesDB = BorderPlatesDB or {}
            db = BorderPlatesDB
            Place(); RefreshModel(); Refresh()
        end
        return
    end
    if not db then return end
    if event == "PLAYER_REGEN_ENABLED" then Place() end
    if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_PET" or event == "UNIT_MODEL_CHANGED" or event == "UNIT_PORTRAIT_UPDATE" then
        if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_PET" or unit == "pet" then RefreshModel() end
    end
    if not unit or unit == "pet" or unit == "player" then Refresh() end
end)

------------------------------------------------------------
-- Comandos: /bppet scale 0.8   /bppet zoom 1.0   /bppet reset
------------------------------------------------------------
SLASH_BORDERPLATESPET1 = "/bppet"
SlashCmdList["BORDERPLATESPET"] = function(msg)
    if not db then return end
    local cmd, rest = string.lower(msg or ""):match("^(%S*)%s*(.-)$")
    local say = function(t) DEFAULT_CHAT_FRAME:AddMessage("|cffaa80ffBorder Plates (mascota):|r " .. t) end
    if cmd == "scale" and tonumber(rest) then
        db.petScale = math.max(0.5, math.min(1.5, tonumber(rest)))
        Place()
        say("tamaño " .. string.format("%.2f", db.petScale))
    elseif cmd == "zoom" and tonumber(rest) then
        db.petZoom = math.max(0, math.min(1.5, tonumber(rest)))
        RefreshModel()
        say("zoom del retrato " .. string.format("%.2f", db.petZoom))
    elseif cmd == "reset" then
        db.petScale, db.petZoom = nil, nil
        Place(); RefreshModel()
        say("tamaño y zoom restablecidos.")
    else
        say("/bppet scale 0.5-1.5   /bppet zoom 0-1.5   /bppet reset")
    end
end
