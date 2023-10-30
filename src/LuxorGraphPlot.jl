module LuxorGraphPlot
using Luxor, Graphs
using LinearAlgebra
using MLStyle: @match

export show_graph, show_gallery, spring_layout!, left, right, top, bottom, center, boundary, connect, offset
export Node, Connection, ncircle, nbox, npolygon, ndot, nline, tonode
export Diagram, diagram, strokenodes, fillnodes, strokeconnections, showlabels, figdiagram
export nbox!, ncircle!, npolygon!, ndot!, nline!, connect!, label!

include("nodes.jl")
include("layouts.jl")
include("graphplot.jl")
include("diagram.jl")
include("tnet.jl")

end