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

AutoRoll.ADDON_PREFIX = ITEM_QUALITY_COLORS[AutoRoll.ITEM_QUALITY.ARTIFACT].hex.."[AutoRoll]: "..FONT_COLOR_CODE_CLOSE
function AutoRoll:Print(string)
	DEFAULT_CHAT_FRAME:AddMessage(self.ADDON_PREFIX..tostring(string))
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

function AutoRoll:SetItem(itemID, rollValue)
	AutoRollData.items[itemID] = rollValue
	if rollValue then
		return self:Print("Automatically rolling "..self.TEXT[rollValue].." on "..self:GetItemLink(itemID))
	end

	self:Print("Removed roll automation for "..self:GetItemLink(itemID))
end

function AutoRoll:MuteRolls(mute)
	AutoRollData.settings.muteRolls = mute
	if mute then
		return self:Print("Muting individual roll values. Showing only win and received.")
	end

	return self:Print("Showing all roll values.")
end

function AutoRoll:SetRaidRoll(rollValue)
	AutoRollData.raid = rollValue
	if rollValue then
		return self:Print("Automatically rolling "..self.TEXT[rollValue].. " on items in Raid instances.")
	end

	self:Print("Removed roll automation in Raid instances.")
end

function AutoRoll:ConfirmPopup(popupName)
	for i=1,STATICPOPUP_NUMDIALOGS do
		local frame = getglobal("StaticPopup"..i)
		if frame.which == popupName and frame:IsShown() then
			local bindConfirmButton = getglobal("StaticPopup"..i.."Button1")
			return bindConfirmButton:Click()
		end
	end
end

function AutoRoll:OnLootBindConfirm()
	local lootSlotID = arg1
	local lootSlotLinkID = arg1

	-- Always auto approve when solo
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
		self:ConfirmPopup(self.STATIC_POPUP.LOOT_BIND)
		LootSlot(lootSlotID) -- this does not work so far. Check if it can be removed.
		return
	end

	-- LootSlot() function / arg1 lootSlotID does not include the "money item" as an index
	-- GetLootSlotLink() function does includes the "money item" as an index
	for i=1,GetNumLootItems() do
		if LootSlotIsCoin(i) and i <= lootSlotLinkID then
			lootSlotLinkID = lootSlotLinkID + 1
			break
		end
	end

	local itemID = self:GetItemIDFromLink(GetLootSlotLink(lootSlotLinkID))
	local rollValue = AutoRollData.items[itemID]
	if rollValue and rollValue > 0 then
		self:ConfirmPopup(self.STATIC_POPUP.LOOT_BIND)
		LootSlot(lootSlotID) -- this does not work so far. Check if it can be removed.
	end
end

function AutoRoll:OnLootOpened()
	-- Always auto approve when solo
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
		for i=1,GetNumLootItems() do
			LootSlot(i)
		end
		return
	end

	local moneySlotID
	for i=1,GetNumLootItems() do
		local lootSlotID = i
		local lootSlotLinkID = i

		if LootSlotIsCoin(i) then
			moneySlotID = i
			break
		end

		-- LootSlot() function does not include the "money item" as an index
		-- GetLootSlotLink() function does includes the "money item" as an index
		if moneySlotID then
			lootSlotID = lootSlotID - 1
		end

		local itemID = self:GetItemIDFromLink(GetLootSlotLink(lootSlotLinkID))
		local rollValue = AutoRollData.items[itemID]
		if rollValue and rollValue > 0 then
			LootSlot(lootSlotID)
		end

		rollValue = AutoRollData.raid
		if self:IsInRaidInstance() and rollValue and rollValue > 0 then
			LootSlot(lootSlotID)
		end
	end
end

function AutoRoll:OnStartLootRoll()
	local rollID = arg1

	local itemLink = GetLootRollItemLink(rollID)
	local itemID = self:GetItemIDFromLink()
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
	local rollValue = AutoRollData.items[itemID]
	if rollValue then
		self:ConfirmPopup(self.STATIC_POPUP.CONFIRM_LOOT_ROLL)
	end

	rollValue = AutoRollData.raid
	if self:IsInRaidInstance() and rollValue then
		self:ConfirmPopup(self.STATIC_POPUP.CONFIRM_LOOT_ROLL)
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

function AutoRoll:GetRollValue(arg)
	if arg == "need" or arg == "greed" or arg == "pass" then
		return AutoRoll.ACTION[string.upper(arg)]
	end

	if arg == "remove" then
		return nil
	end

	return -1
end

local helpMessage = [[
--- Valid commands ---
	Single item: /ar (need|greed|pass|remove) (itemID|itemLink)
	Raid setting: /ar raid (need|greed|pass|remove)
	Mute rolls: /ar (mute|unmute)
	Show this message: /ar help
]]

function AutoRoll:OnAddonLoaded()
	self:UnregisterEvent("ADDON_LOADED")

	self:RegisterEvent("LOOT_BIND_CONFIRM")
	self:RegisterEvent("LOOT_OPENED")

	self:RegisterEvent("START_LOOT_ROLL")
	self:RegisterEvent("CONFIRM_LOOT_ROLL")

	AutoRollData = AutoRollData or {
		items = {},
		raid = nil, -- need / greed / pass in raid instance as fallback after items has been checked
		settings = {
			muteRolls = false
		}
	}

	self.BlizzardFunctions = {
		ChatFrame_OnEvent = ChatFrame_OnEvent
	}

	ChatFrame_OnEvent = self.ChatFrame_OnEvent

	SLASH_AUTOROLL1 = "/ar"
	SLASH_AUTOROLL2 = "/autoroll"
	SlashCmdList["AUTOROLL"] = function(msg)
		local _, _, cmd, arg = string.find(string.lower(msg), "%s?(%a+)%s?(.*)")

		if cmd == "help" then
			return self:Print(helpMessage)
		end

		if cmd == "mute" then
			return self:MuteRolls(true)
		end
		if cmd == "unmute" then
			return self:MuteRolls(false)
		end

		if cmd == "raid" then
			local rollValue = self:GetRollValue(arg)
			if rollValue == -1 then
				return self:Print(string.format("Unknown argument: '%s'. Type '/ar help' to learn the commands", arg))
			end

			return self:SetRaidRoll(rollValue)
		end

		local rollValue = self:GetRollValue(cmd)
		if rollValue == -1 then
			return self:Print(string.format("Unknown argument: '%s'. Type '/ar help' to learn the commands", cmd))
		end

		local itemID = self:ValidateItemArg(arg)
		if not itemID then
			return self:Print(string.format("Unknown argument: '%s'. Type '/ar help' to learn the commands", arg))
		end

		return self:SetItem(itemID, rollValue)
	end

	self:Print("Addon loaded. Do /ar or /autoroll for help")
end

function AutoRoll:OnEvent()
	if event == "ADDON_LOADED" and arg1 == "AutoRoll" then
		return AutoRoll:OnAddonLoaded()
	end

	if event == "LOOT_BIND_CONFIRM" then
		return AutoRoll:OnLootBindConfirm()
	end

	if evenet == "START_LOOT_ROLL" then
		return AutoRoll:OnStartLootRoll()
	end

	if event == "CONFIRM_LOOT_ROLL" then
		return AutoRoll:OnConfirmLootRoll()
	end
end

AutoRoll:SetScript("OnEvent", AutoRoll.OnEvent)
AutoRoll:RegisterEvent("ADDON_LOADED")