

local name, addon = ...;

addon.levelXpValues = {
    [0] = {
        [1] = 400,
        [2] = 900,
        [3] = 1400,
        [4] = 2100,
        [5] = 2800,
        [6] = 3600,
        [7] = 4500,
        [8] = 5400,
        [9] = 6500,
        [10] = 7600,
        [11] = 8800,
        [12] = 10100,
        [13] = 11400,
        [14] = 12900,
        [15] = 14400,
        [16] = 16000,
        [17] = 17700,
        [18] = 19400,
        [19] = 21300,
        [20] = 23200,
        [21] = 25200,
        [22] = 27300,
        [23] = 29400,
        [24] = 31700,
        [25] = 34000,
        [26] = 36400,
        [27] = 38900,
        [28] = 41400,
        [29] = 44300,
        [30] = 47400,
        [31] = 50800,
        [32] = 54500,
        [33] = 58600,
        [34] = 62800,
        [35] = 67100,
        [36] = 71600,
        [37] = 76100,
        [38] = 80800,
        [39] = 85700,
        [40] = 90700,
        [41] = 95800,
        [42] = 101000,
        [43] = 106300,
        [44] = 111800,
        [45] = 117500,
        [46] = 123200,
        [47] = 129100,
        [48] = 135100,
        [49] = 141200,
        [50] = 147500,
        [51] = 153900,
        [52] = 160400,
        [53] = 167100,
        [54] = 173900,
        [55] = 180800,
        [56] = 187900,
        [57] = 195000,
        [58] = 202300,
        [59] = 209800,
        [60] = 217400,
    }
}

addon.zones = {
    [0] = {
        [[Ahn'Qiraj]],
        [[Alterac Mountains]],
        [[Alterac Valley]],
        [[Arathi Basin]],
        [[Arathi Highlands]],
        [[Ashenvale]],
        [[Azshara]],
        [[Badlands]],
        [[Blackfathom Deeps]],
        [[Blackrock Depths]],
        [[Blackrock Mountain]],
        [[Blackrock Spire]],
        [[Blackwing Lair]],
        [[Blasted Lands]],
        [[Burning Steppes]],
        [[Caverns of Time]],
        [[Darkshore]],
        [[Darnassus]],
        [[Deadwind Pass]],
        [[Deeprun Tram]],
        [[Desolace]],
        [[Dire Maul]],
        [[Dun Morogh]],
        [[Durotar]],
        [[Duskwood]],
        [[Dustwallow Marsh]],
        [[Eastern Plaguelands]],
        [[Elwynn Forest]],
        [[Emerald Forest]],
        [[Felwood]],
        [[Feralas]],
        [[Gnomeregan]],
        [[Hillsbrad Foothills]],
        [[Ironforge]],
        [[Loch Modan]],
        [[Maraudon]],
        [[Molten Core]],
        [[Moonglade]],
        [[Mulgore]],
        [[Naxxramas]],
        [[Onyxia's Lair]],
        [[Orgrimmar]],
        [[Ragefire Chasm]],
        [[Razorfen Downs]],
        [[Razorfen Kraul]],
        [[Redridge Mountains]],
        [[Ruins of Ahn'Qiraj]],
        [[Scarlet Monastery]],
        [[Scholomance]],
        [[Searing Gorge]],
        [[Shadowfang Keep]],
        [[Silithus]],
        [[Silverpine Forest]],
        [[Stonetalon Mountains]],
        [[Stormwind City]],
        [[Stranglethorn Vale]],
        [[Stratholme]],
        [[Sunken Temple]],
        [[Swamp of Sorrows]],
        [[Tanaris]],
        [[Teldrassil]],
        [[The Barrens]],
        [[The Deadmines]],
        [[The Great Sea]],
        [[The Hinterlands]],
        [[The Stockade]],
        [[The Temple of Atal'Hakkar]],
        [[The Veiled Sea]],
        [[Thousand Needles]],
        [[Thunder Bluff]],
        [[Tirisfal Glades]],
        [[Uldaman]],
        [[Un'Goro Crater]],
        [[Undercity]],
        [[Wailing Caverns]],
        [[Warsong Gulch]],
        [[Western Plaguelands]],
        [[Westfall]],
        [[Wetlands]],
        [[Winterspring]],
        [[Zul'Farrak]],
        [[Zul'Gurub]],
    }
};


addon.factions = {
    [0] = {
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
}
