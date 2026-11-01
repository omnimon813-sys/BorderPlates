-- BorderPlates Raid - marcos reales raid1..raid25 (WoW 3.3.5a)
-- Ajuste visual: encabezado de nombre/nivel separado de las barras.
-- Reconstruccion: no depende de hijos generados por SecureRaidGroupHeaderTemplate.
-- Botones protegidos precreados, visibilidad gestionada por SecureStateDriver.
local addon=CreateFrame('Frame')
local holders, buttons, testButtons={}, {}, {}
local db, testing, locked=nil,false,false
local W,H,GAP=76,34,2
local function msg(s) DEFAULT_CHAT_FRAME:AddMessage('|cffaa80ffBorderPlates Raid:|r '..s) end
local function isCombat() return InCombatLockdown() end
local function visual(b)
    if b.bpVisual then return end
    b.bpVisual = true
    b:SetWidth(W); b:SetHeight(H)
    b:RegisterForClicks('AnyUp')
    b:SetAttribute('type1','target')
    b:SetAttribute('type2','menu')
    local bg=b:CreateTexture(nil,'BACKGROUND'); bg:SetAllPoints(b); bg:SetTexture(.16,.12,.24,.94)
    local border=b:CreateTexture(nil,'BORDER'); border:SetAllPoints(b); border:SetTexture(.45,.31,.65,.65)
    local inner=b:CreateTexture(nil,'ARTWORK'); inner:SetPoint('TOPLEFT',b,1,-1); inner:SetPoint('BOTTOMRIGHT',b,-1,1); inner:SetTexture(.08,.07,.13,.95)
    local name=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); name:SetPoint('TOPLEFT',b,3,-3); name:SetWidth(56); name:SetHeight(9); name:SetJustifyH('LEFT'); name:SetFont('Fonts\\FRIZQT__.TTF',7,'OUTLINE')
    local lvl=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall'); lvl:SetPoint('TOPRIGHT',b,-2,-3); lvl:SetFont('Fonts\\FRIZQT__.TTF',7,'OUTLINE')
    local function bar(y,height)
        local x=CreateFrame('StatusBar',nil,b); x:EnableMouse(false)
        x:SetPoint('TOPLEFT',b,3,y); x:SetWidth(W-6); x:SetHeight(height)
        x:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
        local t=x:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); t:SetPoint('CENTER'); t:SetFont('Fonts\\FRIZQT__.TTF',6,'OUTLINE')
        return x,t
    end
    b.bpName=name; b.bpLevel=lvl; b.bpHP,b.bpHPText=bar(-15,8); b.bpPower,b.bpPowerText=bar(-25,6)
    b.menu=function(self)
        local unit=SecureButton_GetUnit and SecureButton_GetUnit(self) or self:GetAttribute('unit')
        if not unit or not UnitExists(unit) or not FriendsDropDown then return end
        FriendsDropDown.unit=unit; FriendsDropDown.name=UnitName(unit)
        FriendsDropDown.id=tonumber(string.match(unit,'(%d+)'))
        FriendsDropDown.initialize=RaidFrameDropDown_Initialize
        ToggleDropDownMenu(1,nil,FriendsDropDown,self:GetName(),0,0)
    end
end
local function update(b)
    if not b.bpVisual then return end
    local unit=SecureButton_GetUnit and SecureButton_GetUnit(b) or b:GetAttribute('unit')
    if not unit or not UnitExists(unit) then return end
    b.bpName:SetText(UnitName(unit) or '')
    b.bpLevel:SetText(UnitLevel(unit) or '')
    local hp,mhp=UnitHealth(unit) or 0,UnitHealthMax(unit) or 1
    local p,mp=UnitPower(unit) or 0,UnitPowerMax(unit) or 1
    b.bpHP:SetMinMaxValues(0,math.max(1,mhp)); b.bpHP:SetValue(hp); b.bpHP:SetStatusBarColor(.13,.79,.27)
    b.bpHPText:SetText(hp..'/'..mhp)
    b.bpPower:SetMinMaxValues(0,math.max(1,mp)); b.bpPower:SetValue(p)
    local kind=UnitPowerType(unit)
    if kind==1 then b.bpPower:SetStatusBarColor(1,.15,.15)
    elseif kind==3 then b.bpPower:SetStatusBarColor(1,.9,.12)
    elseif kind==6 then b.bpPower:SetStatusBarColor(.25,.75,1)
    else b.bpPower:SetStatusBarColor(.15,.5,1) end
    b.bpPowerText:SetText(mp>0 and (p..'/'..mp) or '')
end

local function position(g)
    local c=holders[g]; c:ClearAllPoints()
    local p=db and db.raidPos and db.raidPos[g]
    if p then c:SetPoint(p.point or 'TOPLEFT',UIParent,p.relPoint or 'TOPLEFT',p.x or 0,p.y or 0)
    else c:SetPoint('TOPLEFT',UIParent,'TOPLEFT',18+(g-1)*79,-175) end
end
for g=1,5 do
    local c=CreateFrame('Frame','BorderPlatesRaidColumn'..g,UIParent)
    c:SetWidth(W); c:SetHeight(5*(H+GAP)); c:SetMovable(true); c:SetClampedToScreen(true)
    c:SetPoint('TOPLEFT',UIParent,'TOPLEFT',18+(g-1)*79,-175)
    holders[g]=c
    local tab=CreateFrame('Frame',nil,c); tab:SetWidth(W); tab:SetHeight(11)
    tab:SetPoint('BOTTOMLEFT',c,'TOPLEFT',0,2); tab:SetFrameStrata('HIGH')
    tab:EnableMouse(true); tab:RegisterForDrag('LeftButton')
    local t=tab:CreateTexture(nil,'BACKGROUND'); t:SetAllPoints(tab); t:SetTexture(.35,.20,.60,.92)
    local label=tab:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); label:SetPoint('CENTER'); label:SetText('Grupo '..g)
    tab:SetScript('OnDragStart',function() if not isCombat() and not locked then c:StartMoving() end end)
    tab:SetScript('OnDragStop',function()
        c:StopMovingOrSizing(); if not db then return end
        db.raidPos=db.raidPos or {}; local a,_,r,x,y=c:GetPoint()
        db.raidPos[g]={point=a,relPoint=r,x=x,y=y}
    end)
    c.tab=tab; tab:Hide()
end
-- Los 25 botones se crean al cargar el addon, nunca durante el combate.
-- Se asigna raidN directamente; no se necesitan atributos childN.
for i=1,25 do
    local b=CreateFrame('Button','BorderPlatesRaidUnit'..i,UIParent,'SecureUnitButtonTemplate')
    b:SetAttribute('unit','raid'..i)
    visual(b)
    b:Hide()
    buttons[i]=b
    local g=math.floor((i-1)/5)+1
    local mock=CreateFrame('Button','BorderPlatesRaidTest'..i,holders[g],'SecureUnitButtonTemplate')
    mock:SetAttribute('unit','player'); visual(mock); mock:Hide()
    mock:SetPoint('TOPLEFT',holders[g],'TOPLEFT',0,-((i-1)%5)*(H+GAP))
    testButtons[i]=mock
end
local function layout()
    if isCombat() then return end
    local groups={0,0,0,0,0}
    local count=GetNumRaidMembers() or 0
    for i=1,25 do
        local b=buttons[i]
        local _,_,g=GetRaidRosterInfo(i)
        if i<=count and g and g>=1 and g<=5 then
            groups[g]=groups[g]+1
            b:ClearAllPoints()
            b:SetPoint('TOPLEFT',holders[g],'TOPLEFT',0,-(groups[g]-1)*(H+GAP))
            if not testing then b:Show() else b:Hide() end
        else
            b:Hide()
        end
    end
    for g=1,5 do
        if testing or (groups[g]>0 and not locked) then holders[g].tab:Show() else holders[g].tab:Hide() end
    end
end
local function toggle()
    if isCombat() then msg('No se puede cambiar la prueba en combate.'); return end
    testing=not testing
    for i,b in ipairs(testButtons) do
        if testing then
            b.bpName:SetText(i==1 and (UnitName('player') or 'Jugador') or ('Jugador '..i))
            b.bpLevel:SetText('80'); b.bpHP:SetMinMaxValues(0,20000); b.bpHP:SetValue(14000)
            b.bpHPText:SetText('14000/20000'); b.bpPower:SetMinMaxValues(0,10000)
            b.bpPower:SetValue(7500); b.bpPowerText:SetText('7500/10000'); b:Show()
        else b:Hide() end
    end
    layout(); msg(testing and 'Prueba activada.' or 'Prueba desactivada.')
end
BorderPlatesRaidToggleTest=toggle
BorderPlatesRaidSetLocked=function(v) locked=not not v; if db then db.raidLocked=locked end; layout() end
BorderPlatesRaidReset=function()
    if isCombat() then return end
    if db then db.raidPos=nil end
    for g=1,5 do position(g) end
end
SLASH_BPRAID1='/bpraid'
SlashCmdList.BPRAID=function(s)
    s=string.lower(s or '')
    if s=='test' then toggle()
    elseif s=='lock' then BorderPlatesRaidSetLocked(true)
    elseif s=='unlock' then BorderPlatesRaidSetLocked(false)
    elseif s=='reset' then BorderPlatesRaidReset()
    elseif s=='debug' then
        msg('Banda='..(GetNumRaidMembers() or 0)..', prueba='..tostring(testing)..', combate='..tostring(isCombat()))
        for i=1,math.min(25,GetNumRaidMembers() or 0) do
            local _,_,g=GetRaidRosterInfo(i)
            msg('raid'..i..' grupo='..tostring(g)..' existe='..tostring(UnitExists('raid'..i))..' visible='..tostring(buttons[i]:IsShown()))
        end
    else msg('/bpraid test | lock | unlock | reset | debug') end
end
local elapsed=0
addon:SetScript('OnUpdate',function(self,dt)
    elapsed=elapsed+dt; if elapsed<.4 then return end; elapsed=0
    if not testing then
        for i=1,25 do if buttons[i]:IsShown() then update(buttons[i]) end end
    end
end)
for _,e in ipairs({'ADDON_LOADED','PLAYER_ENTERING_WORLD','RAID_ROSTER_UPDATE','PLAYER_REGEN_ENABLED'}) do addon:RegisterEvent(e) end
addon:SetScript('OnEvent',function(self,e,arg)
    if e=='ADDON_LOADED' then
        if arg~='BorderPlates' then return end
        BorderPlatesDB=BorderPlatesDB or {}; db=BorderPlatesDB
        locked=not not db.raidLocked
        for g=1,5 do position(g) end
    end
    if not testing then layout() end
end)
