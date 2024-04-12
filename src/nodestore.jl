abstract type AbstractNodeStore end
struct NodeStore <: AbstractNodeStore
    nodes::Vector{Node}
end
NodeStore() = NodeStore(Node[])
nodes(d::NodeStore) = d.nodes
function Base.push!(d::NodeStore, obj::Node)
    push!(d.nodes, obj)
    return d
end
function Base.append!(d::NodeStore, objs)
    append!(d.nodes, objs)
    return d
end
function get_bounding_box(d::AbstractNodeStore)
    nds = nodes(d)
    isempty(nds) && return (0.0, 0.0, 0.0, 0.0)
    xmin_val, xmax_val, ymin_val, ymax_val = Inf, -Inf, Inf, -Inf
    for n in nds
        path = getpath(n)
        xmin_val = min(xmin_val, xmin(path))
        xmax_val = max(xmax_val, xmax(path))
        ymin_val = min(ymin_val, ymin(path))
        ymax_val = max(ymax_val, ymax(path))
    end
    return xmin_val, xmax_val, ymin_val, ymax_val
end

const CURRENT_CONTEXT = Base.RefValue{AbstractNodeStore}(NodeStore())
function setcontext!(d::AbstractNodeStore)
    CURRENT_CONTEXT[] = d
    return d
end
function emptycontext!()
    CURRENT_CONTEXT[] = NodeStore()
end
function getcontext!()
    return CURRENT_CONTEXT[]
end

for F in [:line, :dot, :circle, :box, :polygon, :ellipse]
    SF = String(F)
    @eval begin
        """
            $($SF)!([nodestore, ]args...; kwargs...) = push!(nodestore, $($SF)node(args...; kwargs...))

        Add a $($SF) shaped node to the nodestore. Please refer to [`$($SF)node`](@ref) for more information.
        If `nodestore` is not provided, the current nodestore is used.
        """
        function $(Symbol(F, :!))(args...; kwargs...)
            obj = $(Symbol(F, :node))(args...; kwargs...)
            push!(getcontext!(), obj)
            return obj
        end
        function $(Symbol(F, :!))(d::AbstractNodeStore, args...; kwargs...)
            obj = $(Symbol(F, :node))(args...; kwargs...)
            push!(d, obj)
            return obj
        end
    end
end

"""
    nodestore(f)

Create a nodestore context and execute the function `f` with the nodestore as argument.

### Example
```julia
julia> using LuxorGraphPlot, LuxorGraphPlot.Luxor

julia> nodestore() do ns
    box = box!(ns, (100, 100), 100, 100)
    circle = circle!(ns, (200, 200), 50)
    with_nodes(ns) do
        stroke(box)
        stroke(circle)
        Luxor.line(topright(box), circle)
    end
end
```
"""
function nodestore(f)
    d = NodeStore()
    setcontext!(d)
    drawing = f(d)
    emptycontext!()
    return drawing
end

"""
    with_nodes(f[, nodestore]; kwargs...)

Create a drawing with the nodes in the nodestore.
The bounding box of the drawing is determined by the bounding box of the nodes in the nodestore.
If `nodestore` is not provided, the current nodestore is used.

### Keyword arguments
- `padding_left::Int=10`: Padding on the left side of the drawing.
- `padding_right::Int=10`: Padding on the right side of the drawing.
- `padding_top::Int=10`: Padding on the top side of the drawing.
- `padding_bottom::Int=10`: Padding on the bottom side of the drawing.
- `format::Symbol=:svg`: The format of the drawing. Available formats are `:png`, `:pdf`, `:svg`...
- `filename::String=nothing`: The filename of the drawing. If `nothing`, a temporary file is created.
- `background::String="white"`: The background color of the drawing.
"""
with_nodes(f; kwargs...) = with_nodes(f, getcontext!(); kwargs...)
function with_nodes(f, d::AbstractNodeStore;
        padding_left=10, padding_right=10,
        padding_top=10, padding_bottom=10,
        format=:svg, filename=nothing,
        background="white"
    )
    xmin, xmax, ymin, ymax = get_bounding_box(d) .+ (-padding_left, padding_right, -padding_top, padding_bottom)
    Luxor.Drawing(ceil(Int, xmax - xmin), ceil(Int, ymax - ymin), filename === nothing ? format : filename)
    Luxor.origin(-xmin, -ymin)
    Luxor.background(background)
    f()
    Luxor.finish()
    Luxor.preview()
end
