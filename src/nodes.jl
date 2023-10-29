@enum Shape Circle Box Polygon Segment Dot
const REQUIRED_PARAMS = Dict(
    Circle => [:radius],
    Box => [:width, :height],
    Polygon => [:relpath],
    Segment => [:relpath],
    Dot => Symbol[]
)

const OPTIONAL_PARAMS = Dict(
    Circle => Dict{Symbol, Any}(),
    Box => Dict{Symbol, Any}(),
    Polygon => Dict{Symbol, Any}(),
    Segment => Dict{Symbol, Any}(:arrowstyle=>"-"),
    Dot => Dict{Symbol, Any}()
)

"""
### Required Keyword Arguments
$REQUIRED_PARAMS

### Optional Keyword Arguments
$OPTIONAL_PARAMS
"""
struct Node
    shape::Shape
    loc::Point
    props::Dict{Symbol, Any}
end
function Node(shape::Shape, loc; props...)
    d = Dict{Symbol, Any}(props)
    check_props!(shape, d)
    return Node(shape, Point(loc), d)
end
ndot(x::Real, y::Real) = Node(Dot, (x, y))
ndot(p::Point) = Node(shape, p)
ncircle(loc, radius) = Node(Circle, loc; radius)
nbox(loc, width, height) = Node(Box, loc; width, height)
npolygon(loc, relpath) = Node(Polygon, loc; relpath)
function nsegment(args...)
    relpath = [Point(x) for x in args]
    return Node(Segment, Point(0, 0); relpath)
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
    return hasfield(n, p) ? getfield(n, p) : n.props[p]
end

# default close = true
# draw at loc
stroke(n::Node) = apply_action(n, :stroke)
Base.fill(n::Node) = apply_action(n, :fill)
function apply_action(n::Node, action)
    @match n.shape begin
        Circle => circle(n.loc, n.radius, action)
        Box => box(n.loc, n.width, n.height, action)
        Polygon => poly(Ref(n.loc) .+ n.relpath, action; close=true)
        Segment => line((Ref(n.loc) .+ n.relpath)..., action)
        Dot => circle(n.loc, 1, action)  # dot has unit radius
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
        Circle => ndot(n.loc.x + n.radius * cos(angle), n.loc.y + n.radius * sin(angle))
        Box || Polygon => begin
            path = getpath(n)
            radi = max(xmax(path) - xmin(path), ymax(path) - ymin(path))
            x = n.loc.x + 2*radi * cos(angle)
            y = n.loc.y + 2*radi * sin(angle)
            # NOTE: polygon must intersect with its center!
            intersectlinepoly(n.loc, Point(x, y), path)[1]
        end
        Dot => n
        _ => error("can not get boundary point for shape: $(n.shape)")
    end
end

# get the path of a node
function getpath(n::Node)
    @match n.shape begin
        Circle => error("getting path of a circle is not allowed!")
        Box => begin
            x, y = n.loc
            w, h = n.width, n.height
            [Point(x-w/2, y-h/2), Point(x-w/2, y+h/2), Point(x+w/2, y+h/2), Point(x+w/2, y-h/2)]
        end
        Polygon => Ref(n.loc) .+ n.relpath
        Dot => [n.loc]
        Segment => Ref(n.loc) .+ n.relpath
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
        Circle => ndot(intersectionlinecircle(a.loc, b.loc, a.loc, a.radius)[2])
        Dot => a
        Segment => ndot(a.loc + a.relpath[end])  # the last node
        Box || Polygon => @match mode begin
            :natural => ndot(closest_natural_point(getpath(a), b.loc))
            :exact => boundary(a, angleof(b.loc-a.loc))
            _ => error("Connection point mode `:$(mode)` is not defined!")
        end
    end
end

angleof(p::Point) = atan(p.y, p.x)

function closest_natural_point(path, p::Point)
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