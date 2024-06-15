using LuxorGraphPlot, Graphs
using Luxor
using Test

@testset "GraphDisplayConfig" begin
    config = GraphDisplayConfig()
    @test config isa GraphDisplayConfig
    c1 = darktheme!(copy(config))
    @test c1 isa GraphDisplayConfig
    @test c1.vertex_stroke_color == "white"
    c2 = lighttheme!(copy(config))
    @test c2 isa GraphDisplayConfig
    @test c2.vertex_stroke_color == "black"
end

@testset "GraphViz" begin
    graph = smallgraph(:petersen)
    gv = GraphViz(graph)
    @test gv isa GraphViz
    @test gv.locs isa Array
end

@testset "graph plot" begin
    locations = [(50.0, 100.0), (100.0, 150.0)]
    @test show_graph(GraphViz(locs=locations, edges=[(1, 2)])) isa Drawing
    gv = GraphViz(locs=[], edges=[])
    @test show_graph(gv) isa Drawing
    @test show_graph(gv; format=:pdf) isa Drawing
    @test show_graph(gv; filename=tempname()*".svg") isa Drawing
    graph = smallgraph(:petersen)
    @test show_graph(graph) isa Drawing
    show_graph(graph; vertex_shapes=fill(:box, 10)) isa Drawing
end

@testset "gallery" begin
    graph = smallgraph(:petersen)
    locs = render_locs(graph, StressLayout())
    matrix = [GraphViz(graph, locs; vertex_colors=[rand(Luxor.RGB) for i=1:10], edge_colors=[rand(Luxor.RGB) for i=1:15]) for i=1:2, j=1:4]
    # gallery
    @test show_gallery(matrix) isa Drawing 
    @test show_gallery(reshape(GraphViz[], 0, 0)) isa Drawing
end
