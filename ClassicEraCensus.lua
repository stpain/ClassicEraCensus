

local addonName, ClassicEraCensus = ...;

local Database = ClassicEraCensus.db;
local Census = ClassicEraCensus.Census;

local EXPANSION = "classic"

local L = {
    TABS_SCAN = "Scan", 
    TABS_CENSUS_LOG = "Log",
    TABS_CENSUS = "Census",
    SELECT_REGION = " - Region:",
    HOME_IS_QUICK_CENSUS_LABEL = "Quick Scan",
    HOME_GUILDS_HELPTIP = "Guilds are orderd by the total XP of all members",
    HOME_CENSUS_HISTORY_HELPTIP = [[
Census records are listed here.

%s Merged records are shown
with this icon.

You can select multiple records 
to view census data.

You can merge or delete selected
records.
]],
    HOME_CLASSES_HELPTIP = "You can select different parts on the charts to filter the results.",
    HOME_FILTERS_HELPTIP = "Adjust the level range and race/class filters to view data.\n\nIf no results show try selecting all races."
}

local MAX_LEVEL = 60;

local racesOrdered = {
    alliance = {
        "human",
        "dwarf",
        "nightelf",
        "gnome",
    },
    horde = {
        "orc",
        "undead",
        "troll",
        "tauren",
    }
}
local classesOrdered = {
    alliance = {
        "druid",
        "hunter",
        "mage",
        "paladin",
        "priest",
        "rogue",
        "warlock",
        "warrior",
    },
    horde = {
        "druid",
        "hunter",
        "mage",
        "priest",
        "rogue",
        "shaman",
        "warlock",
        "warrior",
    },
}


ClassicEraCensusMixin = {
    previousWhoQueryTime = -999,
    whoQueryStagger = 2.0,
    currentQueryIndex = 1,
    currentCensus = {
        timestamp = 0,
        author = "",
        realm = "",
        region = "",
        faction = "",
        characters = {},
        charactersSeen = {},
    },
    isCensusInProgress = false,
    censusProgress = 0,
    censusStartTime = time(),
    selectedCensus = {},
    censusGroup = {},
    regions = {"EU", "NA", "KR", "TW", "Other"},
};

function ClassicEraCensusMixin:OnLoad()

    ClassicEraCensus:RegisterCallback("Database_OnInitialised", self.Database_OnInitialised, self)
    ClassicEraCensus:RegisterCallback("Database_OnCensusTableChanged", self.Database_OnCensusTableChanged, self)
    ClassicEraCensus:RegisterCallback("Census_OnSelectionChanged", self.Census_OnSelectionChanged, self)
    ClassicEraCensus:RegisterCallback("Census_OnMultiSelectChanged", self.Census_OnMultiSelectChanged, self)
    ClassicEraCensus:RegisterCallback("Census_OnGuildSelectionChanged", self.Census_OnGuildSelectionChanged, self)
    ClassicEraCensus:RegisterCallback("Census_OnFinished", self.Census_OnFinished, self)
    ClassicEraCensus:RegisterCallback("Database_OnConfigChanged", self.Database_OnConfigChanged, self)

    self:RegisterForDrag("LeftButton")

    self:RegisterEvent("ADDON_LOADED")

    SetPortraitToTexture(_G[self:GetName().."Portrait"], 134939)

    _G[self:GetName().."TitleText"]:SetText(addonName..L.SELECT_REGION)
    _G[self:GetName().."TitleText"]:SetJustifyH("LEFT")

    self.numTabs = #self.tabs
    self.tab1:SetText(HOME)
    self.tab2:SetText(OPTIONS)
    self.tab3:SetText(L.TABS_CENSUS_LOG)

    PanelTemplates_SetNumTabs(self, self.numTabs);
    PanelTemplates_SetTab(self, 1);

    for i = 1, self.numTabs do
        self["tab"..i]:SetScript("OnClick", function()
            PanelTemplates_SetTab(self, i);
            self:OnTabSelected(i)
        end)
    end

    self.help:SetScript("OnMouseDown", function()
        
        for k, tip in ipairs(self.home.helptips) do
            tip:SetShown(not tip:IsVisible())
        end

    end)

    hooksecurefunc("SetItemRef", function(link)
        local linkRef, addon = strsplit("?", link)
        if (linkRef == "garrmission") and (addon == addonName) then
            self:ParseCensusLink(link)
        end
    end)

    local hooks = {
        "OnMouseDown",
        "OnMouseUp",
    }
    for _, hook in ipairs(hooks) do
        WorldFrame:HookScript(hook, function()
            if self.isCensusInProgress then
                self.currentCensus:AttemptNextWhoQuery()
                FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
                C_FriendList.SetWhoToUi(true)
                self:RegisterEvent("WHO_LIST_UPDATE")
            end
        end)
    end

end

function ClassicEraCensusMixin:OnTabSelected(tabIndex)
    for k, container in ipairs(self.containers) do
        container:Hide()
    end
    self.containers[tabIndex]:Show()
end

function ClassicEraCensusMixin:OnUpdate()
    if self.isCensusInProgress then
        -- self.censusProgress = (self.currentQueryIndex / #self.queries) * 100
        -- self.scanProgress:SetValue(self.censusProgress)
        -- self.scanProgress.text:SetText(string.format("%.1f", self.censusProgress))
        --self.home.censusInfoText:SetText(string.format("Scan time: %s Returned %d characters, processed %d of %d queries", SecondsToClock(time() - self.currentCensus.timestamp), #self.currentCensus.characters, self.currentQueryIndex, #self.queries))
    end
end

function ClassicEraCensusMixin:OnEvent(event, ...)
    
    if event == "ADDON_LOADED" and ... == addonName then
        Database:Init()
    end

    if event == "WHO_LIST_UPDATE" then
        self:WhoList_OnUpdate()
    end
end

function ClassicEraCensusMixin:AddLogMessage(msg)
    self.log.listview.DataProvider:Insert({
        message = msg,
    })
    self.log.listview.scrollBox:ScrollToEnd()
end

function ClassicEraCensusMixin:Database_OnInitialised()

    local addon = self;
    
    local ldb = LibStub("LibDataBroker-1.1")
    local minimapDataBroker = ldb:NewDataObject(addonName, {
        type = "launcher",
        icon = 134939,
        OnClick = function(_, button)
            print(button)
            self:SetShown(not self:IsVisible())
        end,
        OnEnter = function(addon)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(addonName)
            if addon.isCensusInProgress then
                GameTooltip:AddLine("Census progress")
                GameTooltip_ShowProgressBar(GameTooltip, 1, 100, addon.censusProgress)
            end
            GameTooltip:Show()
        end,
        OnLeave = function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end
    })
    self.minimapButton = LibStub("LibDBIcon-1.0")
    self.minimapButton:Register(addonName, minimapDataBroker, ClassicEraCensus_Account.config.minimapButton)

    local faction = UnitFactionGroup("player")
    self.faction = faction:lower()

    self:LoadOptionsInterface()
    self:SetupHomeTab()

    self:Database_OnCensusTableChanged()

    self.realmLabel:SetText(GetNormalizedRealmName())

end


local configCallbacks = {
    region = function(ui, val)
        for k, region in ipairs(ui.regions) do
            if region ~= val then
                ui["regionCheckbox"..region]:SetChecked(false)
            end
        end
    end,
}
function ClassicEraCensusMixin:Database_OnConfigChanged(config, val)
    if configCallbacks[config] then
        configCallbacks[config](self, val)
    end    
end

function ClassicEraCensusMixin:SetupHomeTab()

    local sliders = {
        ["Min level"] = "minLevel",
        ["Max level"] = "maxLevel",
    }

    for label, slider in pairs(sliders) do

        self.home.ribbon[slider].label:SetText(label)

        _G[self.home.ribbon[slider]:GetName().."Low"]:SetText(" ")
        _G[self.home.ribbon[slider]:GetName().."High"]:SetText(" ")
        _G[self.home.ribbon[slider]:GetName().."Text"]:SetText(" ")

        self.home.ribbon[slider]:SetScript("OnMouseWheel", function(s, delta)
            s:SetValue(s:GetValue() + delta)
        end)

        self.home.ribbon[slider]:SetScript("OnValueChanged", function(s)
            s.value:SetText(math.ceil(s:GetValue()))
            self:CensusLevelRange_OnChanged()
        end)
    end

    local reg = Database:GetConfig("region")
    for k, region in ipairs(self.regions) do
        self["regionCheckbox"..region]:SetScript("OnClick", function()
            Database:SetConfig("region", region)
        end)

        self["regionCheckbox"..region].label:SetText(region)

        if reg == region then
            self["regionCheckbox"..region]:SetChecked(true)
        end

    end

    self.home.ribbon.clearCensus:SetScript("OnClick", function()
        self:ClearAllFilters()
        self:ResetHomeCharts()
        self.censusGroup = {}
        Database:CleanCensusTables()
    end)

    self.home.ribbon.mergeCensus:SetScript("OnClick", function()
        StaticPopup_Show("ClassicEraCensusMergeConfirm", nil, nil, self.censusGroup)
    end)
    self.home.ribbon.deleteCensus:SetScript("OnClick", function()
        StaticPopup_Show("ClassicEraCensusDeleteConfirm", nil, nil, self.censusGroup)
    end)

    self.home.censusHistoryHelptip:SetText(L.HOME_CENSUS_HISTORY_HELPTIP:format(CreateAtlasMarkup("poi-workorders", 16, 16)))
    self.home.classesHelptip:SetText(L.HOME_CLASSES_HELPTIP)
    self.home.levelSliderHelptip:SetText(L.HOME_FILTERS_HELPTIP)
    self.home.guildHelptip:SetText(L.HOME_GUILDS_HELPTIP)

    self.home.races.bars = {}
    self.home.classes.bars = {}
    self.home.levels.bars = {}
    self.home.guilds.selectedGuild = false;

    local gender = UnitSex("player") == 2 and "male" or "female";

    local racesParentHeight = self.home.races:GetHeight()
    for k, race in ipairs(racesOrdered[self.faction]) do

        local bar = CreateFrame("FRAME", nil, self.home.races, "ClassicEraCensusBarChartBarTemplate")
        bar:SetWidthHeight(50, racesParentHeight)
        bar:SetPoint("BOTTOMLEFT", 2 + ((k-1) * 50), 1)
        bar:SetIcon(string.format("raceicon-%s-%s", race, gender))
        bar:TrimIcon()
        bar:SetBarColour({r = (191/255), g = (144/255), b = 0, a = 1})

        bar.selected = false;

        bar:SetScript("OnMouseDown", function()
            bar.selected = not bar.selected
            bar.barBackground:SetShown(bar.selected)
            self:FilterCensus(self.censusGroup)
        end)

        self.home.races.bars[race] = bar;
    end

    local classesParentHeight = self.home.classes:GetHeight()
    for k, class in ipairs(classesOrdered[self.faction]) do

        local bar = CreateFrame("FRAME", nil, self.home.classes, "ClassicEraCensusBarChartBarTemplate")
        bar:SetWidthHeight(40, classesParentHeight)
        bar:SetPoint("BOTTOMLEFT", 2 + ((k-1) * 40), 1)
        bar:SetIcon(string.format("classicon-%s", class))
        bar:SetBarColour(RAID_CLASS_COLORS[class:upper()])

        bar:SetScript("OnMouseDown", function()
            bar.selected = not bar.selected
            bar.barBackground:SetShown(bar.selected)
            self:FilterCensus(self.censusGroup)
        end)

        self.home.classes.bars[class] = bar;
    end


    local levelParentHeight = self.home.levels:GetHeight()
    local barWidth = 12
    for level = 1, MAX_LEVEL do
        
        local bar = CreateFrame("FRAME", nil, self.home.levels, "ClassicEraCensusBarChartBarTemplate")
        bar:SetWidthHeight(barWidth, levelParentHeight - 5)
        bar:SetNoIcon()
        bar:SetPoint("BOTTOMLEFT", 2 + ((level-1) * barWidth), 1)
        bar:SetBarColour({r = (191/255), g = (144/255), b = 0, a = 1})
        bar:ShowValues(false)
        bar:SetScript("OnMouseDown", function()
            bar.selected = not bar.selected
            bar.barBackground:SetShown(bar.selected)
            self:FilterCensus(self.censusGroup)
        end)

        self.home.levels.bars[level] = bar;
    end

    self.startScan:SetScript("OnClick", function()
        self:Census_Start()
    end)

    self.home.ribbon.minLevel:SetValue(1)
    self.home.ribbon.maxLevel:SetValue(60)

end

function ClassicEraCensusMixin:CensusLevelRange_OnChanged()
    local levelParentWidth = self.home.levels:GetWidth() - 4
    local levelParentHeight = self.home.levels:GetHeight()

    local minLevel = math.ceil(self.home.ribbon.minLevel:GetValue())
    local maxLevel = math.ceil(self.home.ribbon.maxLevel:GetValue())

    local range = (maxLevel - minLevel ) + 1

    local barWidth = (levelParentWidth / range)

    for i = 1, MAX_LEVEL do
        self.home.levels.bars[i]:Hide()
    end

    if minLevel <= maxLevel then
        local j = 1
        for i = minLevel, maxLevel do
            self.home.levels.bars[i]:ClearAllPoints()
            self.home.levels.bars[i]:SetPoint("BOTTOMLEFT", 2 + ((j-1) * (barWidth)), 1)
            self.home.levels.bars[i]:SetWidthHeight(barWidth, levelParentHeight - 5)
            self.home.levels.bars[i]:SetNoIcon()
            self.home.levels.bars[i]:Show()
            j = j + 1
        end

        self:FilterCensus(self.censusGroup)
    end

end

function ClassicEraCensusMixin:Database_OnCensusTableChanged()

    self:ClearAllFilters()
    self:ResetHomeCharts()
    
    local allCensus = Database:FetchAllCensus()

    self.home.censusHistory.DataProvider:Flush()

    self.home.censusHistory.DataProvider:InsertTable(allCensus)
end


function ClassicEraCensusMixin:Census_OnSelectionChanged(census)
    self:ClearAllFilters()
    self.censusGroup = { census }
    self:LoadCensusGroup(self.censusGroup)
end

function ClassicEraCensusMixin:Census_OnGuildSelectionChanged(guild)
    if self.home.guilds.selectedGuild == guild then
        self.home.guilds.selectedGuild = false

        self:LoadCensusGroup()
    else
        self.home.guilds.selectedGuild = guild
        
        self:FilterCensusForGuild(guild)
    end

end

function ClassicEraCensusMixin:Census_OnMultiSelectChanged(census)

    if #self.censusGroup == 0 then
        table.insert(self.censusGroup, census)
    else
        local exists, key = false, nil
        local realmCheck, factionCheck = true, true
        for k, v in ipairs(self.censusGroup) do
            --print(k, v.realm, v.timestamp)
            if (v.author == census.author) and (v.timestamp == census.timestamp) then
                exists = true;
                key = k
            end
            if census.realm ~= v.realm then
                realmCheck = false
            end
            if census.faction ~= v.faction then
                factionCheck = false;
            end
        end
        if realmCheck == false then
            print("Census is from a different realm!")
            return;
        end
        if factionCheck == false then
            print("Census is from a different faction!")
            return;
        end
        if census.selected == true and exists == false then
            table.insert(self.censusGroup, census)
        end
        if  (not census.selected) and key ~= nil then
            table.remove(self.censusGroup, key)
        end
    end

    self:LoadCensusGroup(self.censusGroup)

    local censusGroupCharactersSeen, count = {}, 0
    for _, census in ipairs(self.censusGroup) do
        for k, character in ipairs(census.characters) do
            if not censusGroupCharactersSeen[character.name]then
                count = count + 1;
                censusGroupCharactersSeen[character.name] = true
            end
        end
    end

    if #self.censusGroup == 0 then
        self.home.censusInfoText:SetText("No census selected")
    else
        self.home.censusInfoText:SetText(string.format("Selected %d, %d unique characters", #self.censusGroup, count))
    end

end


function ClassicEraCensusMixin:Census_Start()

    local name, realm = UnitFullName("player");
    if realm == nil or realm == "" then
        realm = GetNormalizedRealmName();
    end

    local faction = UnitFactionGroup("player")
    local region = Database:GetConfig("region")

    self.currentCensus = Census:New(name, realm, faction, region)

    self.isCensusInProgress = true;

end

function ClassicEraCensusMixin:Census_Pause()
    self.isCensusInProgress = not self.isCensusInProgress;
end

function ClassicEraCensusMixin:Census_Stop()
    
end

function ClassicEraCensusMixin:Census_OnFinished()
    self.isCensusInProgress = false;
    
    local census = self.currentCensus:CreateRecord()
    self.currentCensus = census;
    --Database:InsertCensus(self.currentCensus)
end


function ClassicEraCensusMixin:ResetHomeCharts()
    for _, chart in pairs({"races", "classes", "levels"}) do
        for _, bar in ipairs(self.home[chart].bars) do
            bar:SetBarValue(0)
        end
        for _, bar in pairs(self.home[chart].bars) do
            bar:SetBarValue(0)
        end
    end
    self.home.guilds.DataProvider:Flush()
end

function ClassicEraCensusMixin:ClearAllFilters()
    for k, bar in pairs(self.home.races.bars) do
        bar.selected = false
        bar.barBackground:SetShown(bar.selected)
    end
    for k, bar in pairs(self.home.classes.bars) do
        bar.selected = false
        bar.barBackground:SetShown(bar.selected)
    end
    for k, bar in pairs(self.home.levels.bars) do
        bar.selected = false
        bar.barBackground:SetShown(bar.selected)
    end
    self.home.guilds.selectedGuild = false;
end

function ClassicEraCensusMixin:SetAllRaceFilters()
    for k, bar in pairs(self.home.races.bars) do
        bar.selected = true
        bar.barBackground:SetShown(bar.selected)
    end
end

function ClassicEraCensusMixin:SetAllClassFilters()
    for k, bar in pairs(self.home.classes.bars) do
        bar.selected = true
        bar.barBackground:SetShown(bar.selected)
    end
end

function ClassicEraCensusMixin:FilterCensusForGuild(guild)

    if #self.censusGroup == 0 then
        return
    end

    local t = {
        characters = {},
        faction = self.censusGroup[1].faction,
        realm = self.censusGroup[1].realm,
    }
    for _, census in ipairs(self.censusGroup) do
        for k, character in ipairs(census.characters) do
            if character.guild == guild then
                table.insert(t.characters, character)
            end
        end
    end

    self.censusGroup = {t}
    self:LoadCensusGroup()
end

function ClassicEraCensusMixin:FilterCensus(censusGroup)

    local levelRange = {
        [1] = math.ceil(self.home.ribbon.minLevel:GetValue()),
        [2] = math.ceil(self.home.ribbon.maxLevel:GetValue()),
    }

    local isClassFiltered, isRaceFiltered = false, false;
    
    local guild = self.home.guilds.selectedGuild;

    -- local filterText = ""
    -- local filteredRaces, filteredClasses = "", ""

    local races, classes, levels = {}, {}, {};
    for k, bar in pairs(self.home.races.bars) do
        if bar.selected then
            isRaceFiltered = true;
            races[k:lower()] = true

            --filteredRaces = string.format("%s %s", filteredRaces, k)
        end
    end
    for k, bar in pairs(self.home.classes.bars) do
        if bar.selected then
            isClassFiltered = true;
            classes[k:lower()] = true

            --filteredClasses = string.format("%s %s", filteredClasses, k)
        end
    end

    --self.home.censusInfoText:SetText(string.format("Races: %s, Classes %s", filteredRaces, filteredClasses))

    if levelRange then
        for level = levelRange[1], levelRange[2] do
            levels[level] = true
        end
        --isFiltered = true;
    end

    if self.home.guilds.selectedGuild then
        --isFiltered = true
    end

    if not censusGroup then
        censusGroup = { self.currentCensus }
    end

    if #censusGroup == 0 then
        return
    end

    if isRaceFiltered == false then
        --self:SetAllRaceFilters()
    end

    if isClassFiltered == false then
        --self:SetAllClassFilters()
    end

    if isRaceFiltered == false and isClassFiltered == false then
        self:LoadCensusGroup(censusGroup)
        return;
    end

    local t = {
        characters = {},
        faction = censusGroup[1].faction,
    }

    -- local function generateLevelFilter()
    --     return function(character)
    --         if levels[character.level] then
    --             return true
    --         end
    --     end
    -- end

    local function generateRaceFilter()
        return function(character)
            if levels[character.level] then
                if character.race == "Night Elf" then
                    if races["nightelf"] then
                        return true
                    end
                else
                    if races[character.race:lower()] then
                        return true
                    end
                end
            end
        end
    end
    local function generateClassFilter()
        return function(character)
            if levels[character.level] then
                if classes[character.class:lower()] then
                    return true
                end
            end
        end
    end


    local filters = {
        generateRaceFilter(),
        generateClassFilter(),
    }

    
    local characters, guildCheck
    if guild then
        characters = {}
        --guildCheck = generateGuildFilter()
        for _, census in ipairs(censusGroup) do
            for k, character in ipairs(census.characters) do
                if character.guild == guild then
                    table.insert(characters, character)
                end
            end
        end

        for k, character in ipairs(characters) do
            for k, filter in ipairs(filters) do
                if filter(character) == true then
                    table.insert(t.characters, character)
                end
            end
        end

    else

        for _, census in ipairs(censusGroup) do
            for k, character in ipairs(census.characters) do
                for k, filter in ipairs(filters) do
                    if filter(character) == true then
                        table.insert(t.characters, character)
                    end
                end
    
            end
    
        end
    end

    self:LoadCensusGroup({t})

end


function ClassicEraCensusMixin:GetCharactersTotalXP(currentLevel)

    local xp = 0;
    if type(currentLevel) == "number" then
        for i = 1, (currentLevel - 1) do
            xp = xp + ClassicEraCensus.levelXpValues[EXPANSION][i]
        end
    end
    return xp;
end

function ClassicEraCensusMixin:LoadCensusGroup(censusGroup)

    self:ResetHomeCharts()

    if not censusGroup then
        censusGroup = { self.currentCensus }
    end

    if #censusGroup == 0 then
        return
    end

    local faction = censusGroup[1].faction;

    local races, classes, levels, guilds, guildsSeen, charactersSeen = {}, {}, {}, {}, {}, {};
    local characterCount = 0;

    local characters = {}

    for _, census in ipairs(censusGroup) do
        if census.faction == faction then
            for k, character in ipairs(census.characters) do

                if not charactersSeen[character.name] then

                    table.insert(characters, character)

                    charactersSeen[character.name] = true;

                    characterCount = characterCount + 1;

                    if not races[character.race] then
                        races[character.race] = 1;
                    else
                        races[character.race] = races[character.race] + 1;
                    end

                    if not classes[character.class] then
                        classes[character.class] = 1;
                    else
                        classes[character.class] = classes[character.class] + 1;
                    end

                    local level = tostring(character.level)
                    if not levels[level] then
                        levels[level] = 1;
                    else
                        levels[level] = levels[level] + 1;
                    end

                    if not guildsSeen[character.guild] then
                        guildsSeen[character.guild] = true;
                        table.insert(guilds, {
                            name = character.guild,
                            count = 1,
                            xp = self:GetCharactersTotalXP(character.level)
                        })
                    else
                        for k, guild in ipairs(guilds) do
                            if guild.name == character.guild then
                                guild.count = guild.count + 1;
                                guild.xp = guild.xp + self:GetCharactersTotalXP(character.level)
                            end
                        end
                    end

                end

            end
        end
    end

    for race, count in pairs(races) do
        if race == "Night Elf" then
            self.home.races.bars["nightelf"]:SetBarValue(count, characterCount)
        else
            self.home.races.bars[race:lower()]:SetBarValue(count, characterCount)
        end
    end

    for class, count in pairs(classes) do
        self.home.classes.bars[class:lower()]:SetBarValue(count, characterCount)
    end

    for level, count in pairs(levels) do
        self.home.levels.bars[tonumber(level)]:SetBarValue(count, characterCount)
    end

    self.home.guilds.DataProvider:Flush()
    table.sort(guilds, function(a, b)
        if a.xp == b.xp then
            if a.count == b.count then
                return a.name <b.name
            else
                return a.count < b.count
            end
        else
            return a.xp > b.xp
        end
    end)
    self.home.guilds.DataProvider:InsertTable(guilds)

end


function ClassicEraCensusMixin:WhoList_OnUpdate()

    local numResults = C_FriendList.GetNumWhoResults()

    --to many results for this race/class combo
    if numResults > 49 then
        self.currentCensus:RefineWhoParams()

    else
        self.currentCensus:ProcessWhoResults()

    end

    FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
    C_FriendList.SetWhoToUi(false)
    self:UnregisterEvent("WHO_LIST_UPDATE")

    self:LoadCensusGroup()

end


function ClassicEraCensusMixin:LoadOptionsInterface()

end


function ClassicEraCensusMixin:GenerateCensusLink(census)
    local link = string.format("|cffffffff|Hgarrmission?%s|h%s|h|r",
        addonName,
        census
    )
    return link
end

function ClassicEraCensusMixin:ParseCensusLink(link)
    ClassicEraCensusHyperlinkPopup:LoadLinkInfo({strsplit("?", link)})
end






















ClassicEraCensusHyperlinkPopupMixin = {}
function ClassicEraCensusHyperlinkPopupMixin:LoadLinkInfo(info)
    
end