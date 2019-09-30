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
    local best = {}
    for bag = 0,4 do
        for slot = 1,GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            best.food = self:BetterFood(best.food, self.Food[id])
            best.buffFood = self:BetterBuffFood(best.buffFood, self.Food[id])
            best.drink = self:BetterDrink(best.drink, self.Food[id])
            best.buffDrink = self:BetterBuffDrink(best.buffDrink, self.Food[id])
            best.hPotion = self:BetterHPotion(best.hPotion, self.Potion[id])
            best.mPotion = self:BetterMPotion(best.mPotion, self.Potion[id])
            best.bandage = self:BetterBandage(best.bandage, self.Bandage[id])
            best.healthstone = self:BetterHealthstone(best.healthstone, self.Healthstone[id])
            best.manaGem = self:BetterManaGem(best.manaGem, self.ManaGem[id])
        end
    end
    foodMacro = defaultFoodMacro:gsub("<%a+>", {
        ["<food>"] = (best.food and best.food.id or 0),
        ["<buffFood>"] = (best.buffFood and best.buffFood.id or 0),
        ["<hPotion>"] = (best.hPotion and best.hPotion.id or 0),
        ["<healthStone>"] = (best.healthStone and best.healthStone.id or 0),
        ["<bandage>"] = (best.bandage and best.bandage.id or 0),
    })
    drinkMacro = defaultDrinkMacro:gsub("<%a+>", {
        ["<drink>"] = (best.drink and best.drink.id or 0),
        ["<manaBuff>"] = (best.buffDrink and best.buffDrink.id or 0),
        ["<mPotion>"] = (best.mPotion and best.mPotion.id or 0),
        ["<manaGem>"] = (best.manaGem and best.manaGem.id or 0),
    })
    CreateOrUpdateMacro("NFB_Food", foodMacro)
    CreateOrUpdateMacro("NFB_Drink", drinkMacro)
end

function NeedsFoodBadly:IsUsableFood(food)
    return food 
            and food.lvl <= UnitLevel("player")
            and food.hp 
            and not (food.hp5 or food.mp5 or food.str or food.agi or food.stam or food.int or food.spi)
end

function NeedsFoodBadly:BetterFood(a, b)
    if not self:IsUsableFood(a) then a = nil end
    if not self:IsUsableFood(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.conj and not b.conj then
        return a
    elseif b.conj and not a.conj then
        return b
    end
    -- Percent food is stored as a decimal number, ie "Restores 2% health" is hp=0.02
    a_hp, b_hp = a.hp, b.hp
    if a_hp < 1 then a_hp = UnitHealthMax("player") * a_hp end
    if b_hp < 1 then b_hp = UnitHealthMax("player") * b_hp end
    if a_hp > b_hp or (a_hp == b_hp and GetItemCount(a.id) <= GetItemCount(b.id)) then
        return a
    elseif b_hp > a_hp or (b_hp == a_hp and GetItemCount(b.id) <= GetItemCount(a.id)) then
        return b
    end
end

function NeedsFoodBadly:IsUsableBuffFood(food)
    return food 
        and food.lvl <= UnitLevel("player")
        and food.hp and food.stam and food.spi
end

function NeedsFoodBadly:BetterBuffFood(a, b)
    if not self:IsUsableBuffFood(a) then a = nil end
    if not self:IsUsableBuffFood(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.stam > b.stam or (a.stam == b.stam and GetItemCount(a.id) <= GetItemCount(b.id)) then
        return a
    elseif b.stam > a.stam or (b.stam == a.stam and GetItemCount(b.id) <= GetItemCount(a.id)) then
        return b
    end
end

function NeedsFoodBadly:IsUsableDrink(food)
    return food 
            and food.lvl <= UnitLevel("player")
            and food.mp
            and not food.mp5
end

function NeedsFoodBadly:BetterDrink(a, b)
    if not self:IsUsableDrink(a) then a = nil end
    if not self:IsUsableDrink(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.conj and not b.conj then
        return a
    elseif b.conj and not a.conj then
        return b
    end
    a_mp, b_mp = a.mp, b.mp
    if a_mp < 1 then a_mp = UnitHealthMax("player") * a_mp end
    if b_mp < 1 then b_mp = UnitHealthMax("player") * b_mp end
    if a_mp > b_mp or (a_mp == b_mp and GetItemCount(a.id) <= GetItemCount(b.id)) then
        return a
    elseif b_mp > a_mp or (b_mp == a_mp and GetItemCount(b.id) <= GetItemCount(a.id)) then
        return b
    end
end

function NeedsFoodBadly:IsUsableBuffDrink(food)
    return food 
            and food.lvl <= UnitLevel("player")
            and food.mp5
end

function NeedsFoodBadly:BetterBuffDrink(a, b)
    if not self:IsUsableBuffDrink(a) then a = nil end
    if not self:IsUsableBuffDrink(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.mp5 > b.mp5 or (a.mp5 == b.mp5 and GetItemCount(a.id) <= GetItemCount(b.id)) then
        return a
    elseif b.mp5 > a.mp5 or (b.mp5 == a.mp5 and GetItemCount(b.id) <= GetItemCount(a.id)) then
        return b
    end
end

function NeedsFoodBadly:IsUsableHPotion(potion)
    return potion 
            and potion.lvl <= UnitLevel("player")
            and potion.hp
            and not potion.bg
end

function NeedsFoodBadly:BetterHPotion(a, b)
    if not self:IsUsableHPotion(a) then a = nil end
    if not self:IsUsableHPotion(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.high >= b.high then
        return a
    else
        return b
    end
end

function NeedsFoodBadly:IsUsableMPotion(potion)
    return potion 
            and potion.lvl <= UnitLevel("player")
            and potion.mp
            and not potion.bg
end

function NeedsFoodBadly:BetterMPotion(a, b)
    if not self:IsUsableMPotion(a) then a = nil end
    if not self:IsUsableMPotion(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.high >= b.high then
        return a
    else
        return b
    end
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
    return bandage and bandage.skill <= FirstAidSkillPoints() and not bandage.bg
end

function NeedsFoodBadly:BetterBandage(a, b)
    if not self:IsUsableBandage(a) then a = nil end
    if not self:IsUsableBandage(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.hp >= b.hp then
        return a
    else
        return b
    end
end

function NeedsFoodBadly:IsUsableHealthstone(healthstone)
    return healthstone and healthstone.lvl <= UnitLevel("player")
end

function NeedsFoodBadly:BetterHealthstone(a, b)
    if not self:IsUsableHealthstone(a) then a = nil end
    if not self:IsUsableHealthstone(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.hp >= b.hp then
        return a
    else
        return b
    end
end

function NeedsFoodBadly:IsUsableManaGem(manaGem)
    return manaGem and manaGem.lvl <= UnitLevel("player")
end

function NeedsFoodBadly:BetterManaGem(a, b)
    if not self:IsUsableManaGem(a) then a = nil end
    if not self:IsUsableManaGem(b) then b = nil end
    if a == nil or b == nil then
        return a or b
    end
    if a.high >= b.high then
        return a
    else
        return b
    end
end
