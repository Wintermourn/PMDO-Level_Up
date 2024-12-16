# LevelUp
##### EXP requirement and level cap generation for PMDO/RogueEssence

This mod automatically generates level caps for PMDO, supporting existing growth rates and the option to add in more.

### Setup
The mod should be placed in a folder in your `MODS` folder, so that the folder contains `Mod.xml` and `Data` in the top level.
All options can be changed in the [main.lua](Data/Script/levelup/main.lua) file, including:
- Level Cap
- Automatically regenerate existing levels
- Custom growth rate formulas

### How does it work?
As you can see in the [main.lua](Data/Script/levelup/main.lua) file, the entire mod is 127 lines, *including whitespace*. It's a very simple mod, and is probably *very easy* to break, if it even works in the first place.
Several C# classes are stored (using luanet) to properly match required types by the systems.
`UpdateMaxLevels` runs a loop through all growth rates/groups, replacing their EXP tables with a generated array (resizing doesn't seem to be possible, due to a lack of `ref` in lua).
Other mods *should* be able to access `UpdateMaxLevels` and `RegisterFormula` through the `LevelUp` global table. Note that formulas registered by other mods can't override custom user formulae.
