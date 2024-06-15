# FishTank.jl

[![Build Status](https://github.com/akjake616/FishTank.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/akjake616/FishTank.jl/actions/workflows/CI.yml)

`FishTank.jl` creates an e-fish for you in case you feel lonely when you are coding. The game is visualized using [`PlotlyJS.jl`](https://github.com/JuliaPlots/PlotlyJS.jl) and [`PlotlyGeometries.jl`](https://github.com/akjake616/PlotlyGeometries.jl).

<p align="center">
  <img alt="FishTank.jl" src="./media/fish-tank.gif" width="50%" height="auto" />
</p>

## Installation

To install `FishTank.jl`, use the following command in the Julia REPL:

```julia
using Pkg
Pkg.add("FishTank")
```

## Usage

In order to start a fish tank, you simply need to use the package and call the `init()` function.

```julia
using FishTank
init() # creates a random colored fish by default.
```

To feed the fish with, for example, six grains, call the following:

```julia 
add(6) # add 6 grains to the fish tank, if the input is not specified, 10 grains are added
```

Finally, call the following to decorate the fish tank with waterweed:
```julia 
plant() # randomly plant one waterweed bunble
```

Enjoy! :angel:

## APIs

The following APIs are used to interact with the fish.
___

```julia
init(color::String)
```
Initialization of the fish and tank. The fish is specified with the color=`color`. If `color` is not specified, the color of the fish is set to be random. Currently only one fish tank can be initialized per process.

___

```julia
pause()
```
Pause simulation. If you want to rotate the tank (for a different view), one should pause the simulation first. I have no better solution for this (rotating the plot and continuing the simulation at the same time), so feel free to contribute if you know how to solve this issue :kissing_heart:
___

```julia
go()
```
Continue simulation.
___

```julia
mute()
```
Turn off sound effects. The default is on.
___

```julia
unmute()
```
Turn on sound effects.
___

```julia
add(n::Int=10)
```
Add `n` grains (add 10 if `n` not specified).
___

```julia
check()
```
Check the number of grains.

___

```julia
plant()
```
Plant waterweed.

___

```julia
showup()
```
Show up the fish tank window (if it is accidentally closed).

___






