using Test, LuxorGraphPlot
using LuxorGraphPlot.Layouts: Point, distance, norm, rand_points_2d

@testset "Point" begin
    p1 = Point(1.0, 2.0)
    @test p1[1] == 1.0
    p2 = Point(3.0, 4.0)
    @test p1 + p2 ≈ Point(4.0, 6.0)
    @test norm(p1) == sqrt(5)
    @test distance(p1, p2) == sqrt(8)

    @test rand_points_2d(10) isa Vector{Point{2, Float64}}
    @test rand(Point{2, Float64}) isa Point{2, Float64}
    @test randn(Point{2, Float64}) isa Point{2, Float64}
end

