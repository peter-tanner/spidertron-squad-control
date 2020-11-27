

function IJMean(vectors)
    local sumx = 0
    local sumy = 0
    for i=1, #vectors do
        local vec = vectors[i]
        sumx = vec.x + sumx
        sumy = vec.y + sumy
    end
    return {
            x = sumx/#vectors,
            y = sumy/#vectors
        }
end

function IJMeanEntity(entities)
    local sumx = 0
    local sumy = 0
    for i=1, #entities do
        local pos = entities[i].position
        sumx = pos.x + sumx
        sumy = pos.y + sumy
    end
    return {
            x = sumx/#entities,
            y = sumy/#entities
        }
end

function  IJDelta(vec1, vec2)
    local dx = vec2.x - vec1.x
    local dy = vec2.y - vec1.y
    return { x = dx, y = dy }
end

function IJAdd(vec1, vec2)
    return {
        x = vec1.x + vec2.x,
        y = vec1.y + vec2.y
    }
end

function IJSub(vec1, vec2)
    return {
        x = vec1.x - vec2.x,
        y = vec1.y - vec2.y
    }
end


function IJAhead(vec, dir, dd)
    local dd_diagonal = math.sqrt(dd^2/2)
    local d = defines.direction
    local x = vec.x
    local y = vec.y

    if dir == d.north then
        y = y - dd
    elseif dir == d.northeast then
        -- game.print("ne")
        x = x + dd_diagonal
        y = y - dd_diagonal
    elseif dir == d.east then
        -- game.print("e")
        x = x + dd
    elseif dir == d.southeast then
        -- game.print("se")
        x = x + dd_diagonal
        y = y + dd_diagonal
    elseif dir == d.south then
        -- game.print("s")
        y = y + dd
    elseif dir == d.southwest then
        -- game.print("sw")
        x = x - dd_diagonal
        y = y + dd_diagonal
    elseif dir == d.west then
        -- game.print("w")
        x = x - dd
    else -- northwest
        -- game.print("nw")
        x = x - dd_diagonal
        y = y - dd_diagonal
    end

    return {x=x, y=y}
end