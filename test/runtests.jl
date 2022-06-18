using LuxorGraphPlot, Graphs
using Test

@testset "nodes" begin
    include("nodes.jl")
end

@testset "graphplot" begin
    include("graphplot.jl")
end