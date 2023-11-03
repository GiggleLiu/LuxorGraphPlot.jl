struct Diagram
    # labeled items
    node_store::Dict{String, Vector{Node}}
    connection_store::Dict{String, Vector{Connection}}
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
        push!(store[key], obj)
    else
        store[key] = [obj]
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
    @assert haskey(d.node_store, s) "can not find object with label: $s !"
    nodes = d.node_store[s]
    @assert length(nodes) == 1 "multiple objects with label (ambiguity): $s !"
    return d.node_store[s][]
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

for (F, ACT, FILTER) in [
        (:strokenodes, :stroke, :filternodes),
        (:fillnodes, :fill, :filternodes),
        (:strokeconnections, :stroke, :filterconnections),
    ]
    @eval function $F(filter, d::Diagram)
        for x in $FILTER(filter, d)
            $ACT(x)
        end
    end
    @eval $F(d::Diagram) = $F(x->true, d)
end
function filternodes(filter, d::Diagram)
    filterstorage(filter, d.nodes, d.node_store)
end
function filterconnections(filter, d::Diagram)
    filterstorage(filter, d.connections, d.connection_store)
end
function filterstorage(filter, totalset::Vector{T}, labelset::Dict{String, Vector{T}}) where T
    res = T[]
    for (k, v) in labelset
        filter(k) && append!(res, v)
    end
    filter("") && append!(res, setdiff(totalset, vcat(values(labelset)...)))
    return res
end
function showlabels(filter, d::Diagram)
    for (k, v) in d.node_store
        if filter(k)
            for vi in v
                text(k, vi.loc, valign=:middle, halign=:center)
            end
        end
    end
end
showlabels(d::Diagram) = showlabels(x->true, d)

for F in [:line, :dot, :circle, :box, :polygon]
    @eval function $(Symbol(F, :!))(args...; kwargs...)
        obj = $(Symbol(F, :node))(args...; kwargs...)
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

function figdiagram(f, Dx, Dy; format=:svg, filename=nothing,
        background="white",
        strokeconnections=true,
        strokenodes=true,
        fillnodes=false,
        showlabels=false
    )
    if filename === nothing
        if format == :pdf
            _format = tempname()*".pdf"
        else
            _format = format
        end
    else
        _format = filename
    end
    Luxor.Drawing(round(Int,Dx), round(Int,Dy), _format)
    Luxor.origin(0, 0)
    Luxor.background(background)
    d = diagram() do
        f()
    end
    showlabels && LuxorGraphPlot.showlabels(d)
    strokeconnections && LuxorGraphPlot.strokeconnections(d)
    strokenodes && LuxorGraphPlot.strokenodes(d)
    fillnodes && LuxorGraphPlot.fillnodes(d)
    Luxor.finish()
    Luxor.preview()
end