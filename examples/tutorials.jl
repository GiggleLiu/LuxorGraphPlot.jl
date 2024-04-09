## Show a graph
using Graphs, LuxorGraphPlot

# Show a graph with spring (default) layout.

graph = smallgraph(:petersen)

show_graph(graph; optimal_distance=2.0)

# specify the layout and texts manually

rot15(a, b, i::Int) = cos(2i*π/5)*a + sin(2i*π/5)*b, cos(2i*π/5)*b - sin(2i*π/5)*a
locations = [[rot15(0.0, 1.0, i) for i=0:4]..., [rot15(0.0, 0.5, i) for i=0:4]...]
show_graph(graph; locs=locations, texts=[string('a'+i) for i=0:9], fontsize=8, xpad_right=7, background_color="gray") do transformer
    ## extra commands, transformer is a function that convert graph-axis to canvas axis.
    LuxorGraphPlot.Luxor.fontsize(22)
    LuxorGraphPlot.Luxor.text("haha, the fontsize is so big!", transformer((1.5, 0.2))...)
end

# specify colors, shapes and sizes

show_graph(graph;
	vertex_colors=rand(["blue", "red"], 10),
	vertex_sizes=rand(10) .* 0.2 .+ 0.1,
	vertex_stroke_colors=rand(["blue", "red"], 10),
	vertex_text_colors=rand(["white", "black"], 10),
	edge_colors=rand(["blue", "red"], 15),
	vertex_shapes=rand(["circle", "box"], 10)
)

# for uniform colors/sizes, you can make life easier by specifying global colors.

show_graph(graph;
	vertex_color="blue",
	vertex_size=0.15,
	vertex_stroke_color="transparent",
	vertex_text_color="white",
	edge_color="green",
)

# One can also dump an image to a file

show_graph(graph; filename=tempname()*".svg")

# or render it in another format

show_graph(graph; format=:svg)

# ## Layouts

# The default layout is `:auto`, which uses `:spring` if `locs` is `nothing`.

show_graph(graph; layout=:spring)

show_graph(graph; layout=:stress)

show_graph(graph; layout=:spectral)

# ## Show a gallery

# One can use a boolean vector to represent boolean variables on a vertex or an edge.

show_gallery(smallgraph(:petersen), (2, 3); format=:png,
	vertex_configs=[rand(Bool, 10) for k=1:6],
	edge_configs=[rand(Bool, 15) for k=1:6], xpad=0.5, ypad=0.5)

# for non-boolean configurations, you need to provide a map to colors.

show_gallery(smallgraph(:petersen), (2, 3); format=:png,
	vertex_configs=[rand(1:2, 10) for k=1:6],
	edge_configs=[rand(1:2, 15) for k=1:6], xpad=0.5, ypad=0.5, 
	vertex_color=Dict(1=>"white", 2=>"blue"),
	edge_color=Dict(1=>"black", 2=>"cyan"),
	edge_line_style="dashed")