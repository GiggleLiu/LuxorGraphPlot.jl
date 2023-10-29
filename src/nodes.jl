const REQUIRED_PARAMS = Dict(
    :circle => [:radius],
    :box => [:width, :height],
    :polygon => [:relpath],
    :line => [:relpath],
    :dot => Symbol[]
)

const OPTIONAL_PARAMS = Dict(
    :circle => Dict{Symbol, Any}(),
    :box => Dict{Symbol, Any}(),
    :polygon => Dict{Symbol, Any}(),
    :line => Dict{Symbol, Any}(:arrowstyle=>"-"),
    :dot => Dict{Symbol, Any}()
)

"""
### Required Keyword Arguments
$REQUIRED_PARAMS

### Optional Keyword Arguments
$OPTIONAL_PARAMS
"""
struct Node
    shape::Symbol
    loc::Point
    props::Dict{Symbol, Any}
end
function Node(shape::Symbol, loc; props...)
    d = Dict{Symbol, Any}(props)
    check_props!(shape, d)
    return Node(shape, topoint(loc), d)
end
topoint(x::Point) = x
topoint(x::Tuple) = Point(x...)
ndot(x::Real, y::Real) = ndot(Point(x, y))
ndot(p) = Node(:dot, topoint(p))
ncircle(loc, radius) = Node(:circle, loc; radius)
nbox(loc, width, height) = Node(:box, loc; width, height)
npolygon(loc, relpath) = Node(:polygon, loc; relpath)
function nline(args...)
    relpath = [topoint(x) for x in args]
    return Node(:line, Point(0, 0); relpath)
end

function check_props!(shape, props)
    assert_has_props!(shape, props, REQUIRED_PARAMS[shape], OPTIONAL_PARAMS[shape])
end
function assert_has_props!(shape, props, syms, optional)
    # required arguments
    for sym in syms
        if !haskey(props, sym)
            error("missing property (keyword argument) for shape $shape: $sym ")
        end
    end
    # optional arguments
    for (k, v) in optional
        if !haskey(props, k)
            props[k] = v
        end
    end
    # not recognized arguments
    for (k, v) in props
        if !(k ∈ syms || haskey(optional, k))
            @warn "property not recognized by shape $shape: $k"
        end
    end
    return true
end
function Base.getproperty(n::Node, p::Symbol)
    return hasfield(Node, p) ? getfield(n, p) : n.props[p]
end

# default close = true
# draw at loc
stroke(n::Node) = apply_action(n, :stroke)
Base.fill(n::Node) = apply_action(n, :fill)
function apply_action(n::Node, action)
    @match n.shape begin
        :circle => circle(n.loc, n.radius, action)
        :box => box(n.loc, n.width, n.height, action)
        :polygon => poly(Ref(n.loc) .+ n.relpath, action; close=true)
        :line => line((Ref(n.loc) .+ n.relpath)..., action)
        :dot => circle(n.loc, 1, action)  # dot has unit radius
    end
end
xmin(path) = minimum(x->x.x, path)
xmax(path) = maximum(x->x.x, path)
ymin(path) = minimum(x->x.y, path)
ymax(path) = maximum(x->x.y, path)
left(n::Node) = boundary(n, π)
right(n::Node) = boundary(n, 0)
top(n::Node) = boundary(n, π/2)
bottom(n::Node) = boundary(n, -π/2)

function boundary(n::Node, angle::Real)
    @match n.shape begin
        :circle => ndot(n.loc.x + n.radius * cos(angle), n.loc.y + n.radius * sin(angle))
        :box || :polygon => begin
            path = getpath(n)
            radi = max(xmax(path) - xmin(path), ymax(path) - ymin(path))
            x = n.loc.x + 2*radi * cos(angle)
            y = n.loc.y + 2*radi * sin(angle)
            # NOTE: polygon must intersect with its center!
            ndot(intersectlinepoly(n.loc, Point(x, y), path)[1])
        end
        :dot => n
        :line => begin
            path = getpath(n)
            # project to angle direction, find the one with the largest norm
            unitv = Point(cos(angle), sin(angle))
            projects = dotproduct.(Ref(unitv), path)
            mval, mloc = findmax(projects)
            return ndot(path[mloc])
        end
        _ => error("can not get boundary point for shape: $(n.shape)")
    end
end

# get the path of a node
function getpath(n::Node)
    @match n.shape begin
        :circle => error("getting path of a circle is not allowed!")
        :box => begin
            x, y = n.loc
            w, h = n.width, n.height
            [Point(x-w/2, y-h/2), Point(x-w/2, y+h/2), Point(x+w/2, y+h/2), Point(x+w/2, y-h/2)]
        end
        :polygon => Ref(n.loc) .+ n.relpath
        :dot => [n.loc]
        :line => Ref(n.loc) .+ n.relpath
    end
end

function edge(f, a::Node, b::Node, action=:path)
    a_ = get_connect_point(a, b)
    b_ = get_connect_point(b, a)
    edge(f, a_, b_, action)
end
function edge(::typeof(line), a::Point, b::Point, action=:path)
    line(a, b, action)
end
function edge(::typeof(arrow), a::Point, b::Point, action=:path; kwargs...)
    arrow(a, b; kwargs...)
    do_action(action)
end

function get_connect_point(a::Node, b::Node; mode=:exact)
    @match a.shape begin
        :circle => intersectionlinecircle(a.loc, b.loc, a.loc, a.radius)[2]
        :dot => a.loc
        :line => a.loc + a.relpath[end]  # the last node
        :box || :polygon => @match mode begin
            :natural => closest_natural_point(getpath(a), b.loc)
            :exact => boundary(a, angleof(b.loc-a.loc)).loc
            _ => error("Connection point mode `:$(mode)` is not defined!")
        end
    end
end

angleof(p::Point) = atan(p.y, p.x)

function closest_natural_point(path::AbstractVector, p::Point)
    minval, idx = findmin(x->distance(p, x), path)
    mid = i->midpoint(path[i], path[mod1(i+1, length(path))])
    minval2, idx2 = findmin(i->distance(p, mid(i)), 1:length(path))
    return minval > minval2 ? mid(idx2) : path[idx]
end

# labeled items
const OBJECT_STORE = Dict{String, Node}()
function label!(obj, key::String)
    if haskey(OBJECT_STORE, key)
        error("object $key already exists!")
    else
        OBJECT_STORE[key] = obj
    end
    return obj
end

function getobj(a::String)
    @assert haskey(OBJECT_STORE, a) "object $a not exist!"
    return OBJECT_STORE[a]
end

getobj(a::Node) = a