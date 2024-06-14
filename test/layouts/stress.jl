using Test, LuxorGraphPlot, Graphs
using Luxor: Drawing, RGB
using LuxorGraphPlot.Layouts

@testset "helpers" begin
    g = smallgraph(:petersen)
    @test Layouts.weighted_laplacian(adjacency_matrix(g)) == laplacian_matrix(g)
end

@testset "stress layout" begin
    graph = random_regular_graph(100, 3)
    optimal_distance = 50
    locs = Layouts.stressmajorize_layout(graph; optimal_distance)
    @test locs isa Vector{<:Layouts.Point{2}}
    Q = Layouts.quality_of_layout(graph, locs, optimal_distance)
    @test Q.closeness > 10000 && Q.mean_distance_deviation < 1
end

@testset "stress layout layered" begin
    graph = random_regular_graph(100, 3)
    optimal_distance = 50
    locs= Layouts.stressmajorize_layout_layered(graph, rand([0,200], nv(graph)); optimal_distance)
    @test locs isa Vector{<:Layouts.Point{2}}
    Q = Layouts.quality_of_layout(graph, locs, optimal_distance)
    @test Q.closeness > 5000 && Q.mean_distance_deviation < 4
end