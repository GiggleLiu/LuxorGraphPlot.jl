using LuxorGraphPlot.TensorNetwork, Luxor, Test, LuxorGraphPlot

@testset "mps" begin
    fig = figdiagram(400, 400) do
        mps!(4)
    end
    @test fig isa Drawing
end