mutable struct Food
    num::Int
    pts::PlotlyJS.GenericTrace
    zd::Vector{Float64}
end

function _create_food(n::Int)
    @assert n >= 0

    x = rand(n) .* 0.7 .+ 0.15
    y = rand(n) .* 0.7 .+ 0.15
    z = ones(n)

    zd = rand(n) .* 0.5 .+ 0.3

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

function _check_food_update(food, f)
    if sum(abs.(food.pts.z - food.zd))/length(food.zd) < f
        return false
    else
        return true
    end
end