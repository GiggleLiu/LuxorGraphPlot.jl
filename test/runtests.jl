using LuxorGraphPlot, Graphs
using Test

@testset "LuxorGraphPlot.jl" begin
    locations = [(1.0, 2.0), (2.0, 3.0)]
    @test show_graph(locations, [(1, 2)]) isa Any
    @test show_graph([], []) isa Any
    @test show_graph([], []; format=:pdf) isa Any
    @test show_graph([], []; filename=tempname()*".svg") isa Any
    graph = smallgraph(:petersen)
    @test show_graph(graph) isa Any
    @test show_gallery(graph, (2,4); vertex_configs=[rand(Bool, 15) for i=1:10], edge_configs=[rand(Bool, 15) for i=1:10]) isa Any
end
