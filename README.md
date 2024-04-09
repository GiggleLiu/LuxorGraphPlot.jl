# LuxorGraphPlot

A minimum package for displaying a graph and configurations defined on graphs.
It is the [`Luxor`](https://github.com/JuliaGraphics/Luxor.jl) version of [`GraphPlot`](https://github.com/JuliaGraphs/GraphPlot.jl).

Install by typing `using Pkg; Pkg.add("LuxorGraphPlot")` in a julia REPL.

(NOTE: After implementing this package, I noticed there is a similar package with more features: https://github.com/cormullion/Karnak.jl.)

## Example

In a notebook or IDE with graphical display, use the following statements to show your graph.

```julia
julia> using LuxorGraphPlot, Graphs

julia> show_graph(smallgraph(:petersen); format=:svg)
```
![](notebooks/demo.svg)

### Lower-level API

You can also use the lower-level API to customize the graph display.

```julia
julia> using LuxorGraphPlot, LuxorGraphPlot.Luxor
```