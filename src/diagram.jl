struct Diagram
    # labeled items
    node_store::Dict{String, Node}
    connection_store::Dict{String, Connection}
    nodes::Vector{Node}
    connections::Vector{Connection}
end
function Diagram()
    return Diagram(Dict{String, Node}(), Dict{String, Node}(), Node[], Connection[])
end
label!(d::Diagram, obj::Node, key::String) = _label!(d.node_store, obj, key)
label!(d::Diagram, obj::Connection, key::String) = _label!(d.connection_store, obj, key)
function _label!(store, obj::Node, key::String)
    if haskey(store, key)
        error("object $key already exists!")
    else
        store[key] = obj
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
    @assert haskey(d.node_store, s) "object $s not exist!"
    return d.node_store[s]
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

for (F, ACT, STORE, LIST) in [
        (:strokenodes, :stroke, :node_store, :nodes),
        (:fillnodes, :fill, :node_store, :nodes),
        (:strokeconnections, :stroke, :connection_store, :connections),
    ]
    @eval function $F(filter, d::Diagram)
        for (k, v) in d.$STORE
            if filter(k)
                $ACT(v)
            end
        end
        if filter("")
            for n in setdiff(d.$LIST, values(d.$STORE))
                $ACT(n)
            end
        end
    end
    @eval $F(d::Diagram) = $F(x->true, d)
end
function showlabels(filter, d::Diagram)
    for (k, v) in d.node_store
        if filter(k)
            text(k, v.loc, valign=:middle, halign=:center)
        end
    end
end
showlabels(d::Diagram) = showlabels(x->true, d)

for F in [:nline, :ndot, :ncircle, :nbox, :npolygon]
    @eval function $(Symbol(F, :!))(args...; kwargs...)
        obj = $F(args...; kwargs...)
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

