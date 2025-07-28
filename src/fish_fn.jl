mutable struct Fish
    body::PlotlyJS.GenericTrace
    tail::PlotlyJS.GenericTrace
    pos::Vector{Float64}
    dir::Vector{Float64}
    hunger::Float64
    target_food_idx::Union{Int, Nothing}
    combo::Int
end

function _create_fish(pos, color="", opc=0.9)

    if color == ""
        r = round(Int, rand() * 255)
        g = round(Int, rand() * 255)
        b = round(Int, rand() * 255)
        color = "rgb($r, $g, $b)"
    end

    a = 0.06
    b = 0.016
    c = 0.02

    body = ellipsoids(pos, [a, b, c], color; opc=opc, tres=7, pres=16, ah=0)
    tail = polygons([[-0.2 * a, 0.0, 0.0] .+ pos, [-1.8 * a, 0.0, -1.5 * b] .+ pos, [-1.8 * a, 0.0, 1.5 * b] .+ pos], color; opc=opc * 0.7)

    fish = Fish(body, tail, pos, [1.0, 0.0, 0.0], 0.55, nothing, 0)

    return fish
end

function _update_fish!(fish, v, ang, zmax, rest)

    if !rest
        axis = [fish.dir[2], -fish.dir[1], 0]

        grot!(fish.body, ang[1], axis, fish.pos)
        grot!(fish.body, ang[2], [0, 0, 1], fish.pos)

        grot!(fish.tail, ang[1], axis, fish.pos)
        grot!(fish.tail, ang[2], [0, 0, 1], fish.pos)

        ## calculate new direction
        axis .= axis ./ norm(axis)
        fish.dir .= cosd(ang[1]) * fish.dir + sind(ang[1]) * cross(axis, fish.dir) + (1 - cosd(ang[1])) * dot(axis, fish.dir) * axis
        axis .= [0, 0, 1]
        fish.dir .= cosd(ang[2]) * fish.dir + sind(ang[2]) * cross(axis, fish.dir) + (1 - cosd(ang[2])) * dot(axis, fish.dir) * axis
        fish.dir .= fish.dir ./ norm(fish.dir)

        fish.pos .= fish.pos + v .* fish.dir
        gtrans!(fish.body, v .* fish.dir)
        gtrans!(fish.tail, v .* fish.dir)

        # change direction if close to wall
        eps = 0.06
        if (abs(fish.pos[1]) < eps && fish.dir[1] < 0) || (abs(fish.pos[1] - 1) < eps && fish.dir[1] > 0)
            fish.dir[1] = -fish.dir[1]
            @inbounds for n in eachindex(fish.body.x)
                fish.body.x[n] = -(fish.body.x[n] - fish.pos[1]) + fish.pos[1]
            end
            @inbounds for n in eachindex(fish.tail.x)
                fish.tail.x[n] = -(fish.tail.x[n] - fish.pos[1]) + fish.pos[1]
            end
        end
        if (abs(fish.pos[2]) < eps && fish.dir[2] < 0) || (abs(fish.pos[2] - 1) < eps && fish.dir[2] > 0)
            fish.dir[2] = -fish.dir[2]
            @inbounds for n in eachindex(fish.body.x)
                fish.body.y[n] = -(fish.body.y[n] - fish.pos[2]) + fish.pos[2]
            end
            @inbounds for n in eachindex(fish.tail.x)
                fish.tail.y[n] = -(fish.tail.y[n] - fish.pos[2]) + fish.pos[2]
            end
        end
        if (abs(fish.pos[3] - zmax) < eps && fish.dir[3] < 0) || (abs(fish.pos[3] - 1) < eps && fish.dir[3] > 0)
            fish.dir[3] = -fish.dir[3]
            @inbounds for n in eachindex(fish.body.x)
                fish.body.z[n] = -(fish.body.z[n] - fish.pos[3]) + fish.pos[3]
            end
            @inbounds for n in eachindex(fish.tail.x)
                fish.tail.z[n] = -(fish.tail.z[n] - fish.pos[3]) + fish.pos[3]
            end
        end
    end

    vec = [fish.body.x[1] - fish.pos[1], fish.body.y[1] - fish.pos[2], fish.body.z[1] - fish.pos[3]]

    tail_dir = [fish.tail.x[1], fish.tail.y[1], fish.tail.z[1]] .- [fish.tail.x[4], fish.tail.y[4], fish.tail.z[4]]
    dp = dot(tail_dir, fish.dir) / norm(tail_dir) / norm(fish.dir)
    if abs(dp) > 1
        dp = sign(dp) * 1
    end
    tail_ang = sign(dot(cross(tail_dir, fish.dir), vec)) * acosd(dp) 

    grot!(fish.tail, 5 * rand()-2.5 + tail_ang, vec, fish.pos)

    return nothing
end