
# API to get and set simulation parameters
function get_params()
    return TANK_STATE.params
end

function set_param!(name::Symbol, value)
    if hasfield(FishTankParams, name)
        setfield!(TANK_STATE.params, name, value)
    else
        error("Parameter $(name) does not exist in FishTankParams.")
    end
end
"""
    init(color::String="")

Initialize the fish tank.

Arguments:
- `color`: The color of the fish. If not specified, a random color will be used.
"""
function init(color::String="")
    if !TANK_STATE.lock
        println("Creating your fish tank...")
        TANK_STATE.lock = true
        @async main(color)
    else
        println("Fish tank already initialized.")
    end
    return nothing
end

"""
    pause()

Pause the simulation.
"""
function pause()
    TANK_STATE.running = false
    return nothing
end

"""
    go()

Resume the simulation.
"""
function go()
    TANK_STATE.running = true
    return nothing
end

"""
    mute()

Mute the sound.
"""
function mute()
    TANK_STATE.sound = false
    return nothing
end

"""
    unmute()

Unmute the sound.
"""
function unmute()
    TANK_STATE.sound = true
    return nothing
end

"""
    feed(n::Int=10)

Feed the fish.

Arguments:
- `n`: The number of food particles to add.
"""
function feed(n::Int=10)
    @assert n >= 0

    food_tmp = _create_food(n)

    TANK_STATE.food.num += n
    TANK_STATE.food.zd = [TANK_STATE.food.zd; food_tmp.zd]

    TANK_STATE.food.pts.x = [TANK_STATE.food.pts.x; food_tmp.pts.x]
    TANK_STATE.food.pts.y = [TANK_STATE.food.pts.y; food_tmp.pts.y]
    TANK_STATE.food.pts.z = [TANK_STATE.food.pts.z; food_tmp.pts.z]
    return nothing
end

"""
    check()

Check the amount of food in the tank.
"""
function check()
    return TANK_STATE.food.num
end

"""
    plant()

Plant a weed in the tank.
"""
function plant()
    push!(TANK_STATE.weedList, _create_weed())
    TANK_STATE.weedCount += 1
    return nothing
end

"""
    plant(n::Int)

Plant n weeds in the tank.
"""
function plant(n::Int)
    for _ in 1:n
        push!(TANK_STATE.weedList, _create_weed())
        TANK_STATE.weedCount += 1
    end
    return nothing
end

"""
    replot()

Replot the tank.
"""
function replot()
    TANK_STATE.plotTrig = true
    return nothing
end

"""
    look(az::Real, el::Real)

Change the camera angle.

Arguments:
- `az`: The azimuth angle.
- `el`: The elevation angle.
"""
function look(az::Real, el::Real)
    TANK_STATE.Az = az
    TANK_STATE.El = el
    TANK_STATE.viewTrig = true
    return nothing
end