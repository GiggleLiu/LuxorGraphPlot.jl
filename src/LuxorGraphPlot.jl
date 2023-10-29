module LuxorGraphPlot
using Luxor, Graphs
using LinearAlgebra
using MLStyle: @match

export node
export show_graph, show_gallery, spring_layout!, left, right, top, bottom, boundary, connect, node
export Node, Circle, Box, Polygon, Segment, Dot, ncircle, nbox, npolygon, ndot, nsegment

include("nodes.jl")
include("layouts.jl")
include("graphplot.jl")

end