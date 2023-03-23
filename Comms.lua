

local name, addon = ...;

local AceComm = LibStub:GetLibrary("AceComm-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("LibSerialize")

local Comms = {};
Comms.prefix = name;
Comms.version = 0;

function Comms:Init()
    
    AceComm:Embed(self);
    self:RegisterComm(self.prefix);

    self.version = tonumber(GetAddOnMetadata(name, "Version"));

end


function Comms:BroadcastGuildData(data, channel)

    local inInstance, instanceType = IsInInstance()
    if instanceType ~= "none" then
        return;
    end
    local inLockdown = InCombatLockdown()
    if inLockdown then
        return;
    end

    if IsInGuild() and GetGuildInfo("player") then

    else
        return;
    end
    
    -- add the version and sender guid to the message
    data.version = self.version;

    local serialized = LibSerialize:Serialize(data);
    local compressed = LibDeflate:CompressDeflate(serialized);
    local encoded    = LibDeflate:EncodeForWoWAddonChannel(compressed);

    if encoded and channel then
        self:SendCommMessage(self.prefix, encoded, channel, nil, "NORMAL")
    end
    
end

function Comms:OnCommReceived(prefix, message, distribution, sender)

    if prefix ~= self.prefix then 
        return 
    end
    local decoded = LibDeflate:DecodeForWoWAddonChannel(message);
    if not decoded then
        return;
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded);
    if not decompressed then
        return;
    end
    local success, data = LibSerialize:Deserialize(decompressed);
    if not success or type(data) ~= "table" then
        return;
    end

end

addon.Comms = Comms;