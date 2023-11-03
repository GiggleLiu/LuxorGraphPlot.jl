module TensorNetwork
using ..LuxorGraphPlot
using Luxor
export mps!, ts!, cc!, dc!, dangle!, grid!
# tensor network visualization
function mps!(n::Int; open=false, label_prefix="", radius=15, distance=50, offset=(0, 0))
    nodes = []
    for i=1:n
        node = ts!(LuxorGraphPlot.topoint(offset) + Point((i-1) * distance, 0); radius, label="$(label_prefix)$i")
        push!(nodes, node)
    end
    # vertical lines
    for i=1:n
        dangle!(nodes[i], "top", distance ÷ 2)
    end
    # horizontal lines
    for i=1:n-1
        dc!(nodes[i], nodes[i+1])
    end
    if open
        dangle!(nodes[1], "left", distance ÷ 2)
        dangle!(nodes[end], "right", distance ÷ 2)
    end
end

function ts!(loc; size=15, label=nothing, shape::String="o")
    node = LuxorGraphPlot._node(shape, loc, size)
    push!(LuxorGraphPlot.getcontext!(), node)
    if label !== nothing
        label!(node, "$label")
    end
    return node
end

function grid!(m::AbstractMatrix; vspace=50, hspace=50, offset=(0, 0), size=15, labels=nothing)
    n, p = Base.size(m)
    nodes = similar(m, Node, n, p)
    for i=1:n
        for j=1:p
            node = ts!(LuxorGraphPlot.topoint(offset) + Point(hspace * (j-1), vspace * (i-1));
                shape=m[i,j], size,
                label=labels === nothing ? nothing : labels[i,j]
            )
            nodes[i, j] = node
        end
    end
    return nodes
end

function cc!(a, b, direction; label=nothing, offsetrate=0.5)
    r = distance(a, b)
    control_points = [boundary(offset(a, direction, r * offsetrate), direction).loc, boundary(offset(b, direction, r * offsetrate), direction).loc]
    edge = connect!(a, b; control_points)
    # label it
    if label !== nothing
        label!(edge, label)
    end
    return edge
end

function dc!(a, b, label=nothing)
    edge = connect!(a, b)
    # label it
    if label !== nothing
        label!(edge, label)
    end
    return edge
end

function dangle!(a, direction, distance)
    connect!(a, offset(center(a), direction, distance))
end
end
