var documenterSearchIndex = {"docs":
[{"location":"generated/features/","page":"Features","title":"Features","text":"EditURL = \"../../../examples/features.jl\"","category":"page"},{"location":"generated/features/","page":"Features","title":"Features","text":"using LuxorGraphPlot, LuxorGraphPlot.Luxor\nusing LuxorGraphPlot.TensorNetwork","category":"page"},{"location":"generated/features/#Node-styles","page":"Features","title":"Node styles","text":"","category":"section"},{"location":"generated/features/","page":"Features","title":"Features","text":"We a combination of nodestore and with_nodes to draw nodes with automatically inferred bounding boxes.","category":"page"},{"location":"generated/features/","page":"Features","title":"Features","text":"nodestore() do ns  # store nodes in the nodestore (used to infer the bounding box)\n    a = circle!((0, 0), 30)\n    b = ellipse!((100, 0), 60, 40)\n    c = box!((200, 0), 50, 50; smooth=10)\n    d = polygon!([rotatepoint(Point(30, 0), i*π/3) for i=1:6] .+ Ref(Point(300, 0)); smooth=5)\n    with_nodes(ns) do  # the context manager to draw nodes\n        fontsize(6)\n        for (node, shape) in [(a, \"circle\"), (b, \"ellipse\"), (c, \"box\"), (d, \"polygon\")]\n            stroke(node)\n            text(shape, node)\n            for p in [left, right, top, bottom, topleft, bottomleft, topright, bottomright, LuxorGraphPlot.center]\n                text(string(p), offset(fill(circlenode(p(node), 3)), (0, 6)))\n            end\n        end\n    end\nend","category":"page"},{"location":"generated/features/#Connection-points","page":"Features","title":"Connection points","text":"","category":"section"},{"location":"generated/features/","page":"Features","title":"Features","text":"nodestore() do ns\n    a1 = circle!((150, 150), 30)\n    a2 = circle!((450, 150), 30)\n    box1s = [offset(boxnode(rotatepoint(Point(100, 0), i*π/8), 20, 20), a1.loc) for i=1:16]\n    box2s = offset.(box1s, Ref(a2.loc-a1.loc))\n    append!(ns, box1s)\n    append!(ns, box2s)\n    with_nodes(ns) do\n        fontsize(14)\n        stroke(a1)\n        stroke(a2)\n        for b in box1s\n            stroke(b)\n            line(a1, b; mode=:exact)\n        end\n        for b in box2s\n            stroke(b)\n            line(a2, b; mode=:natural)\n        end\n        text(\"exact\", a1)\n        text(\"natural\", a2)\n    end\nend","category":"page"},{"location":"generated/features/#Connector-styles","page":"Features","title":"Connector styles","text":"","category":"section"},{"location":"generated/features/","page":"Features","title":"Features","text":"nodestore() do ns\n\tradius = 30\n    a = boxnode(Point(50, 50), 40, 40; smooth=5)\n    b = offset(a, (100, 0))\n    groups = Matrix{Vector{Node}}(undef, 2, 3)\n    for j=0:1\n        for k = 0:2\n            items = [offset(a, (200k, 150j)), offset(b, (200k, 150j))]\n            groups[j+1, k+1] = items\n            append!(ns, items)\n            push!(ns, offset(midpoint(items...), (0, 70)))\n        end\n    end\n    with_nodes() do\n        fontsize(28)\n        # the default smooth method is \"curve\", it must take two control points.\n        for j=1:2\n            for k = 1:3\n                a, b = groups[j, k]\n                cps  = [[offset(midpoint(a, b), (0, 50))], [offset(a, (0, 50)), offset(b, (0, 50))]][j]\n                smoothprops = [\n                    Dict(:method=>length(cps) == 1 ? \"nosmooth\" : \"curve\"),\n                    Dict(:method=>\"smooth\", :radius=>10),\n                    Dict(:method=>\"bezier\", :radius=>10),\n                ][k]\n                stroke(a)\n                stroke(b)\n                text(\"A\", a)\n                text(\"B\", b)\n                Connection(a, b; smoothprops, control_points=cps) |> stroke\n                @layer begin\n                    fontsize(14)\n                    text(string(get(smoothprops, :method, \"\")), offset(midpoint(a, b), (0, 70)))\n                end\n            end\n        end\n    end\nend","category":"page"},{"location":"generated/features/","page":"Features","title":"Features","text":"","category":"page"},{"location":"generated/features/","page":"Features","title":"Features","text":"This page was generated using Literate.jl.","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"EditURL = \"../../../examples/tutorials.jl\"","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"# Show a graph\nusing Graphs, LuxorGraphPlot, LuxorGraphPlot.Luxor","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"Show a graph with spring (default) layout.","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"graph = smallgraph(:petersen)\n\nshow_graph(graph)","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"specify the layout and texts manually","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"rot15(a, b, i::Int) = cos(2i*π/5)*a + sin(2i*π/5)*b, cos(2i*π/5)*b - sin(2i*π/5)*a\nlocations = [[rot15(0.0, 50.0, i) for i=0:4]..., [rot15(0.0, 25.0, i) for i=0:4]...]\nshow_graph(graph, locations,\n        texts=[string('a'+i) for i=0:9], padding_right=300,\n        config=GraphDisplayConfig(; background=\"gray\")) do nd\n    # extra commands, transformer is a function that convert graph-axis to canvas axis.\n    LuxorGraphPlot.Luxor.fontsize(22)\n    xmin, xmax, ymin, ymax = LuxorGraphPlot.get_bounding_box(nd)\n    LuxorGraphPlot.text(\"haha, the fontsize is so big!\", Point(xmax + 20, (ymin + ymax) / 2))\nend","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"specify colors, shapes and sizes","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"show_graph(graph;\n\tvertex_colors=rand([\"blue\", \"red\"], 10),\n\tvertex_sizes=rand(10) .* 10 .+ 5,\n\tvertex_stroke_colors=rand([\"blue\", \"red\"], 10),\n\tvertex_text_colors=rand([\"white\", \"black\"], 10),\n\tedge_colors=rand([\"blue\", \"red\"], 15),\n\tvertex_shapes=rand([:circle, :box], 10)\n)","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"for uniform colors/sizes, you can make life easier by specifying global colors.","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"show_graph(graph;\n    config = GraphDisplayConfig(\n        vertex_color=\"blue\",\n        vertex_size=7.5,\n        vertex_stroke_color=\"transparent\",\n        vertex_text_color=\"white\",\n        edge_color=\"green\"\n    )\n)","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"One can also dump an image to a file","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"show_graph(graph; format=:svg)","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"or render it in another format","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"show_graph(graph; format=:svg)","category":"page"},{"location":"generated/tutorials/#Layouts","page":"Tutorials","title":"Layouts","text":"","category":"section"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"The default layout is :auto, which uses :spring if locs is nothing.","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"show_graph(graph, SpringLayout())\n\nshow_graph(graph, StressLayout())\n\nshow_graph(graph, SpectralLayout())","category":"page"},{"location":"generated/tutorials/#Show-a-gallery","page":"Tutorials","title":"Show a gallery","text":"","category":"section"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"One can use a boolean vector to represent boolean variables on a vertex or an edge.","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"locs = render_locs(graph, SpringLayout())\nmatrix = [GraphViz(graph, locs; vertex_colors=[rand(Luxor.RGB) for i=1:10],\n    edge_colors=[rand(Luxor.RGB) for i=1:15]) for i=1:2, j=1:4]\nshow_gallery(matrix; format=:png, padding_left=20, padding_right=20, padding_top=20, padding_bottom=20)","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"","category":"page"},{"location":"generated/tutorials/","page":"Tutorials","title":"Tutorials","text":"This page was generated using Literate.jl.","category":"page"},{"location":"ref/#API-manual","page":"References","title":"API manual","text":"","category":"section"},{"location":"ref/","page":"References","title":"References","text":"Modules = [LuxorGraphPlot, LuxorGraphPlot.Layouts]\nOrder   = [:function, :type]","category":"page"},{"location":"ref/#Luxor.midpoint-Tuple{Node, Node}","page":"References","title":"Luxor.midpoint","text":"midpoint(a::Node, b::Node)\n\nGet the midpoint of two nodes. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.bottom-Tuple{Node}","page":"References","title":"LuxorGraphPlot.bottom","text":"bottom(n::Node)\n\nGet the bottom boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.bottomleft-Tuple{Node}","page":"References","title":"LuxorGraphPlot.bottomleft","text":"bottomleft(n::Node)\n\nGet the bottomleft boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.bottomright-Tuple{Node}","page":"References","title":"LuxorGraphPlot.bottomright","text":"bottomright(n::Node)\n\nGet the bottomright boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.boundary-Tuple{Node, String}","page":"References","title":"LuxorGraphPlot.boundary","text":"boundary(n::Node, s::String)\nboundary(n::Node, angle::Real)\n\nGet the boundary point of a node in a direction. The direction can be specified by a string or an angle. Possible strings are: \"left\", \"right\", \"top\", \"bottom\", \"topright\", \"topleft\", \"bottomleft\", \"bottomright\".\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.box!-Tuple","page":"References","title":"LuxorGraphPlot.box!","text":"box!([nodestore, ]args...; kwargs...) = push!(nodestore, boxnode(args...; kwargs...))\n\nAdd a box shaped node to the nodestore. Please refer to boxnode for more information. If nodestore is not provided, the current nodestore is used.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.boxnode-Tuple{Any, Any, Any}","page":"References","title":"LuxorGraphPlot.boxnode","text":"box(loc, width, height; props...) = Node(:box, loc; width, height, props...)\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.center-Tuple{Node}","page":"References","title":"LuxorGraphPlot.center","text":"center(n::Node)\n\nGet the center point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.circle!-Tuple","page":"References","title":"LuxorGraphPlot.circle!","text":"circle!([nodestore, ]args...; kwargs...) = push!(nodestore, circlenode(args...; kwargs...))\n\nAdd a circle shaped node to the nodestore. Please refer to circlenode for more information. If nodestore is not provided, the current nodestore is used.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.circlenode-Tuple{Any, Any}","page":"References","title":"LuxorGraphPlot.circlenode","text":"circle(loc, radius; props...) = Node(:circle, loc; radius, props...)\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.darktheme!-Tuple{GraphDisplayConfig}","page":"References","title":"LuxorGraphPlot.darktheme!","text":"darktheme!(config::GraphDisplayConfig)\n\nSet the dark theme for the graph display.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.dot!-Tuple","page":"References","title":"LuxorGraphPlot.dot!","text":"dot!([nodestore, ]args...; kwargs...) = push!(nodestore, dotnode(args...; kwargs...))\n\nAdd a dot shaped node to the nodestore. Please refer to dotnode for more information. If nodestore is not provided, the current nodestore is used.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.dotnode-Tuple{Real, Real}","page":"References","title":"LuxorGraphPlot.dotnode","text":"dotnode(x, y)\ndotnode(p::Point)\n\nCreate a node with a shape :dot and a location.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.ellipse!-Tuple","page":"References","title":"LuxorGraphPlot.ellipse!","text":"ellipse!([nodestore, ]args...; kwargs...) = push!(nodestore, ellipsenode(args...; kwargs...))\n\nAdd a ellipse shaped node to the nodestore. Please refer to ellipsenode for more information. If nodestore is not provided, the current nodestore is used.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.ellipsenode-Tuple{Any, Any, Any}","page":"References","title":"LuxorGraphPlot.ellipsenode","text":"ellipse(loc, width, height; props...) = Node(:ellipse, loc; width, height, props...)\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.left-Tuple{Node}","page":"References","title":"LuxorGraphPlot.left","text":"left(n::Node)\n\nGet the left boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.lighttheme!-Tuple{GraphDisplayConfig}","page":"References","title":"LuxorGraphPlot.lighttheme!","text":"lighttheme!(config::GraphDisplayConfig)\n\nSet the light theme for the graph display.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.line!-Tuple","page":"References","title":"LuxorGraphPlot.line!","text":"line!([nodestore, ]args...; kwargs...) = push!(nodestore, linenode(args...; kwargs...))\n\nAdd a line shaped node to the nodestore. Please refer to linenode for more information. If nodestore is not provided, the current nodestore is used.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.linenode-Tuple","page":"References","title":"LuxorGraphPlot.linenode","text":"line(args...; props...) = Node(:line, mid; relpath, props...)\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.nodestore-Tuple{Any}","page":"References","title":"LuxorGraphPlot.nodestore","text":"nodestore(f)\n\nCreate a NodeStore context, such that box!, circle!, polygon!, dot! and line! will add nodes to the nodestore. The nodestore is passed to the function f as an argument.\n\nExample\n\njulia> using LuxorGraphPlot, LuxorGraphPlot.Luxor\n\njulia> nodestore() do ns\n    box = box!(ns, (100, 100), 100, 100)\n    circle = circle!(ns, (200, 200), 50)\n    with_nodes(ns) do\n        stroke(box)\n        stroke(circle)\n        Luxor.line(topright(box), circle)\n    end\nend\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.offset-Tuple{Node, Union{Luxor.Point, Tuple}}","page":"References","title":"LuxorGraphPlot.offset","text":"offset(n::Node, p::Union{Tuple,Point})\noffset(n::Node, direction, distance)\noffset(n::Node, direction::Node, distance)\n\nOffset a node towards a direction or another node. The direction can be specified by a tuple, a Point or a Node.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.polygon!-Tuple","page":"References","title":"LuxorGraphPlot.polygon!","text":"polygon!([nodestore, ]args...; kwargs...) = push!(nodestore, polygonnode(args...; kwargs...))\n\nAdd a polygon shaped node to the nodestore. Please refer to polygonnode for more information. If nodestore is not provided, the current nodestore is used.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.polygonnode-Tuple{Any, AbstractVector}","page":"References","title":"LuxorGraphPlot.polygonnode","text":"polygon([loc, ]relpath::AbstractVector; props...) = Node(:polygon, loc; relpath, props...)\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.right-Tuple{Node}","page":"References","title":"LuxorGraphPlot.right","text":"right(n::Node)\n\nGet the right boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.show_gallery-Tuple{Any, AbstractMatrix{GraphViz}}","page":"References","title":"LuxorGraphPlot.show_gallery","text":"show_gallery([f, ]stores::AbstractMatrix{GraphViz};\n    kwargs...\n    )\n\nShow a gallery of graphs in VSCode, Pluto or Jupyter notebook, or save it to a file.\n\nPositional arguments\n\nf is a function that returns extra Luxor plotting statements.\nstores is a matrix of GraphViz instances.\n\nKeyword arguments\n\nconfig is a GraphDisplayConfig instance.\npadding_left::Int = 10, the padding on the left side of the drawing\npadding_right::Int = 10, the padding on the right side of the drawing\npadding_top::Int = 10, the padding on the top side of the drawing\npadding_bottom::Int = 10, the padding on the bottom side of the drawing\nformat is the output format, which can be :svg, :png or :pdf.\nfilename is a string as the output filename.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.show_graph-Tuple{GraphViz}","page":"References","title":"LuxorGraphPlot.show_graph","text":"show_graph([f, ]graph::AbstractGraph;\n    kwargs...\n    )\n\nShow a graph in VSCode, Pluto or Jupyter notebook, or save it to a file.\n\nPositional arguments\n\nf is a function that returns extra Luxor plotting statements.\ngraph is a graph instance.\nlocs is a vector of tuples for specifying the vertex locations, or a AbstractLayout instance.\n\nKeyword arguments\n\nconfig is a GraphDisplayConfig instance.\nvertex_colors is a vector of color strings for specifying vertex fill colors.\nvertex_sizes is a vector of real numbers for specifying vertex sizes.\nvertex_shapes is a vector of strings for specifying vertex shapes, the string should be \"circle\" or \"box\".\nvertex_stroke_colors is a vector of color strings for specifying vertex stroke colors.\nvertex_text_colors is a vector of color strings for specifying vertex text colors.\nedge_colors is a vector of color strings for specifying edge colors.\ntexts is a vector of strings for labeling vertices.\n\npadding_left::Int = 10, the padding on the left side of the drawing\npadding_right::Int = 10, the padding on the right side of the drawing\npadding_top::Int = 10, the padding on the top side of the drawing\npadding_bottom::Int = 10, the padding on the bottom side of the drawing\nformat is the output format, which can be :svg, :png or :pdf.\nfilename is a string as the output filename.\n\nExample\n\njulia> using Graphs, LuxorGraphPlot\n\njulia> show_graph(smallgraph(:petersen); format=:png, vertex_colors=rand([\"blue\", \"red\"], 10));\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.stroke-Tuple{Union{Connection, Node}}","page":"References","title":"LuxorGraphPlot.stroke","text":"circle(n::Node, action=:stroke)\n\nStroke a node with line.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.top-Tuple{Node}","page":"References","title":"LuxorGraphPlot.top","text":"top(n::Node)\n\nGet the top boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.topleft-Tuple{Node}","page":"References","title":"LuxorGraphPlot.topleft","text":"topleft(n::Node)\n\nGet the topleft boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.topright-Tuple{Node}","page":"References","title":"LuxorGraphPlot.topright","text":"topright(n::Node)\n\nGet the topright boundary point of a node. Returns a Node of shape :dot.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.with_nodes-Tuple{Any}","page":"References","title":"LuxorGraphPlot.with_nodes","text":"with_nodes(f[, nodestore]; kwargs...)\n\nCreate a drawing with the nodes in the nodestore. The bounding box of the drawing is determined by the bounding box of the nodes in the nodestore. If nodestore is not provided, the current nodestore is used.\n\nKeyword arguments\n\npadding_left::Int=10: Padding on the left side of the drawing.\npadding_right::Int=10: Padding on the right side of the drawing.\npadding_top::Int=10: Padding on the top side of the drawing.\npadding_bottom::Int=10: Padding on the bottom side of the drawing.\nformat::Symbol=:svg: The format of the drawing. Available formats are :png, :pdf, :svg...\nfilename::String=nothing: The filename of the drawing. If nothing, a temporary file is created.\nbackground::String=\"white\": The background color of the drawing.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.Connection","page":"References","title":"LuxorGraphPlot.Connection","text":"Connection(start, stop; isarrow=false, mode=:exact, arrowprops=Dict{Symbol, Any}(), control_points=Point[], smoothprops=Dict{Symbol, Any}())\n\nCreate a connection between two nodes. The connection can be a line, a curve, a bezier curve, a smooth curve or a zig-zag line.\n\nRequired Arguments\n\nstart::Node: the start node\nstop::Node: the stop node\n\nOptional Keyword Arguments\n\nisarrow=false: whether to draw an arrow at the end of the connection\nmode=:exact: the mode to get the connection point, can be :exact or :natural\narrowprops=Dict{Symbol, Any}(): the properties of the arrow\ncontrol_points=Point[]: the control points for the connection\nsmoothprops=Dict{Symbol, Any}(): the properties of the smooth curve\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.GraphDisplayConfig","page":"References","title":"LuxorGraphPlot.GraphDisplayConfig","text":"GraphDisplayConfig\n\nThe configuration for graph display.\n\nKeyword arguments\n\nlocs is a vector of tuples for specifying the vertex locations.\nedges is a vector of tuples for specifying the edges.\nfontsize::Float64 = 12.0, the font size\nfontface::String = \"\", the font face, leave empty to follow system\nvertex_text_color = \"black\", the default text color\nvertex_stroke_color = \"black\", the default stroke color for vertices\nvertex_color = \"transparent\", the default default fill color for vertices\nvertex_size::Float64 = 10.0, the default vertex size\nvertex_shape::Symbol = :circle, the default vertex shape, which can be :circle, :box or :dot\nvertex_line_width::Float64 = 1, the default vertex stroke line width\nvertex_line_style::String = \"solid\", the line style of vertex stroke, which can be one of [\"solid\", \"dotted\", \"dot\", \"dotdashed\", \"longdashed\", \"shortdashed\", \"dash\", \"dashed\", \"dotdotdashed\", \"dotdotdotdashed\"]\nedge_color = \"black\", the default edge color\nedge_line_width::Float64 = 1, the default line width\nedge_style::String = \"solid\", the line style of edges, which can be one of [\"solid\", \"dotted\", \"dot\", \"dotdashed\", \"longdashed\", \"shortdashed\", \"dash\", \"dashed\", \"dotdotdashed\", \"dotdotdotdashed\"]\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.GraphViz","page":"References","title":"LuxorGraphPlot.GraphViz","text":"GraphViz\n\nThe struct for storing graph visualization information.\n\nKeyword arguments\n\nvertex_colors is a vector of color strings for specifying vertex fill colors.\nvertex_sizes is a vector of real numbers for specifying vertex sizes.\nvertex_shapes is a vector of strings for specifying vertex shapes, the string should be \"circle\" or \"box\".\nvertex_stroke_colors is a vector of color strings for specifying vertex stroke colors.\nvertex_text_colors is a vector of color strings for specifying vertex text colors.\nedge_colors is a vector of color strings for specifying edge colors.\ntexts is a vector of strings for labeling vertices.\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.Node","page":"References","title":"LuxorGraphPlot.Node","text":"Node(shape::Symbol, loc; props...)\n\nCreate a node with a shape and a location. The shape can be :circle, :ellipse, :box, :polygon, :line or :dot.\n\nRequired Keyword Arguments\n\nellipse: [:width, :height]\ncircle: [:radius]\nline: [:relpath]\ndot: Symbol[]\npolygon: [:relpath]\nbox: [:width, :height]\n\nOptional Keyword Arguments\n\nellipse: Dict{Symbol, Any}()\ncircle: Dict{Symbol, Any}()\nline: Dict{Symbol, Any}(:arrowstyle => \"-\")\ndot: Dict{Symbol, Any}()\npolygon: Dict{Symbol, Any}(:smooth => 0, :close => true)\nbox: Dict{Symbol, Any}(:smooth => 0)\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.NodeStore","page":"References","title":"LuxorGraphPlot.NodeStore","text":"NodeStore <: AbstractNodeStore\n\nA collection of nodes, which is used to infer the bounding box of a drawing.\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.Layouts.LayeredSpringLayout-Tuple{}","page":"References","title":"LuxorGraphPlot.Layouts.LayeredSpringLayout","text":"LayeredSpringLayout(; zlocs, optimal_distance, aspect_ration=0.2)\n\nCreate a layered spring layout.\n\nKeyword Arguments\n\nzlocs: the z-axis locations\noptimal_distance::Float64: the optimal distance between vertices\naspect_ration::Float64: the aspect ratio of the z-axis\nα0::Float64: the initial moving speed\nmaxiter::Int: the maximum number of iterations\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.Layouts.LayeredStressLayout-Tuple{}","page":"References","title":"LuxorGraphPlot.Layouts.LayeredStressLayout","text":"LayeredStressLayout(; zlocs, optimal_distance, aspect_ration=0.2)\n\nCreate a layered stress layout.\n\nKeyword Arguments\n\nzlocs: the z-axis locations\noptimal_distance::Float64: the optimal distance between vertices\naspect_ration::Float64: the aspect ratio of the z-axis\nmaxiter::Int: the maximum number of iterations\nrtol::Float64: the absolute tolerance\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.Layouts.render_locs-Tuple{Graphs.AbstractGraph, AbstractVector}","page":"References","title":"LuxorGraphPlot.Layouts.render_locs","text":"render_locs(graph, layout::Layout)\n\nRender the vertex locations for a graph from an AbstractLayout instance.\n\nArguments\n\ngraph::AbstractGraph: the graph to render\nlayout::AbstractLayout: the layout algorithm\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.Layouts.spectral_layout","page":"References","title":"LuxorGraphPlot.Layouts.spectral_layout","text":"spectral_layout(g::AbstractGraph, weight=nothing; optimal_distance=50.0)\n\nSpectral layout for graph plotting, returns a vector of vertex locations.\n\n\n\n\n\n","category":"function"},{"location":"ref/#LuxorGraphPlot.Layouts.spring_layout-Tuple{Graphs.AbstractGraph}","page":"References","title":"LuxorGraphPlot.Layouts.spring_layout","text":"spring_layout(g::AbstractGraph;\n                   locs=nothing,\n                   optimal_distance=50.0,   # the optimal vertex distance\n                   maxiter=100,\n                   α0=2*optimal_distance,  # initial moving speed\n                   mask::AbstractVector{Bool}=trues(nv(g))   # mask for which to relocate\n                   )\n\nSpring layout for graph plotting, returns a vector of vertex locations.\n\nnote: Note\nThis function is copied from GraphPlot.jl, where you can find more information about his function.\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.Layouts.stressmajorize_layout-Tuple{Graphs.AbstractGraph}","page":"References","title":"LuxorGraphPlot.Layouts.stressmajorize_layout","text":"stressmajorize_layout(g::AbstractGraph;\n                           locs=rand_points_2d(nv(g)),\n                           w=nothing,\n                           optimal_distance=50.0,   # the optimal vertex distance\n                           maxiter = 400 * nv(g)^2,\n                           rtol=1e-2,\n                           )\n\nStress majorization layout for graph plotting, returns a vector of vertex locations.\n\nReferences\n\nhttps://github.com/JuliaGraphs/GraphPlot.jl/blob/e97063729fd9047c4482070870e17ed1d95a3211/src/stress.jl\n\n\n\n\n\n","category":"method"},{"location":"ref/#LuxorGraphPlot.Layouts.AbstractLayout","page":"References","title":"LuxorGraphPlot.Layouts.AbstractLayout","text":"AbstractLayout\n\nAbstract type for layout algorithms.\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.Layouts.Layered","page":"References","title":"LuxorGraphPlot.Layouts.Layered","text":"Layered <: AbstractLayout\n\nLayered version of a parent layout algorithm.\n\nFields\n\nparent::LT: the parent layout algorithm\nzlocs::Vector{T}: the z-axis locations\naspect_ratio::Float64: the aspect ratio of the z-axis\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.Layouts.Point","page":"References","title":"LuxorGraphPlot.Layouts.Point","text":"Point{D, T}\n\nA point in D-dimensional space, with coordinates of type T.\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.Layouts.SpectralLayout","page":"References","title":"LuxorGraphPlot.Layouts.SpectralLayout","text":"SpectralLayout <: AbstractLayout\n\nA layout algorithm based on spectral graph theory.\n\nFields\n\noptimal_distance::Float64: the optimal distance between vertices\ndimension::Int: the number of dimensions\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.Layouts.SpringLayout","page":"References","title":"LuxorGraphPlot.Layouts.SpringLayout","text":"SpringLayout <: AbstractLayout\n\nA layout algorithm based on a spring model.\n\nFields\n\noptimal_distance::Float64: the optimal distance between vertices\nmaxiter::Int: the maximum number of iterations\nα0::Float64: the initial moving speed\nmeta::Dict{Symbol, Any}: graph dependent meta information, including\ninitial_locs: initial vertex locations\nmask: boolean mask for which vertices to relocate\n\n\n\n\n\n","category":"type"},{"location":"ref/#LuxorGraphPlot.Layouts.StressLayout","page":"References","title":"LuxorGraphPlot.Layouts.StressLayout","text":"StressLayout <: AbstractLayout\n\nA layout algorithm based on stress majorization.\n\nFields\n\noptimal_distance::Float64: the optimal distance between vertices\nmaxiter::Int: the maximum number of iterations\nrtol::Float64: the absolute tolerance\ninitial_locs: initial vertex locations\nmask: boolean mask for which vertices to relocate\nmeta::Dict{Symbol, Any}: graph dependent meta information, including\ninitial_locs: initial vertex locations\nmask: boolean mask for which vertices to relocate\n\n\n\n\n\n","category":"type"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = LuxorGraphPlot","category":"page"},{"location":"#LuxorGraphPlot","page":"Home","title":"LuxorGraphPlot","text":"","category":"section"},{"location":"#Features","page":"Home","title":"Features","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"automatically detecting the size of the diagram by combining nodestore and with_nodes.\nconnecting nodes with edges, finding middle points and corners of the nodes. Related APIs: Luxor.midpoint, left, right, top, bottom, center, boundary.\nsimple graph layouts, such as SpringLayout, StressLayout, SpectralLayout, LayeredSpringLayout and LayeredStressLayout.","category":"page"}]
}
