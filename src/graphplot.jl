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
    * `vertex_color = DEFAULT_VERTEX_FILL_COLOR[]`, the default default fill color for vertices
    * `vertex_size::Float64 = DEFAULT_VERTEX_SIZE[]`, the default vertex size
    * `vertex_shape::String = "circle"`, the default vertex shape, which can be "circle" or "box"
    * `vertex_line_width::Float64 = 1`, the default vertex stroke line width
    * `vertex_line_style::String = "solid"`, the line style of vertex stroke, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]
* edge
    * `edge_color = DEFAULT_EDGE_COLOR[]`, the default edge color
    * `edge_line_width::Float64 = 1`, the default line width
    * `edge_style::String = "solid"`, the line style of edges, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]
"""
module GraphDisplayConfig
    # line, vertex and text
    xpad = Ref(1.0)
    ypad = Ref(1.0)
    xpad_right = Ref(1.0)
    ypad_bottom = Ref(1.0)
    fontface = Ref("")
    background_color = Ref("white")
    unit = Ref(50.0)   # how many pixels as unit?
    fontsize = Ref(12.0)
    format = Ref(:svg)
    text = Ref("")
    # vertex
    vertex_shape = Ref("circle")
    vertex_line_width = Ref(1.0)  # in pt
    vertex_line_style = Ref("solid")
    vertex_text_color = Ref("black")
    vertex_stroke_color = Ref("black")
    vertex_color = Ref("transparent")
    vertex_size = Ref(0.15)
    # edge
    edge_color = Ref("black")
    edge_line_width = Ref(1.0)  # in pt
    edge_line_style = Ref("solid")
end

macro get(ex)
    @match ex begin
        :($d.$x[$i]) => begin
            item = Symbol(String(x)[1:end-1])
            esc(:($haskey($d, $(QuoteNode(x))) ? $d[$(QuoteNode(x))][$i] : $GraphDisplayConfig.$item[]))
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
        format=GraphDisplayConfig.format[],
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

$CONFIGHELP

Example
------------------------------
```jldoctest
julia> using Graphs

julia> show_graph(smallgraph(:petersen); format=:png, vertex_colors=rand(["blue", "red"], 10));
```
"""
function show_graph(f, locs, edges;
        format=GraphDisplayConfig.format[],
        filename=nothing,
        kwargs...
        )
    length(locs) == 0 && return _draw(()->nothing, 100, 100; format, filename)
    unit = GraphDisplayConfig.unit[]
    config = graphsizeconfig(locs)
    transform(loc) = loc[1]-config.xmin+config.xpad, loc[2]-config.ymin+config.ypad
    _draw(config.Dx*unit, config.Dy*unit; format, filename) do
        _show_graph(locs, edges;
            kwargs...)
        f(x->transform(x) .* unit)
    end
end

function _show_graph(locs, edges; kwargs...)
    config = graphsizeconfig(locs)
    transform(loc) = loc[1]-config.xmin+config.xpad, loc[2]-config.ymin+config.ypad
    background(GraphDisplayConfig.background_color[])
    unitless_show_graph(transform.(locs), edges, Dict(kwargs...))
    return nothing
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
    locs = autolocs(graph, locs, layout, optimal_distance, spring_mask)
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

function unitless_show_graph(locs, edges, configs::Dict)
    unit = GraphDisplayConfig.unit[]
    # nodes, we have to set a minimum size to 1e-3, so that the intersection algorithm can work
    nodes = [
        _node(
            @get(configs.vertex_shapes[i]),
            Point(vertex)*unit,
            max(@get(configs.vertex_sizes[i])*unit, 1e-3)
        ) for (i, vertex) in enumerate(locs)]
    # edges
    for (k, (i, j)) in enumerate(edges)
        draw_edge(nodes[i], nodes[j]; color=@get(configs.edge_colors[k]),
            line_width=GraphDisplayConfig.edge_line_width[],
            line_style=GraphDisplayConfig.edge_line_style[],
        )
    end
    # vertices
    for (i, node) in enumerate(nodes)
        draw_vertex(node; fill_color=@get(configs.vertex_colors[i]),
            stroke_color=@get(configs.vertex_stroke_colors[i]),
            line_width=GraphDisplayConfig.vertex_line_width[],
            line_style=GraphDisplayConfig.vertex_line_style[])
        draw_text(node.loc, @get(configs.texts[i]); fontsize=GraphDisplayConfig.fontsize[]*unit/50,
            color=@get(configs.vertex_text_colors[i]),
            fontface=GraphDisplayConfig.fontface[])
    end
end
_get(::Nothing, i, default) = default
_get(x, i, default) = x[i]
function _node(shape, loc, size)
    @match shape begin
        "circle" || "o" || :circle => Node(:circle, loc; radius=size)
        "box" || "□" || :box => Node(:box, loc; width=2*size, height=2*size)
        "dot" || "." || :dot => Node(:dot, loc)
        _ => error("shape `$shape` is not define!")
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
