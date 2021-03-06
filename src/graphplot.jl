const DEFAULT_BACKGROUND_COLOR = Ref("white")
const DEFAULT_UNIT = Ref(50)
const DEFAULT_FONTSIZE = Ref(12.0)
const DEFAULT_VERTEX_SIZE = Ref(0.15)
const DEFAULT_FORMAT = Ref(:svg)
const DEFAULT_VERTEX_TEXT_COLOR = Ref("black")
const DEFAULT_VERTEX_STROKE_COLOR = Ref("black")
const DEFAULT_VERTEX_FILL_COLOR = Ref("transparent")
const DEFAULT_EDGE_COLOR = Ref("black")

const CONFIGHELP = """
Extra keyword arguments
-------------------------------
* general
    * `xpad::Float64 = 1.0`, the padding space in x direction
    * `ypad::Float64 = 1.0`, the padding space in y direction
    * `xpad_right::Float64 = 1.0`, the padding space in x direction (right side)
    * `ypad_bottom::Float64 = 1.0`, the padding space in y direction (bottom side)
    * `background_color = DEFAULT_BACKGROUND_COLOR[]`, the background color
    * `unit::Float64 = DEFAULT_UNIT[]`, the unit distance as the number of pixels
    * `fontsize::Float64 = DEFAULT_FONTSIZE[]`, the font size
    * `fontface::String = ""`, the font face, leave empty to follow system
* vertex
    * `vertex_text_color = DEFAULT_VERTEX_TEXT_COLOR[]`, the default text color
    * `vertex_stroke_color = DEFAULT_VERTEX_STROKE_COLOR[]`, the default stroke color for vertices
    * `vertex_fill_color = DEFAULT_VERTEX_FILL_COLOR[]`, the default default fill color for vertices
    * `vertex_size::Float64 = DEFAULT_VERTEX_SIZE[]`, the default vertex size
    * `vertex_shape::String = "circle"`, the default vertex shape, which can be "circle" or "box"
    * `vertex_line_width::Float64 = 1`, the default vertex stroke line width
    * `vertex_line_style::String = "solid"`, the line style of vertex stroke, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]
* edge
    * `edge_color = DEFAULT_EDGE_COLOR[]`, the default edge color
    * `edge_line_width::Float64 = 1`, the default line width
    * `edge_style::String = "solid"`, the line style of edges, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]
"""
Base.@kwdef struct GraphDisplayConfig
    # line, vertex and text
    xpad::Float64 = 1.0
    ypad::Float64 = 1.0
    xpad_right::Float64 = 1.0
    ypad_bottom::Float64 = 1.0
    background_color = DEFAULT_BACKGROUND_COLOR[]
    unit::Int = DEFAULT_UNIT[]   # how many pixels as unit?
    fontsize::Float64 = DEFAULT_FONTSIZE[]
    fontface::String = ""

    # vertex
    vertex_text_color = DEFAULT_VERTEX_TEXT_COLOR[]
    vertex_stroke_color = DEFAULT_VERTEX_STROKE_COLOR[]
    vertex_fill_color = DEFAULT_VERTEX_FILL_COLOR[]
    vertex_size::Float64 = DEFAULT_VERTEX_SIZE[]
    vertex_shape::String = "circle"
    vertex_line_width::Float64 = 1  # in pt
    vertex_line_style::String = "solid"
    # edge
    edge_color = DEFAULT_EDGE_COLOR[]
    edge_line_width::Float64 = 1  # in pt
    edge_line_style::String = "solid"
end

function get_bounding_box(locs)
    @assert length(locs) > 0
    xmin = minimum(x->x[1], locs)
    ymin = minimum(x->x[2], locs)
    xmax = maximum(x->x[1], locs)
    ymax = maximum(x->x[2], locs)
    return (; xmin, ymin, xmax, ymax)
end

"""
    show_graph([f, ]graph::SimpleGraph;
        locs=nothing,
        spring::Bool=locs === nothing,
        optimal_distance=1.0,
        spring_mask=trues(nv(graph)),

        vertex_colors=nothing,
        vertex_sizes=nothing,
        vertex_stroke_colors=nothing,
        vertex_text_colors=nothing,
        edge_colors=nothing,
        texts = nothing,
        format=DEFAULT_FORMAT[],
        filename=nothing,
        kwargs...)

Show a graph in VSCode, Pluto or Jupyter notebook, or save it to a file.

Positional arguments
-----------------------------
* `f` is a function that returns extra `Luxor` plotting statements.
* `graph` is a graph instance.

Keyword arguments
-----------------------------
* `locs` is a vector of tuples for specifying the vertex locations.
* `spring` is switch to use spring method to optimize the location.
* `optimal_distance` is a optimal distance parameter for `spring` optimizer.
* `spring_mask` specfies which location is optimizable for `spring` optimizer.

* `vertex_colors` is a vector of color strings for specifying vertex fill colors.
* `vertex_sizes` is a vector of real numbers for specifying vertex sizes.
* `vertex_shapes` is a vector of strings for specifying vertex shapes, the string should be "circle" or "box".
* `vertex_stroke_colors` is a vector of color strings for specifying vertex stroke colors.
* `vertex_text_colors` is a vector of color strings for specifying vertex text colors.
* `edge_colors` is a vector of color strings for specifying edge colors.
* `texts` is a vector of strings for labeling vertices.
* `format` is the output format, which can be `:svg`, `:png` or `:pdf`.
* `filename` is a string as the output filename.

$CONFIGHELP

Example
------------------------------
```jldoctest
julia> using Graphs

julia> show_graph(smallgraph(:petersen); format=:png, vertex_colors=rand(["blue", "red"], 10));
```
"""
function show_graph(f, locs, edges;
        vertex_colors=nothing,
        vertex_sizes=nothing,
        vertex_shapes=nothing,
        vertex_stroke_colors=nothing,
        vertex_text_colors=nothing,
        edge_colors=nothing,
        texts = nothing,
        format=DEFAULT_FORMAT[], filename=nothing,
        kwargs...)
    length(locs) == 0 && return _draw(f, 100, 100; format, filename)

    (xmin, ymin), (Dx, Dy), config = get_config(locs, edges; kwargs...)
    transform(loc) = loc[1]-xmin+config.xpad, loc[2]-ymin+config.ypad
    _draw(Dx*config.unit, Dy*config.unit; format, filename) do
        background(config.background_color)
        _show_graph(transform.(locs), edges,
        vertex_colors, vertex_stroke_colors, vertex_text_colors, vertex_sizes, vertex_shapes, edge_colors, texts, config)
        f()
    end
end

function get_config(locs, edges;
        xpad=1.0,
        ypad=1.0,
        xpad_right=xpad,
        ypad_bottom=ypad,
        kwargs...)
    xmin, ymin, xmax, ymax = get_bounding_box(locs)
    config = GraphDisplayConfig(; xpad, ypad, xpad_right, ypad_bottom, kwargs...)
    Dx, Dy = (xmax-xmin)+config.xpad+config.xpad_right, (ymax-ymin)+config.ypad+config.ypad_bottom
    # xmin/ymin is the minimum x/y coordinate
    # Dx/Dy is the x/y span
    # config is the plotting config
    return (xmin, ymin), (Dx, Dy), config
end

# NOTE: the final positions are in range [-5, 5]
function show_graph(f, graph::SimpleGraph;
        locs=nothing,
        spring::Bool=locs === nothing,
        optimal_distance=1.0,
        spring_mask=trues(nv(graph)),
        kwargs...)
    locs = autolocs(graph, locs, spring, optimal_distance, spring_mask)
    show_graph(f, locs, [(e.src, e.dst) for e in edges(graph)]; kwargs...)
end
show_graph(graph::SimpleGraph; kwargs...) = show_graph(()->nothing, graph; kwargs...)
show_graph(locs::AbstractVector, edges; kwargs...) = show_graph(()->nothing, locs, edges; kwargs...)

function autolocs(graph, locs, spring, optimal_distance, spring_mask)
    if spring
        locs_x = locs === nothing ? [2*rand()-1.0 for i=1:nv(graph)] : getindex.(locs, 1)
        locs_y = locs === nothing ? [2*rand()-1.0 for i=1:nv(graph)] : getindex.(locs, 2)
        spring_layout!(graph;
                    C=optimal_distance,
                    locs_x,
                    locs_y,
                    mask=spring_mask   # mask for which to relocate
                    )
        collect(zip(locs_x, locs_y))
    else
        locs
    end
end

function _draw(f, Dx, Dy; format, filename)
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
    f()
    Luxor.finish()
    Luxor.preview()
end

function _show_graph(locs, edges, vertex_colors, vertex_stroke_colors, vertex_text_colors, vertex_sizes, vertex_shapes, edge_colors, texts, config)
    # nodes
    nodes = [_node(_get(vertex_shapes, i, config.vertex_shape), Point(vertex)*config.unit, _get(vertex_sizes, i, config.vertex_size)*config.unit) for (i, vertex) in enumerate(locs)]
    # edges
    for (k, (i, j)) in enumerate(edges)
        ri = _get(vertex_sizes, i, config.vertex_size)
        rj = _get(vertex_sizes, j, config.vertex_size)
        draw_edge(nodes[i], nodes[j]; color=_get(edge_colors,k,config.edge_color),
            line_width=config.edge_line_width,
            line_style=config.edge_line_style,
        )
    end
    # vertices
    for (i, node) in enumerate(nodes)
        draw_vertex(node; fill_color=_get(vertex_colors, i, config.vertex_fill_color),
            stroke_color=_get(vertex_stroke_colors, i, config.vertex_stroke_color),
            line_width=config.vertex_line_width,
            line_style=config.vertex_line_style)
        draw_text(node.loc, _get(texts, i, "$i"); fontsize=config.fontsize*config.unit/50,
            color=_get(vertex_text_colors, i, config.vertex_text_color),
            fontface=config.fontface)
    end
end
_get(::Nothing, i, default) = default
_get(x, i, default) = x[i]
function _node(shape::String, loc, size)
    if shape == "circle"
        return node(circle, loc, size)
    elseif shape == "box"
        return node(box, loc, 2*size, 2*size)
    else
        error("shape `$shape` is not define!")
    end
end

function draw_text(loc, text; fontsize, color, fontface)
    isempty(text) && return
    Luxor.fontsize(fontsize)
    !isempty(fontface) && Luxor.fontface(fontface)
    setcolor(color)
    Luxor.text(text, loc, valign=:middle, halign=:center)
end
function draw_edge(a::Union{Node,Point}, b::Union{Node,Point}; color, line_width, line_style, arrow=false, kwargs...)
    setcolor(color)
    setline(line_width)
    setdash(line_style)
    edge(arrow ? Luxor.arrow : Luxor.line, a, b, :stroke; kwargs...)
end
function draw_vertex(node; stroke_color, fill_color, line_width, line_style)
    setcolor(fill_color)
    fill(node)
    setline(line_width)
    setcolor(stroke_color)
    setdash(line_style)
    stroke(node)
end

"""
    spring_layout!(g::AbstractGraph;
                       locs_x=2*rand(nv(g)).-1.0,
                       locs_y=2*rand(nv(g)).-1.0,
                       C=2.0,   # the optimal vertex distance
                       MAXITER=100,
                       INITTEMP=2.0,
                       mask::AbstractVector{Bool}=trues(length(locs_x))   # mask for which to relocate
                       )

Spring layout for graph plotting, returns a vector of vertex locations.

!!! note
    This function is copied from [`GraphPlot.jl`](https://github.com/JuliaGraphs/GraphPlot.jl),
    where you can find more information about his function.
"""
function spring_layout!(g::AbstractGraph;
                       locs_x=2*rand(nv(g)).-1.0,
                       locs_y=2*rand(nv(g)).-1.0,
                       C=2.0,   # the optimal vertex distance
                       MAXITER=100,
                       INITTEMP=2.0,
                       mask::AbstractVector{Bool}=trues(length(locs_x))   # mask for which to relocate
                       )

    nvg = nv(g)
    adj_matrix = adjacency_matrix(g)

    # The optimal distance bewteen vertices
    k = C * sqrt(4.0 / nvg)
    k?? = k * k

    # Store forces and apply at end of iteration all at once
    force_x = zeros(nvg)
    force_y = zeros(nvg)

    # Iterate MAXITER times
    @inbounds for iter = 1:MAXITER
        # Calculate forces
        for i = 1:nvg
            force_vec_x = 0.0
            force_vec_y = 0.0
            for j = 1:nvg
                i == j && continue
                d_x = locs_x[j] - locs_x[i]
                d_y = locs_y[j] - locs_y[i]
                dist??  = (d_x * d_x) + (d_y * d_y)
                dist = sqrt(dist??)

                if !( iszero(adj_matrix[i,j]) && iszero(adj_matrix[j,i]) )
                    # Attractive + repulsive force
                    # F_d = dist?? / k - k?? / dist # original FR algorithm
                    F_d = dist / k - k?? / dist??
                else
                    # Just repulsive
                    # F_d = -k?? / dist  # original FR algorithm
                    F_d = -k?? / dist??
                end
                force_vec_x += F_d*d_x
                force_vec_y += F_d*d_y
            end
            force_x[i] = force_vec_x
            force_y[i] = force_vec_y
        end
        # Cool down
        temp = INITTEMP / iter
        # Now apply them, but limit to temperature
        for i = 1:nvg
            mask[i] || continue
            fx = force_x[i]
            fy = force_y[i]
            force_mag  = sqrt((fx * fx) + (fy * fy))
            scale      = min(force_mag, temp) / force_mag
            locs_x[i] += force_x[i] * scale
            locs_y[i] += force_y[i] * scale
        end
    end

    locs_x, locs_y
end

"""
    show_gallery([f, ]graph::SimpleGraph, grid::Tuple{Int,Int};
        locs=nothing,
        spring::Bool=locs === nothing,
        optimal_distance=1.0,
        spring_mask=trues(nv(graph)),

        vertex_configs=nothing,
        edge_configs=nothing,
        vertex_color=nothing,
        edge_color=nothing,

        vertex_sizes=nothing,
        vertex_shapes=nothing,
        vertex_stroke_colors=nothing,
        vertex_text_colors=nothing,
        texts=nothing,
        xpad=1.0,
        ypad=1.0,
        format=DEFAULT_FORMAT[],
        filename=nothing,
        kwargs...)

Show a gallery of graphs for multiple vertex configurations or edge configurations in VSCode, Pluto or Jupyter notebook, or save it to a file.

Positional arguments
-----------------------------
* `f` is a function that returns extra `Luxor` plotting statements.
* `graph` is a graph instance.
* `grid` is the grid layout of the gallery, e.g. input value `(2, 3)` means a grid layout with 2 rows and 3 columns.

Keyword arguments
-----------------------------
* `locs` is a vector of tuples for specifying the vertex locations.
* `spring` is switch to use spring method to optimize the location.
* `optimal_distance` is a optimal distance parameter for `spring` optimizer.
* `spring_mask` specfies which location is optimizable for `spring` optimizer.

* `vertex_configs` is an iterator of bit strings for specifying vertex configurations. It will be rendered as vertex colors.
* `edge_configs` is an iterator of bit strings for specifying edge configurations. It will be rendered as edge colors.
* `edge_color` is a dictionary that specifies the edge configuration - color map.
* `vertex_color` is a dictionary that specifies the vertex configuration - color map.

* `vertex_sizes` is a vector of real numbers for specifying vertex sizes.
* `vertex_shapes` is a vector of strings for specifying vertex shapes, the string should be "circle" or "box".
* `vertex_stroke_colors` is a vector of color strings for specifying vertex stroke colors.
* `vertex_text_colors` is a vector of color strings for specifying vertex text colors.
* `texts` is a vector of strings for labeling vertices.

* `xpad` is the space between two adjacent plots in x direction.
* `ypad` is the space between two adjacent plots in y direction.
* `format` is the output format, which can be `:svg`, `:png` or `:pdf`.
* `filename` is a string as the output filename.

$CONFIGHELP

Example
-------------------------------
```jldoctest
julia> using Graphs

julia> show_gallery(smallgraph(:petersen), (2, 3); format=:png, vertex_configs=[rand(Bool, 10) for k=1:6]);
```
"""
function show_gallery(f, graph::SimpleGraph, grid::Tuple{Int,Int};
        locs=nothing,
        spring::Bool=locs === nothing,
        optimal_distance=1.0,
        spring_mask=trues(nv(graph)),
        kwargs...)
    locs = autolocs(graph, locs, spring, optimal_distance, spring_mask)
    show_gallery(f, locs, [(e.src, e.dst) for e in edges(graph)], grid; kwargs...)
end
show_gallery(graph::SimpleGraph, grid; kwargs...) = show_gallery(()->nothing, graph, grid; kwargs...)
function show_gallery(f, locs, edges, grid::Tuple{Int,Int};
        vertex_configs=nothing,
        edge_configs=nothing,
        vertex_sizes=nothing,
        vertex_shapes=nothing,
        vertex_color=nothing,
        edge_color=nothing,
        vertex_stroke_colors=nothing,
        vertex_text_colors=nothing,
        texts=nothing,
        format=DEFAULT_FORMAT[],
        filename=nothing,
        kwargs...)
    length(locs) == 0 && return _draw(f, 100, 100; format, filename)

    (xmin, ymin), (dx, dy), config = get_config(locs, edges; kwargs...)
    m, n = grid
    nv, ne = length(locs), length(edges)
    Dx, Dy = dx*n, dy*m
    transform(loc) = loc[1]-xmin+config.xpad, loc[2]-ymin+config.ypad
    locs = transform.(locs)
    # default vertex and edge maps
    if vertex_color === nothing
        vertex_color = Dict(false=>config.vertex_fill_color, true=>"red")
    end
    if edge_color === nothing
        edge_color = Dict(false=>config.edge_color, true=>"red")
    end

    _draw(Dx*config.unit, Dy*config.unit; format, filename) do
        background(config.background_color)
        for i=1:m
            for j=1:n
                origin((j-1)*dx*config.unit, (i-1)*dy*config.unit)
                # set colors
                k = (i-1) * n + j
                vertex_colors = if vertex_configs isa Nothing
                    fill(config.vertex_fill_color, nv)
                else
                    k > length(vertex_configs) && break
                    [_get(vertex_color, vertex_configs[k][i], config.vertex_fill_color) for i=1:nv]
                end
                edge_colors = if edge_configs isa Nothing
                    fill(config.edge_color, ne)
                else
                    k > length(edge_configs) && break
                    [_get(edge_color, edge_configs[k][i], config.edge_color) for i=1:ne]
                end
                _show_graph(locs, edges, vertex_colors, vertex_stroke_colors, vertex_text_colors,
                vertex_sizes, vertex_shapes, edge_colors, texts, config)
            end
        end
        f()
    end
end
show_gallery(locs::AbstractVector, edges, grid::Tuple{Int,Int}; kwargs...) = show_gallery(()->nothing, locs, edges, grid; kwargs...)