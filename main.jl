using Pkg, Revise
Pkg.activate(".")

using FishTank

# basic usage
init()
add()
for n = 1:5
    plant()
end