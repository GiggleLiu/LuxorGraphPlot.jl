using Test
using LuxorGraphPlot: angleof, closest_natural_point
using LuxorGraphPlot
using Luxor

@testset "nodes" begin
    Node(Circle, )
end

@testset "angleof and boundary" begin
    @test angleof(Point(0.5*sqrt(3.0), 0.5)) ≈ π/6
    n = node(box, O, 100, 100)
    @test boundary(n, angleof(Point(0.5*sqrt(3.0), 0.5))) ≈ Point(50, 50/sqrt(3))
    @test closest_natural_point(n, Point(100, 120)) ≈ Point(50, 50)
    @test closest_natural_point(n, Point(130, -120)) ≈ Point(50, -50)
    @test closest_natural_point(n, Point(130, -10)) ≈ Point(50, 0)
end