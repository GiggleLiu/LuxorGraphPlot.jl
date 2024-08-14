module LuxorGraphPlot
using Luxor, Graphs
using LinearAlgebra
using MLStyle: @match

export show_graph, show_gallery, left, right, top, bottom, center, boundary, connect, offset, topright, topleft, bottomleft, bottomright
export bottomalign, topalign, rightalign, leftalign
export Node, Connection, circlenode, ellipsenode, boxnode, polygonnode, dotnode, linenode, tonode
export NodeStore, nodestore, with_nodes
export box!, circle!, polygon!, dot!, line!, stroke, ellipse!
export GraphDisplayConfig, GraphViz
export SpringLayout, StressLayout, SpectralLayout, render_locs, LayeredStressLayout, LayeredSpringLayout, AbstractLayout, Layered, AestheticLayout
export lighttheme!, darktheme!

include("nodes.jl")
include("layouts/layouts.jl")
using .Layouts: SpringLayout, StressLayout, SpectralLayout, render_locs, LayeredStressLayout, LayeredSpringLayout, AbstractLayout, Layered, AestheticLayout
include("nodestore.jl")
include("graphplot.jl")
include("tnet.jl")

end
