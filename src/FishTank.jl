module FishTank

export init, pause, go, mute, unmute, check, add, plant, showup

using PlotlyJS
using PlotlyGeometries
using Distributions
using BeepBeep
using MeshGrid
using FFTW
using LinearAlgebra
using Infiltrator

include("fish_fn.jl")
include("food_fn.jl")
include("weed_fn.jl")
include("apis.jl")

const lock = Ref(false)
const running = Ref(true)
const sound = Ref(true)
const replot = Ref(false)
const food = _create_food(0)
const weedList = Vector{Weed}()
const weedCount = Ref(0)

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
        scene_camera=attr(
            eye=attr(x=1.75, y=1.25, z=0.6)
        ),
        uirevision=true,
        transition=attr(
            easing="quad-in-out",
        ),
        height=400,
        width=400,
        margin=attr(
            l=45,
            r=0,
            b=15,
            t=0,
        ),
    )

    # fish initialization
    pos = rand(3) .* 0.5 .+ 0.25
    ang = zeros(3)

    v_init = 0.03
    v = fill(v_init, 3)

    fish = _create_fish(pos, color)
    zmax, landscape = _create_landscape()
    world = [tank, fish.body, fish.tail, food.pts, landscape]

    fig = plot(world, layout)
    display(fig)
    sleep(0.1)

    cz = 1
    cy = 1

    count = 0
    reset_num = 666

    while true
        if sound[]
            sleep(0.1)
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
                    ang[3] *= sqrt((factor + 1)) # factor map to 1-2
                end
                if n == 3
                    ang[2] *= (factor + 1)
                end
            end

            _update_fish!(fish, v, ang, zmax)

            t1 = @async restyle!(fig, 3, x=(fish.tail.x,), y=(fish.tail.y,), z=(fish.tail.z,))
            sleep(0.05)
            wait(t1)
            t2 = @async restyle!(fig, 2, x=(fish.body.x,), y=(fish.body.y,), z=(fish.body.z,))
            sleep(0.1)
            wait(t2)

            _check_eat!(food, fish, 1E-1)
            _update_food!(food, v_init)

            t3 = @async restyle!(fig, 4, x=(food.pts.x,), y=(food.pts.y,), z=(food.pts.z,))
            sleep(0.05)
            wait(t3)

            if length(fig.plot.data) - 5 < weedCount[]
                for n in length(fig.plot.data) - 4 : weedCount[] 
                    addtraces!(fig, weedList[n].body)
                    sleep(0.01)
                end
            end

            _update_weed!(weedList)

            for n in eachindex(weedList)
                t = @async restyle!(fig, 5 + n, x=(weedList[n].body.x,), y=(weedList[n].body.y,), z=(weedList[n].body.z,))
                sleep(0.01)
                wait(t)
            end

            count += 1
            if count >= reset_num # reset
                # pause()
                sleep(1)
                # go()
                count = 0
                # reset_num = 3600 + rand(-100:100)
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
    mouth_pos = fish.pos .+ 0.06 .* fish.dir
    if food.num != 0
        @inbounds for n in eachindex(food.num)
            if abs2(mouth_pos[1] - food.pts.x[n]) + abs2(mouth_pos[2] - food.pts.y[n]) + abs2(mouth_pos[3] .- food.pts.z[n]) < eps^2
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

function _create_landscape()
    x = -0.05:0.11:1.05
    y = -0.05:0.11:1.05

    Y, X = meshgrid(y, x)
    H = exp.(-15 * ((X .- 0.5) .^ 2 + (Y .- 0.5) .^ 2))
    Z = real.(ifft(H .* fft(rand(length(y), length(x)))))
    Z[Z.<0] .= 0
    Z0 = similar(Z)
    fill!(Z0, -0.05)

    return maximum(Z), mesh3d(x=[X[:]; X[:]], y=[Y[:]; Y[:]], z=[Z[:]; Z0[:]],
        alphahull=0,
        # color="#CBBD93",
        color="#ECB88A"; # USUGAKI
        opacity=1,
        lighting=attr(
            diffuse=0.1,
            specular=1.2,
            roughness=1.0,
        ),
    )
end



end

