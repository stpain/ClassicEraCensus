

local name , addon = ...;

addon.locales = {};

addon.locales.enUS = {

    --these are lower case on purpose
    human = "Human",
    dwarf = "Dwarf",
    gnome = "Gnome",
    nightelf = "Night Elf",
    orc = "Orc",
    undead = "Undead",
    troll = "Troll",
    tauren = "Tauren",

    druid = "Druid",
    hunter = "Hunter",
    mage = "Mage",
    priest = "Priest",
    paladin = "Paladin",
    shaman = "Shaman",
    rogue = "Rogue",
    warrior = "Warrior",
    warlock = "Warlock",

    --use capital for rest of the locales
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
    HOME_FILTERS_HELPTIP = "Adjust the level range and race/class filters to view data.\n\nIf no results show try selecting all races.",

    CUSTOM_CENSUS_COOP_HELPTIP = "Enter a players name here to send them the custom census. Once its been competed it'll be sent back to you.",
    CUSTOM_CENSUS_FILTERS_HELPTIP = "Select which races, classes or level range you want to include in a custom census.",

    HELP_ABOUT = "ClassicEraCensus is an addon that aims to collect population data for the WoW Classic Era servers.\n\nDue to the nature of conducting a census they can take a long time on high pop servers. To aid with this the addon allows multiple people to each conduct a smaller part of a census. The main organiser can then merge all the results to create a full census record."
}

addon.locales.deDE = {

}

addon.locales.frFR = {

}