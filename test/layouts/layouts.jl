module LayoutsTest
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
    for layout in [
                [(randn(), randn()) for i=1:nv(graph)],
                SpringLayout(),
                StressLayout(),
                SpectralLayout(),
                StressLayoutLayered(zlocs=rand([0,200], nv(graph))),
                SpringLayoutLayered(zlocs=rand([0,200], nv(graph))),
            ]
        @test show_graph(graph, layout) isa Drawing
        gs = [GraphViz(graph, layout; vertex_sizes=rand(Bool, 10) .* 100, edge_colors=rand(RGB, 15)) for i=1:2, j=1:4]
        @test show_gallery(gs) isa Drawing
    end
    locs = [(randn(2)...,) for i=1:10]
    @test show_graph(graph, SpringLayout()) isa Drawing
    gs = [GraphViz(graph, SpringLayout(); vertex_sizes=rand(Bool, 10) .* 100, edge_colors=rand(RGB, 15)) for i=1:2, j=1:4]
    @test show_gallery(gs) isa Drawing
end
end