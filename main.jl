push!(LOAD_PATH, ".")
using FishTank

init()
add(100)
for n = 1:4
    plant()
end