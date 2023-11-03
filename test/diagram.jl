using LuxorGraphPlot
using Luxor
using Test

@testset "diagram" begin
    @test (@drawsvg begin
        background("white")
        d = diagram() do
            label!(circle!((0.4, 0.5), 30), "y")
            label!(circle!((0.4, 0.5), 80), "x")
            connect!("x", "y")
        end
        sethue("white")
        fillnodes(d)
        sethue("black")
        showlabels(d)
        strokeconnections(d)
        strokenodes(d)
    end 400 400) isa Drawing
end