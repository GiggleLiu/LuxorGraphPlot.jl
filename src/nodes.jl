@enum Shape Circle Box Polygon Segment Dot

struct Node
    shape::Shape
    loc::Point
    props::Dict{Symbol, Any}
end
function Node(shape::Shape, loc; props...)
    d = Dict{Symbol, Any}(props)
    check_props(shape, d)
    return Node(shape, Point(loc), d)
end
ndot(x::Real, y::Real) = Node(Dot, (x, y))
ndot(p::Point) = Node(shape, p)
ncircle(loc, radius) = Node(Circle, loc; radius)
nbox(loc, width, height) = Node(Box, loc; width, height)
npolygon(loc, abspath) = Node(Polygon, loc; abspath)
function nsegment(args...)
    abspath = [Point(x) for x in args]
    return Node(Segment, Point(0, 0); abspath)
end

function check_props(shape, props)
    @match shape begin
        Circle => assert_has_props(shape, props, [:radius])
        Box => assert_has_props(shape, props, [:width, :height])
        Polygon => assert_has_props(shape, props, [:abspath])
        Segment => assert_has_props(shape, props, [:abspath])
        Dot => assert_has_props(shape, props, Symbol[])
        _ => error("unknown shape: $shape")
    end
end
function assert_has_props(shape, props, syms)
    for sym in syms
        if !haskey(props, sym)
            error("missing property (keyword argument) for shape $shape: $sym ")
        end
    end
    for (k, v) in props
        if !(k ∈ syms)
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
        Polygon => poly(Ref(n.loc) .+ n.abspath, action; close=true)
        Segment => line((Ref(n.loc) .+ n.abspath)..., action)
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
function getpath(n::Node)
    @match n.shape begin
        Circle => error("getting path of a circle is not allowed!")
        Box => begin
            x, y = n.loc
            w, h = n.width, n.height
            [Point(x-w/2, y-h/2), Point(x-w/2, y+h/2), Point(x+w/2, y+h/2), Point(x+w/2, y-h/2)]
        end
        Polygon => Ref(n.loc) .+ n.abspath
        Dot => [n.loc]
        Segment => Ref(n.loc) .+ n.abspath
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
    if a.shape == Circle
        nints, ip1, ip2 =  intersectionlinecircle(a.loc, b.loc, a.loc, width(a)/2)
        return ip1
    else
        if mode == :natural
            return closest_natural_point(a, b.loc)
        elseif mode == :exact
            return boundary(a, angleof(b.loc-a.loc))
        else
            error("Connection point mode `:$(mode)` is not defined!")
        end
    end
end

angleof(p::Point) = atan(p.y, p.x)

function closest_natural_point(n::Node, p::Point)
    minval, idx = findmin(x->distance(p, x), n.path)
    mid = i->midpoint(n.path[i], n.path[mod1(i+1, length(n.path))])
    minval2, idx2 = findmin(i->distance(p, mid(i)), 1:length(n.path))
    return minval > minval2 ? mid(idx2) : n.path[idx]
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