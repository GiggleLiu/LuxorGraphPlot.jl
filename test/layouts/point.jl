using Test, LuxorGraphPlot
using LuxorGraphPlot.Layouts: Point, distance, norm

@testset "Point" begin
    p1 = Point(1.0, 2.0)
    p2 = Point(3.0, 4.0)
    @test p1 + p2 ≈ Point(4.0, 6.0)
    @test norm(p1) == sqrt(5)
    @test distance(p1, p2) == sqrt(8)
end

