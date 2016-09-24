NeP.Engine = {
	Run = false,
	ForceTarget = nil,
	lastTarget = nil,
	lastCast = nil,
	forcePause = false,
	Current_Spell = nil,
	Rotations = {},
}

local Engine = NeP.Engine
local Core = NeP.Core

local function Cast(spell, target, isGroundCast)
	-- FORCED TARGET
	if Engine.ForceTarget then
		target = Engine.ForceTarget
	end
	if isGroundCast then
		Engine.CastGround(spell, target)
	else
		Engine.Cast(spell, target)
	end
	Engine.lastCast = spell
	Engine.insertToLog('Spell', spell, target)
end

local function checkTarget(target)
	local isGroundCast = false
	-- none defined (decide one)
	if not target then
		target = UnitExists('target') and 'target' or 'player'
	else
		target = NeP.FakeUnits.Filter(target)
		if not target then return end
	end
	-- is it ground?
	if target:sub(-7) == '.ground' then
		isGroundCast = true
		target = target:sub(0,-8)
	end
	-- Sanity checks
	if isGroundCast and target == 'mouseover'
	or UnitExists(target) and UnitIsVisible(target)
	and Engine.LineOfSight('player', target) then
		Engine.lastTarget = target
		return target, isGroundCast
	end
end

local function castingTime(target)
    local a_name, _,_,_, a_startTime, a_endTime = UnitCastingInfo("player")
    local b_name, _,_,_, b_startTime, b_endTime = UnitChannelInfo("player")
    local time = GetTime() * 1000
    if a_endTime then return (a_endTime - time) / 1000 end
    if b_endTime then return (b_endTime - time) / 1000 end
    return 0
end

local function IsMountedCheck()
	for i = 1, 40 do
		local mountID = select(11, UnitBuff('player', i))
		if mountID and NeP.ByPassMounts(mountID) then
			return true
		end
	end
	return not IsMounted()
end

function Engine.FUNCTION(spell, conditions)
	local result = NeP.DSL.Parse(conditions) and spell()
	if result then return true end
end

function Engine.TABLE(spell, conditions)
	local result = NeP.DSL.Parse(conditions) and Engine.Parse(spell)
	if result then return true end
end

function Engine.STRING(spell, conditions, target, bypass)
	local pX = spell:sub(1, 1)
	local target, isGroundCast = checkTarget(target)
	if Engine.Actions[pX] and NeP.DSL.Parse(conditions) then
		spell = spell:lower():sub(2)
		local result = Engine.Actions[pX](spell, target, sI)
		if result then return true end
	elseif target and (castingTime('player') == 0) or bypass then
		local spell = Engine.spellResolve(spell, target, isGroundCast)
		if spell and NeP.DSL.Parse(conditions, spell) then
			Cast(spell, target, isGroundCast)
			return true
		end
	end
end

function Engine.Parse(cr_table)
	for i=1, #cr_table do
		local table = cr_table[i]
		local spell, conditions, target = table[1], table[2], table[3]
		if not UnitIsDeadOrGhost('player') and IsMountedCheck() then
			local tP = type(spell):upper()
			local result = Engine[tP] and Engine[tP](spell, conditions, target)
			if result then return true end
		end
	end
	-- Reset States
	Engine.isGroundSpell = false
	Engine.ForceTarget = nil
end

function Engine.spellResolve(spell, target, isGroundCast)
	-- Convert Ids to Names
	if spell and spell:find('%d') then
		spell = GetSpellInfo(spell)
		if not spell then return end
	end
	-- locale spells
	spell = NeP.Locale.Spells(spell)
	-- Make sure we can cast the spell
	local skillType = GetSpellBookItemInfo(spell)
	local isUsable, notEnoughMana = IsUsableSpell(spell)
	if skillType ~= 'FUTURESPELL' and isUsable and not notEnoughMana and NeP.Helpers.SpellSanity(spell, target) then
		if not (IsHarmfulSpell(spell) and not UnitCanAttack('player', target)) or isGroundCast then
			local _, GCD = GetSpellCooldown(61304)
			if (GetSpellCooldown(spell) <= GCD) then
				Engine.Current_Spell = spell
				return spell
			end
		end
	end
end

function Engine.insertToLog(whatIs, spell, target)
	local targetName = UnitName(target or 'player')
	local name, icon
	if whatIs == 'Spell' then
		local spellIndex, spellBook = GetSpellBookIndex(spell)
		if spellBook then
			local spellID = select(2, GetSpellBookItemInfo(spellIndex, spellBook))
			name, _, icon = GetSpellInfo(spellIndex, spellBook)
		else
			name, _, icon = GetSpellInfo(spellIndex)
		end
	elseif whatIs == 'Item' then
		name, _,_,_,_,_,_,_,_, icon = GetItemInfo(spell)
	end
	NeP.Interface.UpdateToggleIcon('mastertoggle', icon)
	NeP.ActionLog.insert('Engine_'..whatIs, name, icon, targetName)
end


NeP.Timer.Sync("nep_parser", 0.01, function()
	local Running = NeP.DSL.Get('toggle')(nil, 'mastertoggle')
	if Running then
		local SelectedCR = NeP.Interface.GetSelectedCR()
		if SelectedCR then
			if not Engine.forcePause then
				local InCombatCheck = InCombatLockdown()
				local table = SelectedCR[InCombatCheck]
				Engine.Parse(table)
			end
		else
			Core.Message(Core.TA('Engine', 'NoCR'))
		end
	end
end, 3)