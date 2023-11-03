const REQUIRED_PARAMS = Dict(
    :circle => [:radius],
    :box => [:width, :height],
    :polygon => [:relpath],
    :line => [:relpath],
    :dot => Symbol[]
)

const OPTIONAL_PARAMS = Dict(
    :circle => Dict{Symbol, Any}(),
    :box => Dict{Symbol, Any}(:smooth=>0),
    :polygon => Dict{Symbol, Any}(:smooth=>0),
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
offset(n::Node, p::Union{Tuple,Point}) = Node(n.shape, n.loc + topoint(p), n.props)
offset(n::Node, direction, distance) = offset(n, render_offset(direction, distance))
function offset(n::Node, direction::Node, distance)
    p = direction.loc - n.loc
    return offset(n, normalize(p) * distance)
end
function render_offset(direction, distance)
    angle = render_direction(direction)
    return Point(distance * cos(angle), -distance * sin(angle))
end
render_direction(s) = @match s begin
    ::Real => Float64(s)
    "right" => 0.0
    "topright" => π/4
    "top" => π/2
    "topleft" => 3π/4
    "left" => 1.0π
    "bottomleft" => 5π/4
    "bottom" => 3π/2
    "bottomright" => 7π/4
end
Luxor.distance(a::Node, b::Node) = distance(a.loc, b.loc)
topoint(x::Point) = x
topoint(x::Node) = x.loc
topoint(x::Tuple) = Point(x...)
dotnode(x::Real, y::Real) = dotnode(Point(x, y))
dotnode(p) = Node(:dot, topoint(p))
circlenode(loc, radius) = Node(:circle, loc; radius)
boxnode(loc, width, height; smooth=0.0) = Node(:box, loc; width, height, smooth)
polygonnode(loc, relpath::AbstractVector) = Node(:polygon, loc; relpath=topoint.(relpath))
polygonnode(relpath::AbstractVector) = polygonnode(Point(0, 0), relpath)
function linenode(args...)
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

struct Connection
    start::Node
    stop::Node
    isarrow::Bool
    arrowprops::Dict{Symbol, Any}
    control_points::Vector{Point}
    smoothprops::Dict{Symbol, Any}
end
# TODO: polish arrow props, smooth corners
function Connection(start::Node, stop::Node; isarrow=false, arrowprops=Dict{Symbol, Any}(), control_points=Point[], smoothprops=Dict{Symbol, Any}())
    return Connection(start, stop, isarrow, arrowprops, Point[topoint(x) for x in control_points], smoothprops)
end
connect(a, b; kwargs...) = Connection(tonode(a), tonode(b); kwargs...)
tonode(a::Point) = dotnode(a)
tonode(a::Node) = a

# default close = true
# draw at loc
stroke(n::Union{Node, Connection}) = apply_action(n, :stroke)
Base.fill(n::Union{Node, Connection}) = apply_action(n, :fill)
function Luxor.text(t::AbstractString, n::Node; angle=0.0)
    text(t, n.loc; valign=:middle, halign=:center, angle)
end
function apply_action(n::Node, action)
    @match n.shape begin
        :circle => circle(n.loc, n.radius, action)
        :box => box(n.loc, n.width, n.height, n.smooth, action)
        :polygon => if n.props[:smooth] == 0
                poly(Ref(n.loc) .+ n.relpath, action; close=true)
            else
                polysmooth(Ref(n.loc) .+ n.relpath, n.props[:smooth], action)
            end
        :line => line((Ref(n.loc) .+ n.relpath)..., action)
        :dot => nothing #circle(n.loc, 1, action)  # dot has unit radius
    end
end
function apply_action(n::Connection, action)
    a_ = get_connect_point(n.start, isempty(n.control_points) ? n.stop.loc : n.control_points[1])
    b_ = get_connect_point(n.stop, isempty(n.control_points) ? n.start.loc : n.control_points[end])
    if n.isarrow
        # arrow, line or curve
        arrow(a_, n.control_points..., b_; n.arrowprops...)
        do_action(action)
    else
        method = get(n.smoothprops, :method, "curve")
        if method == "nosmooth" || isempty(n.control_points)
            if isempty(n.control_points)
                # line
                line(a_, b_, action)
            else
                # zig-zag line
                # TODO: support arrow
                poly([a_, n.control_points..., b_], action; close=false)
            end
        elseif method == "smooth"
                # TODO: support close=false
                move(a_)
                polysmooth([a_, n.control_points..., b_], get(n.smoothprops, :radius, 5), action; close=false)
        elseif method == "bezier"
            # bezier curve
            pts = [a_, n.control_points..., b_]
            bezpath = makebezierpath(pts)
            drawbezierpath(bezpath, action, close=false)
        else
            # curve
            move(a_)
            curve(n.control_points..., b_)
            do_action(action)
        end
    end
end

xmin(path) = minimum(x->x.x, path)
xmax(path) = maximum(x->x.x, path)
ymin(path) = minimum(x->x.y, path)
ymax(path) = maximum(x->x.y, path)
for F in [:left, :right, :top, :bottom, :topright, :topleft, :bottomleft, :bottomright]
    @eval $F(n::Node) = boundary(n, $(String(F)))
end
Luxor.midpoint(a::Node, b::Node) = dotnode(midpoint(a.loc, b.loc))
center(n::Node) = dotnode(n.loc)
boundary(n::Node, s::String) = boundary(n, render_direction(s))

function boundary(n::Node, angle::Real)
    @match n.shape begin
        :circle => dotnode(n.loc.x + n.radius * cos(angle), n.loc.y + n.radius * sin(angle))
        # TODO: polish for rounded corners
        :box || :polygon => begin
            path = getpath(n)
            radi = max(xmax(path) - xmin(path), ymax(path) - ymin(path))
            x = n.loc.x + 2*radi * cos(angle)
            y = n.loc.y + 2*radi * sin(angle)
            # NOTE: polygon must intersect with its center!
            dotnode(intersectlinepoly(n.loc, Point(x, y), path)[1])
        end
        :dot => n
        :line => begin
            path = getpath(n)
            # project to angle direction, find the one with the largest norm
            unitv = Point(cos(angle), sin(angle))
            projects = dotproduct.(Ref(unitv), path)
            mval, mloc = findmax(projects)
            return dotnode(path[mloc])
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
    a_ = get_connect_point(a, b.loc)
    b_ = get_connect_point(b, a.loc)
    edge(f, a_, b_, action)
end
function edge(::typeof(line), a::Point, b::Point, action=:path)
    line(a, b, action)
end
function edge(::typeof(arrow), a::Point, b::Point, action=:path; kwargs...)
    arrow(a, b; kwargs...)
    do_action(action)
end

function get_connect_point(a::Node, bloc::Point; mode=:exact)
    @match a.shape begin
        :circle => intersectionlinecircle(a.loc, bloc, a.loc, a.radius)[2]
        :dot => a.loc
        :line => a.loc + a.relpath[end]  # the last node
        :box || :polygon => @match mode begin
            :natural => closest_natural_point(getpath(a), bloc)
            :exact => boundary(a, angleof(bloc-a.loc)).loc
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
