local LevelUp = {
    -- Overrides the default maximum level, changing it for the current session.
    -- If disabled, the mod will still generate missing exp values.
    -- Default: true
    OverrideMaxLevel = true,

    -- If existing experience requirements exist, this will recalculate them.
    -- Default: false
    RecalculateExistingLevels = false,

    -- The maximum level that any(?) Pokemon can reach.
    -- PMDO Default:    100
    -- LevelUp Default: 200
    MaxLevel = 200,

    -- Custom formula for leveling go here
    -- Format: ["growth_data"] = function(level) return number end
    --          growth type               |             |
    --          (fast, slow, ...)         current level |
    --                                                  total experience required to reach next level
    ---@type (fun(level: number): number)[]
    Formulae = {
    }
}

-- EVERYTHING BELOW IS CODE EVERYTHING BELOW IS CODE EVERYTHING BELOW IS CODE EVERYTHING BELOW IS CODE
--  Be careful with what you edit!
-- EVERYTHING BELOW IS CODE EVERYTHING BELOW IS CODE EVERYTHING BELOW IS CODE EVERYTHING BELOW IS CODE

---@diagnostic disable: undefined-global

LevelUp.ExternalFormulae = {};
local LevelUp_Public = {};
local __Array = luanet.import_type('System.Array'); -- Used to recreate EXPTable (can't access Array.Resize, unless there's some way to ref...)
local __Int32 = luanet.import_type('System.Int32'); -- Guaranteed int
local __Type =  luanet.import_type('System.Type');  -- Used to get Type instead of ProxyType
local type_Int32 = __Type.GetType('System.Int32');

local function UpdateMaxLevels()
    local realMaxLevel = LUA_ENGINE:LuaCast(LevelUp.MaxLevel, __Int32);

    if LevelUp.OverrideMaxLevel then
        _DATA.Start.MaxLevel = realMaxLevel;
    end

    local list = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.GrowthGroup]:GetOrderedKeys(false);
    for i = 0, list.Count - 1 do
        local growth = _DATA:GetGrowth(list[i]);
        if (LevelUp.Formulae[list[i]] or LevelUp.ExternalFormulae[list[i]]) then
            local levels = __Array.CreateInstance(type_Int32, _DATA.Start.MaxLevel);
            if not LevelUp.RecalculateExistingLevels then growth.EXPTable:CopyTo(levels, 0); end
            local rExp;
            if LevelUp.Formulae[list[i]] then
                for lv = (LevelUp.RecalculateExistingLevels and 0 or growth.EXPTable.Length), _DATA.Start.MaxLevel - 1 do
                    rExp = LevelUp.Formulae[list[i]](lv+1);
                    if type(rExp) == 'number' then
                        levels[lv] = LUA_ENGINE:LuaCast(rExp,__Int32);
                    else
                        error(string.format("LevelUp: Formula for %s did not return a number for level %s", list[i], lv+1));
                    end
                end
                growth.EXPTable = levels;

                print(string.format("LevelUp: GrowthData %s updated to be %s long", list[i], growth.EXPTable.Length));
            elseif LevelUp.ExternalFormulae[list[i]] then
                for lv = (LevelUp.RecalculateExistingLevels and 0 or growth.EXPTable.Length), _DATA.Start.MaxLevel - 1 do
                    rExp = LevelUp.ExternalFormulae[list[i]](lv+1);
                    if type(rExp) == 'number' then
                        levels[lv] = LUA_ENGINE:LuaCast(rExp,__Int32);
                    else
                        error(string.format("LevelUp: Formula for %s did not return a number for level %s", list[i], lv+1));
                    end
                end
                growth.EXPTable = levels;

                print(string.format("LevelUp: GrowthData %s updated to be %s long", list[i], growth.EXPTable.Length));
            else
                print(string.format("LevelUp: GrowthData %s could not be updated; formula does not exist in LevelUp.Formulae", list[i]));
            end
        end
    end
end
LevelUp_Public.UpdateMaxLevels = UpdateMaxLevels;

---@param growthRateName 'fast'|'slow'|'medium_fast'|'medium_slow'|'erratic'|'fluctuating'|string
---@param formula fun(level: number): number
function LevelUp_Public.RegisterFormula(growthRateName, formula)
    if LevelUp.ExternalFormulae[growthRateName] then
        print(string.format("LevelUp: Existing growth rate formula for %s has been overwritten by a new one", growthRateName));
    end
    LevelUp.ExternalFormulae[growthRateName] = formula;
end

---# LevelUp!
---Globally available methods for the LevelUp mod.
---To register new XP formulas, use `RegisterFormula`.
---
---To regenerate xp requirements (if adding a formula for ), use `UpdateMaxLevels`.
_G.LevelUp = LevelUp_Public;

-- Default XP formulas
--  mostly based on the formulas used in Pokemon Essentials
    LevelUp_Public.RegisterFormula('erratic', function (level)
        return ((level^4) + ((level^3) * 2000)) / 3500;
    end)
    LevelUp_Public.RegisterFormula('fluctuating', function (level)
        -- This might absolutely suck, but I'm not really sure how the rest feel over level 100 either.
        local frequency     = level / 5.0;
        local sine_factor   = math.sin(frequency * math.pi);
        local growth_factor = sine_factor + level * ((5/3)*(5/4-4/5));
        return (growth_factor^(3.4)*140)/(100+level);
    end)
    LevelUp_Public.RegisterFormula('fast', function (level)
        return level^3*4/5;
    end)
    LevelUp_Public.RegisterFormula('slow', function (level)
        return level^3*5/4;
    end)
    LevelUp_Public.RegisterFormula('medium_fast', function (level)
        return level^3;
    end)
    LevelUp_Public.RegisterFormula('medium_slow', function (level)
        return ((level^3) * 6 / 5) - (15 * (level^2)) + (100 * level) - 140;
    end)
--

UpdateMaxLevels();
