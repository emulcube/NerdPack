NeP.Faceroll = {}

local aC = '|cff'..NeP.Interface.addonColor
local lnr = LibStub("AceAddon-3.0"):NewAddon("NerdPack", "LibNameplateRegistry-1.0");
local rangeCheck = LibStub("LibRangeCheck-2.0")

-- This to put an icon on top of the spell we want
local activeFrame = CreateFrame('Frame', 'activeCastFrame', UIParent)
activeFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, tileSize = 16, edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
});
activeFrame:SetBackdropColor(0,0,0,1);
activeFrame.texture = activeFrame:CreateTexture()
activeFrame.texture:SetTexture("Interface/TARGETINGFRAME/UI-RaidTargetingIcon_8")
activeFrame.texture:SetPoint("CENTER")
activeFrame:SetFrameStrata('HIGH')
activeFrame:Hide()

-- Work in Progress...
local display = CreateFrame('Frame', 'Faceroll_Info', activeFrame)
display:SetClampedToScreen(true)
display:SetSize(0, 0)
display:SetPoint("TOP")
display:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, tileSize = 16, edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
});
display:SetBackdropColor(0,0,0,1);
display.text = display:CreateFontString('PE_StatusText')
display.text:SetFont("Fonts\\ARIALN.TTF", 16)
display.text:SetPoint("CENTER", display)

local function showActiveSpell(spell, target)
	local spellButton = NeP.Buttons[spell]
	if spell and spellButton then
		local bSize = spellButton:GetWidth()
		activeFrame:SetSize(bSize+5, bSize+5)
		display:SetSize(display.text:GetStringWidth()+20, display.text:GetStringHeight()+20)
		activeFrame.texture:SetSize(activeFrame:GetWidth()-5,activeFrame:GetHeight()-5)
		activeFrame:SetPoint("CENTER", spellButton, "CENTER")
		display:SetPoint("TOP", spellButton, 0, display.text:GetStringHeight()+20)
		local spell = aC.."Spell:|r "..spell
		local isTargeting = aC..tostring(UnitIsUnit("target", target))
		local target = aC.."\nTarget:|r"..(UnitName(target) or '')
		display.text:SetText(spell..target.."("..isTargeting..")")
		activeFrame:Show()
		display:Show()
	end
end

-- Hide it
NeP.Timer.Sync("nep_faceroll", 1, function()
	activeFrame:Hide()
	display:Hide()
end)

local nameplates = {}
	
function lnr:OnEnable()
	self:LNR_RegisterCallback("LNR_ON_NEW_PLATE");
	self:LNR_RegisterCallback("LNR_ON_RECYCLE_PLATE");
end

function lnr:OnDisable()
	self:LNR_UnregisterAllCallbacks();
end

function lnr:LNR_ON_NEW_PLATE(_, _, plateData)
	local tK = plateData.unitToken
	nameplates[tK] = tK
end

function lnr:LNR_ON_RECYCLE_PLATE(_, _, plateData)
	local tK = plateData.unitToken
	nameplates[tK] = nil
end

local function GenericFilter(unit)
	if not UnitExists(unit) then return false end
	local table = UnitCanAttack('player', unit) and 'unitEnemie' or 'unitFriend'
	for i=1, #NeP.OM[table] do
		local Obj = NeP.OM[table][i]
		if Obj.guid == UnitGUID(unit) then
			return false
		end
	end
	return true	
end

function NeP.Engine.FaceRoll()

	-- cast on ground
	function NeP.Engine.CastGround(spell, target)
		showActiveSpell(spell, target)
	end

	-- Cast
	function NeP.Engine.Cast(spell, target)
		showActiveSpell(spell, target)
	end

	-- Macro
	function NeP.Engine.Macro(text)
	end

	function NeP.Engine.UseItem(name, target)
	end

	function NeP.Engine.UseInvItem(slot)
	end

	function NeP.Engine.LineOfSight(_, b)
		return NeP.Helpers.infront and UnitExists(b)
	end

	function NeP.Engine.Distance(_, b)
		if UnitExists(b) then
			local minRange, maxRange = rangeCheck:GetRange(b)
			return maxRange or minRange
		end
		return 0
	end

	-- Infront
	function NeP.Engine.Infront()
		return NeP.Helpers.infront
	end

	function NeP.Engine.UnitCombatRange(unitA, unitB)
		return NeP.Engine.Distance(unitA, unitB)
	end

	local _rangeTable = {
		['melee'] = 1.5,
		['ranged'] = 40,
	}

	function NeP.Engine.UnitAttackRange(unitA, unitB, rType)
		if rType then
			return _rangeTable[rType] + 3.5
		end
		return 0
	end

	function NeP.OM.Maker()
		-- Self
		NeP.OM.addToOM('player')
		-- Mouseover
		if UnitExists('mouseover') then
			local object = 'mouseover'
			if GenericFilter(object) then
				NeP.OM.addToOM(object)
			end
		end
		-- Target Cache
		if UnitExists('target') then
			local object = 'target'
			if GenericFilter(object) then
				NeP.OM.addToOM(object)
			end
		end
		-- If in Group scan frames...
		if IsInGroup() or IsInRaid() then
			local prefix = (IsInRaid() and 'raid') or 'party'
			for i = 1, GetNumGroupMembers() do
				-- Enemie
				local target = prefix..i..'target'
				if GenericFilter(target) then
					NeP.OM.addToOM(target)
				end
				-- Friendly
				local friendly = prefix..i
				if GenericFilter(friendly) then
					NeP.OM.addToOM(friendly)
				end
			end
		end
		-- Nameplate cache
		for k,_ in pairs(nameplates) do
			local plate = nameplates[k]
			if GenericFilter(plate) then
				NeP.OM.addToOM(plate)
			end
		end
	end

end

NeP.Engine.FaceRoll()