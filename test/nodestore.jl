using LuxorGraphPlot
using Luxor
using Test

@testset "nodestore" begin
    drawing = nodestore() do ns
        c1 = circle!((0.4, 0.5), 30)
        c2 = circle!((0.4, 0.5), 80)
        with_nodes() do
            sethue("white")
            fill(c1)
            fill(c2)
            sethue("black")
            text("y", c1)
            text("x", c2)
            line(c1, c2)
            stroke(c1)
            stroke(c2)
        end
    end
    @test drawing isa Drawing
end