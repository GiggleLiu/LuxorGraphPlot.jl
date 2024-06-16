const REQUIRED_PARAMS = Dict(
    :circle => [:radius],
    :ellipse => [:width, :height],
    :box => [:width, :height],
    :polygon => [:relpath],
    :line => [:relpath],
    :dot => Symbol[]
)

const OPTIONAL_PARAMS = Dict(
    :circle => Dict{Symbol, Any}(),
    :ellipse => Dict{Symbol, Any}(),
    :box => Dict{Symbol, Any}(:smooth=>0),
    :polygon => Dict{Symbol, Any}(:smooth=>0, :close=>true),
    :line => Dict{Symbol, Any}(:arrowstyle=>"-"),
    :dot => Dict{Symbol, Any}()
)

dict2md(d::Dict) = join(["- `$(k)`: $(v)" for (k, v) in d], "\n")

"""
    Node(shape::Symbol, loc; props...)

Create a node with a shape and a location. The shape can be `:circle`, `:ellipse`, `:box`, `:polygon`, `:line` or `:dot`.

### Required Keyword Arguments
$(dict2md(REQUIRED_PARAMS))

### Optional Keyword Arguments
$(dict2md(OPTIONAL_PARAMS))
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

"""
    offset(n::Node, p::Union{Tuple,Point})
    offset(n::Node, direction, distance)
    offset(n::Node, direction::Node, distance)

Offset a node towards a direction or another node. The direction can be specified by a tuple, a `Point` or a `Node`.
"""
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
    "topright" => 7π/4
    "top" => -π/2
    "topleft" => 5π/4
    "left" => 1.0π
    "bottomleft" => 3π/4
    "bottom" => -3π/2
    "bottomright" => π/4
end
Luxor.distance(a::Node, b::Node) = distance(a.loc, b.loc)
topoint(x::Point) = x
topoint(x::Node) = x.loc
topoint(x::Tuple) = Point(x...)
"""
    dotnode(x, y)
    dotnode(p::Point)

Create a node with a shape `:dot` and a location.
"""
dotnode(x::Real, y::Real) = dotnode(Point(x, y))
dotnode(p) = Node(:dot, topoint(p))

"""
    circle(loc, radius; props...) = Node(:circle, loc; radius, props...)
"""
circlenode(loc, radius) = Node(:circle, loc; radius)
"""
    ellipse(loc, width, height; props...) = Node(:ellipse, loc; width, height, props...)
"""
ellipsenode(loc, width, height) = Node(:ellipse, loc; width, height)
"""
    box(loc, width, height; props...) = Node(:box, loc; width, height, props...)
"""
boxnode(loc, width, height; kwargs...) = Node(:box, loc; width, height, kwargs...)
"""
    polygon([loc, ]relpath::AbstractVector; props...) = Node(:polygon, loc; relpath, props...)
"""
polygonnode(loc, relpath::AbstractVector; kwargs...) = Node(:polygon, loc; relpath=topoint.(relpath), kwargs...)
function polygonnode(path::AbstractVector; kwargs...)
    mid, relpath = centerize([topoint(x) for x in path])
    Node(:polygon, mid; relpath, kwargs...)
end
"""
    line(args...; props...) = Node(:line, mid; relpath, props...)
"""
function linenode(args...)
    mid, relpath = centerize([topoint(x) for x in args])
    return Node(:line, mid; relpath)
end
function centerize(path)
    mid = sum(path) / length(path)
    return mid, path .- mid
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

"""
    Connection(start, stop; isarrow=false, mode=:exact, arrowprops=Dict{Symbol, Any}(), control_points=Point[], smoothprops=Dict{Symbol, Any}())

Create a connection between two nodes. The connection can be a line, a curve, a bezier curve, a smooth curve or a zig-zag line.

### Required Arguments
- `start::Node`: the start node
- `stop::Node`: the stop node

### Optional Keyword Arguments
- `isarrow=false`: whether to draw an arrow at the end of the connection
- `mode=:exact`: the mode to get the connection point, can be `:exact` or `:natural`
- `arrowprops=Dict{Symbol, Any}()`: the properties of the arrow
- `control_points=Point[]`: the control points for the connection
- `smoothprops=Dict{Symbol, Any}()`: the properties of the smooth curve
"""
struct Connection
    start::Node
    stop::Node
    mode::Symbol
    isarrow::Bool
    arrowprops::Dict{Symbol, Any}
    control_points::Vector{Point}
    smoothprops::Dict{Symbol, Any}
end
# TODO: polish arrow props, smooth corners
function Connection(start::Node, stop::Node; isarrow=false, mode=:exact, arrowprops=Dict{Symbol, Any}(), control_points=Point[], smoothprops=Dict{Symbol, Any}())
    return Connection(start, stop, mode, isarrow, arrowprops, Point[topoint(x) for x in control_points], smoothprops)
end
offset(c::Connection, p::Union{Tuple,Point}) = Connection(offset(c.start, p), offset(c.stop, p); c.mode, c.isarrow, c.arrowprops, c.control_points, c.smoothprops)
connect(a, b; kwargs...) = Connection(tonode(a), tonode(b); kwargs...)
tonode(a::Point) = dotnode(a)
tonode(a::Node) = a

"""
    circle(n::Node, action=:stroke)

Stroke a node with line.
"""
stroke(n::Union{Node, Connection}) = (apply_action(n, :stroke); n)
Base.fill(n::Union{Node, Connection}) = (apply_action(n, :fill); n)
function Luxor.text(t::AbstractString, n::Node; angle=0.0)
    text(t, n.loc; valign=:middle, halign=:center, angle)
end
function apply_action(n::Node, action)
    @match n.shape begin
        :circle => circle(n.loc, n.radius, action)
        :ellipse => ellipse(n.loc, n.width, n.height, action)
        :box => box(n.loc, n.width, n.height, n.smooth, action)
        :polygon => if n.props[:smooth] == 0
                poly(Ref(n.loc) .+ n.relpath, action; close=n.props[:close])
            else
                #move(n.loc + n.relpath[1])
                polysmooth(Ref(n.loc) .+ n.relpath, n.props[:smooth], action)
            end
        :line => line((Ref(n.loc) .+ n.relpath)..., action)
        :dot => nothing #circle(n.loc, 1, action)  # dot has unit radius
    end
end
function apply_action(n::Connection, action)
    a_ = get_connect_point(n.start, isempty(n.control_points) ? n.stop.loc : n.control_points[1]; mode=n.mode)
    b_ = get_connect_point(n.stop, isempty(n.control_points) ? n.start.loc : n.control_points[end]; mode=n.mode)
    if n.isarrow
        # arrow, line or curve
        arrow(a_, n.control_points..., b_; n.arrowprops...)
        do_action(action)
    else
        method = get(n.smoothprops, :method, "curve")
        @assert method ∈ ["nosmooth", "smooth", "bezier", "curve"]
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
                #move(a_)
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
    SF = String(F)
    @eval begin
    """
        $($SF)(n::Node)

    Get the $($SF) boundary point of a node. Returns a `Node` of shape `:dot`.
    """
    $F(n::Node) = boundary(n, $(String(F)))
    end
end

"""
    midpoint(a::Node, b::Node)

Get the midpoint of two nodes. Returns a `Node` of shape `:dot`.
"""
Luxor.midpoint(a::Node, b::Node) = dotnode(midpoint(a.loc, b.loc))

"""
    center(n::Node)

Get the center point of a node. Returns a `Node` of shape `:dot`.
"""
center(n::Node) = dotnode(n.loc)

"""
    boundary(n::Node, s::String)
    boundary(n::Node, angle::Real)

Get the boundary point of a node in a direction. The direction can be specified by a string or an angle.
Possible strings are: "left", "right", "top", "bottom", "topright", "topleft", "bottomleft", "bottomright".
"""
boundary(n::Node, s::String) = boundary(n, render_direction(s))

function boundary(n::Node, angle::Real)
    @match n.shape begin
        :circle => dotnode(n.loc.x + n.radius * cos(angle), n.loc.y + n.radius * sin(angle))
        :ellipse => dotnode(n.loc.x + n.width/2 * cos(angle), n.loc.y + n.height/2 * sin(angle))
        # TODO: polish for rounded corners
        :box || :polygon => begin
            path = getpath(n)
            radi = max(xmax(path) - xmin(path), ymax(path) - ymin(path))
            x = n.loc.x + 2*radi * cos(angle)
            y = n.loc.y + 2*radi * sin(angle)
            # NOTE: polygon must intersect with its center!
            intersect = intersectlinepoly(n.loc, Point(x, y), path)
            if isempty(intersect)
                @warn "boundary point not found, return center instead: path=$path, angle=$angle"
                return center(n)
            else
                return dotnode(intersect[1])
            end
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

bottomalign(n::Node, target::Node) = bottomalign(n, target.loc[1])
bottomalign(n::Node, x::Real) = dotnode(x, bottom(n).loc[2])
topalign(n::Node, target::Node) = topalign(n, target.loc[1])
topalign(n::Node, x::Real) = dotnode(x, top(n).loc[2])
leftalign(n::Node, target::Node) = topalign(n, target.loc[2])
leftalign(n::Node, y::Real) = dotnode(left(n).loc[1], y)
rightalign(n::Node, target::Node) = rightalign(n, target.loc[2])
rightalign(n::Node, y::Real) = dotnode(right(n).loc[1], y)

# get the path of a node
function getpath(n::Node)
    @match n.shape begin
        :circle => [Point(n.loc.x + n.radius * cos(θ), n.loc.y + n.radius * sin(θ)) for θ in 0:π/8:2π]
        :ellipse => [Point(n.loc.x + n.width/2 * cos(θ), n.loc.y + n.height/2 * sin(θ)) for θ in 0:π/8:2π]
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

function Luxor.line(a::Node, b::Node, action=:stroke; mode=:exact, kwargs...)
    a_ = get_connect_point(a, b.loc; mode)
    b_ = get_connect_point(b, a.loc; mode)
    line(a_, b_, action; kwargs...)
end
function Luxor.arrow(a::Node, b::Node, action=:stroke; mode=:exact, kwargs...)
    a_ = get_connect_point(a, b.loc; mode)
    b_ = get_connect_point(b, a.loc; mode)
    arrow(a_, b_; kwargs...)
    do_action(action)
end

function get_connect_point(a::Node, bloc::Point; mode)
    @match a.shape begin
        :circle => intersectionlinecircle(a.loc, bloc, a.loc, a.radius)[2]
        :ellipse => boundary(a, angleof(bloc-a.loc)).loc
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
