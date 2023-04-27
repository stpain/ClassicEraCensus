

local name, addon = ...;

local configDefaults = {
    ["minimapButton"] = {},
    ["region"] = "EU",
}

local Database = {};

function Database:Init()

    self.version = tonumber(GetAddOnMetadata(name, "Version"));
    if self.version == 0.1 then
        ClassicEraCensus_Account = nil;
    end

    if not ClassicEraCensus_Account then
        ClassicEraCensus_Account = {
            config = {
                minimapButton = {},
            },
            census = {},
            temp = {},
        };
    end

    self.db = ClassicEraCensus_Account;

    for conf, val in pairs(configDefaults) do
        if not self.db.config[conf] then
            self.db.config[conf] = val;
        end
    end

    if not self.db.temp then
        self.db.temp = {};
    end

    addon:TriggerEvent("Database_OnInitialised")
    
    self:CleanCensusTables()
end

function Database:CleanCensusTables()
    local symbols = '["<>/@?$&"]'
    if self.db then
        local keys = {}
        for censusIndex, census in ipairs(self.db.census) do
            local isDirty = false;
            if census.selected then
                census.selected = nil;
            end

            for k, v in pairs(census) do
                if(k:match(symbols)) then
                    isDirty = true;
                end
                if type(v) == "string" then
                    if(v:match(symbols)) then
                        isDirty = true;
                    end
                end
            end
            for _, character in ipairs(census.characters) do
                for k, v in pairs(character) do
                    if(k:match(symbols)) then
                        isDirty = true;
                    end
                    if type(v) == "string" then
                        if(v:match(symbols)) then
                            isDirty = true;
                        end
                    end
                end
            end
            if isDirty == true then
                table.insert(keys, { index = censusIndex })
            end
        end
        if #keys > 0 then
            table.sort(keys, function(a, b)
                return a.index > b.index;
            end)
            for k, v in ipairs(keys) do
                table.remove(self.db.census, v.index)
            end
        end
    end
    addon:TriggerEvent("Database_OnCensusTableChanged")
end

function Database:SetConfig(key, val, t)
    if t then
        if not self.db.config[t] then
            self.db.config[t] = {}
            self.db.config[t][key] = val;

        else
            self.db.config[t][key] = val;

        end
    end
    if self.db and self.db.config then
        self.db.config[key] = val;
    end
    addon:TriggerEvent("Database_OnConfigChanged", key, val, t)
end

function Database:GetConfig(key, t)
    if t then
        if self.db.config[t] then
            return self.db.config[t][key];
        end
    else
        return self.db.config[key];
    end

end

function Database:SaveTempData(key, val)
    if self.db then
        self.db.temp[key] = val;
    end
end

function Database:GetTempData(dataKey)
    if self.db then
        if self.db.temp[dataKey] then
            return self.db.temp[dataKey]
        end
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
    addon:TriggerEvent("Database_OnCensusTableChanged", true) --true means census group was removed so clear it
end

function Database:GetCharacterInfo(character, info)
    
    local t = {}
    t.name, t.level, t.race, t.class, t.guild = strsplit(",", character)

    t.level = tonumber(t.level)

    if info and t[info] then
        return t[info]
    else
        return t.name, t.level, t.race, t.class, t.guild;
    end
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
        isMerged = true,
    }
    
    for k, census in ipairs(censusGroup) do
        for j, character in ipairs(census.characters) do
            table.insert(t, {
                character = character,
                timestamp = census.timestamp,
            })
        end
    end

    local charactersSeen = {}
    for k, v in ipairs(t) do
        --local name = self:GetCharacterInfo(v.character, "name")
        local name = v.character.name
        if not charactersSeen[name] then
            charactersSeen[name] = v.timestamp
            table.insert(merge.characters, v.character)

        else

            --this is a newer record so update
            if v.timestamp > charactersSeen[name] then
                for k, x in ipairs(merge.characters) do
                    if x.name == name then
                        x = v.character;
                    end
                end
            end
        end
    end

    self:InsertCensus(merge)
end

function Database:GetLatestCensus()
    if self.db then
        return self.db.census[1];
    end
    return {};
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