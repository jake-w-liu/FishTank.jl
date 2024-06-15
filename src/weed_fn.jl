mutable struct Weed
    body::PlotlyJS.GenericTrace
    pos::Vector
end

function _create_weed()
    h = 0.3 * rand() + 0.3
    z = 0 : 0.025 : h

    xc = 0.8 * rand() + 0.1
    yc = 0.8 * rand() + 0.1

    pts = []
    push!(pts, [xc, yc, 0])
    for n in eachindex(z)
        push!(pts, [xc + rand() * 0.02, yc + rand() * 0.02, z[n]])
    end
    push!(pts, [xc, yc, h])
    for n in reverse(eachindex(z))
        push!(pts, [xc - rand() * 0.02, yc - rand() * 0.02, z[n]])
    end

    # base color: HIWAMOEGI
    r = round(Int, 144 + rand()*4) 
    g = round(Int, 180 + rand()*5)
    b = round(Int,  75 + rand()*3)
    color = "rgb($r, $g, $b)"

    weed = Weed(polygons(pts, color, 0.6), pts)

    return weed
end

function _update_weed!(weedList)

    for w in weedList

        for n in eachindex(w.pos)
            dx = rand(Normal(0.0, 0.01)) * w.body.z[n]
            dy = rand(Normal(0.0, 0.01)) * w.body.z[n]

            w.body.x[n] = w.pos[n][1] + dx
            w.body.y[n] = w.pos[n][2] + dy
        end
    end

    return nothing
end