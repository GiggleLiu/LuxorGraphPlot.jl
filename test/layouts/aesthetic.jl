using LuxorGraphPlot, Test, Graphs

@testset "utilities" begin
    points = [LuxorGraphPlot.Layouts.Point(randn(), randn()) for i=1:10]
    packed = LuxorGraphPlot.Layouts.unpack_points(points)
    recovered = LuxorGraphPlot.Layouts.pack_points(packed)
    @test points == recovered
end

@testset "aesthetic layout" begin
    g = smallgraph(:petersen)
    g = Graph(12)
    for (i, j) in [(1, 2), (2, 5), (2, 6), (2, 7), (3, 4), (4, 5), (5, 6), (5, 11), (6, 7), (6, 9), (6, 10), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12)]
        add_edge!(g, i, j)
    end
    l = AestheticLayout(; optimal_distance=50.0)
    locs = render_locs(g, l)
    @show locs
end