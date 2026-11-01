-- Border Plates 1.0.0: marcos de grupo con encabezado seguro y aspecto 0.8.4.
-- Compatible con la API de WoW 3.3.5a. No modifica los marcos existentes.
local MEDIA = "Interface\\AddOns\\BorderPlates\\Media\\"
local members = {}
local BUFFS_PER_ROW, MAX_BUFFS = 8, 40
local ICON, ICON_GAP = 17, 2
local WIDTH, HEAD, STEP = 166, 47, 158
local function PowerColor(t)
    if t == 1 then return 1,.15,.15 end
    if t == 2 then return 1,.52,.20 end
    if t == 3 then return 1,.90,.12 end
    if t == 6 then return .25,.75,1 end
    return .15,.50,1
end
local function NewMember(i, f)
    local unit = "party" .. i
    f = f or CreateFrame("Button", "BorderPlatesParty" .. i, UIParent, "SecureUnitButtonTemplate")
    f:SetWidth(WIDTH); f:SetHeight(HEAD)
    f:SetFrameStrata("MEDIUM")
    -- Marco integrado de acero violeta: fondo, doble bisel y separador.
    -- Se ancla al propio boton seguro; no modifica su posicion ni sus eventos.
    local back = f:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints(f)
    back:SetTexture(.16, .095, .24, .98)
    local function Line(layer, x, y, w, h, r, g, b, alpha)
        local t = f:CreateTexture(nil, layer)
        t:SetTexture(r, g, b, alpha or 1)
        t:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
        t:SetWidth(w); t:SetHeight(h)
        return t
    end
    -- Contorno exterior y perfil interior, sin sobresalir del retrato.
    Line("OVERLAY", 0, 0, WIDTH, 2, .72, .62, .86)
    Line("OVERLAY", 0, -HEAD+2, WIDTH, 2, .39, .30, .53)
    Line("OVERLAY", 0, 0, 2, HEAD, .58, .47, .73)
    Line("OVERLAY", WIDTH-2, 0, 2, HEAD, .39, .30, .53)
    Line("OVERLAY", 2, -2, WIDTH-4, 1, .30, .22, .43)
    Line("OVERLAY", 2, -HEAD+3, WIDTH-4, 1, .67, .54, .80)
    Line("OVERLAY", 2, -2, 1, HEAD-4, .28, .20, .40)
    Line("OVERLAY", WIDTH-3, -2, 1, HEAD-4, .65, .51, .77)
    -- Separador metalico entre el retrato y la zona de nombre/barras.
    Line("OVERLAY", 41, -2, 2, HEAD-4, .70, .58, .85)
    Line("OVERLAY", 43, -2, 1, HEAD-4, .24, .17, .35)
    Line("OVERLAY", 44, -2, 1, HEAD-4, .47, .36, .62)
    -- Moldura horizontal que separa el encabezado de las barras.
    Line("OVERLAY", 45, -13, WIDTH-48, 1, .58, .46, .74)
    -- Remaches discretos en las esquinas.
    for _, pt in ipairs({{3,-3},{WIDTH-6,-3},{3,-HEAD+6},{WIDTH-6,-HEAD+6}}) do
        Line("OVERLAY", pt[1], pt[2], 3, 3, .80, .70, .92)
    end
    -- El encabezado controla el anclaje y la visibilidad de los hijos.
    f:RegisterForClicks("AnyUp")
    f:SetAttribute("type1", "target")
    f:SetAttribute("type2", nil)
    f:HookScript("OnClick", function(self, button)
        if button ~= "RightButton" or not UnitExists(unit) then return end
        if PartyMemberFrame1DropDown and ToggleDropDownMenu then
            local dropdown = _G["PartyMemberFrame" .. i .. "DropDown"] or PartyMemberFrame1DropDown
            dropdown.unit = unit
            dropdown.name = UnitName(unit)
            ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
        end
    end)
    local portraitBack = f:CreateTexture(nil,"BACKGROUND")
    portraitBack:SetTexture(MEDIA .. "pet_plate.tga")
    portraitBack:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    portraitBack:SetWidth(39); portraitBack:SetHeight(HEAD-4)
    local portrait = CreateFrame("PlayerModel",nil,f)
    portrait:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2)
    portrait:SetWidth(39); portrait:SetHeight(HEAD-4)
    portrait:EnableMouse(false)
    local name = f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    name:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE")
    name:SetPoint("TOPLEFT",f,"TOPLEFT",47,-1)
    name:SetWidth(92); name:SetJustifyH("LEFT")
    local level = f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    level:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-1)
    local function Bar(y,h)
        local bar = CreateFrame("StatusBar",nil,f)
        bar:SetPoint("TOPLEFT",f,"TOPLEFT",46,y)
        bar:SetWidth(118); bar:SetHeight(h)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        local bg = bar:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints(bar); bg:SetTexture(.09,.06,.14,.95)
        local edge = CreateFrame("Frame",nil,bar)
        edge:SetAllPoints(bar); edge:EnableMouse(false)
        local line = edge:CreateTexture(nil,"OVERLAY")
        line:SetTexture(.55,.43,.70,.95)
        line:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0)
        line:SetPoint("TOPRIGHT",bar,"TOPRIGHT",0,0)
        line:SetHeight(1)
        local txt = bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        txt:SetFont("Fonts\\FRIZQT__.TTF",8,"OUTLINE")
        txt:SetPoint("CENTER",bar,"CENTER",0,0)
        return bar,txt
    end
    local hp,hpt = Bar(-15,13)
    local power,powert = Bar(-30,10)
    local buffs = {}
    for j=1,MAX_BUFFS do
        local icon = CreateFrame("Frame",nil,f)
        icon:SetWidth(ICON);icon:SetHeight(ICON)
        local col=(j-1)%BUFFS_PER_ROW
        local row=math.floor((j-1)/BUFFS_PER_ROW)
        icon:SetPoint("TOPLEFT",f,"BOTTOMLEFT",col*(ICON+ICON_GAP),-3-row*(ICON+ICON_GAP))
        icon:SetFrameStrata("MEDIUM")
        icon:SetFrameLevel(f:GetFrameLevel()+2)
        local tex=icon:CreateTexture(nil,"ARTWORK")
        tex:SetAllPoints(icon)
        icon.tex=tex
        local count=icon:CreateFontString(nil,"OVERLAY","NumberFontNormalSmall")
        count:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",1,-1)
        icon.count=count
        local timer=icon:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        timer:SetFont("Fonts\\FRIZQT__.TTF",7,"OUTLINE")
        timer:SetPoint("BOTTOM",icon,"BOTTOM",0,1)
        icon.timer=timer
        icon:EnableMouse(true)
        icon:SetScript("OnEnter",function(self)
            if not self.buffIndex then return end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetUnitBuff(f:GetAttribute("unit") or unit,self.buffIndex)
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave",function() GameTooltip:Hide() end)
        icon:Hide()
        buffs[j]=icon
    end
    return {frame=f,unit=unit,portrait=portrait,name=name,level=level,hp=hp,hpt=hpt,power=power,powert=powert,buffs=buffs}
end
-- SecureGroupHeaderTemplate genera y distribuye los botones de party.
-- No se reposicionan ni se muestran/ocultan manualmente durante combate.
local partyHeader = CreateFrame("Frame", "BorderPlatesPartyHeader", UIParent, "SecureGroupHeaderTemplate")
partyHeader:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -230)
partyHeader:SetAttribute("showParty", true)
partyHeader:SetAttribute("showRaid", false)
partyHeader:SetAttribute("showSolo", false)
partyHeader:SetAttribute("showPlayer", false)
partyHeader:SetAttribute("sortMethod", "INDEX")
partyHeader:SetAttribute("point", "TOP")
partyHeader:SetAttribute("yOffset", -(STEP - HEAD))
partyHeader:SetAttribute("minWidth", WIDTH)
partyHeader:SetAttribute("minHeight", HEAD)
partyHeader:SetAttribute("template", "SecureUnitButtonTemplate")
local created = 0
partyHeader.initialConfigFunction = function(child)
    created = created + 1
    if created <= 4 then members[created] = NewMember(created, child) end
end
partyHeader:Show()
local function UpdateBuffs(m)
    for j=1,MAX_BUFFS do
        local buffName,rank,texture,count,debuffType,duration,expiration = UnitBuff(m.unit,j)
        local icon=m.buffs[j]
        if buffName and texture then
            icon.tex:SetTexture(texture)
            icon.count:SetText(count and count>1 and count or "")
            icon.expiration=expiration or 0
            icon.duration=duration or 0
            icon.buffIndex=j
            icon:Show()
        else
            icon.buffIndex=nil
            icon:Hide()
        end
    end
end
local function UpdateMember(m)
    if not UnitExists(m.unit) then return end
    local hmax=UnitHealthMax(m.unit) or 0
    local h=UnitHealth(m.unit) or 0
    m.hp:SetMinMaxValues(0,math.max(1,hmax))
    m.hp:SetValue(h)
    m.hp:SetStatusBarColor(.13,.79,.27)
    m.hpt:SetText(math.floor(h) .. " / " .. math.floor(hmax))
    local pmax=UnitPowerMax(m.unit) or 0
    local p=UnitPower(m.unit) or 0
    m.power:SetMinMaxValues(0,math.max(1,pmax))
    m.power:SetValue(p)
    m.power:SetStatusBarColor(PowerColor(UnitPowerType(m.unit)))
    m.powert:SetText(pmax>0 and (math.floor(p) .. " / " .. math.floor(pmax)) or "")
    m.name:SetText(UnitName(m.unit) or "")
    m.level:SetText(tostring(UnitLevel(m.unit) or "?"))
end
-- Ocultar los marcos de grupo originales de Blizzard sin tocar los marcos
-- personalizados ni los controles de grupo del juego.
local function HideBlizzardPartyFrames()
    if InCombatLockdown and InCombatLockdown() then return end
    for i=1,4 do
        local original = _G["PartyMemberFrame" .. i]
        if original then
            original:UnregisterAllEvents()
            original:Hide()
        end
        local pet = _G["PartyMemberFrame" .. i .. "PetFrame"]
        if pet then
            pet:UnregisterAllEvents()
            pet:Hide()
        end
    end
end

-- Usar la camara de retrato en lugar de la vista de cuerpo completo.
-- Reaplicar tras cambios de modelo (transformaciones, monturas, etc.).
local function UpdatePortrait(m)
    if not UnitExists(m.unit) then return end
    m.portrait:SetUnit(m.unit)
    if m.portrait.SetCamera then m.portrait:SetCamera(0) end
    if m.portrait.SetPortraitZoom then m.portrait:SetPortraitZoom(1) end
    if m.portrait.SetPosition then m.portrait:SetPosition(0, 0, 0) end
end

local function UpdateRoster()
    HideBlizzardPartyFrames()
    local inParty=(GetNumPartyMembers and GetNumPartyMembers() or 0)>0
    local inRaid=(GetNumRaidMembers and GetNumRaidMembers() or 0)>0
    for i,m in ipairs(members) do
        m.unit = m.frame:GetAttribute("unit") or m.unit
        local shouldShow=inParty and not inRaid and UnitExists(m.unit)
        if shouldShow then
            UpdateMember(m)
            UpdateBuffs(m)
            UpdatePortrait(m)
        end
    end
end
local event=CreateFrame("Frame")
for _,ev in ipairs({"PLAYER_ENTERING_WORLD","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","PLAYER_REGEN_ENABLED","UNIT_AURA","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_MANA","UNIT_MAXMANA","UNIT_RAGE","UNIT_ENERGY","UNIT_FOCUS","UNIT_RUNIC_POWER","UNIT_DISPLAYPOWER","UNIT_POWER","UNIT_MAXPOWER","UNIT_NAME_UPDATE","UNIT_LEVEL","UNIT_PORTRAIT_UPDATE","UNIT_MODEL_CHANGED"}) do event:RegisterEvent(ev) end
event:SetScript("OnEvent",function(self,ev,unit)
    if ev=="PARTY_MEMBERS_CHANGED" or ev=="PLAYER_ENTERING_WORLD" or ev=="RAID_ROSTER_UPDATE" or ev=="PLAYER_REGEN_ENABLED" then
        UpdateRoster()
        return
    end
    for _,m in ipairs(members) do
        if m.frame:GetAttribute("unit")==unit and UnitExists(unit) then
            m.unit = unit
            if ev=="UNIT_AURA" then UpdateBuffs(m)
            elseif ev=="UNIT_PORTRAIT_UPDATE" or ev=="UNIT_MODEL_CHANGED" then UpdatePortrait(m)
            else UpdateMember(m) end
            break
        end
    end
end)
local elapsed=0
event:SetScript("OnUpdate",function(self,dt)
    elapsed=elapsed+dt
    if elapsed<.5 then return end
    elapsed=0
    local now=GetTime()
    for _,m in ipairs(members) do
        if m.frame:IsShown() then
            for _,icon in ipairs(m.buffs) do
                if icon:IsShown() then
                    local remain=icon.expiration-now
                    if icon.duration>0 and remain>0 then
                        if remain>=60 then icon.timer:SetText(math.ceil(remain/60).."m")
                        else icon.timer:SetText(math.ceil(remain).."s") end
                    else icon.timer:SetText("") end
                end
            end
        end
    end
end)
