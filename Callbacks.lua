

local name, addon = ...;

Mixin(addon, CallbackRegistryMixin)
addon:GenerateCallbackEvents({
    "Database_OnInitialised",
    "Database_OnCensusTableChanged",
    "Database_OnConfigChanged",

    "Database_OnMergeConfirmed",

    "Census_OnSelectionChanged",
    "Census_OnMultiSelectChanged",
    "Census_OnGuildSelectionChanged",

    "Census_OnFinished",

})
CallbackRegistryMixin.OnLoad(addon);