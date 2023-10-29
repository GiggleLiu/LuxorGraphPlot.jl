const CURRENT_CONTEXT = Base.RefValue{Any}(nothing)
function setcontext!(d::Diagram)
    CURRENT_CONTEXT[] = d
    return d
end
function emptycontext!()
    CURRENT_CONTEXT[] = nothing
end
function getcontext!()
    ctx = CURRENT_CONTEXT[]
    if ctx === nothing
        ctx = Diagram()
        CURRENT_CONTEXT[] = ctx
        return ctx
    else
        ctx
    end
end

struct Diagram
    # labeled items
    object_store::Dict{String, Node}
    nodes::Vector{Node}
    connections::Vector{Connection}
end
function Diagram()
    return Diagram(Dict{String, Node}(), Node[], Connection[])
end
function label!(d::Diagram, obj, key::String)
    if haskey(d.object_store, key)
        error("object $key already exists!")
    else
        d.object_store[key] = obj
    end
    return obj
end
label!(obj, key::String) = label!(getcontext!(), obj, key)

function Base.push!(d::Diagram, obj::Node; label=nothing)
    push!(d.nodes, obj)
    if label !== nothing
        label!(d, obj, label)
    end
    return d
end
function Base.push!(d::Diagram, obj::Connection)
    return push!(d.connections, obj)
end
function Base.push!(d::Diagram, obj::Tuple; kwargs...)
    return push!(d.connections, Connection(tonode.(Ref(d), obj)...; kwargs...))
end
function tonode(d::Diagram, s::String)
    @assert haskey(d.object_store, s) "object $s not exist!"
    return d.object_store[s]
end
tonode(::Diagram, s) = tonode(s)
tonode(x::String) = tonode(getcontext!(), x)

function diagram(f)
    d = Diagram()
    setcontext!(d)
    f()
    emptycontext!()
    return d
end

strokenodes(d::Diagram) = stroke.(d.nodes)
fillnodes(d::Diagram) = fill.(d.nodes)
strokeconnections(d::Diagram) = stroke.(d.connections)
function showlabels(d::Diagram)
    for (k, v) in d.object_store
        text(k, v.loc)
    end
end

for F in [:nline, :ndot, :ncircle, :nbox, :npolygon]
    @eval function $(Symbol(F, :!))(args...; kwargs...)
        obj = $F(args..., kwargs...)
        push!(getcontext!(), obj)
        return obj
    end
end
function connect!(args...; kwargs...)
    d = getcontext!()
    obj = Connection(tonode.(Ref(d), args)...; kwargs...)
    push!(d, obj)
    return obj
end