using FishTank

println("Testing reset!() function...")
println("\n1. Initializing first tank...")
init("blue")

println("\n2. Waiting 3 seconds...")
sleep(3)

println("\n3. Calling reset!() with red fish...")
reset!("red")

println("\n4. New tank should now be running with a red fish!")
println("   Let it run for a few seconds to verify fish is moving...")
sleep(5)

println("\n5. Test complete! You should have seen:")
println("   - First window with blue fish")
println("   - Window closed")
println("   - New window with red fish (moving)")
