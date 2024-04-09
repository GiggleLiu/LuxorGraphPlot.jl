using LuxorGraphPlot.TensorNetwork, Luxor, Test, LuxorGraphPlot

@testset "mps" begin
    diagram = mps(4)
    fig = with_nodes(diagram) do
        for (i, node) in enumerate(diagram.nodes)
            LuxorGraphPlot.stroke(node)
            text("A($i)", node)
        end
        for edge in diagram.edges
            LuxorGraphPlot.stroke(edge)
        end
    end
    display(fig)
    @test fig isa Drawing
end