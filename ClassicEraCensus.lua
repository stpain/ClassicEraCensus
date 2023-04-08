

local addonName, ClassicEraCensus = ...;

local Comms = ClassicEraCensus.Comms;
local Database = ClassicEraCensus.db;
local Census = ClassicEraCensus.Census;

local EXPANSION = "classic"

--move these into their own file at some point
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

--if this goes beyond Era then this variable needs to be adjusted, either via blizz api or some config setting
local MAX_LEVEL = 60;


--main mixin
ClassicEraCensusMixin = {
    isCensusInProgress = false,
    censusGroup = {},
    regions = {"EU", "NA", "KR", "TW", "Other"},
    classesOrdered = {
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
    },
    racesOrdered = {
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
};

--when we load get the callbacks setup, any addon navigation systems and any script hooking
function ClassicEraCensusMixin:OnLoad()

    ClassicEraCensus:RegisterCallback("Database_OnInitialised", self.Database_OnInitialised, self)
    ClassicEraCensus:RegisterCallback("Database_OnCensusTableChanged", self.Database_OnCensusTableChanged, self)
    ClassicEraCensus:RegisterCallback("Census_OnMultiSelectChanged", self.Census_OnMultiSelectChanged, self)
    ClassicEraCensus:RegisterCallback("Census_OnGuildSelectionChanged", self.Census_OnGuildSelectionChanged, self)
    ClassicEraCensus:RegisterCallback("Census_OnFinished", self.Census_OnFinished, self)
    ClassicEraCensus:RegisterCallback("Census_LogMessage", self.Census_LogMessage, self)
    ClassicEraCensus:RegisterCallback("Database_OnConfigChanged", self.Database_OnConfigChanged, self)
    ClassicEraCensus:RegisterCallback("Comms_OnMessageReceived", self.Comms_OnMessageReceived, self)
    ClassicEraCensus:RegisterCallback("Census_OnCoopCensusRequestAccepted", self.Census_OnCoopCensusRequestAccepted, self)
    ClassicEraCensus:RegisterCallback("Census_OnCoopCensusRecordAccepted", self.Census_OnCoopCensusRecordAccepted, self)

    self:RegisterForDrag("LeftButton")

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LOGOUT")

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


    for _, hook in ipairs({"OnMouseDown", "OnMouseUp"}) do
        WorldFrame:HookScript(hook, function()
            if self.isCensusInProgress then
                FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
                self:RegisterEvent("WHO_LIST_UPDATE")
                C_FriendList.SetWhoToUi(true)
                self.currentCensus:AttemptNextWhoQuery()
            end
        end)
    end

end

--addon navigation
function ClassicEraCensusMixin:OnTabSelected(tabIndex)
    for k, container in ipairs(self.containers) do
        container:Hide()
    end
    self.containers[tabIndex]:Show()
end

--need to finish the Census object so it can return census progress data to be used in here
function ClassicEraCensusMixin:OnUpdate()
    if self.isCensusInProgress then
        local progress = self.currentCensus:GetProgress()
        self.home.censusInfoText:SetText(string.format("Scan time: %s Recorded %d characters, processed %d of %d queries", SecondsToClock(progress.elapsed), progress.characterCount, progress.currentIndex, progress.numQueries))
    end
end

--handle events
function ClassicEraCensusMixin:OnEvent(event, ...)
    
    if event == "ADDON_LOADED" and ... == addonName then
        Database:Init()
        self:UnregisterEvent("ADDON_LOADED")
    end

    if event == "PLAYER_LOGOUT" then
        Database:CleanCensusTables()
    end

    if event == "WHO_LIST_UPDATE" then
        self:WhoList_OnUpdate()
    end
end

function ClassicEraCensusMixin:Comms_OnMessageReceived(sender, data)

    if data.type == "COOP_CENSUS_REQUEST" then
        StaticPopup_Show("ClassicEraCensusAcceptCoopCensusRequest", nil, nil, data.payload)
    end
    
    if data.type == "COOP_CENSUS_RECORD" then
        StaticPopup_Show("ClassicEraCensusAcceptCoopCensusRecord", nil, nil, data.payload)
    end

end

--function used to log messages from the census
function ClassicEraCensusMixin:Census_LogMessage(type, msg)
    self.log.listview.DataProvider:Insert({
        type = type,
        message = msg,
    })
    self.log.listview.scrollBox:ScrollToEnd()
end

--get data from the character string
function ClassicEraCensusMixin:GetCharacterInfo(character, info)
    
    local t = {}
    t.name, t.level, t.race, t.class, t.guild = strsplit(",", character)

    t.level = tonumber(t.level)

    if info and t[info] then
        return t[info]
    else
        return t.name, t.level, t.race, t.class, t.guild;
    end
end

--called after the db has initialized, load the minimap button and call any UI setup functions now the db config data is ready
function ClassicEraCensusMixin:Database_OnInitialised()

    local ldb = LibStub("LibDataBroker-1.1")
    local minimapDataBroker = ldb:NewDataObject(addonName, {
        type = "launcher",
        icon = 134939,
        OnClick = function(_, button)
            print(button)
            self:SetShown(not self:IsVisible())
        end,
        OnEnter = function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(addonName)
            if ClassicEraCensusUI.isCensusInProgress then
                GameTooltip:AddLine("Census progress")
                GameTooltip_ShowProgressBar(GameTooltip, 1, 100, ClassicEraCensusUI.currentCensus:GetProgress().percent)
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
    self:SetupOptionsTab()

    self:Database_OnCensusTableChanged()

    self.realmLabel:SetText(GetNormalizedRealmName())

    Comms:Init()

end

--this was in case the config list got bigger and to avoid lots of if elseif 
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

--setup the options tab
function ClassicEraCensusMixin:SetupOptionsTab()

    local gender = UnitSex("player") == 2 and "male" or "female";

    for k, race in ipairs(self.racesOrdered[self.faction]) do
        self.options.customCensus["race"..k].label:SetText(string.format("%s %s", CreateAtlasMarkup(string.format("raceicon-%s-%s", race, gender), 18, 18), ClassicEraCensus.locales[race]))
        self.options.customCensus["race"..k].race = race;
        if race == "nightelf" then
            self.options.customCensus["race"..k].race = [[night elf]]
        end
    end

    for k, class in ipairs(self.classesOrdered[self.faction]) do
        self.options.customCensus["class"..k].label:SetText(string.format("%s %s", CreateAtlasMarkup(string.format("classicon-%s", class), 18, 18), ClassicEraCensus.locales[class]))
        self.options.customCensus["class"..k].class = class;
    end

    local sliders = {
        ["Min level"] = "minLevel",
        ["Max level"] = "maxLevel",
    }

    for label, slider in pairs(sliders) do

        self.options.customCensus[slider].label:SetText(label)

        _G[self.options.customCensus[slider]:GetName().."Low"]:SetText(" ")
        _G[self.options.customCensus[slider]:GetName().."High"]:SetText(" ")
        _G[self.options.customCensus[slider]:GetName().."Text"]:SetText(" ")

        self.options.customCensus[slider]:SetScript("OnMouseWheel", function(s, delta)
            s:SetValue(s:GetValue() + delta)
        end)

        self.options.customCensus[slider]:SetScript("OnValueChanged", function(s)
            s.value:SetText(math.ceil(s:GetValue()))
        end)
    end

    self.options.customCensus.minLevel:SetValue(1)
    self.options.customCensus.maxLevel:SetValue(60)

    self.options.customCensus.getCustomFilters = function()

        local races, raceFiltered = {}, false
        for k, checkbox in ipairs(self.options.customCensus.raceFilters) do
            if checkbox:GetChecked() then
                table.insert(races, checkbox.race)
                raceFiltered = true;
            end
        end

        local classes, classFiltered = {}, false
        for k, checkbox in ipairs(self.options.customCensus.classFilters) do
            if checkbox:GetChecked() then
                table.insert(classes, checkbox.class)
                classFiltered = true;
            end
        end

        local minL = self.options.customCensus.minLevel.value:GetText()
        local maxL = self.options.customCensus.maxLevel.value:GetText()

        return (raceFiltered == true and races or nil), (classFiltered == true and classes or nil), string.format("%s-%s", minL, maxL)
    end

    self.options.customCensus.startCensus:SetScript("OnClick", function()

        local name, realm = UnitFullName("player");
        if realm == nil or realm == "" then
            realm = GetNormalizedRealmName();
        end
    
        local faction = UnitFactionGroup("player")
        local region = Database:GetConfig("region")

        local races, classes, levelRange = self.options.customCensus.getCustomFilters()
    
        self.currentCensus = Census:New(name, realm, faction, region, races, classes, levelRange)
    
        self.isCensusInProgress = true;
    
    end)

    self.options.customCensus.sendCoopCensusRequest:SetScript("OnClick", function()

        local playerName = self.options.customCensus.coopCensusTeamMemberName:GetText()
        if playerName == "" then
            return
        end
        if playerName then
            
        end
    
        local name, realm = UnitFullName("player");
        if realm == nil or realm == "" then
            realm = GetNormalizedRealmName();
        end
    
        local faction = UnitFactionGroup("player")
        local region = Database:GetConfig("region")

        local races, classes, levelRange = self.options.customCensus.getCustomFilters()

        local whoQueries, customFilters = Census:GenerateWhoQueries(faction, races, classes, levelRange)

        local msg = {
            type = "COOP_CENSUS_REQUEST",
            payload = {
                author = name,
                realm = realm,
                faction = faction,
                region = region,
                whoQueries = whoQueries,
                customFilters = customFilters,
            }
        }

        Comms:SendCoopCensus(msg, playerName)
    end)

end

--setup the home tab, charts, filters etc
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

    self.home.races.bars = {
        alliance = {},
        horde = {},
    }
    self.home.classes.bars = {
        alliance = {},
        horde = {},
    }
    self.home.levels.bars = {}
    self.home.guilds.selectedGuild = false;

    local gender = UnitSex("player") == 2 and "male" or "female";

    local racesParentHeight = self.home.races:GetHeight()
    for _, faction in ipairs({"alliance", "horde"}) do
        for k, race in ipairs(self.racesOrdered[faction]) do

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

            self.home.races.bars[faction][race] = bar;
        end
    end

    local classesParentHeight = self.home.classes:GetHeight()
    for _, faction in ipairs({"alliance", "horde"}) do
        for k, class in ipairs(self.classesOrdered[faction]) do

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

            self.home.classes.bars[faction][class] = bar;
        end
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

    self.startCensus:SetScript("OnClick", function()
        self:Census_Start()
    end)

    self.home.ribbon.minLevel:SetValue(1)
    self.home.ribbon.maxLevel:SetValue(60)

end

--handle the level sliders value changing
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

--this is called when the db table 'census' changes (census added or removed)
function ClassicEraCensusMixin:Database_OnCensusTableChanged()

    self:ClearAllFilters()
    self:ResetHomeCharts()
    
    local allCensus = Database:FetchAllCensus()

    self.home.censusHistory.DataProvider:Flush()

    self.home.censusHistory.DataProvider:InsertTable(allCensus)
end

--filter census group for guild matches
function ClassicEraCensusMixin:Census_OnGuildSelectionChanged(guild)
    if self.home.guilds.selectedGuild == guild then
        self.home.guilds.selectedGuild = false

        self:LoadCensusGroup()
    else
        self.home.guilds.selectedGuild = guild
        
        self:FilterCensusForGuild(guild)
    end

end

--handle census selection(s)
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
            local name = self:GetCharacterInfo(character, "name")
            if not censusGroupCharactersSeen[name]then
                count = count + 1;
                censusGroupCharactersSeen[name] = true
            end
        end
    end

    if #self.censusGroup == 0 then
        self.home.censusInfoText:SetText("No census selected")
        self:ClearAllFilters()
        self:ResetHomeCharts()
    else
        self.home.censusInfoText:SetText(string.format("Selected %d, %d unique characters", #self.censusGroup, count))
    end

end


function ClassicEraCensusMixin:Census_OnCoopCensusRequestAccepted(request)
    
    if self.isCensusInProgress then
        return;
    end

    self.currentCensus = Census:NewCoopCensus(request)
    self.isCensusInProgress = true;
    self.isCoopCensus = true;
end

function ClassicEraCensusMixin:Census_OnCoopCensusRecordAccepted(record)

    Database:InsertCensus(record.census)
end

--create a census object
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

--for now this just pauses the WorldFrame hook clicks to prevent any who queries firing off
function ClassicEraCensusMixin:Census_Pause()
    self.isCensusInProgress = not self.isCensusInProgress;
end

function ClassicEraCensusMixin:Census_Stop()
    
end

--create a SV friendly record of the census object
function ClassicEraCensusMixin:Census_OnFinished()

    if self.isCoopCensus == true then
        
        --need to return the data now!
        local census = self.currentCensus:CreateRecord()
        local msg = {
            type = "COOP_CENSUS_RECORD",
            payload = {
                census = census,
            }
        }

        local author = census.author
        Comms:SendCoopCensus(msg, author)

    else
        local census = self.currentCensus:CreateRecord()
        self.currentCensus = census;
        Database:InsertCensus(self.currentCensus)
    end

    self.isCensusInProgress = false;
    self.isCoopCensus = false;
    
end

function ClassicEraCensusMixin:ShowFactionCharts(faction)
    faction = faction:lower()
    for _, _faction in ipairs({"alliance", "horde"}) do
        for _, chart in pairs({"races", "classes"}) do
            for _, bar in pairs(self.home[chart].bars[_faction]) do
                bar:Hide()
            end
        end
    end
    for _, chart in pairs({"races", "classes"}) do
        for _, bar in pairs(self.home[chart].bars[faction]) do
            bar:Show()
        end
    end
end

function ClassicEraCensusMixin:ResetHomeCharts()
    for _, faction in ipairs({"alliance", "horde"}) do
        for _, chart in pairs({"races", "classes"}) do
            for _, bar in pairs(self.home[chart].bars[faction]) do
                bar:SetBarValue(0)
            end
        end
    end
    for k, bar in ipairs(self.home.levels.bars) do
        bar:SetBarValue(0)
    end
    self.home.guilds.DataProvider:Flush()
end

function ClassicEraCensusMixin:ClearAllFilters()
    for _, faction in ipairs({"alliance", "horde"}) do
        for k, bar in pairs(self.home.races.bars[faction]) do
            bar.selected = false
            bar.barBackground:SetShown(bar.selected)
        end
        for k, bar in pairs(self.home.classes.bars[faction]) do
            bar.selected = false
            bar.barBackground:SetShown(bar.selected)
        end
    end
    for k, bar in pairs(self.home.levels.bars) do
        bar.selected = false
        bar.barBackground:SetShown(bar.selected)
    end
    self.home.guilds.selectedGuild = false;
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
            local _guild = self:GetCharacterInfo(character, "guild")
            if _guild == guild then
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

    local races, classes, levels = {}, {}, {};

    for _, faction in ipairs({"alliance", "horde"}) do
        for k, bar in pairs(self.home.races.bars[faction]) do
            if bar.selected then
                isRaceFiltered = true;
                races[k:lower()] = true
            end
        end
        for k, bar in pairs(self.home.classes.bars[faction]) do
            if bar.selected then
                isClassFiltered = true;
                classes[k:lower()] = true
            end
        end
    end

    if levelRange then
        for level = levelRange[1], levelRange[2] do
            levels[level] = true
        end
    end

    if not censusGroup then
        censusGroup = { self.currentCensus }
    end

    if #censusGroup == 0 then
        return
    end

    if isRaceFiltered == false and isClassFiltered == false then
        self:LoadCensusGroup(censusGroup)
        return;
    end

    local t = {
        characters = {},
        faction = censusGroup[1].faction,
    }

    local function generateRaceFilter()
        return function(character)
            local level = self:GetCharacterInfo(character, "level")
            if levels[level] then
                local race = self:GetCharacterInfo(character, "race")
                if race == "Night Elf" then
                    if races["nightelf"] then
                        return true
                    end
                else
                    if races[race:lower()] then
                        return true
                    end
                end
            end
        end
    end
    local function generateClassFilter()
        return function(character)
            local level = self:GetCharacterInfo(character, "level")
            if levels[level] then
                if classes[self:GetCharacterInfo(character, "class"):lower()] then
                    return true
                end
            end
        end
    end


    local filters = {
        generateRaceFilter(),
        generateClassFilter(),
    }

    
    local characters
    if guild then
        characters = {}
        for _, census in ipairs(censusGroup) do
            for k, character in ipairs(census.characters) do
                local _guild = self:GetCharacterInfo(character, "guild")
                if _guild == guild then
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

    if not faction then
        faction = self.faction;
    end

    self:ShowFactionCharts(faction)

    local races, classes, levels, guilds, guildsSeen, charactersSeen = {}, {}, {}, {}, {}, {};
    local characterCount = 0;

    local characters = {}

    for _, census in ipairs(censusGroup) do
        if census.faction == faction then
            for k, character in ipairs(census.characters) do

                local name, level, race, class, guild = self:GetCharacterInfo(character)
                local xp = self:GetCharactersTotalXP(level)

                if not charactersSeen[name] then

                    table.insert(characters, character)

                    charactersSeen[name] = true;

                    characterCount = characterCount + 1;

                    if not races[race] then
                        races[race] = 1;
                    else
                        races[race] = races[race] + 1;
                    end

                    if not classes[class] then
                        classes[class] = 1;
                    else
                        classes[class] = classes[class] + 1;
                    end

                    local level = tostring(level)
                    if not levels[level] then
                        levels[level] = 1;
                    else
                        levels[level] = levels[level] + 1;
                    end

                    if not guildsSeen[guild] then
                        guildsSeen[guild] = true;
                        table.insert(guilds, {
                            name = guild,
                            count = 1,
                            xp = xp
                        })
                    else
                        for k, v in ipairs(guilds) do
                            if v.name == guild then
                                v.count = v.count + 1;
                                v.xp = v.xp + xp
                            end
                        end
                    end

                end

            end
        end
    end

    faction = faction:lower()

    --for _, faction in ipairs({"alliance", "horde"}) do
        for race, count in pairs(races) do
            if race == "Night Elf" then
                self.home.races.bars.alliance["nightelf"]:SetBarValue(count, characterCount)
            else
                self.home.races.bars[faction][race:lower()]:SetBarValue(count, characterCount)
            end
        end

        for class, count in pairs(classes) do
            self.home.classes.bars[faction][class:lower()]:SetBarValue(count, characterCount)
        end
    --end

    for level, count in pairs(levels) do
        self.home.levels.bars[tonumber(level)]:SetBarValue(count, characterCount)
    end

    self.home.guilds.DataProvider:Flush()
    table.sort(guilds, function(a, b)
        if a.xp == b.xp then
            if a.count == b.count then
                return a.name < b.name
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

    --could probs add a config for this?
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