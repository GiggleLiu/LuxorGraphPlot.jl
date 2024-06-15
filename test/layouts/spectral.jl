using Test, LuxorGraphPlot, Graphs
using Luxor: Drawing, RGB
using LuxorGraphPlot.Layouts

@testset "stress layout" begin
    Random.seed!(0)
    for n =[100, 2000]
        graph = random_regular_graph(n, 3)
        optimal_distance = 50
        locs = Layouts.spectral_layout(graph; optimal_distance)
        @test locs isa Vector{<:Layouts.Point{2}}
        Q = Layouts.quality_of_layout(graph, locs, optimal_distance)
        @test Q.closeness > 10000 && Q.mean_distance_deviation < 3
    end
    graph = SimpleGraph(1)
    optimal_distance = 50
    locs = Layouts.spectral_layout(graph; optimal_distance)
    @test locs isa Vector{<:Layouts.Point{2}} && length(locs) == 1

    graph = SimpleGraph(2)
    add_edge!(graph, 1, 2)
    optimal_distance = 50
    locs = Layouts.spectral_layout(graph; optimal_distance)
    @test locs isa Vector{<:Layouts.Point{2}} && length(locs) == 2
end

@testset "data types" begin
    graph = random_regular_graph(100, 3)
    optimal_distance = 50.0
    # without initial locations
    layout = Layouts.SpectralLayout(; optimal_distance)
    @test layout isa Layouts.SpectralLayout
    @test Layouts.render_locs(graph, layout) isa Vector{<:Layouts.Point{2}}
end