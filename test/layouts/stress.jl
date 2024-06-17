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

@testset "data types" begin
    graph = random_regular_graph(100, 3)
    optimal_distance = 50.0
    # without initial locations
    layout = Layouts.StressLayout(; optimal_distance)
    @test layout isa Layouts.StressLayout
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}

    # with initial locations
    layout = Layouts.StressLayout(; optimal_distance, meta=Dict(:initial_locs=>Layouts.rand_points_2d(100)))
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}

    # with initial locations and mask
    layout = Layouts.StressLayout(; optimal_distance, meta=Dict(:initial_locs=>Layouts.rand_points_2d(100), :mask=>trues(100)))
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}

    # layered
    zlocs = rand([0,200], nv(graph))
    layout = Layouts.LayeredStressLayout(; zlocs, optimal_distance)
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}
end