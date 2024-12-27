-- SIO I: Trees Planter Tool, Version 1.0.2
-- Note: Highlighted tiles = flags
local strings = { -- Table of strings
    density = "Density[zh]密度", 
    close = "Close[zh]关闭", 
    plant = "Plant[zh]种植", 
    trees = "Trees…[zh]种类…", 
    clear = "Clear[zh]清除", 
    about = "About[zh]关于",
    aboutText = "Thanks for using SIO I: Trees Planter Tool!\n\nHow to use?\n1.Tap on a tile to confirm the start of the area that you want to plant trees.\n2.Tap on another tile to confirm the end of the area.\n3.Click the Plant button to plant trees.\n\nPlugin Information\nSIO I: Trees Planter Tool is a plugin which made by dnswodn&TheoTown Team.\nPlugin Version: 1.0\n\nThis plugin was made using the open source codes which made by TheoTown Team, you can check them on https://github.com/TheoTown-Team/TreePlanterTool, I am grateful for the contributions of the open source community, thank you very much![zh]感谢使用SIO I: Trees Planter Tool!\n\n如何使用?\n1.点击一个格子以确定种植区域的起点\n2.点击第二个格子以确定种植区域的终点\n3.点击种植按钮以种植树木\n\n关于本插件\nSIO I: Trees Planter Tool 是一个由dnswodn(Bilibili上的Sioneo)和TheoTown Team(提供的开源代码)开发的插件\n插件版本: 1.0\n\n本插件使用了TheoTown Team在GitHub上的开源代码, 链接: https://github.com/TheoTown-Team/TreePlanterTool, 十分感谢开源代码, 这为本插件提供了很大帮助",
    noMoney = "No enough money to plant trees[zh]没钱了", 
    areaOverSize = "Area Oversize, maximum is 400 tiles[zh]区域过大，最大400格"
}

local buttonSizeList = {
    height = 30,
    width = 50,
    x = 70,
    y = 60
}
local firstTapPosition = {
    tileX = nil,
    tileY = nil,
    x = nil,
    y = nil    
} -- Tables for saving the positions of the tapped tiles.
local lastTapPosition = {
    tileX = nil,
    tileY = nil,
    x = nil,
    y = nil
}
local selectedPositions = {}
local selectedTrees, originalTrees = {}, {}
local canvas, touchTime, inTool, hasBuiltTree, hasSpentMoney, hasRebuild, treeDrafts, tipText, totalMoney, selectedAreaFlagDraft, sandbox
local numOfPositions = 0
local preserveOriginalTrees = TheoTown.getGlobalFunVar("!Sio1GlobalPOT", 0)

local function getStorage()
    return Util.optStorage(TheoTown.getStorage(), script:getDraft():getId())
end

local layout
local function addLine(label, height, w)
	local line = layout:addLayout{height = height}
	line:addLabel{text = label, w = w}
	return line:addLayout{ x = 56 }
end

-- Save settings to storage
local function saveSettings()
    local stg = getStorage()
    stg.selectedTreesSTG = {}
    selectedTrees:forEach(function(d)
        table.insert(stg.selectedTreesSTG, d:getId())
    end) -- I love you Lobby <3
end

-- Load settings from storage
local function loadSettings()
    local stg = getStorage()
    selectedTrees = Array()
    if stg.selectedTreesSTG then
        for _,id in pairs(stg.selectedTreesSTG) do
            local draft = Draft.getDraft(id)
            if draft and draft:getType() == 'tree' and draft:isVisible() then
                selectedTrees:add(draft)
            end
        end
    end
    if selectedTrees:isEmpty() then
        selectedTrees:add(Draft.getDraft('$tree00'))
    end
end

-- Clear flags/trees
local function clear(mode)
    if mode == 1 then -- Clear trees and flags which are in selected area
        for i = 1, numOfPositions do 
            local draft = tostring(Tile.getBuildingDraft(selectedPositions[i][1], selectedPositions[i][2]))
            if Tile.isTree(selectedPositions[i][1], selectedPositions[i][2]) == true or draft == "Draft $sio1_flag_AreaBegin_dnswodn48" or draft == "Draft $sio1_flag_AreaEnd_dnswodn48" then
                Builder.remove(selectedPositions[i][1], selectedPositions[i][2])
            end
        end
        totalMoney = 0

    elseif mode == 2 then -- Only clear the area flags and end flags
	    for i = 1, numOfPositions do 
		    -- Get the draft of the tile
		    local draft = tostring(Tile.getBuildingDraft(selectedPositions[i][1], selectedPositions[i][2]))
			if draft ~= "Draft $sio1_flag_AreaBegin_dnswodn48" and draft ~= "Draft $sio1_flag_AreaEnd_dnswodn48" then
		        draft = tostring(Tile.getTreeDraft(selectedPositions[i][1], selectedPositions[i][2]))
		    end
		    
	        if draft == "Draft $sio1_flag_AreaBegin_dnswodn48" or draft == "Draft $sio1_flag_AreaEnd_dnswodn48" or draft == "Draft $sio1_flag_SelectedArea_dnswodn48" then
	            Builder.remove(selectedPositions[i][1], selectedPositions[i][2])
	        end
        end
    end
    -- Clear the flag when only tap one time
    if firstTapPosition.tileX ~= nil and firstTapPosition.tileY ~= nil then
        local firstTapDraft = tostring(Tile.getBuildingDraft(firstTapPosition.tileX, firstTapPosition.tileY))
        if firstTapDraft == "Draft $sio1_flag_AreaBegin_dnswodn48" or firstTapDraft == "Draft $sio1_flag_AreaEnd_dnswodn48" then
            Builder.remove(firstTapPosition.tileX, firstTapPosition.tileY)
            touchTime = nil
        end
    end
end

local function rebuildOriginalTrees() -- Rebuild the original trees
	if hasBuiltTrees ~= true and preserveOriginalTrees == 0 and #originalTrees > 0 and hasRebuild ~= true then
		for i = 1, #originalTrees do
			Builder.buildTree(originalTrees[i].draft, originalTrees[i].x, originalTrees[i].y, originalTrees[i].frame)
		end
		originalTrees = {}
		hasRebuild = true
	end
end

local function spendMoney()
	if hasSpentMoney == false and totalMoney ~= nil then
		City.spendMoney(totalMoney, lastTapPosition.tileX, lastTapPosition.tileY)
		totalMoney = 0
		hasSpentMoney = true
	end
end

-- Build flags and save positions
local function selectArea(stage)
    if stage == 1 then
        Builder.buildBuilding("$sio1_flag_AreaBegin_dnswodn48", firstTapPosition.tileX, firstTapPosition.tileY)
        
        hasSpentMoney = false
        hasBuiltTree = false
        hasRebuild = false
        originalTrees = {}
    elseif stage == 2 then
        Builder.buildBuilding("$sio1_flag_AreaEnd_dnswodn48", lastTapPosition.tileX, lastTapPosition.tileY)
        selectedPositions = {}

        -- Get the lengths of the selected area
        local lenOfPosX = math.abs(lastTapPosition.tileX - firstTapPosition.tileX)
        local lenOfPosY = math.abs(lastTapPosition.tileY - firstTapPosition.tileY)
        local xBegin, yBegin
        -- Address the start postions of the selected area for saving postions
        if lastTapPosition.tileX < firstTapPosition.tileX then
            xBegin = lastTapPosition.tileX
        else 
            xBegin = firstTapPosition.tileX
        end
        if lastTapPosition.tileY < firstTapPosition.tileY then
            yBegin = lastTapPosition.tileY
        else 
            yBegin = firstTapPosition.tileY
        end
        -- Save the positions
        numOfPositions = 0
        for x = xBegin, xBegin + lenOfPosX do 
            for y = yBegin, yBegin + lenOfPosY do 
	            -- If the setting preserve original trees is on and there is a tree at the tile, do not save the position
	            if preserveOriginalTrees == 1 then
		            local isItTree = Tile.isTree(x, y)
		            if isItTree ~= true then
			            	table.insert(selectedPositions, {x, y})
		                numOfPositions = numOfPositions + 1
					    Builder.buildTree(selectedAreaFlagDraft, x, y)
					end
	            elseif preserveOriginalTrees == 0 then
		            -- Save the draft and position of the original tree
		            if Tile.isTree(x, y) == true then
			            local draft = Tile.getTreeDraft(x, y)
			            local frame = Tile.getTreeFrame(x, y)
			            table.insert(originalTrees, {draft = draft, frame = frame, x = x, y = y})
		            end
	                table.insert(selectedPositions, {x, y})
	                numOfPositions = numOfPositions + 1
				    Builder.buildTree(selectedAreaFlagDraft, x, y)
			    end
            end
        end
    elseif stage == 3 then
        clear(2)
        rebuildOriginalTrees()
        if totalMoney == nil then totalMoney = 0 end
		spendMoney()
		
		selectedPositions = {}
		numOfPositions = 0
    end
end

-- Show the UI or the trees list
local function showTreeDrafts()
    loadSettings() -- Load the selected trees from storage
    GUI.createSelectDraftDialog{
        drafts = treeDrafts,
        selection = selectedTrees,
        multiple = true,
        minSelection = 1,
        onSelect = function(selection)
            selectedTrees = selection
            saveSettings()
        end
    }
end

-- Show the UI of the density adjustment
local function showDensity()
    local densityUI = GUI.createDialog{
        icon = Icon.TERRAIN,
        title = strings.density,
        height = 200,
        width = 300
    }

    layout = densityUI.content:addLayout{
        vertical = true
    }
    -- Create the slider
    local line = addLine(strings.density, 30, 60)
    local slider = line:addSlider{
        width = 220,
        minValue = 0,
        maxValue = 1,
        setValue = function(v)
            TheoTown.setGlobalFunVar("!Sio1GlobalDensity", v*100)
        end,
        getValue = function() return TheoTown.getGlobalFunVar("!Sio1GlobalDensity", 100) / 100 end
    }
end

-- Show the UI of plugin information
local function showAbout()
    local aboutUI = GUI.createDialog{
        icon = Icon.ABOUT,
        title = strings.about,
        text = strings.aboutText,
        height = 200,
        width = 300
    }
end

local function plantTree()
    loadSettings()
    clear(2) -- Clear the flags
    hasBuiltTree = true
    hasSpentMoney = false
    totalMoney = 0
    
    if numOfPositions <= 400 then
        for i = 1, numOfPositions do 
            local randomPlant = math.random(0, 100)
            if randomPlant < TheoTown.getGlobalFunVar("!Sio1GlobalDensity", 100) then
                local randomTree = math.random(1, #selectedTrees)
                -- Calculate the price of every trees and the total price
		        local price = Builder.getTreePrice(selectedTrees[randomTree], selectedPositions[i][1], selectedPositions[i][2])
		        totalMoney = totalMoney + price
		    
		        -- End the loop if there is no enough money
		        if totalMoney > City.getMoney() and sandbox ~= true then 
				    Debug.toast(strings.noMoney)
				    totalMoney = totalMoney - price
				    break
		        else
			        Builder.buildTree(selectedTrees[randomTree], selectedPositions[i][1], selectedPositions[i][2])
			    end
			end
        end
        originalTrees = {} -- Clear the original trees table to disable the rebuild
    else
	    Debug.toast(strings.areaOverSize)
    end
end

-- Show the UI
local function showTool()
	language = tonumber(TheoTown.getGlobalFunVar("!Sio1Language", 1)) -- Update
    touchTime = nil
    root = GUI.getRoot()

    canvas = root:addCanvas{
    }
    canvas:setTouchThrough(true)

    local closeButton = canvas:addButton{
        x = buttonSizeList.x,    
        y = buttonSizeList.y,
        height = buttonSizeList.height,
        width = buttonSizeList.width,
        text = strings.close,
        icon = Icon.CLOSE,
        onClick = function()
            GUI.get("cmdCloseTool"):click()
        end
    }

    local plantButton = canvas:addButton{
        x = buttonSizeList.x,    
        y = buttonSizeList.y + buttonSizeList.height,
        height = buttonSizeList.height,
        width = buttonSizeList.width,
        text = strings.plant,
        icon = Icon.BUILD,
        onClick = function()
            plantTree()
        end
    }

    local treeSelectButton = canvas:addButton{
        x = buttonSizeList.x,    
        y = buttonSizeList.y + (2 * buttonSizeList.height),
        height = buttonSizeList.height,
        width = buttonSizeList.width,
        text = strings.trees,
        icon = Icon.TREE,
        onClick = function()
            showTreeDrafts()
        end
    }

    local clearSelectButton = canvas:addButton{
        x = buttonSizeList.x,    
        y = buttonSizeList.y + (3 * buttonSizeList.height),
        height = buttonSizeList.height,
        width = buttonSizeList.width,
        text = strings.clear,
        icon = Icon.CANCEL,
        onClick = function()
            clear(1)
            touchTime = nil
            hasRebuild = true
        end
    }

    local densityButton = canvas:addButton{
        x = buttonSizeList.x,    
        y = buttonSizeList.y + (4 * buttonSizeList.height),
        height = buttonSizeList.height,
        width = buttonSizeList.width,
        text = strings.density,
        icon = Icon.TERRAIN,
        onClick = function()
            showDensity()
        end
    }
    
    local aboutButton = canvas:addButton{
        x = buttonSizeList.x,    
        y = buttonSizeList.y + (5 * buttonSizeList.height),
        height = buttonSizeList.height,
        width = buttonSizeList.width,
        text = strings.about,
        icon = Icon.ABOUT,
        onClick = function()
            showAbout()
        end
    }
end

function script:init()
    treeDrafts = Draft.getDrafts()
        :filter(function(d) return d:getType() == "tree" and d:isVisible() end)
    selectedAreaFlagDraft = Draft.getDraft("$sio1_flag_SelectedArea_dnswodn48")
    
    -- Address the translation
    for key, value in pairs(strings) do
        strings[key] = TheoTown.translateInline(value)
    end
end

function script:enterCity()    
    -- Check the global function variable
    local checkGlobalFunVar = TheoTown.getGlobalFunVar("!Sio1GlobalDensity", 1000)
    if checkGlobalFunVar == 1000 then 
        TheoTown.setGlobalFunVar("!Sio1GlobalDensity", 100)
    end
    sandbox = City.isSandbox()
end

function script:earlyTap(tileX, tileY, x, y) -- Save the positions of tapped tiles
    if inTool == true then
        if touchTime == nil then
            firstTapPosition.tileX = tileX
            firstTapPosition.tileY = tileY
            totalMoney = 0
            selectArea(1)
            touchTime = 1
	        preserveOriginalTrees = TheoTown.getGlobalFunVar("!Sio1GlobalPOT", 0) -- Update the condition
        elseif touchTime == 1 then
            lastTapPosition.tileX = tileX
            lastTapPosition.tileY = tileY
            lastTapPosition.x = x
            lastTapPosition.y = y
            selectArea(2)
            touchTime = 2
	    elseif touchTime == 2 then
	        selectArea(3)
	        touchTime = nil
        else 
            touchTime = nil
        end
    else end
end

function script:event(_, _, _, event)
    if event == Script.EVENT_TOOL_ENTER then
        showTool()
        inTool = true
    elseif event == Script.EVENT_TOOL_LEAVE then
        canvas:delete()
        spendMoney()
        inTool = false
        clear(2) -- Clear the flags after using the tool
        rebuildOriginalTrees()
        selectedPositions = {}
        numOfPositions = 0 -- Initialization
    end
end