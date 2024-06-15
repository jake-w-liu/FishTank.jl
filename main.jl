push!(LOAD_PATH, ".")
using FishTank

init()
add(10)
for n = 1:10
    plant()
end