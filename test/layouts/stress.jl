using Test, LuxorGraphPlot, Graphs
using Luxor: Drawing, RGB
using LuxorGraphPlot.Layouts

@testset "helpers" begin
    g = smallgraph(:petersen)
    @test Layouts.weighted_laplacian(adjacency_matrix(g)) == laplacian_matrix(g)
end

@testset "stress layout" begin
    graph = random_regular_graph(100, 3)
    C = 50
    locs = Layouts.stressmajorize_layout(graph; C=50)
    @test locs isa Vector{<:Layouts.Point{2}}
    Q, D = quality_of_layout(graph, locs, C)
    @test Q > 10000 && D < 1
end