using LuxorGraphPlot, LuxorGraphPlot.Luxor
using LuxorGraphPlot.TensorNetwork

# ## Node styles
# We a combination of [`nodestore`](@ref) and [`with_nodes`](@ref) to draw nodes with automatically inferred bounding boxes.
nodestore() do ns  # store nodes in the nodestore (used to infer the bounding box)
    a = circle!((0, 0), 30)
    b = ellipse!((100, 0), 60, 40)
    c = box!((200, 0), 50, 50; smooth=10)
    d = polygon!([rotatepoint(Point(30, 0), i*π/3) for i=1:6] .+ Ref(Point(300, 0)); smooth=5)
    with_nodes(ns) do  # the context manager to draw nodes
        fontsize(6)
        for (node, shape) in [(a, "circle"), (b, "ellipse"), (c, "box"), (d, "polygon")]
            stroke(node)
            text(shape, node)
            for p in [left, right, top, bottom, topleft, bottomleft, topright, bottomright, LuxorGraphPlot.center]
                text(string(p), offset(fill(circlenode(p(node), 3)), (0, 6)))
            end
        end
    end
end

# ## Connect points
nodestore() do ns
    a1 = circle!((150, 150), 30)
    a2 = circle!((450, 150), 30)
    box1s = [offset(boxnode(rotatepoint(Point(100, 0), i*π/8), 20, 20), a1.loc) for i=1:16]
    box2s = offset.(box1s, Ref(a2.loc-a1.loc))
    append!(ns, box1s)
    append!(ns, box2s)
    with_nodes(ns) do
        fontsize(14)
        stroke(a1)
        stroke(a2)
        for b in box1s
            stroke(b)
            line(a1, b; mode=:exact)
        end
        for b in box2s
            stroke(b)
            stroke(Connection(a2, b; mode=:natural, isarrow=true))
        end
        text("exact", a1)
        text("natural", a2)
    end
end
        
# ## Connector styles
nodestore() do ns
	radius = 30
    a = boxnode(Point(50, 50), 40, 40; smooth=5)
    b = offset(a, (100, 0))
    groups = Matrix{Vector{Node}}(undef, 2, 3)
    for j=0:1
        for k = 0:2
            items = [offset(a, (200k, 150j)), offset(b, (200k, 150j))]
            groups[j+1, k+1] = items
            append!(ns, items)
            push!(ns, offset(midpoint(items...), (0, 70)))
        end
    end
    with_nodes() do
        fontsize(28)
        ## the default smooth method is "curve", it must take two control points.
        for j=1:2
            for k = 1:3
                a, b = groups[j, k]
                cps  = [[offset(midpoint(a, b), (0, 50))], [offset(a, (0, 50)), offset(b, (0, 50))]][j]
                smoothprops = [
                    Dict(:method=>length(cps) == 1 ? "nosmooth" : "curve"),
                    Dict(:method=>"smooth", :radius=>10),
                    Dict(:method=>"bezier", :radius=>10),
                ][k]
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
    end
end