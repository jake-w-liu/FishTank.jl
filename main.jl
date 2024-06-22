using Pkg
Pkg.activate(".")

using FishTank

# basic usage
init()
add()
for n = 1:10
    plant()
end