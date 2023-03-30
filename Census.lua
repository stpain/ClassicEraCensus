

local name, addon = ...;

local Census = {}

Census.factions = {
    alliance = {
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
    horde = {
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
Census.nameLetters = {}
for _, letter1 in ipairs(alphabet) do
    for _, letter2 in ipairs(alphabet) do
        table.insert(Census.nameLetters, string.format("%s%s", letter1, letter2))
    end
end


function Census:RefineWhoParams()

    ClassicEraCensusUI:AddLogMessage("|cffB0F70E-> RefineWhoParams")

    local index = self.currentQueryIndex;
    local query = self.whoQueries[index]

    ClassicEraCensusUI:AddLogMessage(string.format("who query '%s'", query.who))

    local rangeSet;
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

    ClassicEraCensusUI:AddLogMessage(string.format("using level ranges %s", self.currentLevelRange))

    table.remove(self.whoQueries, index)
    ClassicEraCensusUI:AddLogMessage("removing current who query as it returns 50+ results")

    if rangeSet ~= nil then
        for _, range in ipairs(rangeSet) do

            local minL, maxL = strsplit("-", range)
            minL = tonumber(minL)
            maxL = tonumber(maxL)

            if (minL >= query.minLevel) and (maxL <= query.maxLevel) then

                ClassicEraCensusUI:AddLogMessage(string.format("adding level range %d-%d", minL, maxL))

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

    else

        ClassicEraCensusUI:AddLogMessage("no rangeSet selected")

        for k, letters in ipairs(self.nameLetters) do
            local who = string.format([[r-"%s" c-"%s" %d-%d n-"%s"]], query.race, query.class, query.minLevel, query.maxLevel, letters)
            table.insert(self.whoQueries, index, {
                who = who,
                race = query.race,
                class = query.class,
                minLevel = query.minLevel,
                maxLevel = query.maxLevel,
            })
            index = index + 1;
        end

    end

end



function Census:GetProgress()
    
end

function Census:CreateRecord()
    
    local census = {
        author = self.meta.author,
        timestamp = self.meta.timestamp,
        realm = self.meta.realm,
        region = self.meta.region,
        faction = self.meta.faction,
        characters = self.characters,
    }

    return census;

end

function Census:ProcessWhoResults()

    local numResults = C_FriendList.GetNumWhoResults()

    ClassicEraCensusUI:AddLogMessage(string.format("Process who results, %d characters", numResults))

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
            character.fullGuildName = ">< No Guild ><"
        end

        if not self.charactersSeen[character.fullName] then
            table.insert(self.characters, {
                race = character.raceStr,
                class = character.filename,
                guild = character.fullGuildName,
                gender = character.gender == 2 and "male" or "female",
                level = character.level,
                name = character.fullName,
            })
            self.charactersSeen[character.fullName] = true;

        else
            for k, v in ipairs(self.characters) do
                if (v.fullName == character.fullName) then
                    v = {
                        race = character.raceStr,
                        class = character.filename,
                        guild = character.fullGuildName or " - ",
                        gender = character.gender == 2 and "male" or "female",
                        level = character.level,
                        name = character.fullName,
                    }
                end
            end
        end

    end

    self.currentLevelRange = 60;

    self.currentQueryIndex = self.currentQueryIndex + 1;

    if self.currentQueryIndex > #self.whoQueries then
        addon:TriggerEvent("Census_OnFinished")
    end
end

function Census:AttemptNextWhoQuery()

    if time() > (self.previousWhoAttemptTime + 2) then

        --check if the previous query involved level ranges
        local query = self.whoQueries[self.currentQueryIndex]
        
        ClassicEraCensusUI:AddLogMessage(string.format("Attempting who '%s'", query.who))

        C_FriendList.SendWho(query.who)

        self.previousWhoAttemptTime = time()
    end
end


function Census:New(author, realm, faction, region)

    local whoQueries = {}
    
    for race, classes in pairs(self.factions.alliance) do
        for _, class in ipairs(classes) do
            table.insert(whoQueries, {
                who = string.format([[r-"%s" c-"%s" 1-60]], race, class),
                race = race,
                class = class,
                minLevel = 1,
                maxLevel = 60,
            })
        end
    end

    return Mixin({
        meta = {
            timestamp = time(),
            author = string.format("%s-%s", author, realm),
            realm = realm,
            region = region,
            faction = faction,
        },
        currentQueryIndex = 1,
        currentLevelRange = 60,
        whoQueries = whoQueries,
        charactersSeen = {},
        characters = {},
        previousWhoAttemptTime = time(),
        previousQuery = nil,
    }, self)

end

addon.Census = Census;