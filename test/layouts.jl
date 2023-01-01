using Test, LuxorGraphPlot, Graphs
using Luxor: Drawing

@testset "layouts" begin
    graph = smallgraph(:petersen)
    for layout in [:auto, :spring, :spectral, :stress]
        @test show_graph(graph; layout) isa Drawing
        @test show_gallery(graph, (2,4); vertex_configs=[rand(Bool, 15) for i=1:10], edge_configs=[rand(Bool, 15) for i=1:10], layout) isa Drawing
    end
    locs = [(randn(2)...,) for i=1:10]
    @test show_graph(graph; layout=:auto) isa Drawing
    @test show_gallery(graph, (2,4); vertex_configs=[rand(Bool, 15) for i=1:10], edge_configs=[rand(Bool, 15) for i=1:10], layout=:auto) isa Drawing
end