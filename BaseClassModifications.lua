---------------------------------------------------------------------------------
------------------------------------ ATTENTION ----------------------------------
----------- This file allows modders to Modify to Base Game functions -----------
----------It can also be used to add but not modify, Core Lua functions----------
------------ Always ensure you have the most up to date version from ------------
-------- https://github.com/garethyr/CortexCommandBaseClassModifications --------
--------------------------------- Version 0.0.1 ---------------------------------
---------------------------------------------------------------------------------

--START UNMODIFIABLE SECTION--
local modificationTable = {};

local function searchForExistingEntryForMetatableAndCheckForDuplicateCustomFunctions(metatable, customFunctionTable)
	local existingIndex = -1;
	for i, modificationEntry in ipairs(modificationTable) do
		if (modificationEntry.metatable == metatable) then
			existingIndex = i;
		end
	end
	
	if (existingIndex >= 0) then
		for customFunctionKey, _ in pairs(customFunctionTable) do
			assert(modificationTable[existingIndex][customFunctionKey] == nil, "Custom function entry "..tostring(customFunctionKey).." already exists for metatable "..tostring(metatable)..". This should never happen and probably means you've duplicated a Base Class Modification. If you can't figure this out, go to the github page for support.");
		end
	end
	
	return existingIndex;
end

--Use this function to specify that you'll be modifying a base class. NOTE: Only set classUsesBracketConstructor to true if the class uses bracket constructors (e.g. Vector), otherwise skip it
local function setupBaseClassModification(baseClass, customFunctionTable, classUsesBracketConstructor)
	local modificationEntry = {
		baseClass = baseClass,
		metatable = getmetatable(classUsesBracketConstructor and baseClass() or baseClass),
		customFunctionTable = customFunctionTable;
	};
	modificationEntry.oldIndex = modificationEntry.metatable.__index;
	
	local existingIndexOfMetatable = searchForExistingEntryForMetatableAndCheckForDuplicateCustomFunctions(modificationEntry.metatable, customFunctionTable);
	
	if (existingIndexOfMetatable >= 0) then
		for customFunctionKey, customFunction in pairs(modificationEntry.customFunctionTable) do
			modificationTable[existingIndexOfMetatable].customFunctionTable[customFunctionKey] = customFunction;
		end
	else
		table.insert(modificationTable, modificationEntry);
	end
	return classUsesBracketConstructor and modificationEntry.baseClass or nil;
end

--Use this function to print error messages explaining what arguments need to be passed in to the modified base function.
--Parameters are as follows:
--classNameOrErrorDataTable - Either the name of the class (e.g. Vector) or a table with all the required data, using either numerical keys ordered to match this function's arguments, or string keys that match this function's argument names.
--functionName - The name of the function called
--suppliedArgumentTypes - A table of the types of the incorrect arguments passed in to the function. Obtainable by using type(argument) for each argument.
--allowedArgumentTypeSets - A table of tables, each subtable of which contains a string set of allowed arguments. E.g. A function that supports a number argument and, optionally, a Vector argument would have the table {{"number"}, {"number", "Vector"}}.
--isConstructor - Whether or not the called function was a constructor. This changes some wording and is mostly not used. Defaults to false.

--TODO This should have a parent function that does error checking based on the table. Need to reorganize stuff a little but it'd make it nice and easy for others to follow a template

local function printArgumentError(classNameOrErrorDataTable, functionName, suppliedArgumentTypes, allowedArgumentTypeSets, isConstructor, usesPeriodInsteadOfSemiColon)
	local className = classNameOrErrorDataTable;
	
	if (type(classNameOrErrorDataTable) == "table") then
		className = classNameOrErrorDataTable.className or classNameOrErrorDataTable[1];
		functionName = classNameOrErrorDataTable.functionName or classNameOrErrorDataTable[2];
		suppliedArgumentTypes = classNameOrErrorDataTable.suppliedArgumentTypes or classNameOrErrorDataTable[3];
		allowedArgumentTypeSets = classNameOrErrorDataTable.allowedArgumentTypeSets or classNameOrErrorDataTable[4];
		isConstructor = classNameOrErrorDataTable.isConstructor or classNameOrErrorDataTable[5] or false; --Default to false
		usesPeriodInsteadOfSemiColon = classNameOrErrorDataTable.usesPeriodInsteadOfSemiColon or classNameOrErrorDataTable[6] or false; --Default to false
	end

	local errorString = "ERROR: no ";
	errorString = errorString..(isConstructor == true and "constructor " or "overload ");
	errorString = errorString..string.format("of '%s:%s' matched the arguments (%s)", className, functionName, className..", "..table.concat(suppliedArgumentTypes, ", ")).."\n";
	errorString = errorString.."candidates are:\n";
	for _, allowedArgumentTypeSet in  ipairs(allowedArgumentTypeSets) do
		errorString = errorString..string.format("%s%s%s(%s)", className, (usesPeriodInsteadOfSemiColon and "." or ":"), functionName, table.concat(allowedArgumentTypeSet, ", "));
		errorString = errorString.."\n";
	end
	ConsoleMan:PrintString(errorString);
	error("<- Error Came From Here", 3);
end
--END UNMODIFIABLE SECTION--

--START MODIFIABLE SECTION--

---------------------------------------------
-------Core Lua Function Modifications-------
--------------------NOTE:--------------------
------Do not replace core Lua Functions------
----------------Only Add Them----------------
---------------------------------------------
table.listToSet = function(list, valueToGiveEntries)
	local argumentErrorTable = {"table", "listToSet", {type(list), type(valueToGiveEntries)}, {{"table"}, {"table", "a non-nil value"}}, usesPeriodInsteadOfSemiColon = true};
	
	if (type(list) ~= "table") then
		printArgumentError(argumentErrorTable);
	end

	if (valueToGiveEntries == nil) then
		valueToGiveEntries = true;
	end
	
	local set = {}
	for _, listElement in ipairs(list) do
		set[listElement] = valueToGiveEntries;
	end
    
	return set;
end

table.setToList = function(set, valueNeededToAddToList)
	local argumentErrorTable = {"table", "setToList", {type(set), type(valueNeededToAddToList)}, {{"table"}, {"table", "any value"}}, usesPeriodInsteadOfSemiColon = true};
	
	if (type(set) ~= "table") then
		printArgumentError(argumentErrorTable);
	end
	
	local list = {};
	for setElementKey, setElementValue in pairs(set) do
		if (valueNeededToAddToList == nil or setElementValue == valueNeededToAddToList) then
			table.insert(list, setElementKey);
		end
	end
	
	return list;
end

function string.split(stringToSplit, separator)
	local argumentErrorTable = {"string", "split", {type(stringToSplit), type(separator)}, {{"string", "string"}}, usesPeriodInsteadOfSemiColon = true};
	if (type(stringToSplit) ~= "string" or type(separator) ~= "string") then
		printArgumentError(argumentErrorTable);
	end
	
	return stringToSplit:split(separator);
end

function string:split(separator)
	local argumentErrorTable = {"string", "split", {type(separator)}, {{"string"}}};
	if (type(separator) == "nil") then
		printArgumentError(argumentErrorTable);
	end

	local fields = {};
	self:gsub(string.format("([^%s]+)", separator), function(splitString) fields[#fields+1] = splitString end);
	return fields;
end

function math.normaliseDegAngle(angleInDegrees)
	local argumentErrorTable = {"math", "normaliseDegAngle", {type(angleInDegrees)}, {{"number"}}, usesPeriodInsteadOfSemiColon = true};
	
	if (type(angleInDegrees) ~= "number") then
		printArgumentError(argumentErrorTable);
	end
	
	return ((angleInDegrees % 360) + 360) % 360;
end

function math.normaliseRadAngle(angleInRadians)
	local argumentErrorTable = {"math", "normaliseRadAngle", {type(angleInRadians)}, {{"number"}}, usesPeriodInsteadOfSemiColon = true};
	
	if (type(angleInRadians) ~= "number") then
		printArgumentError(argumentErrorTable);
	end
	
	return math.rad(math.normaliseDegAngle(math.deg(angleInRadians)));
end
---------------------------------------
--End Core Lua Function Modifications--
---------------------------------------

---------------
--SceneObject--
---------------

-----------
--MOPixel--
-----------

-----------------
--TerrainObject--
-----------------

------------
--MOSprite--
------------

---------------
--MOSParticle--
---------------

---------------
--MOSRotating--
---------------

--------------
--Attachable--
--------------

------------
--Emission--
------------

------------
--AEmitter--
------------

---------
--Actor--
---------

---------
--ADoor--
---------

----------
--AHuman--
----------

---------
--ACrab--
---------

----------
--ACraft--
----------

------------
--ACRocket--
------------

--------------
--HeldDevice--
--------------

------------
--Magazine--
------------

---------
--Round--
---------

-------------
--HDFirearm--
-------------

----------------
--ThrownDevice--
----------------

---------------
--TDExplosive--
---------------

---------
--Scene--
---------

--------------
--Deployment--
--------------

------------
--Activity--
------------

----------------
--GameActivity--
----------------

----------------
--GlobalScript--
----------------

----------
--Vector--
----------
--Define your custom new or overriding functions here.
--Please Note the Following:
--1. I suggest you use the name #ClassName#Modifications for your modifications table (obtained as return value 1 of the setupBaseClassModification function), as it makes it easy to find and organize with Notepad++'s function viewer. This is, however, entirely optional.

do 
	local VectorModifications = {};
	
	function VectorModifications:Copy()
		return Vector(self.X, self.Y);
	end
	
	function VectorModifications:RadRotate(angle, ...)
		local argumentErrorTable = {"Vector", "RadRotate", {type(angle)}, {{"number"}, {"number", "boolean"}}};
	
		if (type(angle) ~= "number") then
			printArgumentError(argumentErrorTable);
		end
	
		if (select("#", ...) > 0) then
			local doCopy = select(1, ...);
			
			if (type(doCopy) ~= "boolean") then
				table.insert(argumentErrorTable[3], type(doCopy)); --Add doCopy's type as a supplied argument type for the argument error table
				printArgumentError(argumentErrorTable);
			end
			
			return self:Copy():RadRotate_BASE(angle);
		end
		return self:RadRotate_BASE(angle);
	end
	
	setupBaseClassModification(Vector, VectorModifications, true);
end


-------
--Box--
-------

---------
--Sound--
---------

--------------
--Controller--
--------------

---------
--Timer--
---------

----------------
--TimerManager--
----------------

----------------
--FrameManager--
----------------

-----------------
--PresetManager--
-----------------

----------------
--AudioManager--
----------------

-----------------
--UInputManager--
-----------------

----------------
--SceneManager--
----------------
do 
	local SceneManagerModifications = {};
	
	function SceneManagerModifications:GetTerrMatter(point, ...)
		local argumentErrorTable = {"SceneManager", "GetTerrMatter", {type(point) == "userdata" and point.ClassName or type(point)}, {{"Vector"}, {"number", "number"}}};
		
		if (select("#", ...) > 0) then
			local yValue = select(1, ...);
			
			table.insert(argumentErrorTable[3], type(yValue));
			if (type(point) ~= "number" or type(yValue) ~= "number") then
				printArgumentError(argumentErrorTable);
			end
			
			return self:GetTerrMatter_BASE(point, yValue);
		end
		
		if (type(point) ~= "userdata" or point.ClassName ~= "Vector") then
			printArgumentError(argumentErrorTable);
		end
		
		return self:GetTerrMatter_BASE(point.X, point.Y);
	end
	
	function SceneManagerModifications:TargetDistanceScalar(point, ...)
		local argumentErrorTable = {"SceneManager", "TargetDistanceScalar", {type(point) == "userdata" and point.ClassName or type(point)}, {{"Vector"}, {"Vector", "number"}}};
	
		if (type(point) ~= "userdata" or point.ClassName ~= "Vector") then
			printArgumentError(argumentErrorTable);
		end
		
		if (select("#", ...) == 0) then
			return self:TargetDistanceScalar_BASE(point);
		end
		
		local screen = select(1, ...);
		if (type(screen) ~= "number") then
			table.insert(argumentErrorTable[3], type(screen)); --Add screen's type as a supplied argument type for the argument error table
			printArgumentError(argumentErrorTable);
		end
		if (self.Scene == nil) then
			return 0;
		end
		
		local sceneRadius = math.max(self.SceneWidth, self.SceneHeight)/2;
		local screenRadius = math.max(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenWidth)/2;
		
		--Avoid divide by zero problems if scene and screen radius are the same
		if (sceneRadius == screenRadius) then
			sceneRadius = sceneRadius + 100;
		end
		
		local distance = self:ShortestDistance(point, self:GetScrollTarget(screen), self.SceneWrapsX).Magnitude;
		
		if (distance <= screenRadius) then
			return 0; --Return 0 if within the screen
		end
		
		return 0.5 + (0.5 * (distance - screenRadius) / (sceneRadius - screenRadius)); --Return fallen-off value if we're off the screen
	end

	function SceneManagerModifications:ShortestDistance(vector1, vector2, ...)
		local argumentErrorTable = {"SceneManager", "ShortestDistance", {type(vector1) == "userdata" and vector1.ClassName or type(vector1), type(vector2) == "userdata" and vector2.ClassName or type(vector2)}, {{"Vector", "Vector"}, {"Vector", "Vector", "boolean"}}};
	
		local accountForWrapping = true; --Default to true
		
		if (select("#", ...) > 0) then
			accountForWrapping = select(1, ...);
		end
		
		if ((type(vector1) ~= "userdata" or vector1.ClassName ~= "Vector") or (type(vector2) ~= "userdata" or vector2.ClassName ~= "Vector")) then
			printArgumentError(argumentErrorTable);
		end
		
		return SceneMan:ShortestDistance_BASE(vector1, vector2, accountForWrapping);
	end
	
	setupBaseClassModification(SceneMan, SceneManagerModifications);
end

--------------
--BuyMenuGUI--
--------------

------------------
--SceneEditorGUI--
------------------

-------------------
--ActivityManager--
-------------------

--------------
--MetaPlayer--
--------------

---------------
--MetaManager--
---------------

------------------
--MovableManager--
------------------

------------------
--ConsoleManager--
------------------

--------------
--LuaManager--
--------------

--------------------
--SettingsdManager--
--------------------

--END MODIFIABLE SECTION--

--START UNMODIFIABLE SECTION--
--Overwrite __index metamethod for the each modification entry (or baseInstance if it exists) so it calls custom functions and add flag showing that it's been modified
--If forceModifications is true, it will always modify the class even if it's already been modified. This will almost certainly cause crashes and should never actually be used!
local function runBaseClassModifications(forceModifications)
	local classesModified = false;
	for _, modificationEntry in pairs(modificationTable) do
		local customFunctionTableKeys = {};
		for k, ______ in pairs(modificationEntry.customFunctionTable) do
			table.insert(customFunctionTableKeys, k);
		end
		
		if (forceModifications == true or not modificationEntry.metatable.__modified_by_custom_lua) then
			modificationEntry.metatable.__index = function(self, key)
				if (self ~= nil and key ~= nil) then
					if (modificationEntry.customFunctionTable[key] ~= nil) then
						return modificationEntry.customFunctionTable[key];
					end
					
					if (key:find("_BASE")) then
						key = key:sub(1, key:len() - string.len("_BASE"));
					end
				end
				return modificationEntry.oldIndex(self, key)
			end
			modificationEntry.metatable.__modified_by_custom_lua = true;
			classesModified = true;
		end
	end
	if (classesModified) then
		ConsoleMan:PrintString("");
		ConsoleMan:PrintString("--------------------------------------------------------------------------------");
		ConsoleMan:PrintString("--NOTE: Base Classes Have Been Modified By BaseClassModifications Script. Don't Panic!--");
		ConsoleMan:PrintString("--------------------------------------------------------------------------------");
	end
end
runBaseClassModifications();
--END UNMODIFIABLE SECTION--