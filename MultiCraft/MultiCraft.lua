local SI = {}
if MultiCraftAddon == nil then MultiCraftAddon = {} end

MultiCraftAddon.name = "MultiCraft"
MultiCraftAddon.version = 1.2

MultiCraftAddon.debug = false

MultiCraftAddon.settings = {
	sliderDefault = false,
	traitsEnabled = true,
	callDelay = 500
}

-- register SIs
SI.USAGE_1		= "SI_USAGE_1"
SI.USAGE_2		= "SI_USAGE_2"
SI.USAGE_3		= "SI_USAGE_3"
SI.USAGE_4		= "SI_USAGE_4"
SI.DEFAULT_MAX	= "SI_DEFAULT_MAX"
SI.DEFAULT_MIN	= "SI_DEFAULT_MIN"
SI.TRAITS_ON	= "SI_TRAITS_ON"
SI.TRAITS_OFF	= "SI_TRAITS_OFF"
SI.CALL_DELAY	= "SI_CALL_DELAY"

-- utility functions
function SI.get(key, n)
    assert(key ~= nil)
    return assert(GetString(_G[key], n))
end

MultiCraftAddon.SI = SI

MultiCraftAddon.ENCHANTING_MODE_CREATION = ENCHANTING_MODE_CREATION		-- this is globally defined by ZoS
MultiCraftAddon.ENCHANTING_MODE_EXTRACTION = ENCHANTING_MODE_EXTRACTION -- this is globally defined by ZoS
MultiCraftAddon.SMITHING_MODE_REFINEMENT = 1							-- Smithing ones aren't, what the crap?
MultiCraftAddon.SMITHING_MODE_CREATION = 2
MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION = 4
MultiCraftAddon.GENERAL_MODE_CREATION = 1								-- it's useful to have everything act similar

MultiCraftAddon.repetitions = 1
MultiCraftAddon.sliderValue = 1
MultiCraftAddon.isWorking = false

MultiCraftAddon.provisioner = {
	en = {
		[MultiCraftAddon.GENERAL_MODE_CREATION] = {x = 148, y = -12}
	},
	de = {
		[MultiCraftAddon.GENERAL_MODE_CREATION] = {x = 176, y = -12}
	},
	fr = {
		[MultiCraftAddon.GENERAL_MODE_CREATION] = {x = 174, y = -12}
	}
}

MultiCraftAddon.alchemy = {
	en = {
		[MultiCraftAddon.GENERAL_MODE_CREATION] = {x = 272, y = -12}
	},
	de = {
		[MultiCraftAddon.GENERAL_MODE_CREATION] = {x = 331, y = -12}
	},
	fr = {
		[MultiCraftAddon.GENERAL_MODE_CREATION] = {x = 328, y = -12}
	}
}

MultiCraftAddon.enchanting = {
	en = {
		[MultiCraftAddon.ENCHANTING_MODE_CREATION] = {x = 272, y = -12},
		[MultiCraftAddon.ENCHANTING_MODE_EXTRACTION] = {x = 284, y = -12}
	},
	de = {
		[MultiCraftAddon.ENCHANTING_MODE_CREATION] = {x = 331, y = -12},
		[MultiCraftAddon.ENCHANTING_MODE_EXTRACTION] = {x = 331, y = -12}
	},
	fr = {
		[MultiCraftAddon.ENCHANTING_MODE_CREATION] = {x = 328, y = -12},
		[MultiCraftAddon.ENCHANTING_MODE_EXTRACTION] = {x = 318, y = -12}
	}
}

MultiCraftAddon.smithing = {
	en = {
		[MultiCraftAddon.SMITHING_MODE_REFINEMENT] = {x = 280, y = -12},
		[MultiCraftAddon.SMITHING_MODE_CREATION] = {x = 148, y = -12},
		[MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION] = {x = 310, y = -12}
	},
	de = {
		[MultiCraftAddon.SMITHING_MODE_REFINEMENT] = {x = 324, y = -12},
		[MultiCraftAddon.SMITHING_MODE_CREATION] = {x = 176, y = -12},
		[MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION] = {x = 331, y = -12}
	},
	fr = {
		[MultiCraftAddon.SMITHING_MODE_REFINEMENT] = {x = 320, y = -12},
		[MultiCraftAddon.SMITHING_MODE_CREATION] = {x = 174, y = -12},
		[MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION] = {x = 344, y = -12}
	}
}

MultiCraftAddon.selectedCraft = nil 	-- this will hold a pointer to the currently open crafting station

local function Debug(message)
	if MultiCraftAddon.debug then
		d(message)
	end
end

local function GetClientLanguage()
	local language = GetCVar("language.2")
	if MultiCraftAddon.selectedCraft[language] then return language end
	return "en"
end

local function ToggleSliderDefault()
	MultiCraftAddon.settings.sliderDefault = not MultiCraftAddon.settings.sliderDefault
	
	if MultiCraftAddon.settings.sliderDefault then
		d(SI.get(SI.DEFAULT_MAX))
	else
		d(SI.get(SI.DEFAULT_MIN))
	end
end

local function ToggleTraits()
	MultiCraftAddon.settings.traitsEnabled = not MultiCraftAddon.settings.traitsEnabled
	
	if MultiCraftAddon.settings.traitsEnabled then
		d(SI.get(SI.TRAITS_ON))
	else
		d(SI.get(SI.TRAITS_OFF))
	end
end

local function SetCallDelay(number)
	MultiCraftAddon.settings.callDelay = number
end

function MultiCraftAddon.SelectCraftingSkill(eventId, craftingType, sameStation)
	if craftingType == CRAFTING_TYPE_PROVISIONING then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.provisioner
		MultiCraft:SetHidden(false)
		Debug("Selected Provisioner")
	elseif craftingType == CRAFTING_TYPE_ENCHANTING then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.enchanting
		Debug("Selected Enchanting")
	elseif craftingType == CRAFTING_TYPE_ALCHEMY then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.alchemy
		MultiCraft:SetHidden(false)
		Debug("Selected Alchemy")
	elseif craftingType ~= CRAFTING_TYPE_INVALID then
		MultiCraftAddon.selectedCraft = MultiCraftAddon.smithing
		Debug("Selected Smithing")
	end
	
	MultiCraftAddon:SetLabelAnchor()
	MultiCraftAddon:ResetSlider()
end

function MultiCraftAddon.HideUI(...)
	MultiCraft:SetHidden(true)
end

function MultiCraftAddon.Cleanup(...)
	MultiCraftAddon.HideUI(...)
	MultiCraftAddon.selectedCraft = nil
	Debug("Cleaned")
end

function MultiCraftAddon:EnableOrDisableUI()
	Debug("EnableOrDisableUI()")
	local hidden = true
	
	local mode = MultiCraftAddon.selectedCraft:GetMode()
	if MultiCraftAddon.selectedCraft == MultiCraftAddon.provisioner or
	   MultiCraftAddon.selectedCraft == MultiCraftAddon.alchemy then
		if MultiCraftAddon.selectedCraft:IsCraftable() then
			hidden = false
		end
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.enchanting then
		if (mode == MultiCraftAddon.ENCHANTING_MODE_CREATION and MultiCraftAddon.selectedCraft:IsCraftable()) or
		   (mode == MultiCraftAddon.ENCHANTING_MODE_EXTRACTION and MultiCraftAddon.selectedCraft:IsExtractable()) then
			hidden = false
		end
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.smithing then
-- there is a game bug where this returns erroneously true in refinement after completing an extract that results in having less
-- than 10 items but still having the item selected
-- TODO: fix it
		if (mode == MultiCraftAddon.SMITHING_MODE_REFINEMENT and MultiCraftAddon.selectedCraft:IsExtractable()) or
		   (mode == MultiCraftAddon.SMITHING_MODE_CREATION and MultiCraftAddon.selectedCraft:IsCraftable()) or
		   (mode == MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION and MultiCraftAddon.selectedCraft:IsDeconstructable()) then
			hidden = false
		end
	end
	Debug("hidden = " .. tostring(hidden))
	MultiCraft:SetHidden(hidden)
end

function MultiCraftAddon:SetLabelAnchor()
	if not MultiCraftAddon.selectedCraft then return end
	MultiCraftLabel:ClearAnchors()
	
	local language = GetClientLanguage()
	local mode = MultiCraftAddon.selectedCraft:GetMode()
	
	if MultiCraftAddon.selectedCraft[language][mode] then
		MultiCraftLabel:SetAnchor(BOTTOMLEFT, MultiCraft, nil, MultiCraftAddon.selectedCraft[language][mode].x, MultiCraftAddon.selectedCraft[language][mode].y)
	end
end

function MultiCraftAddon.SetLabelAndValue(...)
	MultiCraftAddon.sliderValue = zo_floor(MultiCraftSlider:GetValue())
	Debug("sliderValue = " .. tostring(MultiCraftAddon.sliderValue))
	MultiCraftLabel:SetText(string.format("%d", MultiCraftAddon.sliderValue))
end

function MultiCraftAddon:ResetSlider()
	Debug("ResetSlider()")
	if not MultiCraftAddon.selectedCraft then return end
	MultiCraftAddon:EnableOrDisableUI()
		
	local numCraftable = 1
	local mode = MultiCraftAddon.selectedCraft:GetMode()
	
	if MultiCraftAddon.selectedCraft == MultiCraftAddon.provisioner then
		if MultiCraftAddon.selectedCraft:IsCraftable() then
			local data = PROVISIONER.recipeTree:GetSelectedData()
			numCraftable = data.numCreatable
		end
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.enchanting then
		if mode == MultiCraftAddon.ENCHANTING_MODE_CREATION then
			if MultiCraftAddon.selectedCraft:IsCraftable() then
				for k, v in pairs(ENCHANTING.runeSlots) do
					if k == 1 then
						numCraftable = v.craftingInventory.itemCounts[v.itemInstanceId]
					else 
						numCraftable = zo_min(numCraftable, v.craftingInventory.itemCounts[v.itemInstanceId])
					end
					Debug("in for numCraftable = " .. tostring(zo_floor(numCraftable)))
				end			
			end
		elseif mode == MultiCraftAddon.ENCHANTING_MODE_EXTRACTION then
			if MultiCraftAddon.selectedCraft:IsExtractable() then
				numCraftable = ENCHANTING.extractionSlot.craftingInventory.itemCounts[ENCHANTING.extractionSlot.itemInstanceId]
			end
		end
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.alchemy then
		if MultiCraftAddon.selectedCraft:IsCraftable() then
			numCraftable = ALCHEMY.solventSlot.craftingInventory.itemCounts[ALCHEMY.solventSlot.itemInstanceId]
			for k, v in pairs(ALCHEMY.reagentSlots) do
				if v.craftingInventory.itemCounts[v.itemInstanceId] ~= nil then
					numCraftable = zo_min(numCraftable, v.craftingInventory.itemCounts[v.itemInstanceId])
					Debug("in for numCraftable = " .. tostring(zo_floor(numCraftable)))
				end
			end
		end
	elseif MultiCraftAddon.selectedCraft == MultiCraftAddon.smithing then
		if mode == MultiCraftAddon.SMITHING_MODE_REFINEMENT then
			if MultiCraftAddon.selectedCraft:IsExtractable() then
				numCraftable = SMITHING.refinementPanel.extractionSlot.craftingInventory.itemCounts[SMITHING.refinementPanel.extractionSlot.itemInstanceId]
				numCraftable = zo_floor(numCraftable / GetRequiredSmithingRefinementStackSize())
			end
		elseif mode == MultiCraftAddon.SMITHING_MODE_CREATION then
			if MultiCraftAddon.selectedCraft:IsCraftable() then
				Debug("SMITHING Creation")
				-- determine metrics for the slider
				local patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex = SMITHING.creationPanel:GetAllCraftingParameters()
				local materialCount = GetCurrentSmithingMaterialItemCount(patternIndex, materialIndex) / materialQuantity
				local styleItemCount = GetCurrentSmithingStyleItemCount(styleIndex)
				local traitCount = GetCurrentSmithingTraitItemCount(traitIndex)
				
				numCraftable = zo_min(materialCount, styleItemCount)
				
				if traitIndex ~= 1 then
					if MultiCraftAddon.settings.traitsEnabled then
						numCraftable = zo_min(numCraftable, traitCount)
					else
						numCraftable = 1
					end
				end
			end
		elseif mode == MultiCraftAddon.SMITHING_MODE_DECONSTRUCTION then
			if MultiCraftAddon.selectedCraft:IsDeconstructable() then
				numCraftable = SMITHING.deconstructionPanel.extractionSlot.craftingInventory.itemCounts[SMITHING.deconstructionPanel.extractionSlot.itemInstanceId]
			end
		end
	end
	
	Debug("numCraftable = " .. tostring(zo_floor(numCraftable)))
	numCraftable = zo_floor(numCraftable)
	if numCraftable == 1 then
		Debug("Hide slider")
		MultiCraftSlider:SetHidden(true)
	else
		Debug("Show slider")
		MultiCraftSlider:SetHidden(false)
		MultiCraftSlider:SetMinMax(1, numCraftable)
	end
	
	if MultiCraftAddon.settings.sliderDefault then
		MultiCraftSlider:SetValue(numCraftable)
	else
		MultiCraftSlider:SetValue(1)
	end
end

function MultiCraftAddon:Work(workFunc)
	Debug("work called")
	
	if not MultiCraftAddon.isWorking then
		MultiCraftAddon.isWorking = true
		EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name .. 'CraftComplete', EVENT_CRAFT_COMPLETED, function() MultiCraftAddon:ContinueWork(workFunc) end)
		MultiCraftAddon.repetitions = MultiCraftAddon.sliderValue - 1
	end
end

function MultiCraftAddon:ContinueWork(workFunc)
	Debug("continue work called")
	
	if MultiCraftAddon.repetitions > 0 then
		MultiCraftAddon.repetitions = MultiCraftAddon.repetitions - 1
		zo_callLater(workFunc, MultiCraftAddon.settings.callDelay)
	else
		EVENT_MANAGER:UnregisterForEvent(MultiCraftAddon.name .. 'CraftComplete', EVENT_CRAFT_COMPLETED)
		MultiCraftAddon.isWorking = false
		MultiCraftAddon:ResetSlider()
	end
end

local function Initialize(eventCode, addonName)
	if addonName ~= MultiCraftAddon.name then return end
	MultiCraftAddon.settings = ZO_SavedVars:NewAccountWide(MultiCraftAddon.name .. 'SV', 1, nil, MultiCraftAddon.settings)
	
	EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name .. 'Interact',		EVENT_CRAFTING_STATION_INTERACT, 		MultiCraftAddon.SelectCraftingSkill)
	EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name .. 'Craft',			EVENT_CRAFT_STARTED, 					MultiCraftAddon.HideUI)
	EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name .. 'EndInteract', 	EVENT_END_CRAFTING_STATION_INTERACT, 	MultiCraftAddon.Cleanup)
	
	-- Set up function overrides
	-- Provisioner
	MultiCraftAddon.provisioner.SelectNode = PROVISIONER.recipeTree.SelectNode
	PROVISIONER.recipeTree.SelectNode = function(...)
		MultiCraftAddon.provisioner.SelectNode(...)
		MultiCraftAddon:ResetSlider()
	end
	
	-- create function
	MultiCraftAddon.provisioner.Create = function()
		PROVISIONER:Create()
	end
	
	-- for polymorphism
	MultiCraftAddon.provisioner.GetMode = function(...)
		return MultiCraftAddon.GENERAL_MODE_CREATION
	end
	
	-- wrapper to check if an item is craftable
	MultiCraftAddon.provisioner.IsCraftable = function(...)
		return PROVISIONER:IsCraftable()
	end
	
	-- Enchanting
	-- tab change
	MultiCraftAddon.enchanting.SetEnchantingMode = ENCHANTING.SetEnchantingMode
	ENCHANTING.SetEnchantingMode = function(...)
		MultiCraftAddon.enchanting.SetEnchantingMode(...)
		MultiCraftAddon:SetLabelAnchor()
		MultiCraftAddon:ResetSlider()
	end
	
	-- for polymorphism
	MultiCraftAddon.enchanting.GetMode = function(...)
		return ENCHANTING:GetEnchantingMode()
	end
	
	-- rune slot change
	MultiCraftAddon.enchanting.SetRuneSlotItem = ENCHANTING.SetRuneSlotItem
	ENCHANTING.SetRuneSlotItem = function(...)
		MultiCraftAddon.enchanting.SetRuneSlotItem(...)
		MultiCraftAddon:ResetSlider()
	end
	
	-- extraction selection change
	MultiCraftAddon.enchanting.OnSlotChanged = ENCHANTING.OnSlotChanged
	ENCHANTING.OnSlotChanged = function(...)
		MultiCraftAddon.enchanting.OnSlotChanged(...)
		MultiCraftAddon:ResetSlider()
	end
	
	-- create and extract function
	MultiCraftAddon.enchanting.Create = function()
		ENCHANTING:Create()
	end
		
	-- wrapper to check if an item is craftable
	MultiCraftAddon.enchanting.IsCraftable = function(...)
		return ENCHANTING:IsCraftable()
	end
	
	MultiCraftAddon.enchanting.IsExtractable = MultiCraftAddon.enchanting.IsCraftable
	
	-- Alchemy
	-- selection change
	MultiCraftAddon.alchemy.OnSlotChanged = ALCHEMY.OnSlotChanged
	ALCHEMY.OnSlotChanged = function(...)
		MultiCraftAddon.alchemy.OnSlotChanged(...)
		MultiCraftAddon:ResetSlider()
	end
	
	-- create function
	MultiCraftAddon.alchemy.Create = function()
		ALCHEMY:Create()
	end
	
	-- for polymorphism
	MultiCraftAddon.alchemy.GetMode = function(...)
		return MultiCraftAddon.GENERAL_MODE_CREATION
	end
	
	-- wrapper to check if an item is craftable
	MultiCraftAddon.alchemy.IsCraftable = function(...)
		return ALCHEMY:IsCraftable()
	end
	
	-- Smithing
	-- tab change
	MultiCraftAddon.smithing.SetMode = SMITHING.SetMode
	SMITHING.SetMode = function(...)
		MultiCraftAddon.smithing.SetMode(...)
		MultiCraftAddon:SetLabelAnchor()
		MultiCraftAddon:ResetSlider()
	end
	
	-- for polymorphism
	MultiCraftAddon.smithing.GetMode = function(...)
		return SMITHING.mode
	end
	
	-- pattern selection in creation
	MultiCraftAddon.smithing.OnSelectedPatternChanged = SMITHING.OnSelectedPatternChanged
	SMITHING.OnSelectedPatternChanged = function(...)
		MultiCraftAddon.smithing.OnSelectedPatternChanged(...)
		MultiCraftAddon:ResetSlider()
	end
	
	-- item selection in deconstruction
	MultiCraftAddon.smithing.OnExtractionSlotChanged = SMITHING.OnExtractionSlotChanged
	SMITHING.OnExtractionSlotChanged = function(...)
		MultiCraftAddon.smithing.OnExtractionSlotChanged(...)
		MultiCraftAddon:ResetSlider()
	end
		
	-- create function
	MultiCraftAddon.smithing.Create = function()
		SMITHING.creationPanel:Create()
	end
	
		
	-- wrapper to check if an item is craftable
	MultiCraftAddon.smithing.IsCraftable = function(...)
		return SMITHING.creationPanel:IsCraftable()
	end
		
	-- deconstruction extract function
	MultiCraftAddon.smithing.Deconstruct = function()
		SMITHING.deconstructionPanel:Extract()
	end

		
	-- wrapper to check if an item is deconstructable
	MultiCraftAddon.smithing.IsDeconstructable = function(...)
		return SMITHING.deconstructionPanel:IsExtractable()
	end
	
	-- refinement extract function
	MultiCraftAddon.smithing.Extract = function()
		SMITHING.refinementPanel:Extract()
	end
	
	-- wrapper to check if an item is refinable
	MultiCraftAddon.smithing.IsExtractable = function(...)
		return SMITHING.refinementPanel:IsExtractable()
	end

	-- hook everything up
	ZO_PreHook(PROVISIONER, 'Create', function() MultiCraftAddon:Work(MultiCraftAddon.provisioner.Create) end)
	ZO_PreHook(ENCHANTING, 'Create', function() MultiCraftAddon:Work(MultiCraftAddon.enchanting.Create) end)
	ZO_PreHook(ALCHEMY, 'Create', function() MultiCraftAddon:Work(MultiCraftAddon.alchemy.Create) end)
	ZO_PreHook(SMITHING.creationPanel, 'Create', function() MultiCraftAddon:Work(MultiCraftAddon.smithing.Create) end)
	ZO_PreHook(SMITHING.deconstructionPanel, 'Extract', function() MultiCraftAddon:Work(MultiCraftAddon.smithing.Deconstruct) end)
	ZO_PreHook(SMITHING.refinementPanel, 'Extract', function() MultiCraftAddon:Work(MultiCraftAddon.smithing.Extract) end)
	
	-- slider
	MultiCraftSlider:SetHandler("OnValueChanged", MultiCraftAddon.SetLabelAndValue)
	
	EVENT_MANAGER:UnregisterForEvent(MultiCraftAddon.name .. 'loaded', EVENT_ADD_ON_LOADED)
end

local function CommandHandler(text)
	local input = string.lower(text)
	local cmd = {}
	local index = 1

	if input ~= nil then
		for value in string.gmatch(input,"%w+") do  
			  cmd[index] = value
				index = index + 1
			end
		end

	if cmd[1] == 'toggle' then
		ToggleSliderDefault()
		MultiCraftAddon:ResetSlider()
	elseif cmd[1] == "trait" then
		ToggleTraits()
		MultiCraftAddon:ResetSlider()
	elseif cmd[1] == "delay" then
		if tonumber(cmd[2]) ~= nil then
			SetCallDelay(zo_floor(tonumber(cmd[2])))
		end
		d(string.format(SI.get(SI.CALL_DELAY), MultiCraftAddon.settings.callDelay))
	else
		d(SI.get(SI.USAGE_1))
		d(SI.get(SI.USAGE_2))
		d(SI.get(SI.USAGE_3))
		d(SI.get(SI.USAGE_4))
	end
end

SLASH_COMMANDS["/mc"] = CommandHandler
SLASH_COMMANDS["/multicraft"] = CommandHandler

EVENT_MANAGER:RegisterForEvent(MultiCraftAddon.name .. 'loaded', EVENT_ADD_ON_LOADED, Initialize)
