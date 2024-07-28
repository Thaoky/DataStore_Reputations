--[[	*** DataStore_Reputations ***
Written by : Thaoky, EU-Marécages de Zangar
June 22st, 2009
--]]
if not DataStore then return end

local addonName, addon = ...
local thisCharacter
local currentGuildName

local DataStore = DataStore
local IsInGuild, GetGuildInfo = IsInGuild, GetGuildInfo
local C_Reputation, C_MajorFactions, C_GossipInfo = C_Reputation, C_MajorFactions, C_GossipInfo
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

local FACTION_TYPE_NORMAL = 0				-- Normal faction, save : earned
local FACTION_TYPE_FRIENDSHIP = 1		-- Friendship faction, save : level, earned, threshold
local FACTION_TYPE_MAJOR = 2				-- Major faction, save : level, earned, threshold

local enum = DataStore.Enum
local factionStandingLabels = enum.FactionStandingLabels
local factionStandingThresholds = enum.FactionStandingThresholds
local bit64 = LibStub("LibBit64")

-- *** Common API ***
local API_GetNumFactions = isRetail and C_Reputation.GetNumFactions or GetNumFactions
local API_ExpandFactionHeader = isRetail and C_Reputation.ExpandFactionHeader or ExpandFactionHeader
local API_CollapseFactionHeader = isRetail and C_Reputation.CollapseFactionHeader or CollapseFactionHeader
local API_GetFactionInfo
local API_GetFactionNameByID

if isRetail then
	API_GetFactionInfo = function(index) 
			local info = C_Reputation.GetFactionDataByIndex(index)
			return info.name, info.factionID, info.isHeader, info.isCollapsed, info.reaction, info.currentStanding
		end
	API_GetFactionNameByID = function(id)
			local info = C_Reputation.GetFactionDataByID(id)
			return info.name
		end
else
	API_GetFactionInfo = function(index) 
			local name, _, standing, _, _, earned, _,	_, isHeader, isCollapsed, _, _, _, factionID = GetFactionInfo(index)
			return name, factionID, isHeader, isCollapsed, standing, earned
		end
	API_GetFactionNameByID = function(id)
			return GetFactionInfoByID(id)
		end
end


local factions = {}
local factionNameToId = {}

do 
	-- Keep the loading of factions in a narrow scope with do-end
	local isVanilla = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
	local isCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
	local BF = LibStub("LibBabble-Faction-3.0"):GetUnstrictLookupTable()

	local function AddFaction(id, text)
		text = text or API_GetFactionNameByID(id)
		factions[id] = text
		
		if not text then
			print("no value for id : " .. id)
		end
		factionNameToId[text] = id
	end

	AddFaction(21, BF["Booty Bay"])
	AddFaction(47, BF["Ironforge"])
	AddFaction(54, isCata and BF["Gnomeregan Exiles"] or BF["Gnomeregan"])
	AddFaction(59, BF["Thorium Brotherhood"])
	AddFaction(68, BF["Undercity"])
	AddFaction(69, BF["Darnassus"])
	AddFaction(70, BF["Syndicate"])
	AddFaction(72, BF["Stormwind"])
	AddFaction(76, BF["Orgrimmar"])
	AddFaction(81, BF["Thunder Bluff"])
	AddFaction(87, BF["Bloodsail Buccaneers"])
	AddFaction(92, BF["Gelkis Clan Centaur"])
	AddFaction(93, BF["Magram Clan Centaur"])
	AddFaction(270, BF["Zandalar Tribe"])
	AddFaction(349, BF["Ravenholdt"])
	AddFaction(369, BF["Gadgetzan"])
	AddFaction(470, BF["Ratchet"])
	AddFaction(509, BF["The League of Arathor"])
	AddFaction(510, BF["The Defilers"])
	AddFaction(529, BF["Argent Dawn"])
	AddFaction(530, BF["Darkspear Trolls"])
	AddFaction(576, BF["Timbermaw Hold"])
	AddFaction(577, BF["Everlook"])
	AddFaction(589, BF["Wintersaber Trainers"])
	AddFaction(609, BF["Cenarion Circle"])
	AddFaction(729, BF["Frostwolf Clan"])
	AddFaction(730, BF["Stormpike Guard"])
	AddFaction(749, BF["Hydraxian Waterlords"])
	AddFaction(809, BF["Shen'dralar"])
	AddFaction(889, BF["Warsong Outriders"])
	AddFaction(890, BF["Silverwing Sentinels"])
	AddFaction(909, BF["Darkmoon Faire"])
	AddFaction(910, BF["Brood of Nozdormu"])

	if not isVanilla then
		AddFaction(911, BF["Silvermoon City"])
		AddFaction(922, BF["Tranquillien"])
		AddFaction(930, BF["Exodar"])
		-- LK & later

		-- The Burning Crusade
		AddFaction(1012, BF["Ashtongue Deathsworn"])
		AddFaction(942, BF["Cenarion Expedition"])
		AddFaction(933, BF["The Consortium"])
		AddFaction(946, BF["Honor Hold"])
		AddFaction(978, BF["Kurenai"])
		AddFaction(941, BF["The Mag'har"])
		AddFaction(1015, BF["Netherwing"])
		AddFaction(1038, BF["Ogri'la"])
		AddFaction(970, BF["Sporeggar"])
		AddFaction(947, BF["Thrallmar"])
		AddFaction(1011, BF["Lower City"])
		AddFaction(1031, BF["Sha'tari Skyguard"])
		AddFaction(1077, BF["Shattered Sun Offensive"])
		AddFaction(932, BF["The Aldor"])
		AddFaction(934, BF["The Scryers"])
		AddFaction(935, BF["The Sha'tar"])
		AddFaction(989, BF["Keepers of Time"])
		AddFaction(990, BF["The Scale of the Sands"])
		AddFaction(967, BF["The Violet Eye"])

		-- Wrath of the Lich King
		AddFaction(1106, BF["Argent Crusade"])
		AddFaction(1090, BF["Kirin Tor"])
		AddFaction(1073, BF["The Kalu'ak"])
		AddFaction(1091, BF["The Wyrmrest Accord"])
		AddFaction(1098, BF["Knights of the Ebon Blade"])
		AddFaction(1119, BF["The Sons of Hodir"])
		AddFaction(1156, BF["The Ashen Verdict"])
		AddFaction(1037, BF["Alliance Vanguard"])
		AddFaction(1068, BF["Explorers' League"])
		AddFaction(1126, BF["The Frostborn"])
		AddFaction(1094, BF["The Silver Covenant"])
		AddFaction(1050, BF["Valiance Expedition"])
		AddFaction(1052, BF["Horde Expedition"])
		AddFaction(1067, BF["The Hand of Vengeance"])
		AddFaction(1124, BF["The Sunreavers"])
		AddFaction(1064, BF["The Taunka"])
		AddFaction(1085, BF["Warsong Offensive"])
		AddFaction(1104, BF["Frenzyheart Tribe"])
		AddFaction(1105, BF["The Oracles"])
		AddFaction(469, BF["Alliance"])
		AddFaction(67, BF["Horde"])
		AddFaction(1134, BF["Gilneas"])
		AddFaction(1133, BF["Bilgewater Cartel"])
		
		-- cataclysm
		AddFaction(1158, BF["Guardians of Hyjal"])
		AddFaction(1135, BF["The Earthen Ring"])
		AddFaction(1171, BF["Therazane"])
		AddFaction(1174, BF["Wildhammer Clan"])
		AddFaction(1173, BF["Ramkahen"])
		AddFaction(1177, BF["Baradin's Wardens"])
		AddFaction(1172, BF["Dragonmaw Clan"])
		AddFaction(1178, BF["Hellscream's Reach"])
		AddFaction(1204, BF["Avengers of Hyjal"])
	end

	if not isRetail then
		AddFaction(471, BF["Wildhammer Clan"])
	else

		-- Mists of Pandaria
		AddFaction(1277, BF["Chee Chee"])
		AddFaction(1275, BF["Ella"])
		AddFaction(1283, BF["Farmer Fung"])
		AddFaction(1282, BF["Fish Fellreed"])
		AddFaction(1228, BF["Forest Hozen"])
		AddFaction(1281, BF["Gina Mudclaw"])
		AddFaction(1269, BF["Golden Lotus"])
		AddFaction(1279, BF["Haohan Mudclaw"])
		AddFaction(1273, BF["Jogu the Drunk"])
		AddFaction(1276, BF["Old Hillpaw"])
		AddFaction(1271, BF["Order of the Cloud Serpent"])
		AddFaction(1242, BF["Pearlfin Jinyu"])
		AddFaction(1270, BF["Shado-Pan"])
		AddFaction(1216, BF["Shang Xi's Academy"])
		AddFaction(1278, BF["Sho"])
		AddFaction(1302, BF["The Anglers"])
		AddFaction(1341, BF["The August Celestials"])
		AddFaction(1358, BF["Nat Pagle"])
		AddFaction(1359, BF["The Black Prince"])
		AddFaction(1351, BF["The Brewmasters"])
		AddFaction(1337, BF["The Klaxxi"])
		AddFaction(1345, BF["The Lorewalkers"])
		AddFaction(1272, BF["The Tillers"])
		AddFaction(1280, BF["Tina Mudclaw"])
		AddFaction(1353, BF["Tushui Pandaren"])
		AddFaction(1352, BF["Huojin Pandaren"])
		AddFaction(1376, BF["Operation: Shieldwall"])
		AddFaction(1387, BF["Kirin Tor Offensive"])
		AddFaction(1375, BF["Dominance Offensive"])
		AddFaction(1388, BF["Sunreaver Onslaught"])
		AddFaction(1435, BF["Shado-Pan Assault"])
		AddFaction(1440, BF["Darkspear Rebellion"])
		AddFaction(1492, BF["Emperor Shaohao"])

		-- Warlords of Draenor
		AddFaction(1515)		-- Arrakoa Outcasts
		AddFaction(1731)		-- Council of Exarchs
		AddFaction(1445)		-- Frostwold Orcs
		AddFaction(1710)		-- Sha'tari Defense
		AddFaction(1711)		-- Steamwheedle Preservation Society
		AddFaction(1682)		-- Wrynn's Vanguard
		AddFaction(1708)		-- Laughing Skull Orcs
		AddFaction(1681)		-- Vol'jin's Spear
		AddFaction(1847)		-- Hand of the Prophet
		AddFaction(1848)		-- Vol'jin's Headhunters
		AddFaction(1849)		-- Order of the Awakened
		AddFaction(1850)		-- The Saberstalkers

		-- Legion
		AddFaction(1900)		-- Court of Farondis
		AddFaction(1883)		-- Dreamweavers
		AddFaction(1828)		-- Highmountain Tribe
		AddFaction(1948)		-- Valarjar
		AddFaction(1859)		-- The Nightfallen
		AddFaction(1894)		-- The Wardens
		AddFaction(2045)		-- Armies of Legionfall
		AddFaction(2165)		-- Army of the Light
		AddFaction(2170)		-- Argussian Reach
		AddFaction(1975) 		-- Conjurer Margoss
		AddFaction(2097) 		-- Ilyssia of the Waters
		AddFaction(2099) 		-- Akule Riverhorn
		AddFaction(2101) 		-- Sha'leth
		AddFaction(2100) 		-- Corbyn
		AddFaction(2102) 		-- Impus
		AddFaction(2098) 		-- Keeper Raynae
		AddFaction(2135) 		-- Chromie

		-- Battle for Azeroth
		AddFaction(2159)		-- A  - 7th Legion
		AddFaction(2164)		-- AH - Champions of Azeroth
		AddFaction(2161)		-- A  - Order of Embers	(alternate ID: 2264 but this seems unused on wowhead)
		AddFaction(2160)		-- A  - Proudmoore Admiralty (alternate ID: 2120 but this seems unused on wowhead)
		AddFaction(2162)		-- A  - Storm's Wake (alternate ID: 2265 but this seems unused on wowhead)
		AddFaction(2156)		-- H  - Talanji's Expedition
		AddFaction(2157)		-- H  - The Honorbound
		AddFaction(2163)		-- AH - Tortollan Seekers
		AddFaction(2158, BF["Voldunai"])		-- H  - Voldunai
		AddFaction(2103, BF["Zandalari Empire"])		-- H  - Zandalari Empire
		AddFaction(2400, BF["Waveblade Ankoan"])		-- A  - Waveblade Ankoan
		AddFaction(2373, BF["The Unshackled"])			-- H  - The Unshackled
		AddFaction(2391)		-- Rustbolt Resistance
		AddFaction(2415)		-- 8.3 Rajani
		AddFaction(2417)		-- 8.3 Uldum Accord

		-- Shadowlands (Source : https://www.wowhead.com/factions/shadowlands)
		AddFaction(2407, BF["The Ascended"])			-- Zone: Bastion
		AddFaction(2410, BF["The Undying Army"]) 		-- Zone : Maldraxxus
		AddFaction(2465, BF["The Wild Hunt"])			-- Zone : Ardenweald
		AddFaction(2413, BF["Court of Harvesters"])	-- Zone : Revendreth
		AddFaction(2432)     -- Ve'nari (The Maw)
		AddFaction(2439)     -- The Avowed (Halls of Attonement)
		AddFaction(2464)     -- Court of Night (Ardenweald)
		AddFaction(2463, BF["Marasmius"])     -- Marasmius (Ardenweald)
		AddFaction(2470)     -- 9.1 Death's Advance
		AddFaction(2472)     -- 9.1 Archivist's Codex
		AddFaction(2478)     -- 9.2 The Enlightened
		
		-- Dragonflight
		AddFaction(2507)     -- Dragonscale Expedition
		AddFaction(2503)     -- Maruuk Centaur
		AddFaction(2511)     -- Iskaara Tuskarr
		AddFaction(2510)     -- Valdrakken Accord
		AddFaction(2526)     -- Winterpelt Furbolg
		AddFaction(2544)     -- Artisan's Consortium - Dragon Isles Branch
		AddFaction(2550)     -- Cobalt Assembly
		AddFaction(2517)     -- Wrathion
		AddFaction(2518)     -- Sabellian
		AddFaction(2553)     -- Soridormi
		AddFaction(2564)     -- Loamm Niffen
		AddFaction(2568)     -- Glimmerogg Racer
		AddFaction(2574)     -- Dream Wardens	
		AddFaction(2523)     -- Dark Talons Dracthyrs
		AddFaction(2524)     -- Obsidian Warders Dracthyrs	
	end
end

-- *** Utility functions ***
local headersState = {}
local inactive = {}

local function SaveHeaders()
	local headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.
	
	for i = API_GetNumFactions(), 1, -1 do		-- 1st pass, expand all categories
		local _, _, isHeader, isCollapsed = API_GetFactionInfo(i)
		
		if isHeader then
			headerCount = headerCount + 1
			if isCollapsed then
				API_ExpandFactionHeader(i)
				headersState[headerCount] = true
			end
		end
	end
	
	-- code disabled until I can find the other addon that conflicts with this and slows down the machine.
	
	-- If a header faction, like alliance or horde, has all child factions set to inactive, it will not be visible, so activate it, and deactivate it after the scan (thanks Zaphon for this)
	-- for i = API_GetNumFactions(), 1, -1 do
		-- if IsFactionInactive(i) then
			-- local name = GetFactionInfo(i)
			-- inactive[name] = true
			-- SetFactionActive(i)
		-- end
	-- end
end

local function RestoreHeaders()
	local headerCount = 0
	for i = API_GetNumFactions(), 1, -1 do
		local _, _, isHeader, isCollapsed = API_GetFactionInfo(i)
		
		-- if inactive[info.name] then
			-- SetFactionInactive(i)
		-- end
		
		if isHeader then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				API_CollapseFactionHeader(i)
			end
		end
	end
	wipe(headersState)
end

local function GetLimits(earned)
	-- return the bottom & top values of a given rep level based on the amount of earned rep
	local top = 53000
	local index = #factionStandingThresholds
	
	while earned < factionStandingThresholds[index] do
		top = factionStandingThresholds[index]
		index = index - 1
	end
	
	return factionStandingThresholds[index], top
end

local function GetEarnedRep(character, faction)
	-- Return guild reputation
	if character.guildName and faction == character.guildName then
		return character.guildRep
	end
	
	local factionID = factionNameToId[faction]
	
	-- also return the game's faction ID, the caller may need it
	return character.Factions[factionID], factionID
end

-- *** Scanning functions ***
local function ScanSingleFaction(factionID, index)
	if not factionID or factionID == 0 then return end
	
	local factions = thisCharacter.Factions

	-- 1) Is it one of the new major factions since 10.0 ?
	if isRetail and C_Reputation.IsMajorFaction(factionID) then
		local data = C_MajorFactions.GetMajorFactionData(factionID)
		
		factions[factionID] = FACTION_TYPE_MAJOR					-- bits 0-2 : faction type, 3 bits
			+ bit64:LeftShift(data.renownLevel, 3)					-- bits 3-10 : renown level, 8 bits
			+ bit64:LeftShift(data.renownReputationEarned, 11)	-- bits 11-26 : rep earned, 16 bits
			+ bit64:LeftShift(data.renownLevelThreshold, 27)	-- bits 27+ : threshold
		return
	end	
	
	-- 2) Is it a friendship factions
	local repInfo = C_GossipInfo.GetFriendshipReputation(factionID)

	if repInfo and repInfo.friendshipFactionID > 0 then
		local ranks = C_GossipInfo.GetFriendshipReputationRanks(factionID)
		
		-- Ex: Cobalt assembly, ID 2550, standing 205 / next threshold 300 => rank 1 / 5 (5 is not saved, maxLevel is identical for all)
		factions[factionID] = FACTION_TYPE_FRIENDSHIP			-- bits 0-2 : faction type, 3 bits
			+ bit64:LeftShift(ranks.currentLevel, 3)				-- bits 3-10 : currentLevel, 8 bits
			+ bit64:LeftShift(repInfo.standing, 11)				-- bits 11-26 : rep earned, 16 bits
			+ bit64:LeftShift(repInfo.nextThreshold or 0, 27)	-- bits 27+ : threshold
		return
	end

	local value
	local _, _, _, _, standing, earned = API_GetFactionInfo(index)
	
	-- local info = C_Reputation.GetFactionDataByID(factionID)
	-- if not info then
		-- print("no info for id : " .. factionID)
	-- end
	-- local earned = info.currentStanding
	-- local standing = info.reaction
	
	-- 3) Is it a faction that supports paragons ?
	if C_Reputation.IsFactionParagon(factionID) then
		local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
		while (currentValue >= 10000) do
			currentValue = currentValue - 10000
		end
	
		if hasRewardPending then
			currentValue = currentValue + 10000
		end
		
		value = 43000 + currentValue
	else
		value = earned
	end
	
	-- test negative factions : id 87 1104 2526 70 934 ..
	local isNegative = 0
	
	if value < 0 then
		value = value < 0 and -value				-- make the negative value positive again
		isNegative = 1
	end	
		
	factions[factionID] = FACTION_TYPE_NORMAL  	-- bits 0-2 : faction type, 3 bits
		+ bit64:LeftShift(isNegative, 3)				-- bit 3 : isNegative
		+ bit64:LeftShift(standing, 4)				-- bits 4-7 : standing (exalted, ..), 4 bits
		+ bit64:LeftShift(value, 8)					-- bits 8+ : value
end

local function ScanAllFactions()
	SaveHeaders()

	thisCharacter.guildName = GetGuildInfo("player")

	for i = 1, API_GetNumFactions() do
		local factionID = select(2, API_GetFactionInfo(i))
		
		if factionID then
			ScanSingleFaction(factionID, i)		-- pass the index for cata.
		end
	end

	RestoreHeaders()
	thisCharacter.lastUpdate = time()
end

local function ScanGuildReputation()
	-- guid faction id seems to be always 1168, was for me on both horde & alliance

	SaveHeaders()
	for i = 1, API_GetNumFactions() do		-- 2nd pass, data collection
		local name, _, _, _, standing, earned = API_GetFactionInfo(i)

		if name and name == currentGuildName then
			-- thisCharacter.guildRep = earned
			
			thisCharacter.guildRep = FACTION_TYPE_NORMAL  	-- bits 0-2 : faction type, 3 bits
				-- + bit64:LeftShift(isNegative, 3)				-- bit 3 : isNegative => stays false (0) for guild rep
				+ bit64:LeftShift(standing, 4)					-- bits 4-7 : standing (exalted, ..), 4 bits
				+ bit64:LeftShift(earned, 8)						-- bits 8+ : value
		end
	end
	RestoreHeaders()
end

-- *** Event Handlers ***
local function OnPlayerAlive()
	ScanAllFactions()
	ScanGuildReputation()
end

local function OnPlayerGuildUpdate()
	-- at login this event is called between OnEnable and PLAYER_ALIVE, where GetGuildInfo returns a wrong value
	-- however, the value returned here is correct
	if IsInGuild() and not currentGuildName then		-- the event may be triggered multiple times, and GetGuildInfo may return incoherent values in subsequent calls, so only save if we have no value.
		currentGuildName = GetGuildInfo("player")
		if currentGuildName then
			thisCharacter.guildName = currentGuildName
			ScanGuildReputation()
		end
	end
end

local function OnFactionChange(event, messageType, faction, amount)
	if messageType ~= "FACTION" then return end
	
	if faction == GUILD then
		ScanGuildReputation()
		return
	end
end

local lastUpdateFaction = time()

local function OnUpdateFaction()
	--[[ 2024/01/28 : Tested on retail, killing a mob in booty bay gives 5 lines (4 increase + 1 decrease in rep)
		for each line I had:
		- CHAT_MSG_COMBAT_FACTION_CHANGE: which is useless, followed by:
		- COMBAT_TEXT_UPDATE: which gave no extra information
		
		After the first 4 increases, I had 1 UPDATE_FACTION.
		After the decrease, I also had 1 UPDATE_FACTION.
		Overall, UPDATE_FACTION is called less often, I'll register this one to rescan factions.
		
		Nope, bad, UPDATE_FACTION is triggered when expanding/collapsing categories => deadlock
		Only solution is to prevent subsequent events from triggering a scan.
		=> No scan if event was triggered less than 3 seconds ago. Not nice, but Blizzard really doesn't help here..
	--]]
	
	local now = time()
	local elapsed = now - lastUpdateFaction
	lastUpdateFaction = now
	
	if elapsed >= 3 then
		ScanAllFactions()
	end
end

-- ** Mixins **
local function _GetReputationInfo_NonRetail(character, faction)
	local earned = GetEarnedRep(character, faction)
	if not earned then return end

	local currentLevel, repEarned, nextLevel, rate
	local bottom, top = GetLimits(earned)

	-- ex: "Revered", 15400, 21000, 73%
	currentLevel = factionStandingLabels[bottom]
	repEarned = earned - bottom
	nextLevel = top - bottom
	rate = repEarned / nextLevel * 100

	return currentLevel, repEarned, nextLevel, rate
end

local function _GetReputationInfo_Retail(character, faction)
	local info, factionID = GetEarnedRep(character, faction)
	if not info then return end

	local factionType = bit64:GetBits(info, 0, 3)		-- bits 0-2 : faction type, 3 bits
	local currentLevel, repEarned, nextLevel, rate
	
	-- earned reputation will be saved as a number for old/normal reputations.
	if factionType == FACTION_TYPE_NORMAL then
		local isNegative = bit64:TestBit(info, 3)			-- bit 3 : isNegative
		local standing = bit64:GetBits(info, 4, 4)		-- bits 4-7 : standing (exalted, ..), 4 bits
		local earned = bit64:RightShift(info, 8)			-- bits 8+ : value
		earned = isNegative and -earned or earned
	
		local bottom, top = GetLimits(earned)
	
		-- ex: "Revered", 15400, 21000, 73%
		currentLevel = _G["FACTION_STANDING_LABEL"..standing]
		repEarned = earned - bottom
		nextLevel = top - bottom
	
	-- For the new major factions introduced in Dragonflight, different processing is required
	else
		-- ex: "9,1252,2500" = level 9, 1252/2500
		-- => 9, 1252, 2500, 50%
		
		currentLevel = bit64:GetBits(info, 3, 8)			-- bits 3-10 : level, 8 bits
		repEarned = bit64:GetBits(info, 11, 16)			-- bits 11-26 : rep earned, 16 bits
		nextLevel = bit64:RightShift(info, 27)			-- bits 27+ : threshold
	end
	
	if nextLevel == 0 then
		rate = 100
	else
		rate = repEarned / nextLevel * 100
	end
	
	-- is it a major faction ? (4 Dragonflight renown)
	local isMajorFaction = (factionID and isRetail) and C_Reputation.IsMajorFaction(factionID) or false
	
	-- is it a friendship faction ? 
	local repInfo = factionID and C_GossipInfo.GetFriendshipReputation(factionID)	
	local isFrienshipFaction = (repInfo and repInfo.friendshipFactionID > 0) 
	
	return currentLevel, repEarned, nextLevel, rate, isMajorFaction, isFrienshipFaction, factionID
end

local function _GetRawReputationInfo(character, faction)
	-- same as GetReputationInfo, but returns raw values
	
	local info = GetEarnedRep(character, faction)
	if not info then return end

	local factionType = bit64:GetBits(info, 0, 3)		-- bits 0-2 : faction type, 3 bits
	
	if factionType == FACTION_TYPE_NORMAL then
		local isNegative = bit64:TestBit(info, 3)			-- bit 3 : isNegative
		local standing = bit64:GetBits(info, 4, 4)		-- bits 4-7 : standing (exalted, ..), 4 bits
		local earned = bit64:RightShift(info, 8)			-- bits 8+ : value
		earned = isNegative and -earned or earned
	
		local bottom, top = GetLimits(earned)
		return bottom, top, earned
	end
end

local function _IsExaltedWithGuild(character)
	return (character.guildRep and character.guildRep >= 42000)
end

DataStore:OnAddonLoaded(addonName, function()
	DataStore:RegisterModule({
		addon = addon,
		addonName = addonName,
		characterTables = {
			["DataStore_Reputations_Characters"] = {
				GetReputations = function(character) return character.Factions end,
				GetRawReputationInfo = _GetRawReputationInfo,
				-- IsExaltedWithGuild = isRetail and _IsExaltedWithGuild,
				IsExaltedWithGuild = _IsExaltedWithGuild,
				-- GetGuildReputation = isRetail and function(character) return character.guildRep or 0 end,
				GetGuildReputation = function(character) return character.guildRep or 0 end,
				-- GetReputationInfo = isRetail and _GetReputationInfo_Retail or _GetReputationInfo_NonRetail,
				GetReputationInfo = _GetReputationInfo_Retail,
			},
		}
	})
	
	DataStore:RegisterMethod(addon, "GetReputationLevels", function() return factionStandingThresholds end)
	DataStore:RegisterMethod(addon, "GetReputationLevelText", function(level) return factionStandingLabels[level] end)
	DataStore:RegisterMethod(addon, "GetFactionName", function(id) return factions[id] end)
	
	thisCharacter = DataStore:GetCharacterDB("DataStore_Reputations_Characters", true)
	thisCharacter.Factions = thisCharacter.Factions or {}
end)

DataStore:OnPlayerLogin(function()
	-- UPDATE_FACTION will be triggered before PLAYER_ALIVE
	addon:ListenTo("UPDATE_FACTION", OnUpdateFaction)
	addon:ListenTo("COMBAT_TEXT_UPDATE", OnFactionChange)
	
	if isRetail then
		addon:ListenTo("PLAYER_GUILD_UPDATE", OnPlayerGuildUpdate)				-- for gkick, gquit, etc..
	else	
		addon:ListenTo("PLAYER_ALIVE", OnPlayerAlive)
	end
end)


-- *** Utility functions ***
local PT = LibStub("LibPeriodicTable-3.1")

function addon:GetSource(searchedID)
	-- returns the faction where a given item ID can be obtained, as well as the level
	local level, repData = PT:ItemInSet(searchedID, "Reputation.Reward")
	if level and repData then
		local _, _, faction = strsplit(".", repData)		-- ex: "Reputation.Reward.Sporeggar"
	
		-- level = 7,  29150:7 where 7 means revered
		return faction, _G["FACTION_STANDING_LABEL"..level]
	end
end
