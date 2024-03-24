module LuxorGraphPlot
using Luxor, Graphs
using LinearAlgebra
using MLStyle: @match

export show_graph, show_gallery, spring_layout!, left, right, top, bottom, center, boundary, connect, offset, topright, topleft, bottomleft, bottomright
export Node, Connection, circlenode, ellipsenode, boxnode, polygonnode, dotnode, linenode, tonode
export Diagram, diagram, strokenodes, fillnodes, strokeconnections, showlabels, figdiagram, filternodes, filterconnections
export box!, circle!, polygon!, dot!, line!, connect!, label!
export stroke, fill
export GraphDisplayConfig

include("nodes.jl")
include("layouts.jl")
include("graphplot.jl")
include("diagram.jl")
include("tnet.jl")

end
