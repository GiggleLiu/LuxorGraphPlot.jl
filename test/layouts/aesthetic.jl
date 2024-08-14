using LuxorGraphPlot, Test, Graphs

@testset "utilities" begin
    points = [LuxorGraphPlot.Layouts.Point(randn(), randn()) for i=1:10]
    packed = LuxorGraphPlot.Layouts.unpack_points(points)
    recovered = LuxorGraphPlot.Layouts.pack_points(packed)
    @test points == recovered
end

@testset "aesthetic layout" begin
    g = smallgraph(:petersen)
    l = AestheticLayout(; optimal_distance=50.0)
    locs = render_locs(g, l)
    @show locs
end