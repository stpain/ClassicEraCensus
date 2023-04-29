

local name, addon = ...;
local Database = addon.db;

ClassicEraCensusHelpTipMixin = {};
function ClassicEraCensusHelpTipMixin:SetText(text)
    self.text:SetText(text)
end
function ClassicEraCensusHelpTipMixin:OnShow()

end


ClassicEraCensusSearchResultsListviewItemMixin = {}
function ClassicEraCensusSearchResultsListviewItemMixin:OnLoad()
    
end
function ClassicEraCensusSearchResultsListviewItemMixin:SetDataBinding(binding, height)
    
    self:SetHeight(height)

    self.icon:SetSize(height * 0.6, height * 0.6)

    self.icon:SetTexture(binding.icon)

    self.name:SetText(string.format("%s %s %s %d", binding.name, binding.race, binding.class, binding.level))

    --self.name:SetText(binding.who)


end
function ClassicEraCensusSearchResultsListviewItemMixin:ResetDataBinding()
    
end



ClassicEraCensusBarChartBarMixin = {}
function ClassicEraCensusBarChartBarMixin:SetWidthHeight(w, h)
    self:SetSize(w,h)
    self.iconBackground:SetSize(w,w)
    self.icon:SetSize(w-2,w-2)
    self.bar:SetWidth(w-2)
    self.barHeight = h-w-2
    self.width = w;
    self.height = h;
end

--nasty hack to just hide the icon
function ClassicEraCensusBarChartBarMixin:SetNoIcon()
    self.icon:SetSize(self.width,1)
    local x, y = self:GetSize()
    self.barHeight = y
end

function ClassicEraCensusBarChartBarMixin:SetIcon(icon)
    self.icon:SetAtlas(icon)
end

function ClassicEraCensusBarChartBarMixin:TrimIcon()
    self.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
end

function ClassicEraCensusBarChartBarMixin:SetBarColour(colour)
    self.bar:SetColorTexture(colour.r, colour.g, colour.b, colour.a)
end

function ClassicEraCensusBarChartBarMixin:SetBarValue(val, maxVal)

    if not val then
        val = 0
    end
    if not maxVal then
        maxVal = 0
    end
    local percent, textureHeight;
    if val == 0 and maxVal == 0 then
        percent = 0
        textureHeight = 0
    else
        percent = (val / maxVal) * 100
        textureHeight = (self.barHeight / 100) * percent
    end

    -- self:SetScript("OnEnter", function()
    --     GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    --     GameTooltip:SetText(val)
    --     GameTooltip:Show()
    -- end)
    -- self:SetScript("OnLeave", function()
    --     GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    -- end)

    self.bar:SetHeight(textureHeight)

    self.text:SetText(string.format("%s\n(%s%%)", val, string.format("%.1f",percent)))

    self.text:ClearAllPoints()
    if percent > 77 then
        self.text:SetPoint("TOP", self.bar, "TOP", 0, -4)
    else
        self.text:SetPoint("BOTTOM", self.bar, "TOP", 0, 4)
    end
end

function ClassicEraCensusBarChartBarMixin:ShowValues(bool)
    if bool then
        self.text:Show()
    else
        self.text:Hide()
    end
end

ClassicEraCensusBasicListviewItemMixin = {}
function ClassicEraCensusBasicListviewItemMixin:SetText(text, height)
    self:SetHeight(height)
    self.text:SetText(text)
end


ClassicEraCensusLogListviewItemMixin = {
    types = {
        warning = "|cffc91A15",
        info = "|cff3EA958",
        who = "|cffffd700",
    }
}
function ClassicEraCensusLogListviewItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)

    --hacked
    -- if binding.who then
        
    -- else

    -- end
    self.text:SetText(string.format("%s%s", self.types[binding.type], binding.message))
end
function ClassicEraCensusLogListviewItemMixin:ResetDataBinding()
    
end



ClassicEraCensusZoneListviewItemMixin = {}
function ClassicEraCensusZoneListviewItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)
    self.text:SetText(binding.zone)

    self.zone = binding.zone;

    self:SetScript("OnMouseDown", function()
        local ignored = Database:GetConfig(binding.zone, "ignoredZones")
        Database:SetConfig(binding.zone, not ignored, "ignoredZones")
    end)

    local ignored = Database:GetConfig(binding.zone, "ignoredZones")
    self:UpdateIgnoreState(binding.zone, ignored, "ignoredZones")

    addon:RegisterCallback("Database_OnConfigChanged", self.UpdateIgnoreState, self)
end
function ClassicEraCensusZoneListviewItemMixin:ResetDataBinding()
    
end
function ClassicEraCensusZoneListviewItemMixin:UpdateIgnoreState(key, val, t)
    if t == "ignoredZones" and key == self.zone then
        if val == true then
            self.text:SetText(string.format("%s%s", "|cff666666", self.zone))
        else
            self.text:SetText(string.format("%s%s", "|cffffffff", self.zone))
        end
    end
end


ClassicEraCensusCensusHistoryListviewItemMixin = {}

function ClassicEraCensusCensusHistoryListviewItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)

    if binding.isMerged == true then

        self.text:SetText(string.format("%s %s", CreateAtlasMarkup("poi-workorders", 16, 16), date('%Y-%m-%d %H:%M:%S', binding.timestamp))) --poi-alliance

        self:SetScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("Merge Info", 1,1,1)
            GameTooltip:AddLine(" ")
            for k, v in ipairs(binding.meta) do
                GameTooltip:AddDoubleLine(v.author, date('%Y-%m-%d %H:%M:%S', v.timestamp))
            end
            GameTooltip:Show()
        end)

        self.text:SetTextColor(1,1,1,1)

    else

        self:SetScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("Census Info", 1,1,1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("|cffffffffAuthor", binding.author)
            GameTooltip:AddDoubleLine("|cffffffffCharacters", #binding.characters)
            if binding.customFilters and next(binding.customFilters) then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Custom census") 
                for k, v in pairs(binding.customFilters) do
                    GameTooltip:AddDoubleLine("|cffffffff"..k, v)
                end
            end
            GameTooltip:Show()
        end)

        if binding.faction:lower() == "alliance" then
            self.text:SetText(string.format("%s %s", CreateAtlasMarkup("poi-alliance", 16, 16), date('%Y-%m-%d %H:%M:%S', binding.timestamp)))
            self.text:SetTextColor(21/255, 101/255, 192/255, 1) --21,101,192
        else
            self.text:SetText(string.format("%s %s", CreateAtlasMarkup("poi-horde", 16, 16), date('%Y-%m-%d %H:%M:%S', binding.timestamp)))
            self.text:SetTextColor(212/255, 37/255, 32/255, 1) --212,37,32
        end
    end


    self:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)

    self:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            binding.selected = not binding.selected
            if binding.selected then
                self.background:Show()
            else
                self.background:Hide()
            end
            addon:TriggerEvent("Census_OnMultiSelectChanged", binding, self)

        else

        end
    end)
end

function ClassicEraCensusCensusHistoryListviewItemMixin:ResetDataBinding()
    self.background:Hide()
    self:SetScript("OnEnter", nil)
end




ClassicEraCensusHomeTabGuildsListviewItemMixin = {}
function ClassicEraCensusHomeTabGuildsListviewItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)
    self.text:SetText(string.format("%s\n|cffffd700%d members", binding.name, binding.count))
    self.text:SetFontObject(GameFontNormalSmall)

    self:SetScript("OnMouseDown", function()
        addon:TriggerEvent("Census_OnGuildSelectionChanged", binding.name)
    end)
end

function ClassicEraCensusHomeTabGuildsListviewItemMixin:ResetDataBinding()
    
end