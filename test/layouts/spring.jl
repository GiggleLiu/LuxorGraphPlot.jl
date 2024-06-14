using Test, LuxorGraphPlot, Graphs
using LuxorGraphPlot.Layouts
using Luxor: Drawing, RGB
using Random

function quality_of_layout(graph, locs, C)
    average_distance_con = sum([Layouts.distance(locs[e.src], locs[e.dst]) for e in edges(graph)])/ne(graph)
    average_distance_dis = sum([Layouts.distance(locs[e.src], locs[e.dst]) for e in edges(complement(graph))])
    deviation = abs(average_distance_con - C) / C
    return average_distance_dis/average_distance_con, deviation
end

@testset "spring layout" begin
    graph = random_regular_graph(100, 3)
    C = 50
    locs = Layouts.spring_layout(graph; C)
    @test locs isa Vector{<:Layouts.Point{2}}
    Q, D = quality_of_layout(graph, locs, C)
    @test Q > 10000 && D < 5
end

@testset "spring layout layered" begin
    graph = random_regular_graph(100, 3)
    C = 50
    locs= Layouts.spring_layout_layered(graph, rand([0,200], nv(graph)); C=50)
    @test locs isa Vector{<:Layouts.Point{2}}
    Q, D = quality_of_layout(graph, locs, C)
    @test Q > 5000 && D < 4
end