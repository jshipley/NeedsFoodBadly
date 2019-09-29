-- These tests temporarily replace some WoW API calls for testing purposes.
-- This lua file should not be enabled/included in any shipped versions of this addon.
-- Always reload before playing after running these tests

local function replaceAndCall(test_func, ...)
    local replacements = {}
    for k, v in pairs({...}) do
        api_call, replacement = unpack(v)
        replacements[api_call] = _G[api_call]
        _G[api_call] = replacement
    end
    test_func()
    for api_call, orig in pairs(replacements) do
        _G[api_call] = orig
    end
end

local Tests = {
    cases = {}
}
local function assertEquals(exprA, exprB, msg)
    if exprA ~= exprB then
        error("|cffff0000Failed: " .. tostring(exprA) .. " does not equal " .. tostring(exprB) .. (msg and (": " .. msg) or ""))
    end
end

local function assertTrue(exprA, msg)
    if not exprA then
        error("|cffff0000Failed: " .. tostring(exprA) .. " is not true" .. (msg and (": " .. msg) or ""))
    end
end

local function assertFalse(exprA, msg)
    if exprA then
        error("|cffff0000Failed: " .. tostring(exprA) .. " is not false" .. (msg and (": " .. msg) or ""))
    end
end

local function assertNil(exprA, msg)
    if exprA ~= nil then
        error("|cffff0000Failed: " .. tostring(exprA) .. " is not nil" .. (msg and (": " .. msg) or ""))
    end
end

local NFB = NeedsFoodBadly

function NFB:runTests()
    Tests.passed = 0
    Tests.failed = 0
    print("Running NeedsFoodBadly unit tests")
    for fn_name, fn in pairs(Tests.cases) do
        local status, msg = pcall(fn)
        if status then
            Tests.passed = Tests.passed + 1
        else
            print(fn_name .. ": " .. string.sub(msg, 47))
            Tests.failed = Tests.failed + 1
        end
    end
    print("|cff00ff00  " .. Tests.passed .. " tests passed")
    if Tests.failed > 0 then
        print("|cffff0000  " .. Tests.failed .. " tests failed")
    end
    print("Test Status: " .. (Tests.failed > 0 and "|cffff0000Failure!" or "|cff00ff00Success!"))
end

--[[ Basic food/drink test data
    16766 - Undermine Clam Chowder - lvl 35 food
    8932 - Alterac Swiss - lvl 45 food
    17222 - Spider Sausage - lvl 35 stam/spi food
    18045 - Tender Wolf Steak - lvl 40 stam/spi food
    19300 - Bottled Winterspring Water - lvl 35 drink
    18300 - Hyjal Nectar - lvl 55 drink
    3448 - Senggin Root - lvl 9 food/drink
    21217 - Sagefish Delight - lvl 30 buff "drink"
]]

function Tests.cases.UsableFood_Basic()
    replaceAndCall(
        function ()
            assertTrue(NFB:IsUsableFood(NFB.Food[16766]))
            assertFalse(NFB:IsUsableFood(NFB.Food[8932]))
            assertFalse(NFB:IsUsableFood(NFB.Food[17222]))
            assertFalse(NFB:IsUsableFood(NFB.Food[18045]))
            assertFalse(NFB:IsUsableFood(NFB.Food[19300]))
            assertFalse(NFB:IsUsableFood(NFB.Food[18300]))
            assertTrue(NFB:IsUsableFood(NFB.Food[3448]))
            assertFalse(NFB:IsUsableFood(NFB.Food[21217]))
        end,
        {"UnitLevel", function () return 35 end}
    )
end

function Tests.cases.UsableBuffFood_Basic()
    replaceAndCall(
        function ()
            assertFalse(NFB:IsUsableBuffFood(NFB.Food[16766]))
            assertFalse(NFB:IsUsableBuffFood(NFB.Food[8932]))
            assertTrue(NFB:IsUsableBuffFood(NFB.Food[17222]))
            assertFalse(NFB:IsUsableBuffFood(NFB.Food[18045]))
            assertFalse(NFB:IsUsableBuffFood(NFB.Food[19300]))
            assertFalse(NFB:IsUsableBuffFood(NFB.Food[18300]))
            assertFalse(NFB:IsUsableBuffFood(NFB.Food[3448]))
            assertFalse(NFB:IsUsableBuffFood(NFB.Food[21217]))
        end,
        {"UnitLevel", function () return 35 end}
    )
end

function Tests.cases.UsableDrink_Basic()
    replaceAndCall(
        function ()
            assertFalse(NFB:IsUsableDrink(NFB.Food[16766]))
            assertFalse(NFB:IsUsableDrink(NFB.Food[8932]))
            assertFalse(NFB:IsUsableDrink(NFB.Food[17222]))
            assertFalse(NFB:IsUsableDrink(NFB.Food[18045]))
            assertTrue(NFB:IsUsableDrink(NFB.Food[19300]))
            assertFalse(NFB:IsUsableDrink(NFB.Food[18300]))
            assertTrue(NFB:IsUsableDrink(NFB.Food[3448]))
            assertFalse(NFB:IsUsableDrink(NFB.Food[21217]))
        end,
        {"UnitLevel", function () return 45 end}
    )
end

function Tests.cases.UsableBuffDrink_Basic()
    replaceAndCall(
        function ()
            assertFalse(NFB:IsUsableBuffDrink(NFB.Food[16766]))
            assertFalse(NFB:IsUsableBuffDrink(NFB.Food[8932]))
            assertFalse(NFB:IsUsableBuffDrink(NFB.Food[17222]))
            assertFalse(NFB:IsUsableBuffDrink(NFB.Food[18045]))
            assertFalse(NFB:IsUsableBuffDrink(NFB.Food[19300]))
            assertFalse(NFB:IsUsableBuffDrink(NFB.Food[18300]))
            assertFalse(NFB:IsUsableBuffDrink(NFB.Food[3448]))
            assertTrue(NFB:IsUsableBuffDrink(NFB.Food[21217]))
        end,
        {"UnitLevel", function () return 45 end}
    )
end

function Tests.cases.UsableHPotion_Basic()
    replaceAndCall(
        function()
            assertTrue(NFB:IsUsableHPotion(NFB.Potion[929]))
            assertTrue(NFB:IsUsableHPotion(NFB.Potion[1710]))
            assertTrue(NFB:IsUsableHPotion(NFB.Potion[2456]))
            assertFalse(NFB:IsUsableHPotion(NFB.Potion[3928]))
            assertFalse(NFB:IsUsableHPotion(NFB.Potion[3827]))
        end,
        {"UnitLevel", function () return 34 end}
    )
end

function Tests.cases.UsableMPotion_Basic()
    replaceAndCall(
        function()
            assertFalse(NFB:IsUsableMPotion(NFB.Potion[929]))
            assertFalse(NFB:IsUsableMPotion(NFB.Potion[1710]))
            assertTrue(NFB:IsUsableMPotion(NFB.Potion[2456]))
            assertFalse(NFB:IsUsableMPotion(NFB.Potion[3928]))
            assertFalse(NFB:IsUsableMPotion(NFB.Potion[13443]))
        end,
        {"UnitLevel", function () return 40 end}
    )
end

function Tests.cases.UsableBandage_Basic()
    replaceAndCall(
        function()
            assertTrue(NFB:IsUsableBandage(NFB.Bandage[14530]))
        end,
        {"UnitLevel", function () return 40 end}
    )
end

function Tests.cases.UsableHealthstone_Basic()
    replaceAndCall(
        function()
            assertTrue(NFB:IsUsableHealthstone(NFB.Healthstone[19009]))
            assertFalse(NFB:IsUsableHealthstone(NFB.Healthstone[19010]))
        end,
        {"UnitLevel", function () return 40 end}
    )
end

function Tests.cases.UsableManaGem_Basic()
    replaceAndCall(
        function()
            assertTrue(NFB:IsUsableManaGem(NFB.ManaGem[5513]))
            assertFalse(NFB:IsUsableManaGem(NFB.ManaGem[8007]))
        end,
        {"UnitLevel", function () return 40 end}
    )
end

-- TODO: test for percent food
function Tests.cases.BetterFood_Basic()
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterFood(NFB.Food[16766], NFB.Food[8932]).name, NFB.Food[8932].name)
        end,
        {"UnitLevel", function () return 45 end},
        {"UnitHealthMax", function () return 100 end},
        {"GetItemCount", function () return 10 end}
    )
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterFood(NFB.Food[8932], NFB.Food[6887]).name, NFB.Food[8932].name, "lower quantity wins")
            assertEquals(NFB:BetterFood(NFB.Food[8932], NFB.Food[8075]).name, NFB.Food[8075].name, "conjured wins")
            assertEquals(NFB:BetterFood(NFB.Food[8932], NFB.Food[1113]).name, NFB.Food[1113].name, "conjured ALWAYS wins")
        end,
        {"UnitLevel", function () return 45 end},
        {"UnitHealthMax", function () return 100 end},
        {"GetItemCount", function (id) if id == 8932 then return 3 else return 5 end end}
    )
end

function Tests.cases.BetterBuffFood_Basic()
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterBuffFood(NFB.Food[17222], NFB.Food[3729]).name, NFB.Food[17222].name)
        end,
        {"UnitLevel", function () return 45 end},
        {"UnitHealthMax", function () return 100 end},
        {"GetItemCount", function () return 10 end}
    )
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterBuffFood(NFB.Food[17222], NFB.Food[16971]).name, NFB.Food[17222].name, "lower quantity wins")
        end,
        {"UnitLevel", function () return 45 end},
        {"UnitHealthMax", function () return 100 end},
        {"GetItemCount", function (id) if id == 17222 then return 3 else return 5 end end}
    )
end

function Tests.cases.BetterDrink_Basic()
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterDrink(NFB.Food[18300], NFB.Food[19300]).name, NFB.Food[18300].name)
            assertEquals(NFB:BetterDrink(NFB.Food[18300], NFB.Food[8079]).name, NFB.Food[8079].name, "conjured wins")
        end,
        {"UnitLevel", function () return 55 end},
        {"UnitHealthMax", function () return 100 end},
        {"GetItemCount", function () return 10 end}
    )
end

function Tests.cases.BetterBuffDrink_Basic()
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterBuffDrink(NFB.Food[13931], NFB.Food[21217]).name, NFB.Food[13931].name)
        end,
        {"UnitLevel", function () return 55 end},
        {"UnitHealthMax", function () return 100 end},
        {"GetItemCount", function () return 10 end}
    )
end

function Tests.cases.BetterHPotion_Basic()
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterHPotion(NFB.Potion[1710], NFB.Potion[13446]).name, NFB.Potion[1710].name)
        end,
        {"UnitLevel", function () return 40 end}
    )
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterHPotion(NFB.Potion[1710], NFB.Potion[13446]).name, NFB.Potion[13446].name)
        end,
        {"UnitLevel", function () return 45 end}
    )
end

function Tests.cases.BetterMPotion_Basic()
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterMPotion(NFB.Potion[3385], NFB.Potion[6149]).name, NFB.Potion[6149].name)
        end,
        {"UnitLevel", function () return 55 end}
    )
end

function Tests.cases.BetterBandage_Basic()
    replaceAndCall(
        function ()
            assertEquals(NFB:BetterBandage(NFB.Bandage[8545], NFB.Bandage[14529]).name, NFB.Bandage[14529].name)
        end,
        {"UnitLevel", function () return 55 end}
    )
end

function Tests.cases.BetterHealthstone_Basic()
    replaceAndCall(
        function()
            assertEquals(NFB:BetterHealthstone(NFB.Healthstone[19009], NFB.Healthstone[19010]).name, NFB.Healthstone[19010].name)
            assertEquals(NFB:BetterHealthstone(NFB.Healthstone[5509], NFB.Healthstone[19008]).name, NFB.Healthstone[19008].name)
        end,
        {"UnitLevel", function () return 60 end}
    )
end

function Tests.cases.BetterManaGem_Basic()
    replaceAndCall(
        function()
            assertEquals(NFB:BetterManaGem(NFB.ManaGem[8007], NFB.ManaGem[8008]).name, NFB.ManaGem[8008].name)
        end,
        {"UnitLevel", function () return 60 end}
    )
end

--NFB:runTests()