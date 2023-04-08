

local name, addon = ...;

Mixin(addon, CallbackRegistryMixin)
addon:GenerateCallbackEvents({
    "Database_OnInitialised",
    "Database_OnCensusTableChanged",
    "Database_OnConfigChanged",

    "Database_OnMergeConfirmed",

    "Census_OnMultiSelectChanged",
    "Census_OnGuildSelectionChanged",

    "Census_OnFinished",
    "Census_LogMessage",
    "Census_OnCoopCensusRequestAccepted",

    "Comms_OnMessageReceived",

})
CallbackRegistryMixin.OnLoad(addon);