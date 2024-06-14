using Test, LuxorGraphPlot, Graphs

@testset "point" begin
    include("point.jl")
end

@testset "spring" begin
    include("spring.jl")
end

@testset "stress" begin
    include("stress.jl")
end

@testset "spectral" begin
    include("spectral.jl")
end

@testset "layouts" begin
    graph = smallgraph(:petersen)
    for layout in [:auto, :spring, :spectral, :stress]
        @test show_graph(graph, Layout(layout)) isa Drawing
        gs = [GraphViz(graph, Layout(layout); vertex_sizes=rand(Bool, 10) .* 100, edge_colors=rand(RGB, 15)) for i=1:2, j=1:4]
        @test show_gallery(gs) isa Drawing
    end
    locs = [(randn(2)...,) for i=1:10]
    @test show_graph(graph, Layout(:auto)) isa Drawing
    gs = [GraphViz(graph, Layout(:auto); vertex_sizes=rand(Bool, 10) .* 100, edge_colors=rand(RGB, 15)) for i=1:2, j=1:4]
    @test show_gallery(gs) isa Drawing
end