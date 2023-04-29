

local name, addon = ...;

local Database = addon.db;

local EXPANSION = GetServerExpansionLevel()

local locale = GetLocale()

local Census = {}

Census.version = tonumber(GetAddOnMetadata(name, "Version"));

Census.factions = {
    Alliance = {
        human = {
            "mage",
            "warrior",
            "paladin",
            "rogue",
            "warlock",
            "priest",
        },
        dwarf = {
            "warrior",
            "paladin",
            "rogue",
            "hunter",
            "priest",
        },
        ["night elf"] = {
            "warrior",
            "rogue",
            "priest",
            "hunter",
            "druid",
        },
        gnome = {
            "mage",
            "warrior",
            "rogue",
            "warlock"
        }
    },
    Horde = {
        orc = {
            "warrior",
            "shaman",
            "rogue",
            "warlock",
            "hunter",
        },
        troll = {
            "warrior",
            "shaman",
            "rogue",
            "hunter",
            "priest",
        },
        tauren = {
            "warrior",
            "hunter",
            "druid",
            "shaman",
        },
        undead = {
            "mage",
            "warrior",
            "rogue",
            "warlock",
            "priest",
        },
    },
}

Census.levelRanges20 = {
    "1-19",
    "20-39",
    "40-59",
    "60-60",
}
Census.levelRanges10 = {
    "1-9",
    "10-19",
    "20-29",
    "30-39",
    "40-49",
    "50-59",
    "60-60",
}
Census.levelRanges5 = {
    "1-4",
    "5-9",
    "10-14",
    "15-19",
    "20-24",
    "25-29",
    "30-34",
    "35-39",
    "40-44",
    "45-49",
    "50-54",
    "55-59",
    "60-60",
}
Census.levelRanges1 = {}
for i = 1, 60 do
    Census.levelRanges1[i] = string.format("%d-%d", i, i)
end
local alphabet = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", }
Census.nameLetter1 = {}
Census.nameLetter2 = {}
for _, letter1 in ipairs(alphabet) do
    table.insert(Census.nameLetter1, letter1)
    for _, letter2 in ipairs(alphabet) do
        table.insert(Census.nameLetter2, string.format("%s%s", letter1, letter2))
    end
end

function Census:GetCharactersTotalXP(currentLevel)

    local xp = 0;
    if type(currentLevel) == "number" then
        for i = 1, (currentLevel - 1) do
            xp = xp + addon.levelXpValues[EXPANSION][i]
        end
    end
    return xp;
end

--hacked to fix bug
function Census:UpdateQueryLog()
    if type(self.whoQueries) == "table" then
        local log = ClassicEraCensusUI.log.queryListview;
        log.DataProvider:Flush();
        for k, v in ipairs(self.whoQueries) do
            log.DataProvider:Insert({
                type = "info",
                message = string.format("[%d] %s", k, v.who),
            })
        end
    end
end

--this function will inject who queries based on the current query, it increases the depth of the query until <50 results are returned
function Census:RefineWhoParams()

    local index = 1-- self.currentQueryIndex;
    local query = self.whoQueries[index]

    addon:TriggerEvent("Census_LogMessage", "who", string.format("current query: %s", query.who))
    addon:TriggerEvent("Census_LogMessage", "warning", "removing current query as it returns 50+ results")
    addon:TriggerEvent("Census_LogMessage", "warning", string.format("current level range is %d", self.currentLevelRange))
    

    local rangeSet;
    --if query.minLevel ~= query.maxLevel then

        if self.currentLevelRange == 60 then
            rangeSet = self.levelRanges20;
            self.currentLevelRange = 20;

        elseif self.currentLevelRange == 20 then
            rangeSet = self.levelRanges10;
            self.currentLevelRange = 10;

        elseif self.currentLevelRange == 10 then
            rangeSet = self.levelRanges5;
            self.currentLevelRange = 5;

        elseif self.currentLevelRange == 5 then
            rangeSet = self.levelRanges1;
            self.currentLevelRange = 1;

        end

    --end

    addon:TriggerEvent("Census_LogMessage", "info", string.format("using level ranges %s", self.currentLevelRange))

    self:UpdateQueryLog();

    table.remove(self.whoQueries, index)

    self:UpdateQueryLog();

    if rangeSet ~= nil then
        for _, range in ipairs(rangeSet) do

            local minL, maxL = strsplit("-", range)
            minL = tonumber(minL)
            maxL = tonumber(maxL)

            if (minL >= query.minLevel) and (maxL <= query.maxLevel) then

                addon:TriggerEvent("Census_LogMessage", "info", string.format("adding level range %d-%d", minL, maxL))

                local who = string.format([[r-"%s" c-"%s" %s]], query.race, query.class, range)
                table.insert(self.whoQueries, index, {
                    who = who,
                    race = query.race,
                    class = query.class,
                    minLevel = minL,
                    maxLevel = maxL,
                })
                index = index + 1;
            end
        end

        self:UpdateQueryLog();

    else

        addon:TriggerEvent("Census_LogMessage", "warning", "no rangeSet selected")

        if not query.zone then

            addon:TriggerEvent("Census_LogMessage", "info", "trying to reduce results using zones")

            for k, zone in ipairs(self.zones) do

                if locale ~= "enUS" then
                    zone = addon.locales[locale][zone]
                end

                local who = string.format([[r-"%s" c-"%s" %d-%d z-"%s"]], query.race, query.class, query.minLevel, query.maxLevel, zone)
                table.insert(self.whoQueries, index, {
                    who = who,
                    race = query.race,
                    class = query.class,
                    minLevel = query.minLevel,
                    maxLevel = query.maxLevel,
                    zone = zone,
                })
                index = index + 1;
            end

        else

            if not query.name then

                addon:TriggerEvent("Census_LogMessage", "info", "trying to reduce results using player names 1 letter")

                for k, letter in ipairs(self.nameLetters) do
                    local who = string.format([[r-"%s" c-"%s" %d-%d n-"%s"]], query.race, query.class, query.minLevel, query.maxLevel, letter)
                    table.insert(self.whoQueries, index, {
                        who = who,
                        race = query.race,
                        class = query.class,
                        minLevel = query.minLevel,
                        maxLevel = query.maxLevel,
                        name = letter
                    })
                    index = index + 1;
                end

            else

                if #query.name == 1 then

                    addon:TriggerEvent("Census_LogMessage", "info", "trying to reduce results using player names 2 letters")

                    for k, letters in ipairs(self.nameLetters2) do
                        local who = string.format([[r-"%s" c-"%s" %d-%d n-"%s"]], query.race, query.class, query.minLevel, query.maxLevel, letters)
                        table.insert(self.whoQueries, index, {
                            who = who,
                            race = query.race,
                            class = query.class,
                            minLevel = query.minLevel,
                            maxLevel = query.maxLevel,
                            name = letters
                        })
                        index = index + 1;
                    end

                else

                    --likely now going deeper will cause the census to become to long to realistically record during a game play session
                    --that is unless its a customized census involving just 1 race for example - this needs configuring in the options tab

                    self:ProcessWhoResults()
                    
                end

            end
        end


    end

end



function Census:GetProgress()

    return {
        elapsed = (time() - self.meta.timestamp),
        percent = (self.currentQueryIndex / #self.whoQueries) * 100,
        characterCount = #self.characters,
        currentWho = self.whoQueries[self.currentQueryIndex],
        currentIndex = self.currentQueryIndex,
        numQueries = #self.whoQueries,
    };

end

function Census:CreateRecord()

    return {
        author = self.meta.author,
        timestamp = self.meta.timestamp,
        realm = self.meta.realm,
        region = self.meta.region,
        faction = self.meta.faction,
        characters = self.characters,
        customFilters = self.meta.customFilters,
        locale = locale,
        version = self.version,
    }

end

function Census:ProcessWhoResults()

    local numResults = C_FriendList.GetNumWhoResults()

    addon:TriggerEvent("Census_LogMessage", "info", string.format("Process who results, %d characters", numResults))

    for i = 1, numResults do

        local character = C_FriendList.GetWhoInfo(i)

        --DevTools_Dump(character)

        --update the name to name-realm format using current player realm info
        if not character.fullName:find("-") then
            local _, realm = UnitFullName("player");
            if realm == nil or realm == "" then
                realm = GetNormalizedRealmName();
            end
            character.fullName = string.format("%s-%s", character.fullName, realm);
        end

        if character.fullGuildName == "" then
            character.fullGuildName = "-No-Guild-"
        end

        local xp = self:GetCharactersTotalXP(character.level);

        if not self.charactersSeen[character.fullName] then
            table.insert(self.characters, {
                race = character.raceStr,
                class = character.filename,
                guild = character.fullGuildName,
                gender = character.gender,
                level = character.level,
                name = character.fullName,
                xp = xp,
            })
            self.charactersSeen[character.fullName] = true;

        else
            for k, v in ipairs(self.characters) do
                if (v.fullName == character.fullName) then
                    v = {
                        race = character.raceStr,
                        class = character.filename,
                        guild = character.fullGuildName or " - ",
                        gender = character.gender,
                        level = character.level,
                        name = character.fullName,
                        xp = xp,
                    }
                end
            end
        end

    end

    table.insert(self.processedQueries, 1, self.whoQueries[1])

    addon:TriggerEvent("Census_LogMessage", "info", string.format("current level range is %s", self.currentLevelRange))
    if self.whoQueries[2] then
        local currentWhoMinLevel = self.whoQueries[2].minLevel
        local currentWhoMaxLevel = self.whoQueries[2].maxLevel
        local rangeDiff = (currentWhoMaxLevel - currentWhoMinLevel)

        local diffs = {
            [19] = 60,
            [9] = 20,
            [4] = 10,
            [1] = 5,
        }

        if diffs[rangeDiff] then
            self.currentLevelRange = diffs[rangeDiff];
        end
    end
    addon:TriggerEvent("Census_LogMessage", "info", string.format("new level range is %s", self.currentLevelRange))

    table.remove(self.whoQueries, 1)

    self:UpdateQueryLog();

    self.currentQueryIndex = 1-- = self.currentQueryIndex + 1;

    if self.currentQueryIndex > #self.whoQueries then
        addon:TriggerEvent("Census_OnFinished")
    end
end

function Census:AttemptNextWhoQuery()

    if time() > (self.previousWhoAttemptTime + 3) then

        --check if the previous query involved level ranges
        local query = self.whoQueries[self.currentQueryIndex]
        
        addon:TriggerEvent("Census_LogMessage", "who", string.format("Attempting who '%s'", query.who))

        C_FriendList.SendWho(query.who)

        self.previousWhoAttemptTime = time()

        return true;
    end
end

function Census:GenerateWhoQueries(faction, raceT, classT, levelRange)

    local whoQueries = {}

    local range = "1-60";
    local minL, maxL = 1, 60;
    if levelRange then
        range = levelRange;

        minL, maxL = strsplit("-", levelRange)
        minL = tonumber(minL)
        maxL = tonumber(maxL)
    end

    local customFilters = {};
    if raceT or classT or levelRange then
        local races;
        local classes;
        if raceT then
            races = table.concat(raceT, ",")
        end
        if classT then
            classes = table.concat(classT, ",")
        end
        customFilters = {
            races = races,
            classes = classes,
            levelRange = levelRange,
        }
        addon:TriggerEvent("Census_LogMessage", "info", string.format("creating census quries, races(%s) classes(%s) levels(%s)", races or "-", classes or "-", levelRange or "-"))
    end

    if raceT and classT then
        for _, race in ipairs(raceT) do
            for _, class in ipairs(classT) do
                table.insert(whoQueries, {
                    who = string.format([[r-"%s" c-"%s" %s]], race, class, range),
                    race = race,
                    class = class,
                    minLevel = minL,
                    maxLevel = maxL,
                })
                addon:TriggerEvent("Census_LogMessage", "info", string.format("adding %s %s to census queries", race, class))
            end
        end
    end

    if raceT and (classT == nil) then
        for _, race in ipairs(raceT) do
            for _, class in ipairs(self.factions[faction][race]) do
                table.insert(whoQueries, {
                    who = string.format([[r-"%s" c-"%s" %s]], race, class, range),
                    race = race,
                    class = class,
                    minLevel = minL,
                    maxLevel = maxL,
                })
                addon:TriggerEvent("Census_LogMessage", "info", string.format("adding %s %s to census queries", race, class))
            end
        end
    end

    if (raceT == nil) and classT then
        for _,class in ipairs(classT) do
            for race, classes in pairs(self.factions[faction]) do
                for _, _class in ipairs(classes) do
                    if _class == class then
                        table.insert(whoQueries, {
                            who = string.format([[r-"%s" c-"%s" %s]], race, class, range),
                            race = race,
                            class = class,
                            minLevel = minL,
                            maxLevel = maxL,
                        })
                        addon:TriggerEvent("Census_LogMessage", "info", string.format("adding %s %s to census queries", race, class))
                    end
                end
            end
        end
    end

    if (raceT == nil) and (classT == nil) then
        for race, classes in pairs(self.factions[faction]) do
            for _, class in ipairs(classes) do
                table.insert(whoQueries, {
                    who = string.format([[r-"%s" c-"%s" %s]], race, class, range),
                    race = race,
                    class = class,
                    minLevel = minL,
                    maxLevel = maxL,
                })
            end
        end
    end

    return whoQueries, customFilters
end

function Census:NewCoopCensus(request)

    local name, realm = UnitFullName("player");
    if realm == nil or realm == "" then
        realm = GetNormalizedRealmName();
    end

    local zones = self:CreateZoneList(request.ignoredZones);
    
    return Mixin({
        meta = {
            requestAuthor = string.format("%s-%s", request.author, request.realm),
            timestamp = time(),
            author = string.format("%s-%s", name, realm),
            realm = request.realm,
            region = request.region,
            faction = request.faction,
            customFilters = request.customFilters,
        },
        currentQueryIndex = 1,
        currentLevelRange = 60,
        whoQueries = request.whoQueries,
        charactersSeen = {},
        characters = {},
        previousWhoAttemptTime = time(),
        previousQuery = nil,
        zones = zones,
        processedQueries = {},
    }, self)

end

function Census:New(author, realm, faction, region, raceT, classT, levelRange)

    local whoQueries, customFilters = self:GenerateWhoQueries(faction, raceT, classT, levelRange)

    self:UpdateQueryLog();

    local zones = self:CreateZoneList();

    return Mixin({
        meta = {
            timestamp = time(),
            author = string.format("%s-%s", author, realm),
            realm = realm,
            region = region,
            faction = faction,
            customFilters = customFilters,
        },
        currentQueryIndex = 1,
        currentLevelRange = 60,
        whoQueries = whoQueries,
        charactersSeen = {},
        characters = {},
        previousWhoAttemptTime = time(),
        previousQuery = nil,
        zones = zones,
        processedQueries = {},
    }, self)

end


function Census:CreateZoneList(ids)

    local zones = {}

    if type(ids) == "table" then
        
        for k, zone in ipairs(addon.zones[EXPANSION]) do
            local ignored = false
            for _, id in ipairs(ids) do
                if k == id then
                    ignored = true
                end
            end
            if ignored == false then
                table.insert(zones, zone)
            end
        end
    
    else
        for k, zone in ipairs(addon.zones[EXPANSION]) do
        
            local ignored = Database:GetConfig(zone, "ignoredZones");
            if ignored == true then
                --it could be false or nil so only act if its true
            else
                table.insert(zones, zone)
            end
        end
    end

    return zones;
end


addon.Census = Census;