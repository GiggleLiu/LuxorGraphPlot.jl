@enum Shape Circle Box Poly

struct Node
    shape::Shape
    loc::Point
    path::Vector{Point}
    width::Float64
    height::Float64
end

function node(::typeof(circle), loc::Point, r, action=:none)
    return Node(Circle, loc, [Point(-r, -r), Point(r, r)], 2r, 2r)
end
function node(::typeof(box), loc::Point, width, height, action=:none)
    x, y = loc
    return Node(Box, loc, [Point(x-width/2, y-height/2), Point(x-width/2, y+height/2), Point(x+width/2, y+height/2), Point(x+width/2, y-height/2)], width, height)
end

# default close = true
# draw at loc
function node(::typeof(poly), loc::Point, path::Vector{Point}, action=:none)
    return Node(Poly, loc, [loc + p for p in path], xmax(path)-xmin(path), ymax(path)-ymin(path))
end

stroke(n::Node) = apply_action(n, :stroke)
Base.fill(n::Node) = apply_action(n, :fill)
function apply_action(n::Node, action)
    if n.shape == Circle
        circle(n.loc, width(n)/2, action)
    elseif n.shape == Box
        box(n.loc, width(n), height(n), action)
    else
        # Poly
        poly(n.path, action; close=true)
    end
end
xmin(path) = minimum(x->x.x, path)
xmax(path) = maximum(x->x.x, path)
ymin(path) = minimum(x->x.y, path)
ymax(path) = maximum(x->x.y, path)
left(n::Node) = Point(xmin(n.path), 0.0)
right(n::Node) = Point(xmax(n.path), 0.0)
top(n::Node) = Point(ymin(n.path), 0.0)
bottom(n::Node) = Point(ymax(n.path), 0.0)
height(n::Node) = n.height
width(n::Node) = n.width

function boundary(n::Node, angle::Real)
    radi = max(height(n), width(n))
    x = n.loc.x + 2*radi * cos(angle)
    y = n.loc.y + 2*radi * sin(angle)
    # NOTE: polygon must intersect with its center!
    intersectlinepoly(n.loc, Point(x, y), n.path)[1]
end

function edge(::typeof(line), a::Node, b::Node, action=:path)
    a_ = get_connect_point(a, b)
    b_ = get_connect_point(b, a)
    line(a_, b_, action)
end
function edge(::typeof(line), a::Point, b::Point, action=:path)
    line(a, b, action)
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
