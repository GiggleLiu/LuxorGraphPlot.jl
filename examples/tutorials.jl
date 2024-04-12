## Show a graph
using Graphs, LuxorGraphPlot, LuxorGraphPlot.Luxor

# Show a graph with spring (default) layout.

graph = smallgraph(:petersen)

show_graph(graph)

# specify the layout and texts manually

rot15(a, b, i::Int) = cos(2i*π/5)*a + sin(2i*π/5)*b, cos(2i*π/5)*b - sin(2i*π/5)*a
locations = [[rot15(0.0, 50.0, i) for i=0:4]..., [rot15(0.0, 25.0, i) for i=0:4]...]
show_graph(graph, locations,
        texts=[string('a'+i) for i=0:9], padding_right=300,
        config=GraphDisplayConfig(; background="gray")) do nd
    ## extra commands, transformer is a function that convert graph-axis to canvas axis.
    LuxorGraphPlot.Luxor.fontsize(22)
    xmin, xmax, ymin, ymax = LuxorGraphPlot.get_bounding_box(nd)
    LuxorGraphPlot.text("haha, the fontsize is so big!", Point(xmax + 20, (ymin + ymax) / 2))
end

# specify colors, shapes and sizes

show_graph(graph;
	vertex_colors=rand(["blue", "red"], 10),
	vertex_sizes=rand(10) .* 10 .+ 5,
	vertex_stroke_colors=rand(["blue", "red"], 10),
	vertex_text_colors=rand(["white", "black"], 10),
	edge_colors=rand(["blue", "red"], 15),
	vertex_shapes=rand([:circle, :box], 10)
)

# for uniform colors/sizes, you can make life easier by specifying global colors.

show_graph(graph;
    config = GraphDisplayConfig(
        vertex_color="blue",
        vertex_size=7.5,
        vertex_stroke_color="transparent",
        vertex_text_color="white",
        edge_color="green"
    )
)

# One can also dump an image to a file

show_graph(graph; format=:svg)

# or render it in another format

show_graph(graph; format=:svg)

# ## Layouts

# The default layout is `:auto`, which uses `:spring` if `locs` is `nothing`.

show_graph(graph, Layout(:spring))

show_graph(graph, Layout(:stress))

show_graph(graph, Layout(:spectral))

# ## Show a gallery

# One can use a boolean vector to represent boolean variables on a vertex or an edge.

locs = render_locs(graph, Layout(:spring))
matrix = [GraphViz(graph, locs; vertex_colors=[rand(Luxor.RGB) for i=1:10],
    edge_colors=[rand(Luxor.RGB) for i=1:15]) for i=1:2, j=1:4]
show_gallery(matrix; format=:png, padding_left=20, padding_right=20, padding_top=20, padding_bottom=20)
