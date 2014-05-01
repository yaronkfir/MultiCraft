addonName, mc_addon, totalToCreate, sliderValue = 'MultiCraft', {}, 1, 1

local NO_SKILL = 0
local ENCHANTING_SKILL = 3
local ALCHEMY_SKILL = 4
local PROVISIONING_SKILL = 5
local SMITHING_SKILLS = {}
SMITHING_SKILLS[1] = 1 -- blacksmithing
SMITHING_SKILLS[2] = 2 -- clothing
SMITHING_SKILLS[6] = 6 -- woodworking

local SMITHING_REFINEMENT_MODE = 1
local SMITHING_CREATION_MODE = 2
local SMITHING_DECONSTRUCTION_MODE = 4
local ENCHANTING_CREATION_MODE = 1
local ENCHANTING_EXTRACTION_MODE = 2

local current_craft = NO_SKILL
local MIN_REFINEMENT_COUNT = 10

function MultiCraft_Initialize(self)
	self:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, MultiCraft_ReplacePanelFunctions)
	self:RegisterForEvent(EVENT_CRAFT_STARTED, MultiCraft_HideUI)
	self:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, MultiCraft_Cleanup)
	
	-- Set up function overrides
	-- Provisioner
	PROVISIONER.recipeTree.RealSelectNode = PROVISIONER.recipeTree.SelectNode
	PROVISIONER.recipeTree.SelectNode = function(...)
		PROVISIONER.recipeTree.RealSelectNode(...)
		
		MultiCraft_ResetSlider()
	end
	
	-- create function
	PROVISIONER.RealCreate = PROVISIONER.Create
	PROVISIONER.Create = function(...)
		MultiCraft_Create()
	end
	
	-- Alchemy
	-- Enchanting
	-- tab change
	ENCHANTING.RealSetEnchantingMode = ENCHANTING.SetEnchantingMode
	ENCHANTING.SetEnchantingMode = function(...)
		ENCHANTING.RealSetEnchantingMode(...)
		MultiCraft_SetLabelAnchor()
		MultiCraft_ResetSlider()
	end
	
	-- rune slot change
	ENCHANTING.RealSetRuneSlotItem = ENCHANTING.SetRuneSlotItem
	ENCHANTING.SetRuneSlotItem = function(...)
		ENCHANTING.RealSetRuneSlotItem(...)
		MultiCraft_ResetSlider()
	end
	
	-- extraction slot change?
	ENCHANTING.RealOnSlotChanged = ENCHANTING.OnSlotChanged
	ENCHANTING.OnSlotChanged = function(...)
		ENCHANTING.RealOnSlotChanged(...)
		MultiCraft_ResetSlider()
	end
	
	-- create and extract function
	ENCHANTING.RealCreate = ENCHANTING.Create
	ENCHANTING.Create = function(...)
		MultiCraft_Create()
	end
	
	-- Smithing
	-- tab change
	SMITHING.RealSetMode = SMITHING.SetMode
	SMITHING.SetMode = function(...)
		SMITHING.RealSetMode(...)
		MultiCraft_SetLabelAnchor()
		MultiCraft_ResetSlider()
	end
	
	-- pattern selection in creation
	SMITHING.creationPanel.RealOnSelectedPatternChanged = SMITHING.creationPanel.OnSelectedPatternChanged
	SMITHING.creationPanel.OnSelectedPatternChanged = function(...)
		SMITHING.creationPanel.RealOnSelectedPatternChanged(...)
		MultiCraft_ResetSlider()
	end
	
	-- item selection in deconstruction
	SMITHING.deconstructionPanel.RealOnSlotChanged = SMITHING.deconstructionPanel.OnSlotChanged
	SMITHING.deconstructionPanel.OnSlotChanged = function(...)
		SMITHING.deconstructionPanel.RealOnSlotChanged(...)
		MultiCraft_ResetSlider()
	end
	
	-- item selection in refinement
	SMITHING.refinementPanel.RealOnSlotChanged = SMITHING.refinementPanel.OnSlotChanged
	SMITHING.refinementPanel.OnSlotChanged = function(...)
		SMITHING.refinementPanel.RealOnSlotChanged(...)
		MultiCraft_ResetSlider()
	end
	
	-- create function
	SMITHING.creationPanel.RealCreate = SMITHING.creationPanel.Create
	SMITHING.creationPanel.Create = function(...)
		MultiCraft_Create()
	end
	
	-- deconstruction extract function
	SMITHING.deconstructionPanel.RealExtract = SMITHING.deconstructionPanel.Extract
	SMITHING.deconstructionPanel.Extract = function(...)
		MultiCraft_Extract()
	end
	
	-- refinement extract function
	SMITHING.refinementPanel.RealExtract = SMITHING.refinementPanel.Extract
	SMITHING.refinementPanel.Extract = function(...)
		MultiCraft_Extract()
	end	
end

function MultiCraft_ReplacePanelFunctions(unknown, craftSkill)
	current_craft = craftSkill
	mc_addon.object = nil
	
	if craftSkill == PROVISIONING_SKILL then
		-- grab the provisioner instance
		if not mc_addon.object then mc_addon.object = PROVISIONER end
		EmitMessage("MC_Addon.Object = PROVISIONER")
		MultiCraft:SetHidden(false)
	elseif craftSkill == ENCHANTING_SKILL then
		if not mc_addon.object then mc_addon.object = ENCHANTING end
		EmitMessage("MC_Addon.Object = ENCHANTING")
	elseif craftSkill == ALCHEMY_SKILL then
	else
		-- grab the smithing instance
		if not mc_addon.object then mc_addon.object = SMITHING end
		EmitMessage("MC_Addon.Object = SMITHING")
	end
	
	MultiCraft_SetLabelAnchor()
	MultiCraft_ResetSlider()
end

function MultiCraft_HideUI(...)
	MultiCraft:SetHidden(true)
end

function MultiCraft_Cleanup(...)
	MultiCraft_HideUI(...)
	mc_addon.object = nil
	current_craft = NO_SKILL
	EmitMessage("MC_Addon.Object = nil")
	
end

function MultiCraft_EnableOrDisableUI()
	if not mc_addon.object then return end
	hidden = true
	
	if current_craft == PROVISIONING_SKILL then
		if mc_addon.object:IsCraftable() then
			hidden = false
		end
	elseif current_craft == ALCHEMY_SKILL then
		hidden = true
	elseif current_craft == ENCHANTING_SKILL then
		if mc_addon.object:IsCraftable() then
			hidden = false
		end
	else
	-- there is a game bug where this returns erroneously true in refinement after completing an extract that results in having less
	-- than 10 items but still having the item selected
	-- TODO: fix it
		if (mc_addon.object.mode == SMITHING_REFINEMENT_MODE and mc_addon.object.refinementPanel:IsExtractable()) or 
		   (mc_addon.object.mode == SMITHING_CREATION_MODE and mc_addon.object.creationPanel:IsCraftable()) or
		   (mc_addon.object.mode == SMITHING_DECONSTRUCTION_MODE and mc_addon.object.deconstructionPanel:IsExtractable()) then		   
			hidden = false
		end
	end
	EmitMessage("hidden = " .. tostring(hidden))
	MultiCraft:SetHidden(hidden)
end

function MultiCraft_SetLabelAnchor()
	MultiCraftLabel:ClearAnchors()
	
	if current_craft == PROVISIONING_SKILL then
		MultiCraftLabel:SetAnchor(BOTTOMLEFT, MultiCraft, nil, 148, -12) 
	elseif current_craft == ENCHANTING_SKILL then
		if mc_addon.object:GetEnchantingMode() == ENCHANTING_CREATION_MODE then
			MultiCraftLabel:SetAnchor(BOTTOMLEFT, MultiCraft, nil, 273, -12) 
		elseif mc_addon.object:GetEnchantingMode() == ENCHANTING_EXTRACTION_MODE then
			MultiCraftLabel:SetAnchor(BOTTOMLEFT, MultiCraft, nil, 283, -12) 
		end		
	elseif SMITHING_SKILLS[current_craft] ~= nil then
		if mc_addon.object.mode == SMITHING_REFINEMENT_MODE then
			MultiCraftLabel:SetAnchor(BOTTOMLEFT, MultiCraft, nil, 280, -12)
		elseif mc_addon.object.mode == SMITHING_CREATION_MODE then
			MultiCraftLabel:SetAnchor(BOTTOMLEFT, MultiCraft, nil, 148, -12) 
		elseif mc_addon.object.mode == SMITHING_DECONSTRUCTION_MODE then
			MultiCraftLabel:SetAnchor(BOTTOMLEFT, MultiCraft, nil, 310, -12) 
		end
	end
end

function MultiCraft_ResetSlider()
	if not mc_addon.object then return end
	MultiCraft_EnableOrDisableUI()
	
	local numCraftable = 1
	
	EmitMessage("current craft is " .. current_craft)
	if current_craft == PROVISIONING_SKILL then
		data = mc_addon.object.recipeTree:GetSelectedData()
		if data ~= nil then
			numCraftable = data.numCreatable
		end		
	elseif current_craft == ALCHEMY_SKILL then
		numCraftable = 1
	elseif current_craft == ENCHANTING_SKILL then
		if mc_addon.object:IsCraftable() then
			if mc_addon.object:GetEnchantingMode() == ENCHANTING_CREATION_MODE then
				for k, v in pairs(mc_addon.object.runeSlots) do
					if k == 1 then
						numCraftable = v.craftingInventory.itemCounts[v.itemInstanceId]
					else 
						numCraftable = zo_min(numCraftable, v.craftingInventory.itemCounts[v.itemInstanceId])
					end
					EmitMessage("in for numCraftable = " .. tostring(zo_floor(numCraftable)))
				end			
			elseif mc_addon.object:GetEnchantingMode() == ENCHANTING_EXTRACTION_MODE then
				numCraftable = mc_addon.object.extractionSlot.craftingInventory.itemCounts[mc_addon.object.extractionSlot.itemInstanceId]
			end
		end
	elseif SMITHING_SKILLS[current_craft] ~= nil then
		if mc_addon.object.mode == SMITHING_REFINEMENT_MODE then
			if mc_addon.object.refinementPanel:IsExtractable() then
				numCraftable = mc_addon.object.refinementPanel.extractionSlot.craftingInventory.itemCounts[mc_addon.object.refinementPanel.extractionSlot.itemInstanceId]
				numCraftable = zo_floor(numCraftable / MIN_REFINEMENT_COUNT)
			end
		elseif mc_addon.object.mode == SMITHING_CREATION_MODE then
			if mc_addon.object.creationPanel:IsCraftable() then
				EmitMessage("SMITHING Creation")
				-- determine metrics for the slider
				patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex = mc_addon.object.creationPanel:GetAllCraftingParameters()
				materialCount = GetCurrentSmithingMaterialItemCount(patternIndex, materialIndex) / materialQuantity
				styleItemCount = GetCurrentSmithingStyleItemCount(styleIndex)
				traitCount = GetCurrentSmithingTraitItemCount(traitIndex)
				
				numCraftable = zo_min(materialCount, styleItemCount)
				
				if traitIndex ~= 1 then
					numCraftable = zo_min(numCraftable, traitCount)
				end
			end
		elseif mc_addon.object.mode == SMITHING_DECONSTRUCTION_MODE then
			if mc_addon.object.deconstructionPanel:IsExtractable() then
				numCraftable = mc_addon.object.deconstructionPanel.extractionSlot.craftingInventory.itemCounts[mc_addon.object.deconstructionPanel.extractionSlot.itemInstanceId]
			end
		end
	end
	
	EmitMessage("numCraftable = " .. tostring(zo_floor(numCraftable)))
	MultiCraftSlider:SetValue(1)	
	if numCraftable == 1 then
		-- MultiCraft_SetSliderLabelValue()
		MultiCraftSlider:SetHidden(true)
		-- MultiCraftLabel:SetText(string.format("%d", numCraftable))
	else
		MultiCraftSlider:SetHidden(false)
		MultiCraftSlider:SetMinMax(1, zo_floor(numCraftable))
	end
end

function MultiCraft_SetSliderLabelValue()
	if not mc_addon.object then return end
	value = MultiCraftSlider:GetValue()	
	sliderValue = value;
	EmitMessage("sliderValue = " .. tostring(zo_floor(sliderValue)))
	MultiCraftLabel:SetText(string.format("%d", value))
end

function MultiCraft_Create()
	if SMITHING_SKILLS[current_craft] ~= nil and mc_addon.object.mode ~= SMITHING_CREATION_MODE then return end
		
	EVENT_MANAGER:RegisterForEvent(addonName, EVENT_CRAFT_COMPLETED, MultiCraft_ContinueCreate)
	
	totalToCreate = zo_floor(sliderValue)
	
	if SMITHING_SKILLS[current_craft] ~= nil then
		if not mc_addon.object.creationPanel:IsCraftable() then return end
		mc_addon.object.creationPanel:RealCreate()
	else 
		if not mc_addon.object:IsCraftable() then return end
		mc_addon.object:RealCreate()
	end
end

function MultiCraft_ContinueCreate(...)
	totalToCreate = totalToCreate - 1
		
	if totalToCreate ~= 0 then
		if SMITHING_SKILLS[current_craft] ~= nil then
			mc_addon.object.creationPanel:RealCreate()
		else
			mc_addon.object:RealCreate()
		end
	else
		EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_CRAFT_COMPLETED)
	end
end

function MultiCraft_Extract()
	if SMITHING_SKILLS[current_craft] == nil then
		return
	elseif (mc_addon.object.mode == SMITHING_REFINEMENT_MODE and mc_addon.object.refinementPanel:IsExtractable() == false) or
		   (mc_addon.object.mode == SMITHING_DECONSTRUCTION_MODE and mc_addon.object.deconstructionPanel:IsExtractable() == false) then
		return 
	end
	
	EVENT_MANAGER:RegisterForEvent(addonName, EVENT_CRAFT_COMPLETED, MultiCraft_ContinueExtract)
	
	totalToCreate = zo_floor(sliderValue)
	if mc_addon.object.mode == SMITHING_REFINEMENT_MODE then
		mc_addon.object.refinementPanel:RealExtract()
	elseif mc_addon.object.mode == SMITHING_DECONSTRUCTION_MODE then
		mc_addon.object.deconstructionPanel:RealExtract()
	end
end

function MultiCraft_ContinueExtract(...)
	totalToCreate = totalToCreate - 1
		
	if totalToCreate ~= 0 then
		if mc_addon.object.mode == SMITHING_REFINEMENT_MODE then
			mc_addon.object.refinementPanel:RealExtract()
		elseif mc_addon.object.mode == SMITHING_DECONSTRUCTION_MODE then
			mc_addon.object.deconstructionPanel:RealExtract()
		end
	else
		EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_CRAFT_COMPLETED)
		MultiCraft_ResetSlider()
	end
end

function EmitMessage(message)
	if (CHAT_SYSTEM) then
		if (message == nil) then
			message = "[nil]"
		elseif (message == "") then
			message = "[Empty String]"
		end
		CHAT_SYSTEM:AddMessage(message)
	end
end
