module FishTank

export init, pause, go, mute, unmute, check, add, showup

using PlotlyJS
using PlotlyGeometries
using Distributions
using BeepBeep
using Infiltrator

include("fish_fn.jl")
include("food_fn.jl")
include("apis.jl")

const lock = Ref(false)
const running = Ref(true)
const sound = Ref(true)
const replot = Ref(false)
const food = _create_food(0)

function main(color="")
    # tank initialzation
    tank = cubes([0.5, 0.5, 0.5], [1.1, 1.1, 1.1], "white", 0.2)
    layout = Layout(scene=attr(
            xaxis=attr(
                visible=false,
                showgrid=false
            ),
            yaxis=attr(
                visible=false,
                showgrid=false
            ),
            zaxis=attr(
                visible=false,
                showgrid=false
            ),   
        ),
        scene_camera= attr(
                eye=attr(x=1.75, y=1.25, z=0.6)
         ),
        uirevision=true,
        transition=attr(
            easing="quad-in-out",
        ),
        height=400,
        width=400,
        # minreducedwidth=400,
        # minreducedheight=400,
        margin=attr(
            l=45, 
            r=0, 
            b=15,
            t=0, 
        ),
        autosize=true,
    )
    
    # fish initialization
    pos = rand(3) .* 0.5 .+ 0.25
    ang = zeros(3) 

    v_init = 0.03
    v = fill(v_init, 3)

    fish = _create_fish(pos, color)
    world = [tank, fish.body, fish.tail, food.pts]

    fig = plot(world, layout)
    display(fig)

    cz = 1
    cy = 1

    count = 0
    reset_num = 3600

    while true 
        if sound[]
            beep("facebook")
        end

        while running[]
            # give random angle
            cy = cy * sign(rand(Normal(0.5, 0.5)))
            cz = cz * sign(rand(Normal(0.5, 0.5)))
            
            # ang_cz = sign(rand(Normal(0.5, 1)))
            ang[1] = rand() .* 1 .- 0.5
            ang[2] = rand() .* 2 .* cy
            ang[3] = (rand() .* 2 .+ 1) .* cz

            # adjust fish speed according to postion
            @inbounds for n = 1:3
                if (fish.pos[n] - 0.5) * fish.dir[n] > 0
                    factor = minimum([fish.pos[n], 1 - fish.pos[n]])
                else
                    factor = maximum([fish.pos[n], 1 - fish.pos[n]])
                end
                v[n] = v_init * factor

                if n == 1 || n == 2
                    ang[3] = ang[3] * sqrt((factor + 1)) # factor map to 1-2
                end
                if n == 3
                    ang[2] = ang[2] * (factor + 1)
                end
            end

            _update_fish!(fish, v, ang)
            
            t1 = @async restyle!(fig, 3, x=(fish.tail.x,), y=(fish.tail.y,), z=(fish.tail.z,))
            sleep(0.05)   
            wait(t1)
            t2 = @async restyle!(fig, 2, x=(fish.body.x,), y=(fish.body.y,), z=(fish.body.z,))
            sleep(0.05)   
            wait(t2)

            _check_eat!(food, fish, 1E-1)
            _update_food!(food, v_init)
            t3 = @async restyle!(fig, 4,  x=(food.pts.x,), y=(food.pts.y,), z=(food.pts.z,))
            sleep(0.05)  
            wait(t3)

            count += 1
            if count >= reset_num # sleep for a while
                pause()
                sleep(floor(rand()*5) + 1)
                go()
                count = 0
                reset_num = 3600 + rand(-100:100)
            end

            if replot[]
                fig = plot(world, layout)
                display(fig)
                sleep(1)
                replot[] = false
            end
        end

        while !running[]
            sleep(1)
        end
    end
end

function _check_eat!(food, fish, eps)
    tmp = []
    mouth_pos = fish.pos .+ 0.06.*fish.dir
    if food.num != 0
        @inbounds for n in eachindex(food.num) 
            if abs2(mouth_pos[1]-food.pts.x[n]) + abs2(mouth_pos[2]-food.pts.y[n]) + abs2(mouth_pos[3].-food.pts.z[n]) < eps^2
                push!(tmp, n)  
                food.num -= 1
                if sound[]
                    if food.num != 0
                        beep("coin")
                    else
                        beep("ping")
                    end
                end
            end
        end
    end

    if length(tmp) != 0
        deleteat!(food.pts.x, tmp)
        deleteat!(food.pts.y, tmp)  
        deleteat!(food.pts.z, tmp)
        deleteat!(food.zd, tmp)
    end
end

end

