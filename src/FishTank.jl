module FishTank

export init, pause, go, mute, unmute, check, feed, plant, replot, look

using PlotlyJS
using PlotlyGeometries
using Distributions
using BeepBeep
using MeshGrid
using FFTW
using LinearAlgebra

include("fish_fn.jl")
include("food_fn.jl")
include("weed_fn.jl")
include("apis.jl")

const lock = Ref(false)
const running = Ref(true)
const sound = Ref(true)
const plotTrig = Ref(false)
const rest = Ref(false)
const food = _create_food(0)
const weedList = Vector{Weed}()
const weedCount = Ref(0)
const Az = Ref(45.0)
const El = Ref(35.264389682754654)
const viewTrig = Ref(false)

function main(color="")
    # tank initialzation
    tank = cubes([0.5, 0.5, 0.5], [1.1, 1.1, 1.1], "white", 0.15)
    tank.hoverinfo = "none"
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
            eye=attr(x=1.25, y=1.25, z=1.25)
        ),
        uirevision=true,
        transition=attr(
            easing="quad-in-out",
        ),
        height=400,
        width=420,
        margin=attr(
            l=45,
            r=0,
            b=0,
            t=0,
        ),
    )

    # fish initialization
    pos = rand(3) .* 0.5 .+ 0.25
    ang = zeros(2)

    v_init = 0.03
    v = fill(v_init, 3)

    fish = _create_fish(pos, color)
    zmax, landscape = _create_landscape()

    world = [tank, fish.body, fish.tail, food.pts, landscape]
    fig = plot(world, layout)
    task_plot = @async display(fig)
    sleep(0.1)

    reset_count = 0
    reset_num = 8192

    rest_count = 0
    rest_period = 1024

    c1 = c2 = 1
    factor = 0

    while true
        if sound[]
            sleep(0.1)
            beep("facebook")
        end

        while running[]

            if viewTrig[]
                _set_view(fig, Az[], El[])
                viewTrig[] = false
            end

            wait(task_plot)

            if !rest[]
                rest_count += 1

                # change sign intertia
                c1 = c1 * sign(rand(Normal(0.5, 0.5)))
                c2 = c2 * sign(rand(Normal(0.5, 0.5)))

                ang[1] = rand() * 2 * c1
                ang[2] = (rand() * 2 + 1) * c2

                # adjust fish speed according to postion
                @inbounds for n = 1:3
                    if (fish.pos[n] - 0.5) * fish.dir[n] > 0
                        factor = minimum([fish.pos[n], 1 - fish.pos[n]])
                    else
                        factor = maximum([fish.pos[n], 1 - fish.pos[n]])
                    end
                    v[n] = v_init * factor

                    if n == 1 || n == 2
                        ang[2] *= 1.1 * sqrt((factor + 1)) # factor map to 1-2
                    end
                    if n == 3
                        ang[1] *= 1.2 * (factor + 1)
                    end
                end
                if abs(fish.dir[3]) > sqrt(3) / 2
                    ang[1] = -2 * sign(fish.dir[3]) * abs(ang[1])
                end

                if rest_count >= rest_period
                    rest_count = 0
                    if abs(fish.dir[3]) < 0.2
                        rest_period = 1024 + rand(-100:100)
                        rest[] = true
                    end
                end
            else
                if rand(Bool)
                    rest_count += 1
                end
                if rest_count > 100
                    rest_count = 0
                    rest[] = false
                else
                    sleep(0.1)
                end
            end

            _update_fish!(fish, v, ang, zmax, rest[])

            _check_eat!(food, fish, 5E-2)

            if _check_update(food, 1E-2)
                _update_food!(food, 1E-2)
            end

            if length(fig.plot.data) - 5 < weedCount[]
                for n in length(fig.plot.data)-4:weedCount[]
                    push!(world, weedList[n].body)
                    react!(fig, world, layout)
                    sleep(0.01)
                end
            end

            _update_weed!(weedList)

            react!(fig, world, layout)
            sleep(0.1)

            reset_count += 1
            if reset_count >= reset_num # reset

                world_copy = copy(world)
                purge!(fig)
                
                for tr in world_copy
                    push!(fig.plot.data, tr)
                end
                world = world_copy
                react!(fig, world, layout)
                sleep(0.1)
                GC.gc()
                reset_count = 0
            end

            if plotTrig[]
                fig = plot(world, layout)
                display(fig)
                sleep(1)
                plotTrig[] = false
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
        color="#ECB88A"; # USUGAKI
        opacity=1,
        lighting=attr(
            diffuse=0.1,
            specular=1.2,
            roughness=1.0,
        ),
        hoverinfo="none",
    )
end

function _set_view(fig, az, el)

    x = 1.25 * sqrt(3) * cosd(el) * cosd(az)
    y = 1.25 * sqrt(3) * cosd(el) * sind(az)
    z = 1.25 * sqrt(3) * sind(el)

    fig.plot.layout.scene_camera[:eye][:x] = x
    fig.plot.layout.scene_camera[:eye][:y] = y
    fig.plot.layout.scene_camera[:eye][:z] = z
end

end

