using Test
using LuxorGraphPlot: angleof, closest_natural_point, getpath
using LuxorGraphPlot
using Luxor

@testset "angleof and boundary" begin
    @test angleof(Point(0.5*sqrt(3.0), 0.5)) ≈ π/6
    n = boxnode(O, 100, 100)
    path = getpath(n)
    @test boundary(n, angleof(Point(0.5*sqrt(3.0), 0.5))).loc ≈ Point(50, 50/sqrt(3))
    @test closest_natural_point(path, Point(100, 120)) ≈ Point(50, 50)
    @test closest_natural_point(path, Point(130, -120)) ≈ Point(50, -50)
    @test closest_natural_point(path, Point(130, -10)) ≈ Point(50, 0)
end

@testset "nodes" begin
    # circle
    n = circlenode((0.2, 0.4), 0.5)
    @test right(n).loc == Point(0.7, 0.4)
    @test left(n).loc == Point(-0.3, 0.4)
    @test bottom(n).loc == Point(0.2, 0.9)
    @test top(n).loc == Point(0.2, -0.1)
    
    # ellipse
    n = ellipsenode((0.2, 0.4), 1.0, 2.0)
    @test right(n).loc == Point(0.7, 0.4)
    @test left(n).loc == Point(-0.3, 0.4)
    @test bottom(n).loc == Point(0.2, 1.4)
    @test top(n).loc == Point(0.2, -0.6)

    # box
    n = boxnode((0.2, 0.4), 1.0, 0.4)
    @test right(n).loc == Point(0.7, 0.4)
    @test left(n).loc == Point(-0.3, 0.4)
    @test top(n).loc == Point(0.2, 0.2)
    @test bottom(n).loc == Point(0.2, 0.6)

    # polygon
    path = getpath(n)
    n = polygonnode((0.2, 0.4), path .- Ref(Point(0.2, 0.4)))
    @test right(n).loc == Point(0.7, 0.4)
    @test left(n).loc == Point(-0.3, 0.4)
    @test bottom(n).loc == Point(0.2, 0.6)
    @test top(n).loc == Point(0.2, 0.2)

    # dot
    n = dotnode((0.2, 0.4))
    @test right(n).loc == Point(0.2, 0.4)
    @test left(n).loc == Point(0.2, 0.4)
    @test top(n).loc == Point(0.2, 0.4)
    @test bottom(n).loc == Point(0.2, 0.4)

    # line
    n = linenode((-0.1, 0.2), (0.3, 0.4))
    @test right(n).loc == Point(0.3, 0.4)
    @test left(n).loc == Point(-0.1, 0.2)
    @test bottom(n).loc == Point(0.3, 0.4)
    @test top(n).loc == Point(-0.1, 0.2)
end

@testset "connection" begin
    n = boxnode((0.2, 0.4), 1.0, 0.4)
    @test Connection(left(n), right(n)) isa Connection
end
