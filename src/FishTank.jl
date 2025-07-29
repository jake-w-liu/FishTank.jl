module FishTank

export init, pause, go, mute, unmute, check, feed, plant, replot, look, get_params, set_param!, hunger, resting

using PlotlyJS
using PlotlyGeometries
using Distributions
using BeepBeep
using MeshGrid
using FFTW
using LinearAlgebra
using WAV


include("fish_fn.jl")
include("food_fn.jl")
include("weed_fn.jl")
include("api.jl")


const WAV_PATH = joinpath(@__DIR__, "..", "media", "eat.wav")
const SOUND_EAT, FS = wavread(WAV_PATH)

const RESET_COUNT_THRESH = 8192

# Simulation parameters struct
mutable struct FishTankParams
	INITIAL_FISH_VELOCITY::Float64
    SINK_VELOCITY::Float64
	FOOD_UPDATE_THRESH::Float64
	EAT_DISTANCE::Float64
	BLEND_FACTOR_ANG::Float64
	HUNGER_INC_BASE::Float64
    HUNGER_INC_FAC::Float64
	HUNGER_INC_EXP::Float64
	HUNGER_FOOD_THRESH::Float64
	HUNGER_FAC_THRESH::Float64
	HUNGER_EAT_FAC_EXP::Float64
	HUNGER_EAT_FAC_BASE::Float64
	HUNGER_EAT_MIN::Float64
    HUNGER_EAT_BASE::Float64
	COMBO_EXP::Float64
	DOT_FRONT_THRESH::Float64
	REST_PERIOD::Int
	REST_COUNT_MAX::Int
	REST_DIR_THRESH::Float64
end

function default_params()
	FishTankParams(
		0.03, # INITIAL_FISH_VELOCITY
        0.02, # SINK_VELOCITY
		0.02, # FOOD_UPDATE_THRESH
		0.015, # EAT_DISTANCE
		0.14,   # BLEND_FACTOR_ANG
		0.0001, # HUNGER_INC_BASE
        0.0001, # HUNGER_INC_FAC
		1.2,    # HUNGER_INC_EXP
		0.6,    # HUNGER_FOOD_THRESH
		0.4,    # HUNGER_FAC_THRESH
		2.3,    # HUNGER_EAT_FAC_EXP
		1.1,    # HUNGER_EAT_FAC_BASE
		0.001,  # HUNGER_EAT_MIN
        0.05, # HUNGER_EAT_BASE
		0.4,    # COMBO_EXP
		0.707,    # DOT_FRONT_THRESH
		1024, # REST_PERIOD
		100,    # REST_COUNT_MAX
		0.2,    # REST_DIR_THRESH
	)
end

const PARAMS = default_params()

mutable struct TankState
	lock::Bool
	running::Bool
	sound::Bool
	plotTrig::Bool
	food::Food
	weedList::Vector{Weed}
	weedCount::Int
	Az::Float64
	El::Float64
	viewTrig::Bool
end

function TankState()
	TankState(false, true, true, false, _create_food(0), Vector{Weed}(), 0, 28.0, 12.0, false)
end

const TANK_STATE = TankState()

function _initialize_tank()
	tank = cubes([0.5, 0.5, 0.5], 1.1, "white"; opc = 0.15)
	x = 1.25 * sqrt(3) * cosd(TANK_STATE.El) * cosd(TANK_STATE.Az)
	y = 1.25 * sqrt(3) * cosd(TANK_STATE.El) * sind(TANK_STATE.Az)
	z = 1.25 * sqrt(3) * sind(TANK_STATE.El)
	tank.hoverinfo = "none"
	layout = Layout(scene = attr(
			xaxis = attr(
				visible = false,
				showgrid = false,
			),
			yaxis = attr(
				visible = false,
				showgrid = false,
			),
			zaxis = attr(
				visible = false,
				showgrid = false,
			),
		),
		scene_camera = attr(
			eye = attr(x = x, y = y, z = z),
		),
		uirevision = true,
		transition = attr(
			easing = "quad-in-out",
		),
		height = 400,
		width = 420,
		margin = attr(
			l = 45,
			r = 0,
			b = 0,
			t = 0,
		),
	)
	return tank, layout
end

function _initialize_fish(color)
	pos = rand(3) .* 0.5 .+ 0.25
	
	fish = _create_fish(pos, color)
	return fish, ang, v
end

const FISH = _create_fish(rand(3) .* 0.5 .+ 0.25, "")

function main(color = "")

    # fish coloring
    if color == ""
        r = round(Int, rand() * 255)
        g = round(Int, rand() * 255)
        b = round(Int, rand() * 255)
        color = "rgb($r, $g, $b)"
    end
    FISH.body.color = color
    FISH.tail.color = color

	# tank initialzation
	tank, layout = _initialize_tank()
    
	zmax, landscape = _create_landscape()

	world = [tank, FISH.body, FISH.tail, TANK_STATE.food.pts, landscape]
	fig = plot(world, layout)
	task_plot = @async display(fig)
	sleep(0.1)

	reset_count = 0
	rest_count = 0

	s1 = s2 = 1
	factor = 0

    ang = zeros(2)
	v = fill(PARAMS.INITIAL_FISH_VELOCITY, 3)

	while true
		if TANK_STATE.sound
			sleep(1)
			beep("facebook")
		end

		while TANK_STATE.running

			if TANK_STATE.viewTrig
				set_view!(fig, TANK_STATE.Az, TANK_STATE.El)
				TANK_STATE.viewTrig = false
			end

			wait(task_plot)

			# Increase hunger over time
			if FISH.hunger < 1.0
				FISH.hunger = min(1.0, FISH.hunger + PARAMS.HUNGER_INC_BASE +PARAMS.HUNGER_INC_FAC * (FISH.hunger+1)^PARAMS.HUNGER_INC_EXP)
			end

			if !FISH.rest
				rest_count += 1
                # change sign intertia

				target_dir = FISH.dir # Default to current direction
				if FISH.hunger > PARAMS.HUNGER_FOOD_THRESH && TANK_STATE.food.num > 0 # If hungry and food is available
					# Find closest food particle
					min_dist_sq = Inf
					closest_food_idx = -1
                    dot_th_v = PARAMS.DOT_FRONT_THRESH - PARAMS.DOT_FRONT_THRESH * (FISH.hunger -  PARAMS.HUNGER_FOOD_THRESH) / (1 -  PARAMS.HUNGER_FOOD_THRESH)  # Adjust threshold based on hunger
					for i in eachindex(TANK_STATE.food.pts.x)
						food_vec = [TANK_STATE.food.pts.x[i], TANK_STATE.food.pts.y[i], TANK_STATE.food.pts.z[i]] .- FISH.pos
						if dot(food_vec ./ norm(food_vec), FISH.dir ./ norm(FISH.dir)) > dot_th_v # Check if food is in front of the fish
							dist_sq = (FISH.pos[1] - TANK_STATE.food.pts.x[i])^2 + (FISH.pos[2] - TANK_STATE.food.pts.y[i])^2 + (FISH.pos[3] - TANK_STATE.food.pts.z[i])^2
							if dist_sq < min_dist_sq
								min_dist_sq = dist_sq
								closest_food_idx = i
							end
						end
					end

					# println("ind: ", closest_food_idx)

					if closest_food_idx != -1
						food_pos = [TANK_STATE.food.pts.x[closest_food_idx], TANK_STATE.food.pts.y[closest_food_idx], TANK_STATE.food.pts.z[closest_food_idx]]
						target_dir = food_pos .- FISH.pos
						target_dir .= target_dir ./ norm(target_dir) # Normalize target direction

						# Calculate desired angles to steer towards target_dir
						# Yaw angle (rotation around Z-axis)
						current_yaw = atan(FISH.dir[2], FISH.dir[1])
						target_yaw = atan(target_dir[2], target_dir[1])
						delta_yaw = target_yaw - current_yaw
						if delta_yaw > pi
							delta_yaw -= 2 * pi
						elseif delta_yaw < -pi
							delta_yaw += 2 * pi
						end

						# Pitch angle (rotation around Y-axis, assuming FISH.dir is in XY plane for this)
						# This is a simplification, a more robust pitch would involve cross products
						current_pitch = atan(FISH.dir[3], sqrt(FISH.dir[1]^2 + FISH.dir[2]^2))
						target_pitch = atan(target_dir[3], sqrt(target_dir[1]^2 + target_dir[2]^2))
						delta_pitch = target_pitch - current_pitch

						# Convert to degrees for ang
						desired_ang1 = rad2deg(delta_pitch) # Corresponds to ang[1] (pitch)
						desired_ang2 = rad2deg(delta_yaw) # Corresponds to ang[2] (yaw)

						# Blend desired angles with random angles
						blend_factor_ang = PARAMS.BLEND_FACTOR_ANG # How strongly to bias towards desired angles
						ang[1] = (1 - blend_factor_ang) * (rand() * 2 * s1) + blend_factor_ang * desired_ang1
						ang[2] = (1 - blend_factor_ang) * ((rand() * 2 + 1) * s2) + blend_factor_ang * desired_ang2
					else
						# If hungry but no food in target zone, use original random angles
                        s1 = s1 * sign(rand(Normal(0.5, 0.5)))
                        s2 = s2 * sign(rand(Normal(0.5, 0.5)))

						ang[1] = rand() * 2 * s1
						ang[2] = (rand() * 2 + 1) * s2
					end
				else
					# If not hungry or no food, use original random angles
                    s1 = s1 * sign(rand(Normal(0.5, 0.5)))
                    s2 = s2 * sign(rand(Normal(0.5, 0.5)))

					ang[1] = rand() * 2 * s1
					ang[2] = (rand() * 2 + 1) * s2
				end

				# adjust fish speed according to postion
				@inbounds for n ∈ 1:3
					if (FISH.pos[n] - 0.5) * FISH.dir[n] > 0
						factor = minimum([FISH.pos[n], 1 - FISH.pos[n]])
					else
						factor = maximum([FISH.pos[n], 1 - FISH.pos[n]])
					end
					v[n] = PARAMS.INITIAL_FISH_VELOCITY * factor

					if n == 1 || n == 2
						ang[2] *= 1.1 * sqrt((factor + 1)) # factor map to 1-2
					end
					if n == 3
						ang[1] *= 1.2 * (factor + 1)
					end
				end
				if abs(FISH.dir[3]) > sqrt(3) / 2
					ang[1] = -1.2 * sign(FISH.dir[3]) * abs(ang[1])
				end

				if rest_count >= PARAMS.REST_PERIOD
					rest_count = 0
					if abs(FISH.dir[3]) < PARAMS.REST_DIR_THRESH
						FISH.rest = true
					end
				end
			else
				if rand(Bool)
					rest_count += 1
				end
				if rest_count > PARAMS.REST_COUNT_MAX
					rest_count = 0
					FISH.rest = false
				else
					sleep(0.1)
				end
			end
			# println("Fish hunger: ", FISH.hunger)

			_update_fish!(FISH, v, ang, zmax)

			_check_eat!()

			if _check_food_update(TANK_STATE.food, PARAMS.FOOD_UPDATE_THRESH)
				_update_food!(TANK_STATE.food, PARAMS.SINK_VELOCITY)
			end

			if length(fig.plot.data) - 5 < TANK_STATE.weedCount
				for n in (length(fig.plot.data)-4):TANK_STATE.weedCount
					push!(world, TANK_STATE.weedList[n].body)
					react!(fig, world, layout)
					sleep(0.01)
				end
			end

			_update_weed!(TANK_STATE.weedList)

			react!(fig, world, layout)
			sleep(0.1)

			reset_count += 1
			if reset_count >= RESET_COUNT_THRESH # reset

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

			if TANK_STATE.plotTrig
				fig = plot(world, layout)
				display(fig)
				sleep(1)
				TANK_STATE.plotTrig = false
			end
		end

		while !TANK_STATE.running
			sleep(1)
		end
	end
end

function _check_eat!()
	tmp = Int[]
	mouth_pos = FISH.pos .+ 0.03 .* FISH.dir
	if FISH.hunger < PARAMS.HUNGER_FOOD_THRESH && FISH.combo > 0
		FISH.combo = 0
	end
	if TANK_STATE.food.num != 0
		@inbounds for n in eachindex(TANK_STATE.food.pts.x)
			if abs2(mouth_pos[1] - TANK_STATE.food.pts.x[n]) + abs2(mouth_pos[2] - TANK_STATE.food.pts.y[n]) + abs2(mouth_pos[3] .- TANK_STATE.food.pts.z[n]) < PARAMS.EAT_DISTANCE^2
				push!(tmp, n)
				TANK_STATE.food.num -= 1
                FISH.combo += 1
                
				if FISH.hunger > PARAMS.HUNGER_FAC_THRESH
					fac = PARAMS.HUNGER_EAT_FAC_BASE * (2 - (FISH.hunger - PARAMS.HUNGER_FAC_THRESH) / (1 - PARAMS.HUNGER_FAC_THRESH))^PARAMS.HUNGER_EAT_FAC_EXP
				end

				FISH.hunger = max(0.0, FISH.hunger - PARAMS.HUNGER_EAT_BASE * (FISH.combo)^(PARAMS.COMBO_EXP) * fac - PARAMS.HUNGER_EAT_MIN) # Reduce hunger when eating

				@async if TANK_STATE.sound
					wavplay(SOUND_EAT, FS)
				end
			end
		end
	end

	if length(tmp) != 0
		deleteat!(TANK_STATE.food.pts.x, tmp)
		deleteat!(TANK_STATE.food.pts.y, tmp)
		deleteat!(TANK_STATE.food.pts.z, tmp)
		deleteat!(TANK_STATE.food.zd, tmp)
	end
    return nothing
end

# function _check_eat!(food, fish, eps)
# 	tmp = Int[]
# 	mouth_pos = fish.pos .+ 0.03 .* fish.dir
# 	if fish.hunger < PARAMS.HUNGER_FOOD_THRESH && fish.combo > 0
# 		fish.combo = 0
# 	end
# 	if food.num != 0
# 		@inbounds for n in eachindex(food.pts.x)
# 			if abs2(mouth_pos[1] - food.pts.x[n]) + abs2(mouth_pos[2] - food.pts.y[n]) + abs2(mouth_pos[3] .- food.pts.z[n]) < eps^2
# 				push!(tmp, n)
# 				food.num -= 1
                
# 				if fish.hunger > PARAMS.HUNGER_FAC_THRESH
# 					fac = PARAMS.HUNGER_EAT_FAC_BASE * (2 - (fish.hunger - PARAMS.HUNGER_FAC_THRESH) / (1 - PARAMS.HUNGER_FAC_THRESH))^PARAMS.HUNGER_EAT_FAC_EXP
# 				end

# 				fish.hunger = max(0.0, fish.hunger - PARAMS.HUNGER_EAT_BASE * (fish.combo)^(PARAMS.COMBO_EXP) * fac - PARAMS.HUNGER_EAT_MIN) # Reduce hunger when eating

# 				@async if TANK_STATE.sound
# 					wavplay(SOUND_EAT, FS)
# 				end
#                 fish.combo += 1
# 			end
# 		end
# 	end

# 	if length(tmp) != 0
# 		deleteat!(food.pts.x, tmp)
# 		deleteat!(food.pts.y, tmp)
# 		deleteat!(food.pts.z, tmp)
# 		deleteat!(food.zd, tmp)
# 	end
# end

function _create_landscape()
	x = -0.05:0.11:1.05
	y = -0.05:0.11:1.05

	Y, X = meshgrid(y, x)
	H = exp.(-15 * ((X .- 0.5) .^ 2 + (Y .- 0.5) .^ 2))
	Z = real.(ifft(H .* fft(rand(length(y), length(x)))))
	Z[Z .< 0] .= 0
	Z0 = similar(Z)
	fill!(Z0, -0.05)

	return maximum(Z), mesh3d(x = [X[:]; X[:]], y = [Y[:]; Y[:]], z = [Z[:]; Z0[:]],
		alphahull = 0,
		color = "#ECB88A"; # USUGAKI
		opacity = 1,
		lighting = attr(
			diffuse = 0.1,
			specular = 1.2,
			roughness = 1.0,
		),
		hoverinfo = "none",
	)
end

end
