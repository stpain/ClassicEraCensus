

local name, addon = ...;


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
    self.barHeight = h-w-2;
    self.width = w;
    self.height = h;
end

--nasty hack to just hide the icon
function ClassicEraCensusBarChartBarMixin:SetNoIcon()
    self.icon:SetSize(self.width,1)
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


ClassicEraCensusCensusHistoryListviewItemMixin = {}

function ClassicEraCensusCensusHistoryListviewItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)

    self.text:SetText(date('%Y-%m-%d %H:%M:%S', binding.timestamp))

    if binding.merged == true then
        self.text:SetTextColor(39/255,183/255,222/255,1)

        self:SetScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("Merge Info", 1,1,1)
            GameTooltip:AddLine(" ")
            for k, v in ipairs(binding.meta) do
                GameTooltip:AddDoubleLine(v.author, date('%Y-%m-%d %H:%M:%S', v.timestamp))
            end
            GameTooltip:Show()
        end)
    else
        self.text:SetTextColor(1,1,1,1)
    end

    self:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)

    self:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            --if IsControlKeyDown() then
                binding.selected = not binding.selected
                if binding.selected then
                    self.background:Show()
                else
                    self.background:Hide()
                end
                addon:TriggerEvent("Census_OnMultiSelectChanged", binding)
            -- else
            --     addon:TriggerEvent("Census_OnSelectionChanged", binding)
            --end

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
    self.text:SetText(string.format("[%d] %s", binding.count, binding.name))

    self:SetScript("OnMouseDown", function()
        addon:TriggerEvent("Census_OnGuildSelectionChanged", binding.name)
    end)
end

function ClassicEraCensusHomeTabGuildsListviewItemMixin:ResetDataBinding()
    
end