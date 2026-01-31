# using Pkg, Revise
# Pkg.activate(".")

# using FishTank

# init()
# feed()
# for n = 1:10
#     plant()
# end

# look(0, 0)
# sleep(0.1)
# @async for n in 1:360
#     look(n, 0)
#     sleep(0.1)
# end

using FishTank
using CSV
using DataFrames
using Statistics

"""
Run parameter sensitivity analysis for FishTank.jl
Tests three key parameters: γ (HUNGER_INC_EXP), β (BLEND_FACTOR_ANG), and T_R (REST_PERIOD)
"""

println("=== FishTank.jl Parameter Sensitivity Analysis ===\n")

# Create output directory
mkpath("experiments/results")

# Simulation parameters
const SIM_DURATION = 60  # 5 minutes in seconds (needed for meaningful trends)
const SAMPLE_INTERVAL = 1.0  # Sample every second
const N_FOOD = 20
const INITIAL_HUNGER = 0.55

# Parameter ranges
gamma_values = [1.2]  # HUNGER_INC_EXP
beta_values = [0.05]  # BLEND_FACTOR_ANG
T_R_values = [256]  # REST_PERIOD

"""
Run a single simulation and collect data
"""
function run_simulation(param_name::Symbol, param_value, sim_id::String)
    println("Running: $param_name = $param_value")

    # Initialize tank
    init("blue")
    sleep(1.0)

    # Set parameter
    set_param!(param_name, param_value)

    # Add food
    feed(N_FOOD)
    sleep(0.5)

    # Collect data
    times = Float64[]
    hungers = Float64[]
    rests = Bool[]
    food_counts = Int[]

    start_time = time()
    last_sample = start_time

    while (time() - start_time) < SIM_DURATION
        current_time = time()

        if (current_time - last_sample) >= SAMPLE_INTERVAL
            elapsed = current_time - start_time
            push!(times, elapsed)
            push!(hungers, hunger())
            push!(rests, resting())
            push!(food_counts, check())

            last_sample = current_time
        end

        sleep(0.1)
    end

    # Create DataFrame
    df = DataFrame(
        time = times,
        hunger = hungers,
        resting = rests,
        food_count = food_counts,
        param_name = fill(String(param_name), length(times)),
        param_value = fill(param_value, length(times)),
        sim_id = fill(sim_id, length(times))
    )

    # Reset for next run
    reset!()
    sleep(1.0)

    return df
end

# Experiment 1: Vary γ (HUNGER_INC_EXP)
println("\n--- Experiment 1: Varying γ (HUNGER_INC_EXP) ---")
gamma_results = DataFrame[]
for (i, gamma) in enumerate(gamma_values)
    df = run_simulation(:HUNGER_INC_EXP, gamma, "gamma_$i")
    push!(gamma_results, df)
end
gamma_df = vcat(gamma_results...)
CSV.write("experiments/results/gamma_sensitivity_01.csv", gamma_df)
println("✓ Saved gamma_sensitivity.csv")

# Experiment 2: Vary β (BLEND_FACTOR_ANG)
println("\n--- Experiment 2: Varying β (BLEND_FACTOR_ANG) ---")
beta_results = DataFrame[]
for (i, beta) in enumerate(beta_values)
    df = run_simulation(:BLEND_FACTOR_ANG, beta, "beta_$i")
    push!(beta_results, df)
end
beta_df = vcat(beta_results...)
CSV.write("experiments/results/beta_sensitivity_01.csv", beta_df)
println("✓ Saved beta_sensitivity.csv")

# Experiment 3: Vary T_R (REST_PERIOD)
println("\n--- Experiment 3: Varying T_R (REST_PERIOD) ---")
T_R_results = DataFrame[]
for (i, T_R) in enumerate(T_R_values)
    df = run_simulation(:REST_PERIOD, T_R, "T_R_$i")
    push!(T_R_results, df)
end
T_R_df = vcat(T_R_results...)
CSV.write("experiments/results/T_R_sensitivity_01.csv", T_R_df)
println("✓ Saved T_R_sensitivity.csv")

# Generate summary statistics
println("\n--- Summary Statistics ---")

function compute_summary(df, param_values)
    summary = DataFrame(
        param_value = Float64[],
        mean_hunger = Float64[],
        std_hunger = Float64[],
        max_hunger = Float64[],
        mean_rest_ratio = Float64[],
        final_food_count = Float64[]
    )

    for pval in param_values
        subset = filter(row -> row.param_value == pval, df)
        if nrow(subset) > 0
            push!(summary, (
                pval,
                mean(subset.hunger),
                std(subset.hunger),
                maximum(subset.hunger),
                mean(subset.resting),
                mean(subset.food_count[end-10:end])  # Average of last 10 samples
            ))
        end
    end

    return summary
end

gamma_summary = compute_summary(gamma_df, gamma_values)
CSV.write("experiments/results/gamma_summary_01.csv", gamma_summary)
println("✓ Gamma summary: mean hunger range = $(minimum(gamma_summary.mean_hunger)) - $(maximum(gamma_summary.mean_hunger))")

beta_summary = compute_summary(beta_df, beta_values)
CSV.write("experiments/results/beta_summary_01.csv", beta_summary)
println("✓ Beta summary: mean hunger range = $(minimum(beta_summary.mean_hunger)) - $(maximum(beta_summary.mean_hunger))")

T_R_summary = compute_summary(T_R_df, T_R_values)
CSV.write("experiments/results/T_R_summary_01.csv", T_R_summary)
println("✓ T_R summary: mean rest ratio range = $(minimum(T_R_summary.mean_rest_ratio)) - $(maximum(T_R_summary.mean_rest_ratio))")

println("\n=== Analysis Complete ===")
println("Results saved to experiments/results/")
println("\nNext: Run plot_sensitivity.jl to generate figures")

