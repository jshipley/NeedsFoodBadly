--[[ TODO
    * Add configuration options
        * Give option to treat buff food as low priority regular food
        * Allow other buff foods (eg agi/str), and let user prioritize them
        * Allow custom macro templates
        * Prefer PVP potions/bandages in battlegrounds (they're ignored for now)
]]

local defaultFoodMacro = [[#showtooltip
/use [combat,nomod] item:<hPotion>
/use [combat,mod:ctrl] item:<healthStone>
/use [nocombat,mod:ctrl] item:<buffFood>
/use [mod:shift] item:<bandage>
/use [nocombat,nomod] item:<food>
]]
local defaultDrinkMacro = [[#showtooltip
/use [combat,nomod] item:<mPotion>
/use [combat,mod:ctrl] item:<manaGem>
/use [nocombat,mod:ctrl] item:<manaBuff>
/use [nocombat,nomod] item:<drink>
]]

local function CreateOrUpdateMacro(macroName, text)
    local macroID = GetMacroIndexByName(macroName)
    if macroID == 0 then
        CreateMacro(macroName, "Inv_misc_questionmark", text, nil, nil)
    else
        EditMacro(macroID, macroName, "Inv_misc_questionmark", text, nil, nil)
    end
end

NeedsFoodBadly = CreateFrame("frame")
NeedsFoodBadly:RegisterEvent("BAG_UPDATE_DELAYED")
NeedsFoodBadly:RegisterEvent("PLAYER_REGEN_ENABLED")
NeedsFoodBadly:RegisterEvent("PLAYER_LEVEL_UP")

NeedsFoodBadly.dirty = false
NeedsFoodBadly:SetScript("OnEvent", function (self, event, ...)
    if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_LEVEL_UP" then
        if InCombatLockdown() then 
            NeedsFoodBadly.dirty = true
        else
            NeedsFoodBadly:UpdateMacros()
        end
    elseif event == "PLAYER_REGEN_ENABLED" and NeedsFoodBadly.dirty then
        NeedsFoodBadly:UpdateMacros()
        NeedsFoodBadly.dirty = false
    end
end)

function NeedsFoodBadly:UpdateMacros()
    local best = {
        food = {}, buffFood = {}, drink = {}, buffDrink = {},
        hPotion = {}, mPotion = {}, healthstone = {}, manaGem = {},
        bandage = {}
    }
    for bag = 0,4 do
        for slot = 1,GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            if not best.food[id] and IsUsableFood(self.Food[id]) then
                best.food[id] = self.Food[id]
            end
            if not best.buffFood[id] and IsUsableBuffFood(self.Food[id]) then
                best.buffFood[id] = self.Food[id]
            end
            if not best.drink[id] and IsUsableDrink(self.Food[id]) then
                best.drink[id] = self.Food[id]
            end
            if not best.buffDrink[id] and IsUsableBuffDrink(self.Food[id]) then
                best.buffDrink[id] = self.Food[id]
            end
            if not best.hPotion[id] and IsUsableHPotion(self.Potion[id]) then
                best.hPotion[id] = self.Potion[id]
            end
            if not best.mPotion[id] and IsUsableMPotion(self.Potion[id]) then
                best.mPotion[id] = self.Potion[id]
            end
            if not best.healthstone[id] and IsUsableHealthstone(self.healthstone[id]) then
                best.healthstone[id] = self.Healthstone[id]
            end
            if not best.manaGem[id] and IsUsableManaGem(self.ManaGem[id]) then
                best.manaGem[id] = self.ManaGem[id]
            end
            if not best.bandage[id] and IsUsableBandage(self.Bandage[id]) then
                best.bandage[id] = self.Bandage[id]
            end
        end
    end
    best.food = self:Sorted(best.food, self.BetterFood)
    best.buffFood = self:Sorted(best.buffFood, self.BetterBuffFood)
    best.drink = self:Sorted(best.drink, self.BetterDrink)
    best.buffDrink = self:Sorted(best.buffDrink, self.BetterBuffDrink)
    best.hPotion = self:Sorted(best.hPotion, self.BetterHPotion)
    best.mPotion = self:Sorted(best.mPotion, self.BetterMPotion)
    best.bandage = self:Sorted(best.bandage, self.BetterBandage)
    foodMacro = defaultFoodMacro:gsub("<%a+>", {
        ["<food>"] = (best.food[1] and best.food[1].id or 0),
        ["<buffFood>"] = (best.buffFood[1] and best.buffFood[1].id or 0),
        ["<hPotion>"] = (best.hPotion[1] and best.hPotion[1].id or 0),
        ["<healthStone>"] = (best.healthStone[1] and best.healthStone[1].id or 0),
        ["<bandage>"] = (best.bandage[1] and best.bandage[1].id or 0),
    })
    drinkMacro = defaultDrinkMacro:gsub("<%a+>", {
        ["<drink>"] = (best.drink[1] and best.drink[1].id or 0),
        ["<manaBuff>"] = (best.buffDrink[1] and best.buffDrink[1].id or 0),
        ["<mPotion>"] = (best.mPotion[1] and best.mPotion[1].id or 0),
        ["<manaGem>"] = (best.manaGem[1] and best.manaGem[1].id or 0),
    })
    CreateOrUpdateMacro("NFB_Food", foodMacro)
    CreateOrUpdateMacro("NFB_Drink", drinkMacro)
end

function NeedsFoodBadly:Sorted(t, f)
    sortedTable = {}
    for _, v in t do
        table.insert(sortedTable, v)
    end
    table.sort(sortedTable, f)
    return sortedTable
end

function NeedsFoodBadly:IsUsableFood(food)
    return not not (food 
            and food.lvl <= UnitLevel("player")
            and food.hp 
            and not (food.hp5 or food.mp5 or food.str or food.agi or food.stam or food.int or food.spi))
end

function NeedsFoodBadly:IsUsableBuffFood(food)
    return not not (food
    and food.lvl <= UnitLevel("player")
    and (food.hp and food.stam and food.spi))
end

function NeedsFoodBadly:IsUsableDrink(food)
    return not not (food 
    and food.lvl <= UnitLevel("player")
    and food.mp
    and not food.mp5)
end

function NeedsFoodBadly:IsUsableBuffDrink(food)
    return not not (food 
    and food.lvl <= UnitLevel("player")
    and food.mp5)
end

function NeedsFoodBadly:IsUsableHPotion(potion)
    return not not (potion 
    and potion.lvl <= UnitLevel("player")
    and potion.hp
    and not potion.bg)
end

function NeedsFoodBadly:IsUsableMPotion(potion)
    return not not (potion 
            and potion.lvl <= UnitLevel("player")
            and potion.mp
            and not potion.bg)
end

function NeedsFoodBadly:IsUsableHealthstone(healthstone)
    return not not (healthstone
        and healthstone.lvl <= UnitLevel("player"))
end

function NeedsFoodBadly:IsUsableManaGem(manaGem)
    return not not (manaGem
        and manaGem.lvl <= UnitLevel("player"))
end

local function FirstAidSkillPoints()
    for i = 1, GetNumSkillLines() do
        local skillName, _, _, skillRank, numTempPoints, skillModifier = GetSkillLineInfo(i)
        if skillName == PROFESSIONS_FIRST_AID then
            return skillRank + numTempPoints + skillModifier
        end
    end
    return 0
end

function NeedsFoodBadly:IsUsableBandage(bandage)
    return not not (bandage
    	and bandage.skill <= FirstAidSkillPoints()
	and not bandage.bg)
end

function NeedsFoodBadly.BetterFood(a, b)
    if a.conj and not b.conj then
        return true
    elseif b.conj and not a.conj then
        return false
    end
    -- Percent food is stored as a decimal number, ie "Restores 2% health" is hp=0.02
    a_hp, b_hp = a.hp, b.hp
    if a_hp < 1 then a_hp = UnitHealthMax("player") * a_hp end
    if b_hp < 1 then b_hp = UnitHealthMax("player") * b_hp end
    return (a_hp > b_hp) or (a_hp == b_hp and GetItemCount(a.id) <= GetItemCount(b.id))
end

function NeedsFoodBadly.BetterBuffFood(a, b)
    return a.stam > b.stam or (a.stam == b.stam and GetItemCount(a.id) <= GetItemCount(b.id))
end

function NeedsFoodBadly.BetterDrink(a, b)
    if a.conj and not b.conj then
        return true
    elseif b.conj and not a.conj then
        return false
    end
    a_mp, b_mp = a.mp, b.mp
    if a_mp < 1 then a_mp = UnitHealthMax("player") * a_mp end
    if b_mp < 1 then b_mp = UnitHealthMax("player") * b_mp end
    return a_mp > b_mp or (a_mp == b_mp and GetItemCount(a.id) <= GetItemCount(b.id))
end

function NeedsFoodBadly.BetterBuffDrink(a, b)
    return a.mp5 > b.mp5 or (a.mp5 == b.mp5 and GetItemCount(a.id) <= GetItemCount(b.id))
end

function NeedsFoodBadly.BetterHPotion(a, b)
    return a.high >= b.high
end

function NeedsFoodBadly.BetterMPotion(a, b)
    return a.high >= b.high
end

function NeedsFoodBadly.BetterHealthstone(a, b)
    return a.hp >= b.hp
end

function NeedsFoodBadly.BetterManaGem(a, b)
    return a.high >= b.high
end

function NeedsFoodBadly.BetterBandage(a, b)
    if a.bg and not b.bg then
        return true
    elseif b.bg and not a.bg then
        return false
    end
    return a.hp >= b.hp
end
