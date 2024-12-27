-- SIO I: Trees Planter Tool, Version 1.0.2
local settings
function script:init()
    settings = Util.optStorage(TheoTown.getStorage(), self:getDraft():getId()..':settings')
    if settings.POT == nil then
        settings.POT = false
    else
        settings.POT = settings.POT
    end
end

function script:settings()
    return {
        {
            name = TheoTown.translateInline("Preserve original trees[zh]保留原始树木"),
            value = settings.POT,
            onChange = function(newState) 
                settings.POT = newState 
                local condition = newState and 1 or 0
                TheoTown.setGlobalFunVar("!Sio1GlobalPOT", condition)
            end
        }
    }
end