### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 8b7e7fac-edb1-11ec-0a14-3d07cf4570c9
# ╠═╡ show_logs = false
using Pkg; Pkg.activate(".."); Pkg.instantiate()

# ╔═╡ 11e91f82-a10e-4d7a-a9f4-93b87a317177
using Revise, PlutoUI; TableOfContents(depth=1)

# ╔═╡ 91f620a0-380a-4da8-844f-2989ef507a66
using Graphs, LuxorGraphPlot

# ╔═╡ b4315259-a737-410a-b48b-b16882292866
md"# Show a graph"

# ╔═╡ 2025bc1a-7ba2-49d1-bad6-60372f476676
md"Show a graph with spring (default) layout."

# ╔═╡ 0693c4ee-5fef-416b-a560-09d19872091b
graph = smallgraph(:petersen)

# ╔═╡ 32773b61-0a5f-45f8-96fa-a277a7c71e6f
show_graph(graph; optimal_distance=2.0)

# ╔═╡ a10c86b3-853c-4286-aedf-7d1daad93411
md"specify the layout and texts manually"

# ╔═╡ fa799355-9cdb-401b-b15c-e858bb224489
let
	rot15(a, b, i::Int) = cos(2i*π/5)*a + sin(2i*π/5)*b, cos(2i*π/5)*b - sin(2i*π/5)*a
	locations = [[rot15(0.0, 1.0, i) for i=0:4]..., [rot15(0.0, 0.5, i) for i=0:4]...]
	show_graph(graph; locs=locations, texts=[string('a'+i) for i=0:9], fontsize=8, xpad_right=5) do  # extra commands
		LuxorGraphPlot.Luxor.fontsize(22)
		LuxorGraphPlot.Luxor.text("haha, the fontsize is so big!", 200, 120.0)
	end
end

# ╔═╡ 60f073fb-6c20-4207-be27-7eef730b3833
md"specify colors, shapes and sizes"

# ╔═╡ 8d3a74c1-1ad2-458a-8078-bb81d48f1783
show_graph(graph;
	vertex_colors=rand(["blue", "red"], 10),
	vertex_sizes=rand(10) .* 0.2 .+ 0.1,
	vertex_stroke_colors=rand(["blue", "red"], 10),
	vertex_text_colors=rand(["white", "black"], 10),
	edge_colors=rand(["blue", "red"], 15),
	vertex_shapes=rand(["circle", "box"], 10)
)

# ╔═╡ d51dd930-28d0-45a3-92e1-e46bcc073d72
md"for uniform colors/sizes, you can make life easier by specifying global colors."

# ╔═╡ 96209743-1ec9-4706-9f8e-3ec63f516104
show_graph(graph;
	vertex_fill_color="blue",
	vertex_size=0.15,
	vertex_stroke_color="transparent",
	vertex_text_color="white",
	edge_color="green",
)

# ╔═╡ 420f32d0-8184-48b4-99c5-642b68a0370e
md"One can also dump an image to a file"

# ╔═╡ 5bf69a0b-32c2-4e44-907f-2ce9d9c33435
show_graph(graph; filename=tempname()*".svg")

# ╔═╡ 322945ed-eda1-4e69-87e7-3f88115adc37
md"or render it in another format"

# ╔═╡ 84c1d386-1661-40f6-a951-1951007c340d
show_graph(graph; format=:svg)

# ╔═╡ a1bd8945-4f34-4313-be71-9583dd0d2c5c
md"# Show a gallery"

# ╔═╡ d29987d0-5a35-42a3-9f5f-6283a2d89704
md"One can use a boolean vector to represent boolean variables on a vertex or an edge."

# ╔═╡ 793d4df0-50a8-40f9-bad0-bc9f2632f5e4
show_gallery(smallgraph(:petersen), (2, 3); format=:png,
	vertex_configs=[rand(Bool, 10) for k=1:6],
	edge_configs=[rand(Bool, 15) for k=1:6], xpad=0.5, ypad=0.5)

# ╔═╡ c0612439-8a0b-4568-8011-387041423023
md"for non-boolean configurations, you need to provide a map to colors."

# ╔═╡ 8d587d56-657a-4430-b5a2-a7224c6d7665
show_gallery(smallgraph(:petersen), (2, 3); format=:png,
	vertex_configs=[rand(1:2, 10) for k=1:6],
	edge_configs=[rand(1:2, 15) for k=1:6], xpad=0.5, ypad=0.5, 
	vertex_color=Dict(1=>"white", 2=>"blue"),
	edge_color=Dict(1=>"black", 2=>"cyan"),
	edge_line_style="dashed")

# ╔═╡ 7e6b731b-2845-4933-bf58-555046123457
md"# API references"

# ╔═╡ c43162e3-4be9-4093-b2c2-c9f09caa5eb2
@doc show_graph

# ╔═╡ 6d218840-b2c7-4f0b-9de5-b13e18309ec3
@doc show_gallery

# ╔═╡ Cell order:
# ╟─8b7e7fac-edb1-11ec-0a14-3d07cf4570c9
# ╟─11e91f82-a10e-4d7a-a9f4-93b87a317177
# ╠═91f620a0-380a-4da8-844f-2989ef507a66
# ╟─b4315259-a737-410a-b48b-b16882292866
# ╟─2025bc1a-7ba2-49d1-bad6-60372f476676
# ╠═0693c4ee-5fef-416b-a560-09d19872091b
# ╠═32773b61-0a5f-45f8-96fa-a277a7c71e6f
# ╟─a10c86b3-853c-4286-aedf-7d1daad93411
# ╠═fa799355-9cdb-401b-b15c-e858bb224489
# ╟─60f073fb-6c20-4207-be27-7eef730b3833
# ╠═8d3a74c1-1ad2-458a-8078-bb81d48f1783
# ╟─d51dd930-28d0-45a3-92e1-e46bcc073d72
# ╠═96209743-1ec9-4706-9f8e-3ec63f516104
# ╟─420f32d0-8184-48b4-99c5-642b68a0370e
# ╠═5bf69a0b-32c2-4e44-907f-2ce9d9c33435
# ╟─322945ed-eda1-4e69-87e7-3f88115adc37
# ╠═84c1d386-1661-40f6-a951-1951007c340d
# ╟─a1bd8945-4f34-4313-be71-9583dd0d2c5c
# ╟─d29987d0-5a35-42a3-9f5f-6283a2d89704
# ╠═793d4df0-50a8-40f9-bad0-bc9f2632f5e4
# ╟─c0612439-8a0b-4568-8011-387041423023
# ╠═8d587d56-657a-4430-b5a2-a7224c6d7665
# ╟─7e6b731b-2845-4933-bf58-555046123457
# ╠═c43162e3-4be9-4093-b2c2-c9f09caa5eb2
# ╠═6d218840-b2c7-4f0b-9de5-b13e18309ec3
