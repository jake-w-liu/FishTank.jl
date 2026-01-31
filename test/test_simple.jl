using FishTank

println("Initializing blue fish tank...")
init("blue")
sleep(2)

println("Resetting to red fish tank...")
FishTank.reset!("red")
sleep(2)

println("Test completed successfully!")
