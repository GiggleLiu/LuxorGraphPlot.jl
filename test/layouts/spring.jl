using Test, LuxorGraphPlot, Graphs
using LuxorGraphPlot.Layouts
using Luxor: Drawing, RGB
using Random

@testset "spring layout" begin
    graph = random_regular_graph(100, 3)
    optimal_distance = 50
    locs = Layouts.spring_layout(graph; optimal_distance)
    @test locs isa Vector{<:Layouts.Point{2}}
    Q = Layouts.quality_of_layout(graph, locs, optimal_distance)
    @test Q.closeness > 10000 && Q.mean_distance_deviation < 2
end

@testset "spring layout layered" begin
    graph = random_regular_graph(100, 3)
    optimal_distance = 50
    locs= Layouts.spring_layout_layered(graph, rand([0,200], nv(graph)); optimal_distance)
    @test locs isa Vector{<:Layouts.Point{2}}
    Q = Layouts.quality_of_layout(graph, locs, optimal_distance)
    @test Q.closeness > 5000 && Q.mean_distance_deviation < 4
end

@testset "data types" begin
    graph = random_regular_graph(100, 3)
    optimal_distance = 50.0
    # without initial locations
    layout = Layouts.SpringLayout(; optimal_distance)
    @test layout isa Layouts.SpringLayout
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}

    # with initial locations
    layout = Layouts.SpringLayout(; optimal_distance, meta=Dict(:initial_locs=>Layouts.rand_points_2d(100)))
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}

    # with initial locations and mask
    layout = Layouts.SpringLayout(; optimal_distance, meta=Dict(:initial_locs=>Layouts.rand_points_2d(100), :mask=>trues(100)))
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}

    # layered
    zlocs = rand([0,200], nv(graph))
    layout = Layouts.SpringLayoutLayered(; zlocs, optimal_distance)
    @test layout isa Layouts.SpringLayoutLayered
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}
end