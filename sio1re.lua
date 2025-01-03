-- SIO I: Trees Planter Tool, Version 1.1.0[Refactored][Developed on 1.12.10i]
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
local selectedTrees = {}
local touchTime, inTool, hasBuiltTree, hasSpentMoney, treeDrafts, totalPrice, isSandbox, hasDrawnMark
local numOfPositions = 0
local preserveOriginalTrees = TheoTown.getGlobalFunVar("!Sio1GlobalPOT", 0)

local function getStorage()
    return Util.optStorage(TheoTown.getStorage(), script:getDraft():getId())
end

local layout
local function addLine(label, height, w)
	local line = layout:addLayout{height = height}
	line:addLabel{text = label, w = w}
	return line:addLayout{x = 56}
end

-- Save settings to storage
local function saveSettings()
    local stg = getStorage()
    stg.selectedTreesSTG = {}
    selectedTrees:forEach(function(d)
        table.insert(stg.selectedTreesSTG, d:getId())
    end)
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
        selectedTrees:add(Draft.getDraft("$tree00"))
    end
end

-- True if trees can be placed here in general
local function isValid(x, y)
    return Tile.isValid(x, y)
        and Tile.isLand(x, y)
        and not Tile.hasRoad(x, y)
end

local function removeTree()
     for i = 1, numOfPositions do
        local pos = {x = selectedPositions[i][1], y = selectedPositions[i][2]}
        if Tile.isTree(pos.x, pos.y) == true then
            Builder.remove(pos.x, pos.y)
        end
    end
    hasBuiltTree = false
end
    
local function clear(target)
    if target == "tree" then
        removeTree()
    elseif target == "tree&mark" then
        removeTree()
        selectedPositions = {}
        firstTapPosition.tileX, firstTapPosition.tileY, lastTapPosition.tileX, lastTapPosition.tileY = nil, nil, nil, nil
        numOfPositions = 0
        touchTime = 1 -- Initialization
    elseif target == "mark" then
        selectedPositions = {}
        numOfPositions = 0
        firstTapPosition.tileX, firstTapPosition.tileY, lastTapPosition.tileX, lastTapPosition.tileY = nil, nil, nil, nil
        touchTime = 1
    end
end

local function spendMoney()
	if hasBuiltTree == true and hasSpentMoney == false and totalPrice ~= nil then
		City.spendMoney(totalPrice, lastTapPosition.tileX, lastTapPosition.tileY)
		totalPrice = 0
		hasSpentMoney = true
	end
end

-- Save positions
local function selectArea(stage)
    if stage == 1 then
        hasSpentMoney = false
        hasBuiltTree = false
        hasDrawnMark = false
    elseif stage == 2 then
        selectedPositions = {}
        hasDrawnMark = false

        -- Get the lengths of the selected area
        local lenOfPosX = math.abs(lastTapPosition.tileX - firstTapPosition.tileX)
        local lenOfPosY = math.abs(lastTapPosition.tileY - firstTapPosition.tileY)
        local xBegin, yBegin
        -- Address the start positions of the selected area for saving positions
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
					end
	            elseif preserveOriginalTrees == 0 then
	                table.insert(selectedPositions, {x, y})
	                numOfPositions = numOfPositions + 1
			    end
            end
        end
    elseif stage == 3 then
        if totalPrice == nil then totalPrice = 0 end
		spendMoney()	
        clear("mark")
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
        title = "Density",
        height = 200,
        width = 300
    }

    layout = densityUI.content:addLayout{
        vertical = true
    }
    -- Create the slider
    local line = addLine("Density", 30, 60)
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
        title = "About",
        text = "Thanks for using SIO I: Trees Planter Tool!\n\nHow to use?\n1.Tap on a tile to confirm the start of the area that you want to plant trees.\n2.Tap on another tile to confirm the end of the area.\n3.Click the Plant button to plant trees.\n\nPlugin Information\nSIO I: Trees Planter Tool is a plugin which made by dnswodn&TheoTown Team.\nPlugin Version: 1.1.0\n\nThis plugin was made using the open source codes which made by TheoTown Team, you can check them on https://github.com/TheoTown-Team/TreePlanterTool, I am grateful for the contributions of the open source community, thank you very much!",
        height = 200,
        width = 300
    }
end

local function plantTree()
    loadSettings()
    hasBuiltTree = true
    hasSpentMoney = false
    totalPrice = 0
    
    if numOfPositions <= 400 then
        for i = 1, numOfPositions do 
            local randomPlant = math.random(0, 100)
            if randomPlant < TheoTown.getGlobalFunVar("!Sio1GlobalDensity", 100) then
                local randomTree = math.random(1, #selectedTrees)
                -- Calculate the price of every trees and the total price
		        local price = Builder.getTreePrice(selectedTrees[randomTree], selectedPositions[i][1], selectedPositions[i][2])
		        totalPrice = totalPrice + price
		    
		        -- End the loop if there is no enough money
		        if totalPrice > City.getMoney() and isSandbox ~= true then 
				    Debug.toast("No enough money")
				    totalPrice = totalPrice - price
				    break
		        else
			        Builder.buildTree(selectedTrees[randomTree], selectedPositions[i][1], selectedPositions[i][2])
			    end
			end
        end
    else
	    Debug.toast("Area Oversize, the maximum tiles is 400")
    end
end

-- Create the UI of the tool
local function showTool()
    touchTime = 1
    TheoTown.registerToolAction{
        icon = Icon.BUILD,
        name = "Plant",
        onClick = function()
            plantTree()
        end
    }
    TheoTown.registerToolAction{
        icon = Icon.REMOVE,
        name = "Clear",
        onClick = function()
            -- This one is mainly used when only comfirm the start of the area
            if numOfPositions == 0 then
                clear("tree&mark")
            else -- Remove trees
                if hasBuiltTree == true then
                    clear("tree")
                    hasBuiltTree = false
                else -- Remove marks and saved positions
                    clear("mark")
                end
            end
        end
    }
    TheoTown.registerToolAction{
        icon = Icon.TREE,
        name = "Trees…",
        onClick = function()
            showTreeDrafts()
        end
    }
    TheoTown.registerToolAction{
        icon = Icon.TERRAIN,
        name = "Density",
        onClick = function()
            showDensity()
        end
    }
    TheoTown.registerToolAction{
        icon = Icon.ABOUT,
        name = "About",
        onClick = function()
            showAbout()
        end
    }
end

function script:earlyTap(tileX, tileY, x, y) -- Save the positions of tapped tiles
    if inTool == true then
        if touchTime == 1 then
            firstTapPosition.tileX = tileX
            firstTapPosition.tileY = tileY
            totalPrice = 0; selectArea(1)
            touchTime = 2
	        preserveOriginalTrees = TheoTown.getGlobalFunVar("!Sio1GlobalPOT", 0) -- Update the condition
        elseif touchTime == 2 then
            lastTapPosition.tileX = tileX
            lastTapPosition.tileY = tileY
            selectArea(2)
            touchTime = 3
	    elseif touchTime == 3 then
	        selectArea(3)
	        touchTime = 1
        else 
            touchTime = 1
        end
    end
end

function script:init()
    treeDrafts = Draft.getDrafts()
            :filter(function(d) return d:getType() == "tree" and d:isVisible() end)
end

function script:enterCity()
    isSandbox = City.isSandbox()
end

-- Draw tile based overlay
function script:draw(tileX, tileY, hoverX, hoverY)
  -- Mark red if not suitable
    if not isValid(tileX, tileY) then
        Drawing.setTile(tileX, tileY)
        Drawing.drawTileFrame(Icon.TOOLMARK + 18)
    end
end

function script:event(_, _, _, event)
    if event == Script.EVENT_TOOL_ENTER then
        showTool()
        inTool = true
    elseif event == Script.EVENT_TOOL_LEAVE then
        inTool = false
        selectedPositions = {}
        numOfPositions = 0 -- Initialization
        spendMoney()
        clear("tree&mark")
    end
end

function script:update()
    if inTool == true then
        -- Mark the first and last tapped tiles green 
        if lastTapPosition.tileX ~= nil then
            Drawing.setTile(lastTapPosition.tileX, lastTapPosition.tileY)
            Drawing.drawTileFrame(Icon.TOOLMARK + 17)
        end
        if firstTapPosition.tileX ~= nil then
            Drawing.setTile(firstTapPosition.tileX, firstTapPosition.tileY)
            Drawing.drawTileFrame(Icon.TOOLMARK + 17)
        end
    end
end