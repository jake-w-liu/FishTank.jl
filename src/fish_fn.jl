mutable struct Fish
    body::PlotlyJS.GenericTrace
    tail::PlotlyJS.GenericTrace
    pos::Vector
    dir::Vector
end

function _create_fish(pos, color="", opc=1)

    if color == ""
        r = round(Int, rand()*255)
        g = round(Int, rand()*255)
        b = round(Int, rand()*255)
        color = "rgb($r, $g, $b)"
    end

    fac = 50
    a = 3 / fac
    b = 0.8 / fac
    c = 1 / fac

    body = ellipsoids(pos, [a, b, c], color, opc, 6, 15)
    tail = polygons([[-0.5*a, 0.0, 0.0].+pos, [-2*a, 0.0, -1.5*b].+pos, [-2*a, 0.0, 1.5*b].+pos], color, opc*0.8)

    fish = Fish(body, tail, pos, [1, 0, 0])

    return fish
end

function _update_fish!(fish, v, ang)

    eps = 0.075
    alpha = ang[1]
    beta = ang[2]
    gama = ang[3]

    Rx = [1 0 0;
        0 cosd(alpha) -sind(alpha);
        0 sind(alpha) cosd(alpha)]
    Ry = [cosd(beta) 0 sind(beta);
        0 1 0;
        -sind(beta) 0 cosd(beta)]
    Rz = [cosd(gama) -sind(gama) 0;
        sind(gama) cosd(gama) 0;
        0 0 1]

    R = Rx * Ry * Rz
    fish.dir = R * fish.dir

    @inbounds for n in eachindex(fish.body.x)
        vec = [fish.body.x[n] - fish.pos[1], fish.body.y[n] - fish.pos[2], fish.body.z[n] - fish.pos[3]]
        vec = R * vec + fish.pos
        fish.body.x[n] = vec[1] + v[1] .* fish.dir[1]
        fish.body.y[n] = vec[2] + v[2] .* fish.dir[2]
        fish.body.z[n] = vec[3] + v[3] .* fish.dir[3]
    end

    @inbounds for n in eachindex(fish.tail.x)
        vec = [fish.tail.x[n] - fish.pos[1], fish.tail.y[n] - fish.pos[2], fish.tail.z[n] - fish.pos[3]]
        # 
        vec = R * vec + fish.pos
        fish.tail.x[n] = vec[1] + v[1] .* fish.dir[1]
        fish.tail.y[n] = vec[2] + v[2] .* fish.dir[2]
        fish.tail.z[n] = vec[3] + v[3] .* fish.dir[3]
    end

    fish.pos = fish.pos + v .* fish.dir

    # change direction if close to wall
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
    if (abs(fish.pos[3]) < eps && fish.dir[3] < 0) || (abs(fish.pos[3] - 1) < eps && fish.dir[3] > 0)
        fish.dir[3] = -fish.dir[3]
        @inbounds for n in eachindex(fish.body.x)
            fish.body.z[n] = -(fish.body.z[n] - fish.pos[3]) + fish.pos[3]
        end
        @inbounds for n in eachindex(fish.tail.x)
            fish.tail.z[n] = -(fish.tail.z[n] - fish.pos[3]) + fish.pos[3]
        end
    end

    return nothing
end