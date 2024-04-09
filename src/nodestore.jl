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
    xmin_val, xmax_val, ymin_val, ymax_val = Inf, -Inf, Inf, -Inf
    for n in nodes(d)
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
    @eval function $(Symbol(F, :!))(args...; kwargs...)
        obj = $(Symbol(F, :node))(args...; kwargs...)
        push!(getcontext!(), obj)
        return obj
    end
    @eval function $(Symbol(F, :!))(d::AbstractNodeStore, args...; kwargs...)
        obj = $(Symbol(F, :node))(args...; kwargs...)
        push!(d, obj)
        return obj
    end
end

function nodestore(f)
    d = NodeStore()
    setcontext!(d)
    drawing = f(d)
    emptycontext!()
    return drawing
end

with_nodes(f; kwargs...) = with_nodes(f, getcontext!(); kwargs...)
function with_nodes(f, d::AbstractNodeStore;
        padding_left=10, padding_right=10,
        padding_top=10, padding_bottom=10,
        format=:svg, filename=nothing,
        background="white"
    )
    xmin, xmax, ymin, ymax = get_bounding_box(d) .+ (-padding_left, padding_right, -padding_top, padding_bottom)
    Luxor.Drawing(ceil(Int, xmax - xmin), ceil(Int, ymax - ymin), filename === nothing ? tempname()*".$format" : filename)
    Luxor.origin(-xmin, -ymin)
    Luxor.background(background)
    f()
    Luxor.finish()
    Luxor.preview()
end