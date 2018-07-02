---- Upvalues
local _G = getfenv(0)
local math, pairs, print = _G.math, _G.pairs, _G.print
local GetSpecialization, GetSpellCooldown, GetSpellInfo, GetTalentInfo, GetTime, UnitAura, UnitDebuff = _G.GetSpecialization, _G.GetSpellCooldown, _G.GetSpellInfo, _G.GetTalentInfo, _G.GetTime, _G.UnitAura, _G.UnitDebuff
local ADDON_NAME, private = ...
local playerName, class, forbearance, symbiosis, active, expirationTime, timer
---- Debuffs to follow
local spellIdList = {
	--[6788] = true, -- Debug with Weakened Soul
	[136295] = true, -- Overcharge
	[135695] = true, -- Static Shock
}
---- Setup
local METHOD = "SAY" -- SAY, YELL, RAID, RAID_WARNING, how to change to CHANNEL explained bellow
	--	Replace every 'METHOD' in the code below with '"CHANNEL", nil, [index]' where [index] equals with
	--  your output channel's index. You find the indexes ingame with '/run print(GetChannelName([index]))'
local LIMIT = 5 -- Countdown last X secs
local SOAKCDS = {
	--["PRIEST"] = 108920, -- Debug with Void Tendrils
	["PRIEST"] = 47585, -- Dispersion
	["ROGUE"] = 31224, -- Cloak of Shadows
	["MAGE"] = 45438, -- Ice Block
	["MONK"] = 115176, -- Zen Meditation
	["HUNTER"] = 19263, -- Deterrence
	["PALADIN"] = 642, -- Divine Shield
}
---- The Magic
local function _round(num, idp) -- Round function, copied from http://lua-users.org/wiki/SimpleRound
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function _checkCD(spellId) -- Check if spell/ability is on CD
	local check = false
	local start, cooldown = GetSpellCooldown(spellId)
	if start ~= nil and cooldown ~= nil and cooldown <= 1.5 then -- No real CD but GCD is OK
		check = true
	end
	return check
end

local function _avaibleCD() -- Check if one can solo soak
	local num = 0
	if class == "PRIEST" and GetSpecialization() ~= 3 then -- Non-Shadow can't solo soak
		return num
	elseif class == "PALADIN" then -- Check for Forbearance, can't solo soak if found
		local debuff = UnitDebuff("player", forbearance)
		if debuff then
			return num
		end
	elseif class == "DRUID" then --Symbiosis
		local _, _, _, _, _, _, _, _, _, _, _, _, _, _, spellId = UnitAura("player", symbiosis)
		if spellId == 110788 and GetSpecialization() == 1 and _checkCD(spellId) then
			num = num + 1 -- Balance: Cloak of Shadows
		elseif (spellId == 110700 or spellId == 110715) and GetSpecialization() == 2 and _checkCD(spellId) then
			num = num + 1 -- Feral: Divine Shield, Dispersion
		elseif (spellId == 110617 or spellId == 110696) and GetSpecialization() == 4 and _checkCD(spellId) then
			num = num + 1 -- Restoration: Deterrence, Ice Block
		end
		return num
	elseif class == "WARLOCK" then
		local _, _, _, _, selected = GetTalentInfo(8) -- Sacrificial Pact
		if selected and selected ~= nil and _checkCD(108416) and _checkCD(104773) then
			num = num + 1 -- Sacrificial Pact & Unending Resolve (You need both to survive)
		end
		return num
	elseif class == "ROGUE" then
		local _, _, _, _, selected = GetTalentInfo(7) -- Cheat Death
		if selected and selected ~= nil and _checkCD(31230) then
			num = num + 1
		end
	elseif class == "MAGE" then
		local _, _, _, _, selected = GetTalentInfo(10) -- Greater Invisibility
		if selected and selected ~= nil and _checkCD(110959) then
			num = num + 1
		end
	elseif class == "MONK" then
		local _, _, _, _, selected = GetTalentInfo(15) -- Diffuse Magic
		if selected and selected ~= nil and _checkCD(122783) then
			num = num + 1
		end
	end

	for i, v in pairs(SOAKCDS) do
		if class == i then
			if _checkCD(v) then
				num = num + 1
			end
		end
	end
	return num
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then -- Init stuff on login
		f:UnregisterEvent("PLAYER_LOGIN")
		playerName = UnitName("player")
		class = select(2, UnitClass("player"))
		forbearance = GetSpellInfo(25771)
		symbiosis = GetSpellInfo(110309)
		for _, i in pairs(spellIdList) do -- Pre-caching spells
			local _ = GetSpellInfo(i)
		end
		for _, i in pairs(SOAKCDS) do -- Pre-caching soaking spells and abilities
			local _ = GetSpellInfo(i)
		end
		for _, i in pairs({ 110788, 110700, 110715, 110617, 110696, 108416, 104773, 31230, 110959, 122783 }) do -- More pre-caching
			local _ = GetSpellInfo(i)
		end
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
		local _, _, difficultyID, _, _, _, _, instanceMapID = GetInstanceInfo() -- /dump GetInstanceInfo()
		if instanceMapID == 1098 and difficultyID ~= 7 then -- not in LFR, 930 == MapAreaID, 1098 == instanceMapID
			f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			f:SetScript("OnUpdate", function(self, elapsed)
				if not active then -- No active countdown, return
					return
				end

				timer = timer + elapsed
				while timer >= 1 do
					local remain = expirationTime - GetTime()
					local delta = remain - _round(remain) -- Should be accurate to <0.1s
					if active == 135695 and _avaibleCD() > 0 and remain > LIMIT then -- Static Shock
					--elseif active == 6788 and _avaibleCD() > 0 and remain > LIMIT then -- Debug with Weakened Soul
						SendChatMessage("Soaking solo", METHOD)
						active = false
						return
					elseif _round(remain,1) > 0 and _round(remain,1) <= LIMIT then
						SendChatMessage(_round(remain), METHOD)
					end
					timer = timer - 1 - delta -- Self correcting
				end
			end)
		else -- Not in ToT, disable CLEU and OnUpdate
			f:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			f:SetScript("OnUpdate", nil)
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, eventType, _, _, _, _, _, _, dstName, _, _, spellId = ...
		--local timeStamp, eventType, _, _, _, _, _, dstGUID, _, _, _, spellId = ... -- How about GUID instead of Name?
		if eventType == "SPELL_AURA_APPLIED" and dstName == playerName and spellIdList[spellId] then
			local aura = GetSpellInfo(spellId)
			local _, _, _, _, _, _, expires = UnitDebuff("player", aura) -- UnitAura doesn't return 'expires' at least for Weakened Soul
			if expires then -- Found something, start countdown
				active = spellId
				expirationTime = expires
				timer = 0
			end
		elseif eventType == "SPELL_AURA_REMOVED" and dstName == playerName and active == spellId then
			active = false
			SendChatMessage("0", METHOD)
			print("|cffff0000"..ADDON_NAME.."|r: Δ~".._round((expirationTime - GetTime()),4).."s") -- Let's see how much we are off with the countdown
		end
	end
end)