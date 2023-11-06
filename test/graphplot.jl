using LuxorGraphPlot, Graphs
using Luxor
using Test

@testset "graph plot" begin
    locations = [(1.0, 2.0), (2.0, 3.0)]
    @test show_graph(locations, [(1, 2)]) isa Drawing
    @test show_graph([], []) isa Drawing
    @test show_graph([], []; format=:pdf) isa Drawing
    @test show_graph([], []; filename=tempname()*".svg") isa Drawing
    graph = smallgraph(:petersen)
    @test show_graph(graph) isa Drawing
    show_graph(graph; vertex_shapes=fill("box", 10)) isa Drawing
    # gallery
    @test show_gallery([], [], (3, 3)) isa Drawing
    @test show_gallery(graph, (2,4); vertex_configs=[rand(Bool, 15) for i=1:10], edge_configs=[rand(Bool, 15) for i=1:10]) isa Drawing

    @test LuxorGraphPlot.@temp GraphDisplayConfig.vertex_color[] = "red" GraphDisplayConfig.vertex_line_width=8 begin
        show_graph([], []; format=:pdf)
    end isa Drawing
    @test GraphDisplayConfig.vertex_color[] == "transparent"
    @test GraphDisplayConfig.vertex_line_width[] == 1
end
