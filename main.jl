push!(LOAD_PATH, ".")
using FishTank

# basic usage
init()
add()
for n = 1:5
    plant()
end