```@meta
EditURL = "../../../examples/features.jl"
```

````@example features
using LuxorGraphPlot, LuxorGraphPlot.Luxor
using LuxorGraphPlot.TensorNetwork
````

## Node styles

````@example features
@drawsvg begin
	background("white")
    for (k, (node, shape)) in enumerate([
            (circlenode((0, 0), 30), "circle"),
            (boxnode((0, 0), 50, 50; smooth=10), "box"),
            (polygonnode([rotatepoint(Point(30, 0), i*π/3) for i=1:6]; smooth=5), "polygon"),
        ])
        origin(k*100-50, 50)
        stroke(node)
        text(shape, offset(node, (0, 43)))
        @layer begin
            setcolor("black")
            setcolor("red")
            fontsize(6)
            for p in [left, right, top, bottom, topleft, bottomleft, topright, bottomright, center]
                text(string(p), offset(fill(circlenode(p(node), 3)), (0, 6)))
            end
        end
    end
end 300 100
````

## Connection points

````@example features
@drawsvg begin
    background("white")
    for (k, mode) in enumerate([:exact, :natural])
        origin(300k-150, 150)
        ct = Point(0, 0)
        a = circlenode(ct, 30) |> stroke
        for i=1:16
            d  = rotatepoint(Point(100, 0), i*π/8)
            b = boxnode(ct + d, 20, 20) |> stroke
            c = Connection(a, b; mode) |> stroke
        end
        fontsize(14)
        text(string(mode), offset(a, (0, 130)))
    end
end 600 300
````

## Connector styles

````@example features
@drawsvg begin
	radius = 30
	background("white")
    fontsize(28)
    a = boxnode(Point(50, 50), 40, 40; smooth=5)
    b = offset(a, (100, 0))
    # the default smooth method is "curve", it must take two control points.
    for cps in [[offset(midpoint(a, b), (0, 50))], [offset(a, (0, 50)), offset(b, (0, 50))]]
        for (k, smoothprops) in enumerate([
                Dict(:method=>length(cps) == 1 ? "nosmooth" : "curve"),
                Dict(:method=>"smooth", :radius=>10),
                Dict(:method=>"bezier", :radius=>10),
            ])
            dx = 200k-200
            origin(dx, length(cps)*150-150)
            stroke(a)
            stroke(b)
            text("A", a)
            text("B", b)
            Connection(a, b; smoothprops, control_points=cps) |> stroke
            @layer begin
                fontsize(14)
                text(string(get(smoothprops, :method, "")), offset(midpoint(a, b), (0, 70)))
            end
        end
    end
    # Connection("A", "B", control_points=[tonode("C").loc, tonode("D").loc])
    # Connection("C", "D", control_points=[tonode("A").loc, tonode("B").loc], isarrow=true, arrowprops=Dict(:finisharrow=>true, :linewidth=>2))
end 600 300
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

