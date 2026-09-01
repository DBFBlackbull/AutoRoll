local AutoRoll = CreateFrame("Frame")

AutoRoll.ITEM_QUALITY = {
	POOR = 0,      -- Gray
	COMMON = 1,    -- White
	UNCOMMON = 2,  -- Green
	RARE = 3,      -- Blue
	EPIC = 4,      -- Purple
	LEGENDARY = 5, -- Orange
	ARTIFACT = 6,  -- Light Gold
}

AutoRoll.STATIC_POPUP = {
	LOOT_BIND = "LOOT_BIND",
	CONFIRM_LOOT_ROLL = "CONFIRM_LOOT_ROLL",
}

AutoRoll.ACTION = {
	NEED = 1,
	GREED = 2,
	PASS = 0,
}

AutoRoll.TEXT = {
	[1] = "Need",
	[2] = "Greed",
	[0] = "Pass",
}

AutoRoll.ARGENT_DAWN = {
	-- Scourgestones
	[12840] = true,
	[12841] = true,
	[12843] = true,
	-- Healthy Dragon Scale
	[13920] = true,
}

AutoRoll.MC = {
	[11382] = true, -- Blood of the Mountain
	[17010] = true, -- Fiery Core
	[17011] = true, -- Lava Core
}

AutoRoll.BWL = {
	[19183] = true, -- Hourglass Sand
	[18562] = true, -- Elementium Ore
}

AutoRoll.ZG = {
	COINS = {
		[19698] = true,
		[19699] = true,
		[19700] = true,
		[19701] = true,
		[19702] = true,
		[19703] = true,
		[19704] = true,
		[19705] = true,
		[19706] = true,
	},
	BIJOUS = {
		[19707] = true,
		[19708] = true,
		[19709] = true,
		[19710] = true,
		[19711] = true,
		[19712] = true,
		[19713] = true,
		[19714] = true,
		[19715] = true,
	},
	CRAFT = {
		[19726] = true, -- Bloodvine
		[19774] = true, -- Souldarite
	},
}

AutoRoll.AQ = {
	SCARABS = {
		-- Scarabs
		[20858] = true,
		[20859] = true,
		[20860] = true,
		[20861] = true,
		[20862] = true,
		[20863] = true,
		[20864] = true,
		[20865] = true,
		-- Scarab Bag
		[21156] = true,
	},
	IDOLS = {
		-- Idols
		[20866] = true,
		[20867] = true,
		[20868] = true,
		[20869] = true,
		[20870] = true,
		[20871] = true,
		[20872] = true,
		[20873] = true,
		[20874] = true,
		[20875] = true,
		[20876] = true,
		[20877] = true,
		[20878] = true,
		[20879] = true,
		[20881] = true,
		[20882] = true,
		-- Scarab Coffer Keys
		[21761] = true,
		[21762] = true,
	},
	MOUNTS = {
		[21218] = true,
		[21321] = true,
		[21323] = true,
		[21324] = true,
	},
}

AutoRoll.Naxx = {
	[23055] = true, -- Word of Thawing
	[22682] = true, -- Frozen Rune
	-- Wartorn Scrap
	[22373] = true,
	[22374] = true,
	[22375] = true,
	[22376] = true,
}

AutoRoll.SCOURGE_INVASION = {
	[22484] = true, -- Necrotic Rune
	[23091] = true, -- Cloth   Undead Cleansing Bracers
	[23085] = true, -- Cloth   Undead Cleansing Chest
	[23093] = true, -- Leather Undead Slaying Bracers
	[23089] = true, -- Leather Undead Slaying Chest
	[23092] = true, -- Mail    Undead Slaying Bracers
	[23088] = true, -- Mail    Undead Slaying Chest
	[23090] = true, -- Plate   Undead Slaying Bracers
	[23087] = true, -- Plate   Undead Slaying Chest
}

local function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		local idx = 0
		for k,v in pairs(o) do
			local key = k
			if type(k) ~= 'number' then
				key = '"'..key..'"'
			end

			if idx > 0 then
				s = s .. ', '
			end
			s = s .. '['..key..'] = ' .. dump(v)
			idx = idx + 1
		end
		return s .. '} '
	end

	return tostring(o)
end


AutoRoll.ADDON_PREFIX = ITEM_QUALITY_COLORS[AutoRoll.ITEM_QUALITY.ARTIFACT].hex.."[AutoRoll]: "
function AutoRoll:Print(string)
	DEFAULT_CHAT_FRAME:AddMessage(self.ADDON_PREFIX..tostring(string)..FONT_COLOR_CODE_CLOSE)
end

function AutoRoll:GetItemIDFromLink(itemLink)
	if not itemLink then
		return
	end

	local foundID, _ , itemID = string.find(itemLink, "item:(%d+)")
	if not foundID then
		return
	end

	return tonumber(itemID)
end

function AutoRoll:GetItemLink(itemID)
	local itemName, itemLink, itemQuality = GetItemInfo(itemID)
	if itemName and itemLink and itemQuality then
		local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
		local hyperLink = hex.. "|H".. itemLink .."|h["..itemName.."]|h" .. FONT_COLOR_CODE_CLOSE
		return hyperLink
	end
end

function AutoRoll:IsInRaidInstance()
	local _, instanceType = IsInInstance()
	return instanceType == "raid"
end

function AutoRoll:GetRollValue(arg)
	if arg == "need" or arg == "greed" or arg == "pass" then
		return AutoRoll.ACTION[string.upper(arg)]
	end

	if arg == "delete" then
		return nil
	end

	return -1
end

function AutoRoll:Dump()
	self:Print("items = "..dump(AutoRollData.items))
	self:Print("raid = "..dump(AutoRollData.raid))
	self:Print("settings = "..dump(AutoRollData.settings))
end

function AutoRoll:SetItem(itemID, rollValue, skipMessage)
	AutoRollData.items[itemID] = rollValue
	if skipMessage then
		return
	end
	if rollValue then
		return self:Print(string.format("Automatically rolling %s on %s", self.TEXT[rollValue], self:GetItemLink(itemID)))
	end

	self:Print(string.format("Removed roll automation for %s", self:GetItemLink(itemID)))
end

function AutoRoll:SetItems(items, arg, itemGroup)
	local rollValue = self:GetRollValue(arg)
	if rollValue == -1 then
		return self:Print(string.format("Unknown argument: '%s'. Type '/ar help' to learn the commands", arg))
	end

	for itemID, value in pairs(items) do
		if type(value) == "table" then
			for innerItemID, _ in pairs(value) do
				self:SetItem(innerItemID, rollValue, true)
			end
		end

		if type(itemID) == "number" then
			self:SetItem(itemID, rollValue, true)
		end
	end

	if rollValue then
		return self:Print(string.format("Automatically rolling %s on %s", self.TEXT[rollValue], itemGroup))
	end

	self:Print(string.format("Removed roll automation for %s", itemGroup))
end

function AutoRoll:MuteRolls(arg)
	local isMuted = arg == "mute"
	AutoRollData.settings.muteRolls = isMuted
	if isMuted then
		return self:Print("Muting individual roll values. Showing only win and received.")
	end

	return self:Print("Showing all roll values.")
end

function AutoRoll:SetRaidRoll(arg)
	local rollValue = self:GetRollValue(arg)
	if rollValue == -1 then
		return self:Print(string.format("Unknown argument: '%s'. Type '/ar help' to learn the commands", arg))
	end

	AutoRollData.raid = rollValue
	if rollValue then
		return self:Print(string.format("Automatically rolling %s on items in Raid instances.", self.TEXT[rollValue]))
	end

	self:Print("Removed roll automation in Raid instances.")
end

function AutoRoll:ConfirmPopup(popupName, data)
	for i=1,STATICPOPUP_NUMDIALOGS do
		local frame = getglobal("StaticPopup"..i)
		if frame:IsShown() and frame.which == popupName and frame.data == data then
			getglobal("StaticPopup"..i.."Button1"):Click()
			return true
		end
	end
end

function AutoRoll:QueueBindConfirm(lootBindSlotID, lootClearedSlotID)
	--AutoRoll:Print(string.format("QueueBindConfirm bindSlotID: %s clearSlotID: %s", lootBindSlotID, lootClearedSlotID))
	self.confirm.lootBindSlotID = lootBindSlotID
	self.confirm.clearedSlotID = lootClearedSlotID
	self.confirm.tries = 0
	self:Show()
end

function AutoRoll.OnUpdate()
	--AutoRoll:Print(string.format("OnUpdate %s", tostring(arg1)))
	if not AutoRoll.confirm.lootBindSlotID then
		AutoRoll:Hide()
	end

	local isConfirmed = AutoRoll:ConfirmPopup(AutoRoll.STATIC_POPUP.LOOT_BIND, AutoRoll.confirm.lootBindSlotID)
	if isConfirmed then
		AutoRoll:Hide()
	end

	-- Safety to prevent system from going wild.
	AutoRoll.confirm.tries = AutoRoll.confirm.tries + 1
	if AutoRoll.confirm.tries > 20 then
		AutoRoll:Hide()
	end
end

function AutoRoll:SetMoneySlotID()
	if self.confirm.moneySlotID then
		return
	end

	for i=1,GetNumLootItems() do
		if LootSlotIsCoin(i) then
			self.confirm.moneySlotID = i
			return
		end
	end

	-- Hack to ignore moneySlot when not present.
	self.confirm.moneySlotID = 999
end

function AutoRoll:OnLootBindConfirm()
	local lootSlotID = arg1
	local lootSlotLinkID = arg1

	-- LootSlot() function / arg1 lootSlotID does not include the "money item" as an index
	-- GetLootSlotLink() function does includes the "money item" as an index
	self:SetMoneySlotID()
	if self.confirm.moneySlotID <= lootSlotLinkID then
		lootSlotLinkID = lootSlotLinkID + 1
	end

	--self:Print(string.format("%s lootSlotID: %s linkSlotID: %s moneySlotID: %s", event, tostring(lootSlotID), tostring(lootSlotLinkID), tostring(self.confirm.moneySlotID)))

	-- Always auto approve when solo
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
		return self:QueueBindConfirm(lootSlotID, lootSlotLinkID)
	end

	local itemID = self:GetItemIDFromLink(GetLootSlotLink(lootSlotLinkID))
	if not itemID then
		return
	end

	local rollValue = AutoRollData.items[itemID]
	if rollValue and rollValue > 0 then
		return self:QueueBindConfirm(lootSlotID, lootSlotLinkID)
	end
end

function AutoRoll:OnLootSlotCleared()
	--self:Print(event .. " " .. tostring(arg1))
	if self.confirm.clearedSlotID ~= arg1 then
		return
	end

	self.confirm.lootBindSlotID = nil
	self.confirm.clearedSlotID = nil
	self:Hide()
end

function AutoRoll:OnLootClosed()
	--self:Print(event .. " " .. tostring(arg1))
	self.confirm.moneySlotID = nil
	self.confirm.lootBindSlotID = nil
	self.confirm.clearedSlotID = nil
	self:Hide()
end

function AutoRoll:OnLootOpened()
	self:SetMoneySlotID()
end

function AutoRoll:OnStartLootRoll()
	local rollID = arg1
	local itemLink = GetLootRollItemLink(rollID)
	local itemID = self:GetItemIDFromLink(itemLink)
	if not itemID then
		return
	end

	local rollValue = AutoRollData.items[itemID]
	if rollValue then
		RollOnLoot(rollID, rollValue)
		self:Print("Rolling "..AutoRoll.TEXT[rollValue].." on "..itemLink)
	end

	rollValue = AutoRollData.raid
	if self:IsInRaidInstance() and rollValue then
		RollOnLoot(rollID, rollValue)
		self:Print("Rolling "..AutoRoll.TEXT[rollValue].." on "..itemLink)
	end
end

function AutoRoll:OnConfirmLootRoll()
	local rollID = arg1
	local itemID = self:GetItemIDFromLink(GetLootRollItemLink(rollID))
	if not itemID then
		return
	end

	local rollValue = AutoRollData.items[itemID]
	if rollValue then
		return self:ConfirmPopup(self.STATIC_POPUP.CONFIRM_LOOT_ROLL, arg1)
	end

	rollValue = AutoRollData.raid
	if self:IsInRaidInstance() and rollValue then
		return self:ConfirmPopup(self.STATIC_POPUP.CONFIRM_LOOT_ROLL, arg1)
	end
end

function AutoRoll.ChatFrame_OnEvent(event)
	if event ~= "CHAT_MSG_LOOT" then
		return AutoRoll.BlizzardFunctions.ChatFrame_OnEvent(event)
	end

	if not AutoRollData.settings.muteRolls then
		return AutoRoll.BlizzardFunctions.ChatFrame_OnEvent(event)
	end

	local isWonReceive = string.find(arg1 ,"won") or string.find(arg1 ,"receive")
	if isWonReceive then
		return AutoRoll.BlizzardFunctions.ChatFrame_OnEvent(event)
	end

	local itemID = AutoRoll:GetItemIDFromLink(arg1)
	if not itemID then
		return AutoRoll.BlizzardFunctions.ChatFrame_OnEvent(event)
	end

	local rollValue = AutoRollData.items[itemID]
	if rollValue then
		return
	end

	rollValue = AutoRollData.raid
	if AutoRoll:IsInRaidInstance() and rollValue then
		return
	end
end

function AutoRoll:ValidateItemArg(arg)
	local itemID = self:GetItemIDFromLink(arg)
	if itemID then
		return itemID
	end

	local found, _, itemID = string.find(arg, "(%d+)")
	if not found then
		return
	end

	local itemName = GetItemInfo(tonumber(itemID))
	if not itemName then
		return
	end

	return itemID
end

local helpMessage = [[
--- Valid commands ---
    Single item: /ar (need|greed|pass|delete) (itemID|itemLink)
    Argent Dawn items: /ar ad (need|greed|pass|delete)
    Scourge Invasion items: /ar si (need|greed|pass|delete)
    MC items: /ar mc (need|greed|pass|delete)
    BWL items: /ar bwl (need|greed|pass|delete)
    ZG items: /ar zg-(all|coin|bijou|craft) (need|greed|pass|delete)
    AQ items: /ar aq-(all|scarab|idol|mount) (need|greed|pass|delete)
    Naxx items: /ar naxx (need|greed|pass|delete)
    Raid setting: /ar raid (need|greed|pass|delete)
    Mute rolls: /ar (mute|unmute)
    Show all items tracked: /ar debug
    Show this message: /ar help]]

function AutoRoll:OnAddonLoaded()
	self:UnregisterEvent("ADDON_LOADED")

	AutoRollData = AutoRollData or {
		items = {},
		raid = nil, -- need / greed / pass in raid instance as fallback after items has been checked
		settings = {
			muteRolls = false
		}
	}

	self.confirm = {
		moneySlotID = nil,
		bindSlotID = nil,
		clearedSlotID = nil,
		tries = 0
	}

	self.BlizzardFunctions = {
		ChatFrame_OnEvent = ChatFrame_OnEvent
	}

	ChatFrame_OnEvent = self.ChatFrame_OnEvent

	self:RegisterEvent("LOOT_BIND_CONFIRM")
	self:RegisterEvent("LOOT_OPENED")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("LOOT_CLOSED")

	self:RegisterEvent("START_LOOT_ROLL")
	self:RegisterEvent("CONFIRM_LOOT_ROLL")

	self:Hide()
	self:SetScript("OnUpdate", self.OnUpdate)

	self:Print("Addon loaded. Do /ar or /autoroll for help")
end

function AutoRoll.OnEvent()
	if event == "ADDON_LOADED" and arg1 == "AutoRoll" then
		return AutoRoll:OnAddonLoaded()
	end

	if event == "LOOT_BIND_CONFIRM" then
		return AutoRoll:OnLootBindConfirm()
	end

	if event == "LOOT_OPENED" then
		return AutoRoll:OnLootOpened()
	end

	if event == "LOOT_SLOT_CLEARED" then
		return AutoRoll:OnLootSlotCleared()
	end

	if event == "LOOT_CLOSED" then
		return AutoRoll:OnLootClosed()
	end

	if event == "START_LOOT_ROLL" then
		return AutoRoll:OnStartLootRoll()
	end

	if event == "CONFIRM_LOOT_ROLL" then
		return AutoRoll:OnConfirmLootRoll()
	end
end

AutoRoll:SetScript("OnEvent", AutoRoll.OnEvent)
AutoRoll:RegisterEvent("ADDON_LOADED")

SLASH_AUTOROLL1 = "/ar"
SLASH_AUTOROLL2 = "/autoroll"
SlashCmdList["AUTOROLL"] = function(msg)
	local _, _, cmd, arg = string.find(string.lower(msg), "%s?([%a-]+)%s?(.*)")

	if not cmd or cmd == "" or cmd == "help" then
		return AutoRoll:Print(helpMessage)
	end

	if cmd == "debug" then
		return AutoRoll:Dump()
	end

	if cmd == "mute" or cmd == "unmute" then
		return AutoRoll:MuteRolls(cmd)
	end

	if cmd == "raid" then
		return AutoRoll:SetRaidRoll(arg)
	end

	if cmd == "ad" then
		return AutoRoll:SetItems(AutoRoll.ARGENT_DAWN, arg, "Argent Dawn reputation items.")
	end

	if cmd == "si" then
		return AutoRoll:SetItems(AutoRoll.SCOURGE_INVASION, arg, "Scourge Invasion items.")
	end

	if cmd == "mc" then
		return AutoRoll:SetItems(AutoRoll.MC, arg, "Molten Core crafting materials.")
	end

	if cmd == "bwl" then
		return AutoRoll:SetItems(AutoRoll.BWL, arg, "Blackwing Lair items.")
	end

	if cmd == "naxx" then
		return AutoRoll:SetItems(AutoRoll.Naxx, arg, "Naxxramas materials.")
	end

	if cmd == "zg-all" then
		return AutoRoll:SetItems(AutoRoll.ZG, arg, "Zul'Gurup coins, bijous, and crafting materials.")
	end

	if cmd == "zg-coin" then
		return AutoRoll:SetItems(AutoRoll.ZG.COINS, arg, "Zul'Gurup coins.")
	end

	if cmd == "zg-bijou" then
		return AutoRoll:SetItems(AutoRoll.ZG.BIJOUS, arg, "Zul'Gurup bijous.")
	end

	if cmd == "zg-craft" then
		return AutoRoll:SetItems(AutoRoll.ZG.BIJOUS, arg, "Zul'Gurup crafting materials.")
	end

	if cmd == "aq-all" then
		return AutoRoll:SetItems(AutoRoll.AQ, arg, "Ahn'Qiraj scarabs, idols, and mounts.")
	end

	if cmd == "aq-scarab" then
		return AutoRoll:SetItems(AutoRoll.AQ.SCARABS, arg, "Ahn'Qiraj scarabs.")
	end

	if cmd == "aq-idol" then
		return AutoRoll:SetItems(AutoRoll.AQ.IDOLS, arg, "Ahn'Qiraj idols.")
	end

	if cmd == "aq-mount" then
		return AutoRoll:SetItems(AutoRoll.AQ.MOUNTS, arg, "Ahn'Qiraj mounts.")
	end

	local rollValue = AutoRoll:GetRollValue(cmd)
	if rollValue == -1 then
		return AutoRoll:Print(string.format("Unknown argument: '%s'. Type '/ar help' to learn the commands", cmd))
	end

	local itemID = AutoRoll:ValidateItemArg(arg)
	if not itemID then
		return AutoRoll:Print(string.format("Unknown argument: '%s'. Type '/ar help' to learn the commands", arg))
	end

	return AutoRoll:SetItem(itemID, rollValue)
end