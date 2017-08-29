local _, NeP = ...

NeP.Protected = {}
NeP.Protected.callbacks = {}

local rangeCheck = LibStub("LibRangeCheck-2.0")
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local IsInGroup = IsInGroup
local UnitIsFriend = UnitIsFriend
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local strsplit = strsplit
local UnitName = UnitName
local noop = function() end

function NeP.Protected:AddCallBack(func)
	if not func() then
		table.insert(self.callbacks, func)
	end
end

NeP.Protected.Cast = function(spell, target)
  NeP.Faceroll:Set(spell, target)
end

NeP.Protected.CastGround = function(spell, target)
  NeP.Faceroll:Set(spell, target)
end

NeP.Protected.Macro = noop
NeP.Protected.UseItem = noop
NeP.Protected.UseInvItem = noop
NeP.Protected.TargetUnit = noop
NeP.Protected.SpellStopCasting = noop

NeP.Protected.Distance = function(_, b)
  local minRange, maxRange = rangeCheck:GetRange(b)
  return maxRange or minRange
end

NeP.Protected.Infront = function(_,b)
  return NeP.Helpers:Infront(b)
end

NeP.Protected.UnitCombatRange = function(_,b)
  local minRange = rangeCheck:GetRange(b)
  return minRange
end

NeP.Protected.LineOfSight = function(_,b)
  return NeP.Helpers:Infront(b)
end

local ValidUnits = {'player', 'mouseover', 'target', 'focus', 'pet',}
local ValidUnitsN = {'boss', 'arena', 'arenapet'}

NeP.Protected.nPlates = {
	Friendly = {},
	Enemy = {}
}

function NeP.Protected.nPlates:Insert(ref, Obj, GUID)
	local distance = NeP.Protected.Distance('player', Obj) or 999
	if distance <= NeP.OM.max_distance then
		local ObjID = select(6, strsplit('-', GUID))
		self[ref][GUID] = {
			key = Obj,
			name = UnitName(Obj),
			distance = distance,
			id = tonumber(ObjID or 0),
			guid = GUID,
			isdummy = NeP.DSL:Get('isdummy')(Obj)
		}
	end
end

NeP.Protected.OM_Maker = function()
  -- If in Group scan frames...
  if IsInGroup() or IsInRaid() then
    local prefix = (IsInRaid() and 'raid') or 'party'
    for i = 1, GetNumGroupMembers() do
      local unit = prefix..i
			local pet = prefix..'pet'..i
      NeP.OM:Add(unit)
			NeP.OM:Add(pet)
      NeP.OM:Add(unit..'target')
      NeP.OM:Add(pet..'target')
    end
  end
  -- Valid Units
  for i=1, #ValidUnits do
    local object = ValidUnits[i]
    NeP.OM:Add(object)
    NeP.OM:Add(object..'target')
  end
	-- Valid Units with numb (5)
	for i=1, #ValidUnitsN do
		for k=1, 5 do
			local object = ValidUnitsN[i]..k
			NeP.OM:Add(object)
			NeP.OM:Add(object..'target')
		end
	end
  --nameplates
	for i=1, 40 do
		local Obj = 'nameplate'..i
		if UnitExists(Obj) then
			local GUID = UnitGUID(Obj) or '0'
			if UnitIsFriend('player',Obj) then
				NeP.Protected.nPlates:Insert('Friendly', Obj, GUID)
			else
				NeP.Protected.nPlates:Insert('Enemy', Obj, GUID)
			end
		end
	end
end

NeP.Globals.Protected = NeP.Protected
