-- Border Plates 1.0.0 - Marco del objetivo. WoW 3.3.5a (Lua 5.1).
-- Modulo independiente: no altera el marco del jugador aprobado en 0.8.4.
local MEDIA = "Interface\\AddOns\\BorderPlates\\Media\\"
local SCALE = 0.35
local W, H = 512 * SCALE, 128 * SCALE
local BAR_H = 32 * SCALE
local HEAD = 40 * SCALE
local SHIFT = W * 22 / (512 + 22)
local BAR_W = W - SHIFT
local db

local function Message(t)
    DEFAULT_CHAT_FRAME:AddMessage("|cffaa80ffBorder Plates objetivo:|r " .. t)
end
local function Format(cur, max)
    cur, max = cur or 0, max or 0
    local pct = max > 0 and math.floor(cur / max * 100 + .5) or 0
    local mode = BorderPlatesDB and BorderPlatesDB.textMode or "both"
    if mode == "num" then return cur .. " / " .. max end
    if mode == "pct" then return pct .. "%" end
    return cur .. " / " .. max .. " (" .. pct .. "%)"
end
local function PowerColor(t)
    if t == 0 then return .12,.5,1 end
    if t == 1 then return 1,.12,.12 end
    if t == 2 then return 1,.5,.25 end
    if t == 3 then return 1,.94,.12 end
    if t == 6 then return .2,.8,1 end
    return .62,.42,.88
end
local f = CreateFrame("Button", "BorderPlatesTargetFrame", UIParent, "SecureUnitButtonTemplate")
f:SetWidth(W)
f:SetHeight(HEAD + H + 4 + BAR_H * 2)
f:SetFrameStrata("MEDIUM")
f:SetClampedToScreen(true)
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 260, -18)
f:RegisterForClicks("AnyUp")
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetAttribute("unit", "target")
f:SetAttribute("type1", "target")
-- En algunos clientes 3.3.5a la accion segura "menu" no abre el desplegable.
-- El boton izquierdo conserva su accion segura, y el derecho usa el menu
 -- nativo de TargetFrame mediante un controlador explicito.
f:SetAttribute("type2", nil)
f:HookScript("OnClick", function(self, button)
    if button ~= "RightButton" or not UnitExists("target") then return end
    if not (TargetFrameDropDown and ToggleDropDownMenu) then
        Message("No se encontro el menu de objetivo de Blizzard.")
        return
    end
    TargetFrameDropDown.unit = "target"
    TargetFrameDropDown.name = UnitName("target")
    ToggleDropDownMenu(1, nil, TargetFrameDropDown, "cursor", 0, 0)
end)
-- La placa y el retrato no interceptan los clics del boton principal.
f:Hide()


-- Posicion del objetivo independiente de la del jugador, pero con presets conjuntos.
local function ApplyTargetPosition()
    if not db then return end
    f:ClearAllPoints()
    f:SetPoint(db.targetPoint or "TOPLEFT", UIParent,
        db.targetRelPoint or "TOPLEFT", db.targetX or 260, db.targetY or -18)
end

function BorderPlatesTargetSetPreset(which)
    db = BorderPlatesDB or db
    if not db then return end
    if InCombatLockdown() then
        Message("No se pueden mover marcos protegidos durante el combate.")
        return
    end
    if which == "center" then
        db.targetPoint, db.targetRelPoint, db.targetX, db.targetY = "CENTER", "CENTER", 270, -150
    elseif which == "original" then
        db.targetPoint, db.targetRelPoint, db.targetX, db.targetY = "TOPLEFT", "TOPLEFT", 260, -18
    end
    ApplyTargetPosition()
end

f:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    if db and not db.locked then self:StartMoving() end
end)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not db or InCombatLockdown() then return end
    local point, _, relPoint, x, y = self:GetPoint()
    db.targetPoint, db.targetRelPoint, db.targetX, db.targetY = point, relPoint, x, y
end)

-- Ocultar el objetivo original; no se modifica la interfaz original en disco.
local function HideBlizzardTarget()
    if TargetFrame then
        TargetFrame:UnregisterAllEvents()
        TargetFrame:Hide()
    end
end

local plate = CreateFrame("Frame", nil, f)
plate:SetSize(W, H)
plate:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -HEAD)
plate:SetFrameLevel(f:GetFrameLevel()+1)
plate:EnableMouse(false)
local plateTex=plate:CreateTexture(nil,"BACKGROUND")
plateTex:SetTexture(MEDIA.."plate")
plateTex:SetAllPoints(plate)
plateTex:SetTexCoord(1,0,0,1)

local model=CreateFrame("PlayerModel",nil,f)
model:SetSize(104*SCALE/.625,112*SCALE/.625)
model:SetPoint("BOTTOMRIGHT",plate,"BOTTOMRIGHT",-6*SCALE/.625,6*SCALE/.625)
model:SetFrameLevel(f:GetFrameLevel()+4)
model:EnableMouse(false)
local front=CreateFrame("Frame",nil,f)
front:SetSize(96*SCALE/.625,12*SCALE/.625)
front:SetPoint("BOTTOMRIGHT",plate,"BOTTOMRIGHT",-4*SCALE/.625,2*SCALE/.625)
front:SetFrameLevel(f:GetFrameLevel()+5)
front:EnableMouse(false)
local frontTex=front:CreateTexture(nil,"ARTWORK")
frontTex:SetTexture(MEDIA.."plate_front")
frontTex:SetAllPoints(front)
frontTex:SetTexCoord(1,0,0,1)

local info=CreateFrame("Frame",nil,f)
info:SetAllPoints(plate)
info:SetFrameLevel(f:GetFrameLevel()+6)
info:EnableMouse(false)
local name=info:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
name:SetPoint("TOPRIGHT",info,"TOPRIGHT",-125*SCALE/.625,-10*SCALE/.625)
name:SetWidth(130*SCALE/.625)
name:SetJustifyH("RIGHT")
name:SetHeight(19*SCALE/.625)
name:SetJustifyV("TOP")
-- Nombre siempre en una linea: medir a ancho libre y ajustar fuente hasta encajar.
-- Se restaura el ancho de la zona de texto antes de dibujarlo.
local NAME_FONT = "Fonts\\FRIZQT__.TTF"
local NAME_MAX_SIZE, NAME_MIN_SIZE = 14, 5
local NAME_WIDTH = 130*SCALE/.625
local function UpdateTargetName(value)
    value = value or "Objetivo"
    name:SetWidth(1000)
    name:SetText(value)
    local size = NAME_MAX_SIZE
    while size > NAME_MIN_SIZE do
        name:SetFont(NAME_FONT,size,"OUTLINE")
        if name:GetStringWidth() <= NAME_WIDTH - 2 then break end
        size = size - .5
    end
    name:SetFont(NAME_FONT,size,"OUTLINE")
    name:SetWidth(NAME_WIDTH)
    name:SetText(value)
end
local level=info:CreateFontString(nil,"OVERLAY","GameFontNormal")
level:SetPoint("TOPRIGHT",info,"TOPRIGHT",-125*SCALE/.625,-46*SCALE/.625)
level:SetJustifyH("RIGHT")

-- Insignia de clase circular para jugadores (recorte por tiras, compatible 3.3.5a).
local iconStrips={}
local iconSize=28*SCALE/.625
local iconCX=W-281*SCALE/.625
local iconCY=-40*SCALE/.625
for i=0,27 do
    local top,bottom=i/28,(i+1)/28
    local mid=(top+bottom)/2
    local dx=math.sqrt(math.max(0,1-(2*mid-1)^2))*.5
    local l,r=.5-dx,.5+dx
    local strip=info:CreateTexture(nil,"OVERLAY")
    strip:SetSize(iconSize*(r-l),iconSize/28+.02)
    strip:SetPoint("TOPLEFT",info,"TOPLEFT",iconCX-iconSize/2+iconSize*l,iconCY+iconSize/2-iconSize*top)
    strip:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    iconStrips[#iconStrips+1]={tex=strip,l=l,r=r,top=top,bottom=bottom}
end
local function UpdateClassIcon()
    local _,class=UnitClass("target")
    local c=UnitIsPlayer("target") and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    for _,v in ipairs(iconStrips) do
        if c then
            v.tex:SetTexCoord(c[1]+(c[2]-c[1])*v.l,c[1]+(c[2]-c[1])*v.r,
                              c[3]+(c[4]-c[3])*v.top,c[3]+(c[4]-c[3])*v.bottom)
            v.tex:Show()
        else v.tex:Hide() end
    end
end

-- Barras espejadas: la de vida crece desde la derecha hacia la izquierda.
-- La inferior se desplaza hacia la derecha para mantener el romboide invertido.
local function MakeBar(borderFile,winFile)
    local bar=CreateFrame("Frame",nil,f)
    bar:SetSize(BAR_W,BAR_H)
    bar:SetFrameLevel(f:GetFrameLevel()+1)
    local bg=bar:CreateTexture(nil,"BACKGROUND")
    bg:SetTexture(MEDIA..winFile)
    bg:SetVertexColor(.04,.025,.06,1)
    bg:SetAllPoints(bar)
    bg:SetTexCoord(1,0,0,1)
    local fill=bar:CreateTexture(nil,"BORDER")
    fill:SetTexture(MEDIA..winFile)
    fill:SetPoint("TOPRIGHT",bar,"TOPRIGHT",0,0)
    fill:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",0,0)
    bar.fill=fill
    local border=bar:CreateTexture(nil,"ARTWORK")
    border:SetTexture(MEDIA..borderFile)
    border:SetAllPoints(bar)
    border:SetTexCoord(1,0,0,1)
    bar.border=border
    local txt=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    txt:SetPoint("CENTER",bar,"CENTER",0,0)
    bar.text=txt
    return bar
end
local health=MakeBar("bar_health","win_health")
health:SetPoint("TOPLEFT",plate,"BOTTOMLEFT",0,-4)
local power=MakeBar("bar_power","win_power")
power:SetPoint("TOPLEFT",health,"BOTTOMLEFT",SHIFT,0)
health.fill:SetVertexColor(.12,.82,.22,1)
local function SetBar(bar,value,max)
    local pct=max and max>0 and math.max(0,math.min(1,(value or 0)/max)) or 0
    local frac=(10+(512-18)*pct)/512
    bar.fill:SetWidth(math.max(.001,bar:GetWidth()*frac))
    bar.fill:SetTexCoord(frac,0,0,1)
end

-- Medallones ornamentados exclusivos de Border Plates (no pixel-art).
-- Se superponen al circulo de clase, sin invadir nombre ni barras.
local crownBadges={}
for _,rank in ipairs({"rare","elite","boss"}) do
    local tex=info:CreateTexture(nil,"OVERLAY")
    tex:SetTexture(MEDIA.."crown_"..rank)
    tex:SetSize(iconSize*1.48,iconSize*1.48)
    -- iconCY ya es negativo: el centro del medallon esta DEBAJO del TOPLEFT.
    tex:SetPoint("CENTER",info,"TOPLEFT",iconCX,iconCY)
    tex:Hide()
    crownBadges[rank]=tex
end
-- El brillo del jefe es una textura transparente que sigue el CONTORNO,
-- no un rectangulo semitransparente sobre el interior de la placa.
-- Capa independiente por encima de la placa: la textura no queda tapada por info.
local glowLayer=CreateFrame("Frame",nil,f)
glowLayer:SetAllPoints(plate)
glowLayer:SetFrameLevel(f:GetFrameLevel()+2)
glowLayer:EnableMouse(false)
local glow=glowLayer:CreateTexture(nil,"OVERLAY")
glow:SetTexture(MEDIA.."boss_border_glow")
glow:SetPoint("TOPLEFT",plate,"TOPLEFT",-3,3)
glow:SetPoint("BOTTOMRIGHT",plate,"BOTTOMRIGHT",3,-3)
glow:SetTexCoord(1,0,0,1)
glow:Hide()
local pulse=0
local currentRank=nil
local function UpdateRank()
    local classification=UnitClassification("target")
    local lvl=UnitLevel("target")
    local rank
    if classification=="worldboss" or lvl==-1 then rank="boss"
    elseif classification=="rare" or classification=="rareelite" then rank="rare"
    elseif classification=="elite" then rank="elite" end
    currentRank=rank
    for key,tex in pairs(crownBadges) do
        if key==rank then tex:Show() else tex:Hide() end
    end
    -- No iluminar placas normales, raras ni elites.
    if rank=="rare" then plateTex:SetTexture(MEDIA.."plate_rare")
    elseif rank=="elite" then plateTex:SetTexture(MEDIA.."plate_elite")
    elseif rank=="boss" then plateTex:SetTexture(MEDIA.."plate_boss")
    else plateTex:SetTexture(MEDIA.."plate") end
    plateTex:SetVertexColor(1,1,1,1)
    if rank=="boss" then glow:Show() else glow:Hide() end
end
f:SetScript("OnUpdate",function(self,elapsed)
    if currentRank=="boss" and glow:IsShown() then
        pulse=pulse+elapsed*2.0
        glow:SetAlpha(.72+.28*(.5+.5*math.sin(pulse)))
    end
end)
local function UpdateModel()
    if not UnitExists("target") then return end
    model:SetUnit("target")
    if model.SetCamera then model:SetCamera(0) end
    if model.SetPortraitZoom then model:SetPortraitZoom(.7) end
end
local function Update()
    if not UnitExists("target") then f:Hide();return end
    f:Show()
    local hp,hpmax=UnitHealth("target"),UnitHealthMax("target")
    SetBar(health,hp,hpmax)
    health.text:SetText(Format(hp,hpmax))
    local typ=UnitPowerType("target")
    local p,pmax=UnitPower("target"),UnitPowerMax("target")
    local r,g,b=PowerColor(typ)
    power.fill:SetVertexColor(r,g,b,1)
    SetBar(power,p,pmax)
    power.text:SetText(Format(p,pmax))
    UpdateTargetName(UnitName("target"))
    local lvl=UnitLevel("target")
    level:SetText(lvl==-1 and "Nivel ??" or "Nivel "..tostring(lvl or "?"))
    name:SetTextColor(1,.82,.3)
    if UnitIsPlayer("target") then
        local _,class=UnitClass("target")
        local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then name:SetTextColor(c.r,c.g,c.b) end
    end
    UpdateClassIcon()
    UpdateRank()
end
local e=CreateFrame("Frame")
for _,ev in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED",
    "UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_MANA","UNIT_RAGE","UNIT_FOCUS",
    "UNIT_ENERGY","UNIT_RUNIC_POWER","UNIT_POWER","UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_MODEL_CHANGED","UNIT_PORTRAIT_UPDATE"}) do
    e:RegisterEvent(ev)
end
e:SetScript("OnEvent",function(self,ev,unit)
    if ev=="PLAYER_LOGIN" then
        db=BorderPlatesDB or {}
        -- Migrar el preset original anterior, que estaba anclado al minimapa.
        if db.targetPoint == "TOPRIGHT" and db.targetRelPoint == "TOPRIGHT"
            and (db.targetX == -18 or db.targetX == nil) then
            db.targetPoint, db.targetRelPoint, db.targetX, db.targetY = "TOPLEFT", "TOPLEFT", 260, -18
        end
        if not db.targetPoint then
            BorderPlatesTargetSetPreset(db.positionPreset == "center" and "center" or "original")
        else
            ApplyTargetPosition()
        end
        HideBlizzardTarget()
        Update()
    elseif ev=="PLAYER_TARGET_CHANGED" or ev=="PLAYER_ENTERING_WORLD" then
        HideBlizzardTarget()
        Update()
        UpdateModel()
    elseif unit=="target" then
        Update()
        if ev=="UNIT_MODEL_CHANGED" or ev=="UNIT_PORTRAIT_UPDATE" then UpdateModel() end
    end
end)
-- Marco original del objetivo oculto. Para recuperarlo, desactiva Border Plates y recarga la interfaz.
