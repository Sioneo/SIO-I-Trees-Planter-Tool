-- SIO I: Trees Planter Tool, Version 1.0
local settings
local function getIndex(list, target)
	for i = 1, #list do
		if list[i] == target then
			return i
		end
	end
end
local languages = {"English", "简体中文", "繁體中文"}
local lang
local translations = {
    {
        POT = "Preserve original trees",
        languages = "Language"
    },
    {
        POT = "保留原始树木",
        languages = "语言"
    },
    {
        POT = "保留原始樹木",
        languages = "語言"
    }
}

function script:init()
    settings = Util.optStorage(TheoTown.getStorage(), self:getDraft():getId()..':settings')
    settings.someBool = settings.someBool == nil and false or settings.someBool
    settings.someString = settings.someString or "English"
    lang = TheoTown.getGlobalFunVar("!Sio1Language", 1)
end

function script:settings()
    return {
        {
            name = translations[lang].POT,
            value = settings.someBool,
            onChange = function(newState) 
                settings.someBool = newState 
                local condition = newState and 1 or 0
                TheoTown.setGlobalFunVar("!Sio1GlobalPOT", condition)
            end
        },
        {
            name = translations[lang].languages,
            value = settings.someString,
            values = {"English", "简体中文", "繁體中文"},
            onChange = function(newState) 
	            settings.someString = newState      
	            condition = getIndex(languages, newState)
	            lang = condition
	            TheoTown.setGlobalFunVar("!Sio1Language", condition)
	        end
        }
    }
end