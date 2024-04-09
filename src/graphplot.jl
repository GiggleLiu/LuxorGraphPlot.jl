const CONFIGHELP = """
* general
    * `xpad::Float64 = 1.0`, the padding space in x direction
    * `ypad::Float64 = 1.0`, the padding space in y direction
    * `xpad_right::Float64 = 1.0`, the padding space in x direction (right side)
    * `ypad_bottom::Float64 = 1.0`, the padding space in y direction (bottom side)
    * `background::String = "white"`, the background color
    * `unit::Float64 = 50`, the unit distance as the number of pixels
    * `fontsize::Float64 = 12.0`, the font size
    * `fontface::String = ""`, the font face, leave empty to follow system
* vertex
    * `vertex_text_color = "black"`, the default text color
    * `vertex_stroke_color = "black"`, the default stroke color for vertices
    * `vertex_color = "transparent"`, the default default fill color for vertices
    * `vertex_size::Float64 = 10.0`, the default vertex size
    * `vertex_shape::Symbol = :circle`, the default vertex shape, which can be :circle, :box or :dot
    * `vertex_line_width::Float64 = 1`, the default vertex stroke line width
    * `vertex_line_style::String = "solid"`, the line style of vertex stroke, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]
* edge
    * `edge_color = "black"`, the default edge color
    * `edge_line_width::Float64 = 1`, the default line width
    * `edge_style::String = "solid"`, the line style of edges, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]
"""

"""
    GraphDisplayConfig

The configuration for graph display.

Keyword arguments
-------------------------------
$CONFIGHELP
"""
Base.@kwdef mutable struct GraphDisplayConfig
    # line, vertex and text
    fontface::String = ""
    background::String = "white"
    unit::Float64 = 50.0   # how many pixels as unit?
    fontsize::Float64 = 12.0
    format::Symbol = :svg
    text::String = ""
    # vertex
    vertex_shape::Symbol = :circle
    vertex_line_width::Float64 = 1.0  # in pt
    vertex_line_style::String = "solid"
    vertex_text_color::String = "black"
    vertex_stroke_color::String = "black"
    vertex_color::String = "transparent"
    vertex_size::Float64 = 10.0
    # edge
    edge_color::String = "black"
    edge_line_width::Float64 = 1.0  # in pt
    edge_line_style::String = "solid"
end

macro get(ex)
    @match ex begin
        :($d.$x[$i]) => begin
            item = Symbol(String(x)[1:end-1])
            esc(:($haskey($d, $(QuoteNode(x))) ? $d[$(QuoteNode(x))][$i] : get($d, $(QuoteNode(item)), $GraphDisplayConfig.$item[])))
        end
    end
end

macro temp(exs...)
    preexprs = []
    postexprs = []
    for ex in exs[1:end-1]
        @match ex begin
            :($x = $b) => begin
                var = gensym()
                push!(preexprs, :($var = $x))
                push!(preexprs, :($x = $b))
                push!(postexprs, :($x = $var))
            end
        end
    end
    res = gensym()
    esc(Expr(:block, preexprs..., :($res = $(exs[end])), postexprs..., res))
end

function get_bounding_box(locs)
    @assert length(locs) > 0
    xmin = minimum(x->x[1], locs)
    ymin = minimum(x->x[2], locs)
    xmax = maximum(x->x[1], locs)
    ymax = maximum(x->x[2], locs)
    return (; xmin, ymin, xmax, ymax)
end

struct GraphDiagram <: AbstractNodeStore
    nodes::Vector{Node}
    edges::Vector{Connection}
end
nodes(d::GraphDiagram) = d.nodes

"""
    show_graph([f, ]graph::SimpleGraph;
        locs=nothing,
        layout=:auto,
        optimal_distance=1.0,
        spring_mask=trues(nv(graph)),

        vertex_colors=nothing,
        vertex_sizes=nothing,
        vertex_stroke_colors=nothing,
        vertex_text_colors=nothing,
        edge_colors=nothing,
        texts = nothing,
        format = :svg,
        filename = nothing,
        kwargs...)

Show a graph in VSCode, Pluto or Jupyter notebook, or save it to a file.

Positional arguments
-----------------------------
* `f` is a function that returns extra `Luxor` plotting statements.
* `graph` is a graph instance.

Keyword arguments
-----------------------------
* `locs` is a vector of tuples for specifying the vertex locations.
* `layout` is one of [:auto, :spring, :stress], the default value is `:spring` if locs is `nothing`.
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

Extra keyword arguments
-------------------------------
$CONFIGHELP

Example
------------------------------
```jldoctest
julia> using Graphs

julia> show_graph(smallgraph(:petersen); format=:png, vertex_colors=rand(["blue", "red"], 10));
```
"""
function show_graph(f, locs, edges;
        format = :svg,
        filename = nothing,
        padding_left = 10,
        padding_right = 10,
        padding_top = 10,
        padding_bottom = 10,
        background = :white,
        vertex_shapes = nothing,
        vertex_shape = :circle,
        vertex_sizes = nothing,
        vertex_size = 10,
        kwargs...
        )
    length(locs) == 0 && return _draw(()->nothing, 100, 100; format, filename)
    ns = diagram(locs, edges; vertex_shapes, vertex_sizes, vertex_shape, vertex_size)
    with_nodes(ns; format, filename, padding_bottom, padding_left, padding_right, padding_top, background) do
        show_diagram(ns; kwargs...)
    end
end

function diagram(locs, edges; vertex_shapes=nothing, vertex_sizes=nothing, vertex_shape=:circle, vertex_size=10)
    nodes = Node[]
    for i=1:length(locs)
        shape = _get(vertex_shapes, i, vertex_shape)
        vertex_size = _get(vertex_sizes, i, vertex_size)
        props = Dict(
                :circle => Dict(:radius=>vertex_size),
                :box => Dict(:width=>2*vertex_size, :height=>2*vertex_size),
                :dot => Dict()
            )[shape]
        push!(nodes, Node(shape, loc; props...))
    end
    edgs = Connection[]
    for (i, j) in edges
        push!(edgs, Connection(i, j))
    end
    return GraphDiagram(nodes, edgs)
end

function split_kwargs(kwargs, set)
    group1 = Dict(k=>v for (k, v) in kwargs if k ∈ set)
    group2 = Dict(k=>v for (k, v) in kwargs if k ∉ set)
    return group1, group2
end

function graphsizeconfig(locs;
        xpad=1.0,
        ypad=1.0,
        xpad_right=xpad,
        ypad_bottom=ypad,
        )
    xmin, ymin, xmax, ymax = get_bounding_box(locs)
    Dx, Dy = (xmax-xmin)+xpad+xpad_right, (ymax-ymin)+ypad+ypad_bottom
    # xmin/ymin is the minimum x/y coordinate
    # Dx/Dy is the x/y span
    # config is the plotting config
    return (; xpad, ypad, xpad_right, ypad_bottom, xmin, ymin, xmax, ymax, Dx, Dy)
end

# NOTE: the final positions are in range [-5, 5]
function show_graph(f, graph::SimpleGraph;
        locs=nothing,
        layout::Symbol=:auto,
        optimal_distance=1.0,
        spring_mask=trues(nv(graph)),
        kwargs...)
    locs = autolocs(graph, locs, layout, optimal_distance, spring_mask) .* GraphDisplayConfig.unit[]
    show_graph(f, locs, [(e.src, e.dst) for e in edges(graph)]; kwargs...)
end
show_graph(graph::SimpleGraph; kwargs...) = show_graph(t->nothing, graph; kwargs...)
show_graph(locs::AbstractVector, edges; kwargs...) = show_graph(t->nothing, locs, edges; kwargs...)

function autolocs(graph, locs, layout, optimal_distance, spring_mask)
    if layout == :auto && locs !== nothing
        return locs
    else
        locs_x = locs === nothing ? [2*rand()-1.0 for i=1:nv(graph)] : getindex.(locs, 1)
        locs_y = locs === nothing ? [2*rand()-1.0 for i=1:nv(graph)] : getindex.(locs, 2)
        if layout == :spring || layout == :auto
            locs_x, locs_y = spring_layout(graph;
                        C=optimal_distance,
                        locs_x,
                        locs_y,
                        mask=spring_mask   # mask for which to relocate
                    )
        elseif layout == :stress
            locs_x, locs_y = stressmajorize_layout(graph;
                        locs_x,
                        locs_y,
                        C=optimal_distance,
                        w=nothing,
                        maxiter = 400 * nv(graph)^2
                       )
        elseif layout == :spectral
            locs_x, locs_y = spectral_layout(graph)
        else
            error("either `locs` is nothing, or layout is not defined: $(layout)")
        end
        return collect(zip(locs_x, locs_y))
    end
end

function show_diagram(locs, edges; vertex_colors, vertex_stroke_colors, vertex_text_colors, texts,
        edge_colors)
    unitless_show_graph(transform.(locs), edges, extra_kwargs)

    # edges
    for (k, (i, j)) in enumerate(edges)
        draw_edge(nodes[i], nodes[j]; color=,
            line_width=GraphDisplayConfig.edge_line_width[],
            line_style=GraphDisplayConfig.edge_line_style[],
        )
        setcolor(_get(edge_colors, k, edge_color))
        setline(_get(edge_line_width))
        setdash(_get(edge_line_style))
        (arrow ? Luxor.arrow : Luxor.line)(a, b, :stroke; kwargs...)
    end
    # vertices
    for (i, node) in enumerate(nodes)
        draw_vertex(node; fill_color=@get(configs.vertex_colors[i]),
            stroke_color=@get(configs.vertex_stroke_colors[i]),
            line_width=GraphDisplayConfig.vertex_line_width[],
            line_style=GraphDisplayConfig.vertex_line_style[])
        draw_text(node.loc, @get(configs.texts[i]); fontsize=GraphDisplayConfig.fontsize[],
            color=@get(configs.vertex_text_colors[i]),
            fontface=GraphDisplayConfig.fontface[])
    end
end
_get(::Nothing, i, default) = default
_get(x, i, default) = x[i]

function draw_text(loc, text; fontsize, color, fontface)
    isempty(text) && return
    Luxor.fontsize(fontsize)
    !isempty(fontface) && Luxor.fontface(fontface)
    setcolor(color)
    Luxor.text(text, loc, valign=:middle, halign=:center)
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
    show_gallery([f, ]graph::SimpleGraph, grid::Tuple{Int,Int};
        locs=nothing,
        layout=:auto,
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
        format=GraphDisplayConfig.format[],
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
* `layout` is one of [:auto, :spring, :stress], the default value is `:spring` if locs is `nothing`.
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

Extra keyword arguments
-------------------------------
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
        layout::Symbol=:auto,
        optimal_distance=1.0,
        spring_mask=trues(nv(graph)),
        kwargs...)
    locs = autolocs(graph, locs, layout, optimal_distance, spring_mask)
    show_gallery(f, locs, [(e.src, e.dst) for e in edges(graph)], grid; kwargs...)
end
show_gallery(graph::SimpleGraph, grid; kwargs...) = show_gallery(transform->nothing, graph, grid; kwargs...)
function show_gallery(f, locs, edges, grid::Tuple{Int,Int};
        vertex_configs=nothing,
        edge_configs=nothing,
        vertex_color=nothing,
        edge_color=nothing,
        format=GraphDisplayConfig.format[],
        filename=nothing,
        kwargs...
        )
    length(locs) == 0 && return _draw(()->nothing, 100, 100; format, filename)

    config = graphsizeconfig(locs)
    unit = GraphDisplayConfig.unit[]
    m, n = grid
    nv, ne = length(locs), length(edges)
    Dx, Dy = config.Dx*n, config.Dx*m
    transform(loc) = loc[1]-config.xmin+config.xpad, loc[2]-config.ymin+config.ypad
    locs = transform.(locs)
    # default vertex and edge maps
    if vertex_color === nothing
        vertex_color = Dict(false=>GraphDisplayConfig.vertex_color[], true=>"red")
    end
    if edge_color === nothing
        edge_color = Dict(false=>GraphDisplayConfig.edge_color[], true=>"red")
    end

    _draw(Dx*unit, Dy*unit; format, filename) do
        background(GraphDisplayConfig.background_color[])
        for i=1:m
            for j=1:n
                origin((j-1)*config.Dx*unit, (i-1)*config.Dy*unit)
                # set colors
                k = (i-1) * n + j
                vertex_colors = if vertex_configs isa Nothing
                    fill(GraphDisplayConfig.vertex_color[], nv)
                else
                    k > length(vertex_configs) && break
                    [_get(vertex_color, vertex_configs[k][i], GraphDisplayConfig.vertex_color[]) for i=1:nv]
                end
                edge_colors = if edge_configs isa Nothing
                    fill(GraphDisplayConfig.edge_color[], ne)
                else
                    k > length(edge_configs) && break
                    [_get(edge_color, edge_configs[k][i], GraphDisplayConfig.edge_color[]) for i=1:ne]
                end
                unitless_show_graph(locs, edges, Dict(
                    :vertex_colors => vertex_colors,
                    :edge_colors => edge_colors,
                    kwargs...)
                )
            end
        end
        f(x->transform(x) .* unit)
    end
end
show_gallery(locs::AbstractVector, edges, grid::Tuple{Int,Int}; kwargs...) = show_gallery(()->nothing, locs, edges, grid; kwargs...)
