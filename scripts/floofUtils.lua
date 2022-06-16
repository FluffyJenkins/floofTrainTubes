local fUtil = {debugMode=false}

function fUtil.debug(str,title)
    title = title or ""
    local output = ""
	if not fUtil.debugMode then return end
	if type(str) == "table" then
        output = serpent.block(str)
	else
		output = str
	end
    if title then
        output = title..": "..output
    end
    game.print(output)
end

function fUtil.clamp(min, max, i)
    return math.min(max,math.max(min,i))
end


return fUtil