using LuxorGraphPlot, LuxorGraphPlot.Luxor
using LuxorGraphPlot: stroke

nodestore() do ns
    box = box!(ns, (100, 100), 100, 100)
    circle = circle!(ns, (200, 200), 50)
    polygon = polygon!(ns, [(300, 300), (350, 350), (400, 300), (350, 250)])
    dot = dot!(ns, (500, 500))
    line = line!(ns, (100, 100), (200, 200))
    with_nodes(ns, filename="nodestore.png") do
        stroke(box)
        stroke(circle)
        stroke(polygon)
        stroke(line)
        stroke(dot)
        Luxor.line(polygon, circle)
    end
end