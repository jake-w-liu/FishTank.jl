mutable struct Food
    num::Int
    pts::PlotlyJS.GenericTrace
    zd::Vector
end

function _create_food(n::Int)
    @assert n >= 0

    x = rand(n) .* 0.8 .+ 0.1
    y = rand(n) .* 0.8 .+ 0.1
    z = ones(n)

    zd = rand(n) .* 0.8 .+ 0.1

    pts = scatter3d(
        x=x, y=y, z=z,
        mode="markers",
        marker=attr(
            size=1,
            color="#8E354A", # SUOH
        )
    )
    food = Food(n, pts, zd)
    return food
end

function _update_food!(food, v)
    @inbounds for n in eachindex(food.pts.z)
        food.pts.z[n] -= v *  (food.pts.z[n] - food.zd[n])
    end
    return nothing
end