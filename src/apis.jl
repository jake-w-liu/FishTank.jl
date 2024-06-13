function init(color::String="")
    @async main(color)
end

function pause()
    running[] = false
end

function go()
    running[] = true
end

function mute()
    sound[] = false
end

function unmute()
    sound[] = true
end

function add(n::Int=10)
    @assert n >= 0

    x = rand(n) .* 0.8 .+ 0.1
    y = rand(n) .* 0.8 .+ 0.1
    z = ones(n)

    zd = rand(n) .* 0.8 .+ 0.1

    food.num += n
    food.zd = [food.zd; zd]

    food.pts = scatter3d(
        x=[food.pts.x; x], y=[food.pts.y; y], z=[food.pts.z; z],
        mode="markers",
        marker=attr(
            size=1
        )
    )
    return nothing
end

function check()
    return food.num
end