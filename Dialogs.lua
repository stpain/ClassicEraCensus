

local addonName, addon = ...;

local Database = addon.db;

StaticPopupDialogs["ClassicEraCensusMergeConfirm"] = {
    text = "Do you want to merge these census records?",
    button1 = YES,
    button2 = NO,
    OnShow = function(self)
        self.button1:Disable()
        self.editBox:SetText("Enter merge name")
    end,
    OnAccept = function(self, censusGroup)
        Database:CreateMerge(censusGroup, self.editBox:GetText())
    end,
    OnCancel = function(self)

    end,
    EditBoxOnTextChanged = function (self, data)
        if (self:GetText() == "") or (self:GetText():find(" ")) then
            self:GetParent().button1:Disable()
        else
            self:GetParent().button1:Enable()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    showAlert = 1,
    hasEditBox = true,
}

StaticPopupDialogs["ClassicEraCensusDeleteConfirm"] = {
    text = "Do you want to delete these census records?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, censusGroup)
        Database:DeleteCensus(censusGroup)
    end,
    OnCancel = function(self)

    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    showAlert = 1,
}

StaticPopupDialogs["ClassicEraCensusAcceptCoopCensusRequest"] = {
    text = "Accept co-op census request?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, censusRequest)
        addon:TriggerEvent("Census_OnCoopCensusRequestAccepted", censusRequest)
    end,
    OnCancel = function(self)

    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    showAlert = 1,
}

StaticPopupDialogs["ClassicEraCensusAcceptCoopCensusRecord"] = {
    text = "Accept co-op census request?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, censusRequest)
        addon:TriggerEvent("Census_OnCoopCensusRecordAccepted", censusRequest)
    end,
    OnCancel = function(self)

    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    showAlert = 1,
}


-- StaticPopupDialogs["VendorMateDialogVendorItemsConfirm"] = {
--     text = string.format("%s %s %s\n\n%s\n\n%s", TRANSMOG_SOURCE_3, "%s", FILTERS, "%s", L.DIALOG_VENDOR_CONFIRM),
--     button1 = YES,
--     button2 = NO,
--     button3 = CANCEL,
--     OnAccept = function(self, items)
--         vendorItems(items, true)
--     end,
--     OnAlt = function(self, items)

--     end,
--     OnCancel = function(self, items)
--         vendorItems(items, false)
--     end,
--     timeout = 0,
--     whileDead = true,
--     hideOnEscape = false,
--     preferredIndex = 3,
--     showAlert = 1,
-- }