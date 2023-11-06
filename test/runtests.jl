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

@testset "diagram" begin
    include("diagram.jl")
end