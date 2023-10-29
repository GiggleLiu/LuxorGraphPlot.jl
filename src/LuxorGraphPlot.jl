module LuxorGraphPlot
using Luxor, Graphs
using LinearAlgebra
using MLStyle: @match

export show_graph, show_gallery, spring_layout!, left, right, top, bottom, boundary, connect
export Node, ncircle, nbox, npolygon, ndot, nline

include("nodes.jl")
include("layouts.jl")
include("graphplot.jl")

end