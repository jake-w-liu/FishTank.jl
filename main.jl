using Pkg, Revise
Pkg.activate(".")

using FishTank

init()
feed()
for n = 1:10
    plant()
end

look(0, 0)
sleep(0.1)
@async for n in 1:360
    look(n, 0)
    sleep(0.1)
end