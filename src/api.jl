
# API to get and set simulation parameters
function get_params()
    return PARAMS
end

function set_param!(name::Symbol, value)
    if hasfield(FishTankParams, name)
        setfield!(PARAMS, name, value)
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
        TANK_STATE.running = true
        TANK_STATE.main_task = @async main(color)
    else
        println("Fish tank already initialized. Use reset!() to reinitialize.")
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
    hunger()

Check the hunger level of the fish.
"""
function hunger()
    return FISH.hunger
end

"""
    resting()

Check if the fish is resting.
"""
function resting()
    return FISH.rest
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

"""
    reset!(color::String="")

Reset and reinitialize the fish tank with a new fish.
Closes the existing window and starts fresh.

Arguments:
- `color`: Optional color for the new fish. Random if not specified.
"""
function reset!(color::String="")
    if TANK_STATE.lock
        println("Resetting fish tank...")

        # Store reference to old task
        old_task = TANK_STATE.main_task

        # Stop the simulation
        TANK_STATE.running = false

        # Wait longer for the simulation loop to exit
        sleep(1.0)

        # Close the existing plot window if it exists
        if TANK_STATE.fig !== nothing
            try
                close(TANK_STATE.fig)
            catch
                # Ignore errors if window already closed
            end
        end

        # Wait for old task to fully terminate (up to 3 seconds)
        if old_task !== nothing
            for i in 1:30
                if istaskdone(old_task) || istaskfailed(old_task)
                    break
                end
                sleep(0.1)
            end
        end

        # Reset all simulation parameters to default values
        default = default_params()
        PARAMS.FOOD_UPDATE_THRESH = default.FOOD_UPDATE_THRESH
        PARAMS.EAT_DISTANCE = default.EAT_DISTANCE
        PARAMS.BLEND_FACTOR_ANG = default.BLEND_FACTOR_ANG
        PARAMS.HUNGER_INC_MIN = default.HUNGER_INC_MIN
        PARAMS.HUNGER_INC_BASE = default.HUNGER_INC_BASE
        PARAMS.HUNGER_INC_EXP = default.HUNGER_INC_EXP
        PARAMS.HUNGER_FOOD_THRESH = default.HUNGER_FOOD_THRESH
        PARAMS.HUNGER_FAC_THRESH = default.HUNGER_FAC_THRESH
        PARAMS.HUNGER_EAT_FAC_EXP = default.HUNGER_EAT_FAC_EXP
        PARAMS.HUNGER_EAT_MIN = default.HUNGER_EAT_MIN
        PARAMS.HUNGER_EAT_BASE = default.HUNGER_EAT_BASE
        PARAMS.COMBO_EXP = default.COMBO_EXP
        PARAMS.DOT_FRONT_THRESH = default.DOT_FRONT_THRESH
        PARAMS.REST_PERIOD = default.REST_PERIOD
        PARAMS.BUFFER_PERIOD = default.BUFFER_PERIOD
        PARAMS.REST_COUNT_MAX = default.REST_COUNT_MAX
        PARAMS.REST_DIR_THRESH = default.REST_DIR_THRESH

        # Reset all tank state to initial values
        TANK_STATE.lock = false
        TANK_STATE.running = false
        TANK_STATE.sound = true
        TANK_STATE.plotTrig = false
        TANK_STATE.food = _create_food(0)
        empty!(TANK_STATE.weedList)
        TANK_STATE.weedCount = 0
        TANK_STATE.Az = 28.0
        TANK_STATE.El = 12.0
        TANK_STATE.viewTrig = false
        TANK_STATE.main_task = nothing
        TANK_STATE.fig = nothing

        # Recreate fish with fresh geometry and initial state
        pos = rand(3) .* 0.5 .+ 0.25
        new_fish = _create_fish(pos, "")

        # Copy all fields from new fish to global FISH
        FISH.body = new_fish.body
        FISH.tail = new_fish.tail
        FISH.pos = new_fish.pos
        FISH.dir = new_fish.dir
        FISH.hunger = new_fish.hunger
        FISH.rest = new_fish.rest
        FISH.target_food_idx = new_fish.target_food_idx
        FISH.combo = new_fish.combo

        # Additional pause to ensure everything is fully reset
        sleep(0.5)

        # Reinitialize with new task
        init(color)
    else
        println("No fish tank to reset. Use init() to create one.")
    end
    return nothing
end