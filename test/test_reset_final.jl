using FishTank

println("=== Comprehensive Reset Test ===\n")

println("1. Testing initial fish tank...")
init("blue")
sleep(3)

println("\n2. Getting initial fish state...")
initial_hunger = hunger()
println("   Initial hunger: ", initial_hunger)
println("   Initial rest state: ", resting())

println("\n3. Modifying parameters to test reset...")
set_param!(:REST_PERIOD, 512)
set_param!(:BLEND_FACTOR_ANG, 0.5)
modified_rest = get_params().REST_PERIOD
modified_blend = get_params().BLEND_FACTOR_ANG
println("   Modified REST_PERIOD: ", modified_rest)
println("   Modified BLEND_FACTOR_ANG: ", modified_blend)

sleep(3)

println("\n4. Calling reset!() - this should completely terminate old task...")
reset!("red")

sleep(2)

println("\n5. Verifying complete reset...")
reset_hunger = hunger()
reset_rest = resting()
reset_rest_period = get_params().REST_PERIOD
reset_blend = get_params().BLEND_FACTOR_ANG

println("   Hunger after reset: ", reset_hunger)
println("   Rest state after reset: ", reset_rest)
println("   REST_PERIOD after reset: ", reset_rest_period, " (should be 1024)")
println("   BLEND_FACTOR_ANG after reset: ", reset_blend, " (should be 0.14)")

all_correct = true
if reset_rest_period != 1024
    println("\n   ✗ ERROR: REST_PERIOD not reset!")
    all_correct = false
end
if reset_blend != 0.14
    println("\n   ✗ ERROR: BLEND_FACTOR_ANG not reset!")
    all_correct = false
end
if abs(reset_hunger - 0.55) > 0.01
    println("\n   ✗ WARNING: Hunger not close to initial value (0.55)")
end

if all_correct
    println("\n   ✓ All parameters correctly reset!")
end

println("\n6. Letting fish swim for a few seconds to verify behavior...")
sleep(5)

println("\n7. Final verification - hunger should have changed from initial:")
final_hunger = hunger()
println("   Final hunger: ", final_hunger)
if final_hunger != reset_hunger
    println("   ✓ Fish is actively updating (hunger changed)")
else
    println("   ✗ WARNING: Fish might not be moving (hunger unchanged)")
end

println("\n=== Test Complete ===")
println("The fish should be swimming normally with default behavior.")
println("There should be NO faster movement or erratic behavior.")
