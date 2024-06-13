function init(color::String="")
    if !lock[]
        lock[] = true
        @async main(color)
    else
        println("Fish tank already initialized.")
    end
    return nothing
end

function pause()
    running[] = false
    return nothing
end

function go()
    running[] = true
    return nothing
end

function mute()
    sound[] = false
    return nothing
end

function unmute()
    sound[] = true
    return nothing
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
            size=1,
            color="red",
        )
    )
    return nothing
end

function check()
    return food.num
end

function showup()
    replot[] = true
    return nothing
end