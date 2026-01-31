using FishTank

println("Testing reset!() with parameter modifications...\n")

println("1. Initializing first tank...")
init("blue")
sleep(2)

println("\n2. Modifying some parameters...")
println("   Original REST_PERIOD: ", get_params().REST_PERIOD)
set_param!(:REST_PERIOD, 512)
println("   Modified REST_PERIOD: ", get_params().REST_PERIOD)

println("   Original BLEND_FACTOR_ANG: ", get_params().BLEND_FACTOR_ANG)
set_param!(:BLEND_FACTOR_ANG, 0.5)
println("   Modified BLEND_FACTOR_ANG: ", get_params().BLEND_FACTOR_ANG)

sleep(2)

println("\n3. Calling reset!() to reset everything...")
reset!("red")

sleep(2)

println("\n4. Checking if parameters were reset to defaults:")
println("   REST_PERIOD after reset: ", get_params().REST_PERIOD, " (should be 1024)")
println("   BLEND_FACTOR_ANG after reset: ", get_params().BLEND_FACTOR_ANG, " (should be 0.14)")

if get_params().REST_PERIOD == 1024 && get_params().BLEND_FACTOR_ANG == 0.14
    println("\n✓ Parameters successfully reset to defaults!")
else
    println("\n✗ WARNING: Parameters were NOT reset properly!")
end

println("\n5. Letting the new tank run for a few seconds...")
sleep(3)

println("\nTest complete!")
