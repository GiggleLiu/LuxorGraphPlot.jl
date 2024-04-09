module TensorNetwork
using ..LuxorGraphPlot
import ..LuxorGraphPlot: AbstractNodeStore, nodes
using Luxor

export mps, TensorNetworkDiagram
struct TensorNetworkDiagram <: AbstractNodeStore
    nodes::Vector{Node}
    dots::Vector{Node}
    edges::Vector{Connection}
end
nodes(tn::TensorNetworkDiagram) = [tn.nodes..., tn.dots...]

# tensor network visualization
function mps(n::Int; radius=15, distance=50, offset=(0, 0))
    nodes = [circlenode(LuxorGraphPlot.topoint(offset) + Point((i-1) * distance, 0), radius) for i=1:n]
    # pins
    pins = [LuxorGraphPlot.offset(center(a), "top", distance ÷ 2) for a in nodes]
    # edges
    edges = [[connect(a, b) for (a, b) in zip(nodes[1:end-1], nodes[2:end])]...,
                [connect(a, b) for (a, b) in zip(nodes, pins)]...]
    return TensorNetworkDiagram(nodes, pins, edges)
end

end
