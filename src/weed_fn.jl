mutable struct Weed
    body::PlotlyJS.GenericTrace
    dir::Vector
end

function _create_weed()
    h = 0.3 * rand() + 0.3
    z = 0 : 0.025 : h

    xc = 0.8 * rand() + 0.1
    yc = 0.8 * rand() + 0.1

    pts = []
    for n in eachindex(z)
        push!(pts, [xc + 0.05 *(rand() - 0.025), yc + 0.05 *(rand() - 0.025), z[n]])
    end

    for n in reverse(eachindex(z))
        push!(pts, [xc + 0.05 *(rand() - 0.025), yc + 0.05 *(rand() - 0.025), z[n]])
    end

    r = round(Int, 137 + rand()*1)
    g = round(Int, 243 + rand()*3)
    b = round(Int, 54 + rand()*2)
    color = "rgb($r, $g, $b)"

    weed = Weed(polygons(pts, color, 0.6), [0.0, 0.0, 1.0])

    return weed
end

function _update_weed!(weedList)

    for w in weedList
        w.dir[1] = (rand()-0.5)*0.02
        w.dir[2] = (rand()-0.5)*0.02
        w.dir .= w.dir./norm(w.dir)

        for n in eachindex(w.body.z)
            w.body.x[n] += w.body.z[n]* w.dir[1] 
            w.body.y[n] += w.body.z[n]* w.dir[2] 
        end
    end

    return nothing
end