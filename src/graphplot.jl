const CONFIGHELP = """
* `fontsize::Float64 = 12.0`, the font size
* `fontface::String = ""`, the font face, leave empty to follow system

* `vertex_text_color = "black"`, the default text color
* `vertex_stroke_color = "black"`, the default stroke color for vertices
* `vertex_color = "transparent"`, the default default fill color for vertices
* `vertex_size::Float64 = 10.0`, the default vertex size
* `vertex_shape::Symbol = :circle`, the default vertex shape, which can be :circle, :box or :dot
* `vertex_line_width::Float64 = 1`, the default vertex stroke line width
* `vertex_line_style::String = "solid"`, the line style of vertex stroke, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]

* `edge_color = "black"`, the default edge color
* `edge_line_width::Float64 = 1`, the default line width
* `edge_style::String = "solid"`, the line style of edges, which can be one of ["solid", "dotted", "dot", "dotdashed", "longdashed", "shortdashed", "dash", "dashed", "dotdotdashed", "dotdotdotdashed"]
"""

const VIZHELP = """
* `vertex_colors` is a vector of color strings for specifying vertex fill colors.
* `vertex_sizes` is a vector of real numbers for specifying vertex sizes.
* `vertex_shapes` is a vector of strings for specifying vertex shapes, the string should be "circle" or "box".
* `vertex_stroke_colors` is a vector of color strings for specifying vertex stroke colors.
* `vertex_text_colors` is a vector of color strings for specifying vertex text colors.
* `edge_colors` is a vector of color strings for specifying edge colors.
* `texts` is a vector of strings for labeling vertices.
"""

#####

"""
    Layout(layout=:spring; optimal_distance=20.0, locs=nothing, spring_mask=nothing)

The struct for specifying the layout of a graph. Use [`render_locs`](@ref) to render the vertex locations.

Positional arguments
-------------------------------
* `layout` is one of [:auto, :spring, :stress, :spectral], the default value is `:spring`.

Keyword arguments
-------------------------------
* `optimal_distance` is a optimal distance parameter for `spring` optimizer.
* `locs` is a vector of tuples for specifying the vertex locations.
* `spring_mask` specfies which location is optimizable for `spring` optimizer.
"""
struct Layout
    layout::Symbol
    optimal_distance::Float64
    locs
    spring_mask
end
function Layout(layout=:spring; optimal_distance=50.0, locs=nothing, spring_mask=nothing)
    return Layout(layout, optimal_distance, locs, spring_mask)
end

"""
    render_locs(graph, layout::Layout)

Render the vertex locations for a graph from a [`Layout`](@ref) instance.
"""
function render_locs(graph, l::Layout)
    optimal_distance, locs, spring_mask, layout = l.optimal_distance, l.locs, l.spring_mask, l.layout
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
                        mask=spring_mask === nothing ? trues(nv(graph)) : spring_mask   # mask for which to relocate
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
            locs_x, locs_y = spectral_layout(graph; C=optimal_distance)
        else
            error("either `locs` is nothing, or layout is not defined: $(layout)")
        end
        return collect(zip(locs_x, locs_y))
    end
end
render_locs(graph, locs::AbstractVector) = locs


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
    fontsize::Float64 = 12.0
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
Base.copy(config::GraphDisplayConfig) = deepcopy(config)

"""
    darktheme!(config::GraphDisplayConfig)

Set the dark theme for the graph display.
"""
darktheme!(config::GraphDisplayConfig) = begin
    config.background = "transparent"
    config.vertex_text_color = "white"
    config.vertex_stroke_color = "white"
    config.edge_color = "white"
    return config
end

"""
    lighttheme!(config::GraphDisplayConfig)

Set the light theme for the graph display.
"""
lighttheme!(config::GraphDisplayConfig) = begin
    config.background = "transparent"
    config.vertex_text_color = "black"
    config.vertex_stroke_color = "black"
    config.edge_color = "black"
    return config
end

"""
    GraphViz

The struct for storing graph visualization information.

Keyword arguments
-------------------------------
$VIZHELP
"""
Base.@kwdef mutable struct GraphViz
    locs::Vector{Tuple{Float64, Float64}}
    edges::Vector{Tuple{Int, Int}}
    vertex_shapes = nothing
    vertex_sizes = nothing
    vertex_colors = nothing
    vertex_stroke_colors = nothing
    vertex_text_colors = nothing
    edge_colors = nothing
    texts = nothing
end
function GraphViz(graph::SimpleGraph, locs=Layout(:spring); kwargs...)
    return GraphViz(; locs=render_locs(graph, locs), edges=[(src(e), dst(e)) for e in edges(graph)], kwargs...)
end
get_bounding_box(g::GraphViz) = (minimum(getindex.(g.locs, 1)), maximum(getindex.(g.locs, 1)), minimum(getindex.(g.locs, 2)), maximum(getindex.(g.locs, 2)))

struct GraphDiagram <: AbstractNodeStore
    nodes::Vector{Node}
    edges::Vector{Connection}
end
nodes(d::GraphDiagram) = d.nodes
function offset(d::GraphDiagram, point)
    GraphDiagram([offset(n, point) for n in d.nodes], [offset(e, point) for e in d.edges])
end

"""
    show_graph([f, ]graph::AbstractGraph;
        kwargs...
        )

Show a graph in VSCode, Pluto or Jupyter notebook, or save it to a file.

Positional arguments
-----------------------------
* `f` is a function that returns extra `Luxor` plotting statements.
* `graph` is a graph instance.
* `locs` is a vector of tuples for specifying the vertex locations, or a [`Layout`](@ref) instance.

Keyword arguments
-----------------------------
* `config` is a [`GraphDisplayConfig`](@ref) instance.

$VIZHELP

* `padding_left::Int = 10`, the padding on the left side of the drawing
* `padding_right::Int = 10`, the padding on the right side of the drawing
* `padding_top::Int = 10`, the padding on the top side of the drawing
* `padding_bottom::Int = 10`, the padding on the bottom side of the drawing

* `format` is the output format, which can be `:svg`, `:png` or `:pdf`.
* `filename` is a string as the output filename.

Example
------------------------------
```jldoctest
julia> using Graphs, LuxorGraphPlot

julia> show_graph(smallgraph(:petersen); format=:png, vertex_colors=rand(["blue", "red"], 10));
```
"""
show_graph(graph::GraphViz; kwargs...) = show_graph(x->nothing, graph; kwargs...)
show_graph(graph::SimpleGraph, locs=Layout(:spring); kwargs...) = show_graph(x->nothing, graph, locs; kwargs...)
function show_graph(f, g::GraphViz;
        format = :svg,
        filename = nothing,
        padding_left = 10,
        padding_right = 10,
        padding_top = 10,
        padding_bottom = 10,
        config = GraphDisplayConfig(),
    )
    diag = diagram(g.locs, g.edges; g.vertex_shapes, g.vertex_sizes, config)
    with_nodes(diag; format, filename, padding_bottom, padding_left, padding_right, padding_top, background=config.background) do
        f(diag)
        show_diagram(diag; config,
            texts=g.texts,
            vertex_colors=g.vertex_colors,
            vertex_stroke_colors = g.vertex_stroke_colors,
            vertex_text_colors = g.vertex_text_colors,
            edge_colors = g.edge_colors)
    end
end

function diagram(locs, edges; vertex_sizes=nothing, vertex_shapes=nothing, config=GraphDisplayConfig())
    nodes = Node[]
    for i in eachindex(locs)
        shape = _get(vertex_shapes, i, config.vertex_shape)
        vertex_size = _get(vertex_sizes, i, config.vertex_size)
        props = Dict(
                :circle => Dict(:radius=>vertex_size),
                :box => Dict(:width=>2*vertex_size, :height=>2*vertex_size),
                :dot => Dict()
            )[shape]
        push!(nodes, Node(shape, locs[i]; props...))
    end
    edgs = Connection[]
    for (i, j) in edges
        push!(edgs, Connection(nodes[i], nodes[j]))
    end
    return GraphDiagram(nodes, edgs)
end
function show_graph(f, graph::SimpleGraph, locs=Layout(:spring);
        vertex_shapes = nothing,
        vertex_sizes = nothing,
        vertex_colors = nothing,
        vertex_stroke_colors = nothing,
        vertex_text_colors = nothing,
        edge_colors = nothing,
        texts = nothing,
        padding_left = 10,
        padding_right = 10,
        padding_top = 10,
        padding_bottom = 10,
        format = :svg,
        filename = nothing,
        config = GraphDisplayConfig()
    )
    viz = GraphViz(graph, locs;
            vertex_shapes, vertex_sizes, vertex_colors, vertex_stroke_colors,
            vertex_text_colors, edge_colors, texts)
    show_graph(f, viz; format, filename, padding_bottom, padding_left, padding_right, padding_top, config)
end

function show_diagram(diag::GraphDiagram;
            config=GraphDisplayConfig(),
            vertex_colors,
            vertex_stroke_colors,
            vertex_text_colors,
            texts,
            edge_colors)
    # edges
    setline(config.edge_line_width)
    setdash(config.edge_line_style)
    for (k, e) in enumerate(diag.edges)
        setcolor(_get(edge_colors, k, config.edge_color))
        stroke(e)
    end
    # vertices
    setline(config.vertex_line_width)
    setdash(config.vertex_line_style)
    Luxor.fontsize(config.fontsize)
    !isempty(config.fontface) && Luxor.fontface(config.fontface)
    for (i, node) in enumerate(diag.nodes)
        setcolor(_get(vertex_colors, i, config.vertex_color))
        fill(node)
        setcolor(_get(vertex_stroke_colors, i, config.vertex_stroke_color))
        stroke(node)
        text = _get(texts, i, "")
        if !isempty(text)
            setcolor(_get(vertex_text_colors, i, config.vertex_text_color))
            Luxor.text(text, node)
        end
    end
end
_get(::Nothing, i, default) = default
_get(x, i, default) = x[i]

"""
    show_gallery([f, ]stores::AbstractMatrix{GraphViz};
        kwargs...
        )

Show a gallery of graphs in VSCode, Pluto or Jupyter notebook, or save it to a file.

Positional arguments
-----------------------------
* `f` is a function that returns extra `Luxor` plotting statements.
* `stores` is a matrix of `GraphViz` instances.

Keyword arguments
-----------------------------
* `config` is a [`GraphDisplayConfig`](@ref) instance.

* `padding_left::Int = 10`, the padding on the left side of the drawing
* `padding_right::Int = 10`, the padding on the right side of the drawing
* `padding_top::Int = 10`, the padding on the top side of the drawing
* `padding_bottom::Int = 10`, the padding on the bottom side of the drawing

* `format` is the output format, which can be `:svg`, `:png` or `:pdf`.
* `filename` is a string as the output filename.
"""
function show_gallery(f, stores::AbstractMatrix{GraphViz};
        padding_left=10, padding_right=10,
        padding_top=10, padding_bottom=10,
        config=GraphDisplayConfig(),
        format=:svg,
        filename=nothing
    )
    if isempty(stores)
        return Luxor.Drawing(1, 1, filename === nothing ? tempname()*".$format" : filename)
    end
    xmin, _, ymin, _ = get_bounding_box(stores[1, 1]) .+ (-padding_left, padding_right, -padding_top, padding_bottom)
    xspans = map(stores[1, :]) do d
        xmin, xmax, _, _ = get_bounding_box(d) .+ (-padding_left, padding_right, -padding_top, padding_bottom)
        xmax - xmin
    end
    yspans = map(stores[:, 1]) do d
        _, _, ymin, ymax = get_bounding_box(d) .+ (-padding_left, padding_right, -padding_top, padding_bottom)
        ymax - ymin
    end
    m, n = size(stores)
    xoffsets = cumsum([0; xspans[1:end-1]])
    yoffsets = cumsum([0; yspans[1:end-1]])

    Luxor.Drawing(ceil(Int, sum(xspans)), ceil(Int, sum(yspans)), filename === nothing ? tempname()*".$format" : filename)
    Luxor.origin(-xmin, -ymin)
    Luxor.background(config.background)
    for i=1:m, j=1:n
        g = stores[i, j]
        diag_ = diagram(g.locs, g.edges; g.vertex_shapes, g.vertex_sizes, config)
        diag = offset(diag_, (xoffsets[j], yoffsets[i]))
        f(diag)
        show_diagram(diag; config,
            texts=g.texts,
            vertex_colors=g.vertex_colors,
            vertex_stroke_colors = g.vertex_stroke_colors,
            vertex_text_colors = g.vertex_text_colors,
            edge_colors = g.edge_colors)
    end
    Luxor.finish()
    Luxor.preview()
end
show_gallery(stores::AbstractMatrix{GraphViz}; kwargs...) = show_gallery(x->nothing, stores; kwargs...)