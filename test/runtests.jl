using LuxorGraphPlot, Graphs
using Test

@testset "layouts" begin
    include("layouts.jl")
end

@testset "graphplot" begin
    include("graphplot.jl")
end

@testset "nodes" begin
    include("nodes.jl")
end

@testset "nodestore" begin
    include("nodestore.jl")
end