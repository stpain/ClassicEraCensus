

local name, addon = ...;

local configDefaults = {
    ["minimapButton"] = {},
    ["region"] = "EU",
}

local Database = {};

function Database:Init()

    if not ClassicEraCensus_Account then
        ClassicEraCensus_Account = {
            config = {
                minimapButton = {},
            },
            census = {},
        };
    end

    self.db = ClassicEraCensus_Account;

    for conf, val in pairs(configDefaults) do
        if not self.db.config[conf] then
            self.db.config[conf] = val;
        end
    end

    addon:TriggerEvent("Database_OnInitialised")
    
    self:CleanCensusTables()
end

function Database:CleanCensusTables()
    if self.db then
        for k, census in ipairs(self.db.census) do
            if census.selected then
                census.selected = nil;
            end
        end
    end
    addon:TriggerEvent("Database_OnCensusTableChanged")
end

function Database:SetConfig(key, val)
    if self.db and self.db.config then
        self.db.config[key] = val;
    end
    addon:TriggerEvent("Database_OnConfigChanged", key, val)
end

function Database:GetConfig(key)
    if self.db and self.db.config then
        return self.db.config[key];
    end
end

function Database:InsertCensus(census)
    if self.db then
        table.insert(self.db.census, 1, census)
    end
    addon:TriggerEvent("Database_OnCensusTableChanged")
end

function Database:DeleteCensus(censusGroup)
    if self.db then
        for _, census in ipairs(censusGroup) do
            local key;
            for k, v in ipairs(self.db.census) do
                if (v.author == census.author) and (v.timestamp == census.timestamp) and (v.realm == census.realm) and (v.faction == census.faction) then
                    key = k
                end
            end
            if type(key) == "number" then
                table.remove(self.db.census, key)
            end
        end
    end
    addon:TriggerEvent("Database_OnCensusTableChanged")
end

function Database:CreateMerge(censusGroup, name)


    if #censusGroup == 0 then
        return
    end

    local t = {}
    local merge = {
        author = name,
        realm = censusGroup[1].realm,
        faction = censusGroup[1].faction,
        characters = {},
        timestamp = time(),
        merged = true,
        meta = {},
    }
    
    for k, census in ipairs(censusGroup) do
        table.insert(merge.meta, {
            author = census.author,
            timestamp = census.timestamp,
            merged = census.merged,
        })
        for j, character in ipairs(census.characters) do
            table.insert(t, character)
        end
    end

    table.sort(t, function(a, b)
        if a.name == b.name then
            return a.level > b.level
        else
            return a.name < b.name
        end
    end)

    local charactersSeen = {}
    for k, character in ipairs(t) do
        if not charactersSeen[character.name] then
            charactersSeen[character.name] = true
            table.insert(merge.characters, character)
        end
    end

    self:InsertCensus(merge)
end

function Database:FetchAllCensus()
    if self.db then
        return self.db.census;
    end
    return {};
end

function Database:FetchCensusByTimestamp(timestamp)
    if self.db then
        for k, census in ipairs(self.db.census) do
            if census.timestamp == timestamp then
                return census;
            end
        end
    end
    return {};
end


addon.db = Database;